# Phase 1 Implementation Guide - Step by Step

## 📋 Pre-Implementation Checklist

- [ ] Full database backup created
- [ ] Staging environment available for testing
- [ ] Team informed of migration schedule
- [ ] Rollback procedure documented
- [ ] Read this entire guide
- [ ] Review SQL migration script

---

## 🚀 WEEK 1: Database Migration

### Step 1.1: Backup Your Database

```bash
# Create backup with timestamp
mysqldump -u root drais_school > backup_$(date +%Y%m%d_%H%M%S).sql

# Verify backup size
ls -lh backup_*.sql

# Store backup in safe location
cp backup_*.sql /path/to/backup/
```

### Step 1.2: Review Migration Script

```bash
# Examine the migration script first
cat sql/PHASE_1_MIGRATION.sql | head -100

# Count the number of ALTER statements
grep -c "ALTER TABLE" sql/PHASE_1_MIGRATION.sql

# Expected: ~5-6 ALTER statements
```

### Step 1.3: Run Migration on Staging First

```bash
# IMPORTANT: Test on staging first!
mysql -u root drais_school_staging < sql/PHASE_1_MIGRATION.sql

# Check for errors
echo $?  # Should output 0 for success
```

### Step 1.4: Verify Schema Changes

```bash
# Login to MySQL
mysql -u root drais_school_staging

# Run verification queries
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'drais_school_staging' 
AND TABLE_NAME IN ('schools', 'biometric_devices', 'device_user_mappings', 'activity_logs')
ORDER BY TABLE_NAME;

# Expected output: 4 tables (schools, biometric_devices, device_user_mappings, activity_logs, etc)
```

### Step 1.5: Check Data Integrity

```sql
-- Check students table got school_id
SELECT COUNT(DISTINCT school_id) FROM students;

-- Expected: 1 (all with school_id=1 from default migration)

-- Check no orphaned records
SELECT COUNT(*) FROM students WHERE school_id IS NULL;

-- Expected: 0

-- Verify new tables are empty (initial state)
SELECT COUNT(*) FROM biometric_devices;
SELECT COUNT(*) FROM device_user_mappings;
SELECT COUNT(*) FROM activity_logs;

-- Expected: All 0
```

### Step 1.6: Run on Production

```bash
# Only after successful staging test!
mysql -u root drais_school < sql/PHASE_1_MIGRATION.sql

# Monitor for errors
echo $? 

# Take another backup after migration
mysqldump -u root drais_school > backup_after_migration_$(date +%Y%m%d_%H%M%S).sql
```

---

## ✅ WEEK 2: Backend API Updates

### Step 2.1: Update Environment Variables

```bash
# Add to .env.local (if not exists)
ENABLE_MULTI_TENANCY=true
DEFAULT_SCHOOL_ID=1
MULTI_TENANCY_STRICT_MODE=false  # Set to true after testing
```

### Step 2.2: Update Students API

Current API: `/api/students/full` doesn't require `school_id`

Update to: `/api/students/full?school_id=1`

```typescript
// Before:
// GET /api/students/full?q=john

// After:
// GET /api/students/full?q=john&school_id=1

// Test it:
curl "http://localhost:3000/api/students/full?q=&school_id=1"
```

### Step 2.3: Update Edit Endpoint

The existing `/api/students/edit` needs to verify school ownership:

```typescript
// Add this check at the top of the PUT handler:
const tenant = extractTenantContext(req);
if (!tenant) {
  return NextResponse.json(
    { success: false, error: 'school_id is required' },
    { status: 400 }
  );
}

// Verify student belongs to school
const belongsToSchool = await verifyCrossSchoolAccess(tenant.school_id, studentId);
if (!belongsToSchool) {
  return NextResponse.json(
    { success: false, error: 'Student not found in your school' },
    { status: 403 }
  );
}
```

### Step 2.4: Test All Updated APIs

```bash
# Test with school_id
curl -X GET "http://localhost:3000/api/students/full?school_id=1"

# Test devices endpoint
curl -X GET "http://localhost:3000/api/devices?school_id=1"

# Test device-mappings endpoint
curl -X GET "http://localhost:3000/api/device-mappings?school_id=1"
```

### Step 2.5: Add Logging

```typescript
// In each API, add logging
console.log(`[School ${tenant.school_id}] Processing request`, {
  action: 'create_student',
  studentId,
  timestamp: new Date().toISOString()
});
```

---

## 🧪 WEEK 3: Testing & Validation

### Step 3.1: Unit Tests

Create `tests/multi-tenancy.test.ts`:

```typescript
import { extractTenantContext, validateSchoolAccess } from '@/lib/multi-tenancy';

describe('Multi-Tenancy', () => {
  it('should extract school_id from URL', () => {
    const req = new NextRequest('http://localhost:3000/api/students?school_id=1');
    const tenant = extractTenantContext(req);
    expect(tenant?.school_id).toBe(1);
  });

  it('should validate school access', async () => {
    const hasAccess = await validateSchoolAccess(1, 1); // userId=1, schoolId=1
    expect(hasAccess).toBe(true);
  });

  it('should prevent cross-school access', async () => {
    const hasAccess = await validateSchoolAccess(1, 999); // Non-existent school
    expect(hasAccess).toBe(false);
  });
});
```

### Step 3.2: Integration Tests

Test the complete flow:

```bash
# Create test device
curl -X POST "http://localhost:3000/api/devices?school_id=1" \
  -H "Content-Type: application/json" \
  -d '{
    "device_id": "TEST_001",
    "device_name": "Test Device",
    "location": "Gate"
  }'

# Get device ID from response, then map a student
curl -X POST "http://localhost:3000/api/device-mappings?school_id=1" \
  -H "Content-Type: application/json" \
  -d '{
    "device_id": 1,
    "student_id": 1,
    "device_user_id": 100
  }'

# Verify mapping
curl "http://localhost:3000/api/device-mappings?school_id=1&device_id=1"
```

### Step 3.3: Audit Trail Testing

```sql
-- Check activity logs were created
SELECT * FROM activity_logs 
WHERE school_id = 1 
ORDER BY created_at DESC 
LIMIT 10;

-- Expected: Entries for device creation, mapping creation, etc
```

### Step 3.4: Performance Testing

```bash
# Test with 100 students
curl "http://localhost:3000/api/students/full?school_id=1&q=" \
  --write-out 'Time: %{time_total}s\n'

# Expected: < 1 second response time

# Test with multiple filters
curl "http://localhost:3000/api/students/full?school_id=1&class_id=1&status=active" \
  --write-out 'Time: %{time_total}s\n'

# Expected: < 500ms response time
```

---

## 🎯 Validation Checklist

After Week 3, verify all of the following:

### Database Integrity ✅
- [ ] All students have school_id  
- [ ] All enrollments have school_id
- [ ] All people have school_id
- [ ] No NULL school_id values
- [ ] All foreign keys valid

### API Functionality ✅
- [ ] `/api/devices` returns list of devices
- [ ] `/api/device-mappings` returns list of mappings
- [ ] `/api/students/full` works with school_id
- [ ] Duplicate detection still works
- [ ] Edit student still works

### Security ✅
- [ ] Cannot access other school's students
- [ ] Cannot create device for other school
- [ ] Cannot map student from other school
- [ ] Activity logs created for all changes
- [ ] IP addresses logged correctly

### Performance ✅
- [ ] List endpoints < 1 second
- [ ] Create endpoints < 500ms
- [ ] No query timeouts
- [ ] Indexes created successfully

---

## 🚨 Troubleshooting

### Issue: "Unknown column 'school_id'"

**Cause:** Migration script didn't run

**Fix:**
```bash
# Check if column exists
mysql -u root drais_school -e "DESCRIBE students;" | grep school_id

# If missing, run migration again
mysql -u root drais_school < sql/PHASE_1_MIGRATION.sql
```

### Issue: "Foreign key constraint fails"

**Cause:** Orphaned records without school_id

**Fix:**
```sql
-- Find problematic records
SELECT COUNT(*) FROM students WHERE school_id IS NULL;

-- Set to default school
UPDATE students SET school_id = 1 WHERE school_id IS NULL;
```

### Issue: API returns "school_id is required"

**Cause:** Not passing school_id parameter

**Fix:**
```bash
# Wrong:
GET /api/students/full

# Correct:
GET /api/students/full?school_id=1
```

### Issue: Performance degradation

**Cause:** Missing indexes

**Fix:**
```sql
-- Re-run indexes creation
ALTER TABLE students ADD INDEX idx_school_id (school_id);
ALTER TABLE students ADD INDEX idx_school_status (school_id, status);
ALTER TABLE enrollments ADD INDEX idx_school_student (school_id, student_id);
```

---

## 📊 Success Metrics

Track these metrics to ensure Phase 1 is successful:

| Metric | Target | Check |
|--------|--------|-------|
| Data Integrity | 100% school_id populated | `SELECT COUNT(*) FROM students WHERE school_id IS NULL;` |
| API Response Time | < 1 second | `curl --write-out 'Time: %{time_total}s\n'` |
| Test Coverage | > 80% | `npm test -- --coverage` |
| Activity Logs | Every change logged | `SELECT COUNT(*) FROM activity_logs;` |
| Zero Data Loss | All existing data preserved | `SELECT COUNT(*) FROM students;` |

---

## 📝 Before/After Comparison

### Before Phase 1
```
Single school system
- students table has no school_id
- No device abstraction
- Biometric IDs stored directly
- No audit trail
- Cross-school access possible (risk)
```

### After Phase 1
```
Multi-tenant ready system
- All tables have school_id
- Device abstraction layer created
- Biometric IDs mapped via device_user_mappings
- Full audit trail in activity_logs
- School isolation enforced at API level
- Ready for Phase 2 (Device Sync Engine)
```

---

## ✅ Phase 1 Complete!

Once all checkboxes are filled:

1. **Document any changes** to the implementation
2. **Create a summary** of what was done
3. **Prepare for Phase 2** (Device Sync Engine)
4. **Schedule Phase 2** - 2 weeks from Phase 1 completion

---

## 📞 Getting Help

If you encounter issues:

1. Check the "Troubleshooting" section above
2. Review the database schema: `DESCRIBE biometric_devices;`
3. Check activity logs for warnings: `SELECT * FROM activity_logs ORDER BY created_at DESC;`
4. Restore from backup if needed: `mysql -u root drais_school < backup_*.sql`

---

## 🎉 Next Phase

After Phase 1 is complete and tested:
- Phase 2: Device Sync Engine (2-3 weeks)
- Phase 3: Device User Mapping Resolver (2 weeks)
- Phase 4: Real-time Dashboards (2 weeks)

**Total Project Duration: 12 weeks**
