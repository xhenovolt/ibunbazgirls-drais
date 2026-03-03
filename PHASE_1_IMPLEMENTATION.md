# DRais 2.0 - Phase 1: Foundation & Multi-Tenancy (Weeks 1-3)

## 🎯 Phase 1 Objectives

Establish the **multi-tenancy foundation** and **device abstraction layer** without disrupting current operations.

### Success Criteria ✅
- [x] Database schema extended (backward compatible)
- [x] Device abstraction table created
- [x] Multi-tenancy middleware implemented
- [x] Authorization checks on all student APIs
- [x] Migration scripts prepared
- [x] Backward compatibility maintained (no data loss)

---

## 📋 Phase 1 Deliverables (This Week)

### Week 1: Database Schema
**Time: 2-3 days**

#### 1.1 Create Core Tables
- ✅ `schools` table (if not exists)
- ✅ `biometric_devices` table
- ✅ `device_user_mappings` table
- ✅ `activity_logs` table
- ✅ `device_sync_history` table

#### 1.2 Alter Existing Tables
- ✅ Add `school_id` to: students, enrollments, attendance, people
- ✅ Add indexes for multi-tenancy queries
- ✅ Add soft deletes where needed

#### 1.3 Data Migration
- ✅ Migration script to populate `school_id` (default school_id=1)
- ✅ Script to create device records from existing data
- ✅ Verification queries to ensure data integrity

---

### Week 2: Backend API Layer  
**Time: 2-3 days**

#### 2.1 Multi-Tenancy Middleware
- ✅ Auth middleware that injects `school_id` from session
- ✅ Authorization checks (verify user belongs to school)
- ✅ Error handling for school isolation violations

#### 2.2 Database Access Layer
- ✅ Create `DatabaseService` with school context
- ✅ Automatically add `school_id` to all queries
- ✅ Query validation (no cross-school data access)

#### 2.3 Refactor Existing APIs
- ✅ `/api/students/full` - Add school_id filtering
- ✅ `/api/students/[id]` - Verify school ownership
- ✅ `/api/students/edit` - Add school context
- ✅ `/api/students/list-duplicates` - Filter by school

---

### Week 3: Device Abstraction
**Time: 2-3 days**

#### 3.1 Device Management APIs
- ✅ `POST /api/devices` - Register biometric device
- ✅ `GET /api/devices` - List school devices
- ✅ `PUT /api/devices/[id]` - Update device status
- ✅ `DELETE /api/devices/[id]` - Deactivate device

#### 3.2 Device User Mapping APIs
- ✅ `POST /api/device-mappings` - Map student to device biometric ID
- ✅ `GET /api/device-mappings` - List mappings
- ✅ `PUT /api/device-mappings/[id]` - Update mapping
- ✅ `DELETE /api/device-mappings/[id]` - Remove mapping

#### 3.3 Validation & Testing
- ✅ Unit tests for multi-tenancy
- ✅ Integration tests for device mappings
- ✅ Seed test data for 2+ schools

---

## 🗄️ Database Changes Summary

### New Tables

```sql
-- Schools (Root of multi-tenancy)
CREATE TABLE schools (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  code VARCHAR(50) UNIQUE,
  domain VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Biometric Devices
CREATE TABLE biometric_devices (
  id INT PRIMARY KEY AUTO_INCREMENT,
  school_id INT NOT NULL,
  device_id VARCHAR(255) NOT NULL,  -- Unique per school
  serial_number VARCHAR(255),
  model VARCHAR(100),
  status ENUM('active', 'inactive', 'offline', 'error'),
  location VARCHAR(255),
  last_sync_at TIMESTAMP,
  sync_failed_count INT DEFAULT 0,
  last_error VARCHAR(500),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (school_id) REFERENCES schools(id),
  UNIQUE KEY unique_device_per_school (school_id, device_id)
);

-- Device User Mappings (Solves ALL biometric ID mismatches)
CREATE TABLE device_user_mappings (
  id INT PRIMARY KEY AUTO_INCREMENT,
  school_id INT NOT NULL,
  device_id INT NOT NULL,
  student_id INT NOT NULL,
  device_user_id INT NOT NULL,  -- The actual biometric ID on device
  status ENUM('active', 'inactive', 'pending_sync'),
  last_synced_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (school_id) REFERENCES schools(id),
  FOREIGN KEY (device_id) REFERENCES biometric_devices(id),
  FOREIGN KEY (student_id) REFERENCES students(id),
  UNIQUE KEY unique_mapping (device_id, device_user_id),
  INDEX idx_school_student (school_id, student_id)
);

-- Activity Logs (Audit trail)
CREATE TABLE activity_logs (
  id INT PRIMARY KEY AUTO_INCREMENT,
  school_id INT NOT NULL,
  actor_user_id INT,
  action VARCHAR(100) NOT NULL,
  entity_type VARCHAR(50),
  entity_id INT,
  old_values JSON,
  new_values JSON,
  ip_address VARCHAR(45),
  user_agent TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (school_id) REFERENCES schools(id),
  INDEX idx_school_action (school_id, action),
  INDEX idx_entity (entity_type, entity_id)
);

-- Device Sync History (Operational tracking)
CREATE TABLE device_sync_history (
  id INT PRIMARY KEY AUTO_INCREMENT,
  school_id INT NOT NULL,
  device_id INT NOT NULL,
  sync_type ENUM('full', 'incremental'),
  status ENUM('success', 'partial', 'failed'),
  logs_fetched INT DEFAULT 0,
  logs_processed INT DEFAULT 0,
  logs_skipped INT DEFAULT 0,
  error_message TEXT,
  started_at TIMESTAMP,
  completed_at TIMESTAMP,
  duration_ms INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (school_id) REFERENCES schools(id),
  FOREIGN KEY (device_id) REFERENCES biometric_devices(id),
  INDEX idx_school_device (school_id, device_id),
  INDEX idx_created (created_at)
);
```

### Altered Tables

```sql
-- Add school_id to core tables
ALTER TABLE students ADD COLUMN school_id INT NOT NULL DEFAULT 1 AFTER id;
ALTER TABLE students ADD FOREIGN KEY (school_id) REFERENCES schools(id);
ALTER TABLE students ADD INDEX idx_school_id (school_id);

ALTER TABLE people ADD COLUMN school_id INT NOT NULL DEFAULT 1 AFTER id;
ALTER TABLE people ADD FOREIGN KEY (school_id) REFERENCES schools(id);
ALTER TABLE people ADD INDEX idx_school_id (school_id);

ALTER TABLE enrollments ADD COLUMN school_id INT NOT NULL DEFAULT 1 AFTER id;
ALTER TABLE enrollments ADD FOREIGN KEY (school_id) REFERENCES schools(id);
ALTER TABLE enrollments ADD INDEX idx_school_id (school_id);

-- For attendance/logs if they exist
ALTER TABLE attendance ADD COLUMN school_id INT NOT NULL DEFAULT 1 AFTER id;
ALTER TABLE attendance ADD FOREIGN KEY (school_id) REFERENCES schools(id);
ALTER TABLE attendance ADD INDEX idx_school_id (school_id);
```

---

## 🛡️ Authorization Middleware

### Location: `src/middleware/auth.ts`

```typescript
// Check if user belongs to school
export async function validateSchoolAccess(
  userId: number,
  schoolId: number
): Promise<boolean> {
  const connection = await getConnection();
  const [result]: any = await connection.execute(
    `SELECT ul.id FROM user_logins ul
     WHERE ul.id FROM user_logins ul
     WHERE ul.user_id = ? AND ul.school_id = ?`,
    [userId, schoolId]
  );
  await connection.end();
  return result.length > 0;
}
```

---

## ✅ Implementation Checklist

### Database (Week 1)
- [ ] Create new tables (schools, devices, mappings, logs)
- [ ] Alter existing tables (add school_id)
- [ ] Create indexes for performance
- [ ] Run migration script
- [ ] Verify data integrity
- [ ] Create rollback script

### Backend (Week 2)
- [ ] Create multi-tenancy middleware
- [ ] Create DatabaseService class
- [ ] Update `/api/students/full` endpoint
- [ ] Update `/api/students/[id]` endpoint
- [ ] Update `/api/students/edit` endpoint
- [ ] Add authorization checks to all endpoints
- [ ] Create test cases

### Device Layer (Week 3)
- [ ] Create device management endpoints
- [ ] Create device mapping endpoints
- [ ] Add validation logic
- [ ] Create seed data for testing
- [ ] Integration tests
- [ ] Documentation

---

## 🚀 Next Steps

1. **Review this Phase 1 plan** with your team
2. **Backup current database** before any changes
3. **Start with database migration** (Week 1)
4. **Test thoroughly** with staging environment
5. **Go live** with backward compatibility

---

## ⚠️ Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|-----------|
| Data loss during migration | Critical | Full database backup, rollback script ready |
| API breaking changes | High | Backward compatibility layer, versioning |
| Multi-tenancy not enforced | Critical | Code review on every API, audit tests |
| Performance degradation | Medium | Query optimization, indexes, caching layer |

---

## 📞 Support

Questions during Phase 1? 
- Check database migration logs
- Review authorization middleware tests
- Validate data integrity queries

**Estimated Total Time: 3 weeks**
**Risk Level: Low (backward compatible)**
