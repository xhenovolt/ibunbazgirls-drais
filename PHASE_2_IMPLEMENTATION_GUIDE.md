# 📋 PHASE 2 - Device Sync Engine: Step-by-Step Implementation Guide

**Duration:** 2-3 weeks  
**Effort:** 80-120 developer hours  
**Build Status:** Ready  
**Last Updated:** March 3, 2026

---

## 📖 Table of Contents

1. [Quick Start (20 min)](#quick-start)
2. [Pre-Implementation Setup](#pre-implementation-setup)
3. [Database Schema Changes](#database-schema-changes)
4. [Backend Implementation](#backend-implementation)
5. [Testing & Validation](#testing--validation)
6. [Deployment & Go-Live](#deployment--go-live)
7. [Troubleshooting](#troubleshooting)

---

## 🚀 Quick Start

**For the impatient:** 20-minute orientation to Phase 2

### What Gets Built

```
Multi-Tenancy Foundation (From Phase 1) ✅
        │
        ▼
    Device Sync Engine (Phase 2) ← YOU ARE HERE
        │
        ├─ Sync Service: Pulls logs from Dahua devices
        ├─ Log Processor: Matches logs to students
        ├─ Worker: Runs every 5 minutes
        ├─ APIs: Manual sync & monitoring
        └─ Dashboard: Sync health & statistics
        │
        ▼
    Result: Automated attendance tracking for 100+ schools
```

### 30-Second Overview

```bash
# What you'll build:
1. DeviceSyncService - Fetches logs from biometric devices
2. LogProcessorService - Matches device IDs to students
3. Sync Worker - Runs on a schedule (every 5 min)
4. API endpoints - Manual sync, status, history
5. Admin Dashboard - Monitor sync health

# Files to create: ~6-7
# Database changes: ~4 new tables
# Implementation time: 2-3 weeks
# Team size: 3-5 developers
```

### Why Phase 2 is Important

```
WITHOUT Phase 2:
├─ Manual attendance entry
├─ Only 1-2 devices per school
├─ No sync history
├─ High error rates
└─ Not scalable

WITH Phase 2:
├─ Automatic log collection from devices
├─ 20+ devices per school
├─ Complete sync history
├─ 99.9% accuracy
└─ Scales to 100+ schools ✅
```

### Critical Timeline

```
Week 1: Services (50-60 hours)
├─ DeviceSyncService ......... 2 days
├─ LogProcessorService ....... 2 days
├─ API endpoints ............ 1 day
└─ Database migration ........ 1 day

Week 2: Worker & Monitoring (40-50 hours)
├─ Sync Worker .............. 2 days
├─ Admin Dashboard .......... 2 days
├─ Testing .................. 1 day

Week 3: Finalization & Go-live (30-40 hours)
├─ Documentation ............ 1 day
├─ Team training ............ 1 day
├─ Staging deployment ....... 1 day
├─ Production deployment .... 1 day
└─ Monitoring & support ..... 1 day
```

---

## 🔧 Pre-Implementation Setup

### 1. Environment Preparation

#### 1.1 Verify Phase 1 Completion
```bash
# Check Phase 1 was fully deployed
mysql -u root -p -e "
  SELECT COUNT(*) as schemas_created FROM information_schema.TABLES 
  WHERE TABLE_SCHEMA = 'abildaan' 
  AND TABLE_NAME IN ('schools', 'biometric_devices', 'device_user_mappings', 'activity_logs', 'device_sync_history')
;"

# Expected output: 5 (all tables from Phase 1)
```

#### 1.2 Verify Multi-Tenancy Context
```bash
# Check that auth middleware is in place
grep -r "enrichTenantContext\|school_id" src/lib/multi-tenancy.ts | wc -l

# Expected: >10 references
```

#### 1.3 Inventory Dahua Devices
```bash
# List all Dahua devices and their models
mysql -u root -p -e "
  SELECT school_id, COUNT(*) as device_count, GROUP_CONCAT(model) as models 
  FROM biometric_devices 
  WHERE is_active = 1 
  GROUP BY school_id
;"

# Expected: At least 1 device per school
```

### 2. Team Assignment & Preparation

```
Development Tasks:
├─ Developer 1: DeviceSyncService + LogProcessorService
├─ Developer 2: API endpoints + Worker
├─ Developer 3: Testing + QA
├─ Database Eng: Schema migration + performance tuning
└─ Tech Lead: Architecture review + blockers

Knowledge Requirements:
├─ Dahua API documentation (read ~30 min)
├─ Phase 1 code review (read ~60 min)
├─ Device mapping logic (read ~30 min)
└─ Event-driven architecture (read ~30 min)
```

### 3. Dependencies & Infrastructure

#### 3.1 Node.js Packages (Update package.json)
```bash
npm install node-cron        # Task scheduling
npm install bull             # Job queue (optional, for better reliability)
npm install pino             # Structured logging
npm install ioredis          # Redis client (optional, for distributed locks)

# Development dependencies
npm install --save-dev @types/node-cron jest @testing-library/jest-dom
```

#### 3.2 Infrastructure Requirements
```
├─ Cron/Scheduler: Node.js process or external cron
├─ Message Queue (optional): Redis or RabbitMQ for reliability
├─ Monitoring: Prometheus, Datadog, or similar
├─ Logging: Centralized logging (ELK stack recommended)
└─ Database: Verified MySQL 8.0+ with InnoDB
```

### 4. Configuration

#### 4.1 Environment Variables (.env.local)
```bash
# Device Sync Configuration
DEVICE_SYNC_INTERVAL_MINUTES=5              # Sync every 5 minutes
DEVICE_SYNC_TIMEOUT_MINUTES=3               # Timeout after 3 min
DEVICE_SYNC_MAX_LOGS_PER_BATCH=1000         # Process 1K logs at a time
DEVICE_SYNC_RETRY_MAX_ATTEMPTS=3            # Retry 3 times
DEVICE_SYNC_RETRY_BACKOFF_MS=5000            # Exponential backoff

# Dahua Device Configuration
DAHUA_TIMEOUT_MS=30000                      # Device timeout: 30 seconds
DAHUA_MAX_PAGE_SIZE=1000                    # Logs per request
DAHUA_DEFAULT_REGION=EMEA                   # Default region

# Logging
LOG_LEVEL=info                               # info | debug | error
ENABLE_STRUCTURED_LOGGING=true

# Feature Flags
ENABLE_DEVICE_SYNC=true
ENABLE_LOG_PROCESSOR=true
ENABLE_SYNC_WORKER=true
```

#### 4.2 Create Configuration File (src/config/device-sync.config.ts)
```typescript
export const deviceSyncConfig = {
  // Sync timing
  syncIntervalMinutes: parseInt(process.env.DEVICE_SYNC_INTERVAL_MINUTES || '5'),
  syncTimeoutMinutes: parseInt(process.env.DEVICE_SYNC_TIMEOUT_MINUTES || '3'),
  
  // Batch processing
  maxLogsPerBatch: parseInt(process.env.DEVICE_SYNC_MAX_LOGS_PER_BATCH || '1000'),
  maxConcurrentDevices: 10,
  
  // Retry strategy
  retryMaxAttempts: parseInt(process.env.DEVICE_SYNC_RETRY_MAX_ATTEMPTS || '3'),
  retryBackoffMs: parseInt(process.env.DEVICE_SYNC_RETRY_BACKOFF_MS || '5000'),
  
  // Dahua settings
  dahua: {
    timeoutMs: parseInt(process.env.DAHUA_TIMEOUT_MS || '30000'),
    maxPageSize: parseInt(process.env.DAHUA_MAX_PAGE_SIZE || '1000'),
    defaultRegion: process.env.DAHUA_DEFAULT_REGION || 'EMEA',
  },
  
  // Feature flags
  features: {
    enableSync: process.env.ENABLE_DEVICE_SYNC === 'true',
    enableProcessor: process.env.ENABLE_LOG_PROCESSOR === 'true',
    enableWorker: process.env.ENABLE_SYNC_WORKER === 'true',
    enableAlerts: process.env.ENABLE_DEVICE_SYNC_ALERTS !== 'false',
  },
};
```

---

## 🗄️ Database Schema Changes

### Step 1: Create Migration File

Create `sql/PHASE_2_MIGRATION.sql`:

```sql
-- ================================================================
-- PHASE 2 MIGRATION: Device Sync Engine
-- Database: abildaan
-- Date: March 3, 2026
-- Status: Ready to apply
-- ================================================================

-- IMPORTANT: Backup your database before running this!
-- Example: mysqldump -u root -p abildaan > backup_phase2_$(date +%s).sql

-- ================================================================
-- SECTION 1: Alter existing tables from Phase 1
-- ================================================================

-- Extend device_sync_history with Phase 2 fields
ALTER TABLE device_sync_history 
ADD COLUMN IF NOT EXISTS duration_ms INT AFTER sync_end_at,
ADD COLUMN IF NOT EXISTS logs_processed INT DEFAULT 0 AFTER logs_fetched,
ADD COLUMN IF NOT EXISTS logs_matched INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS logs_unmatched INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS worker_id VARCHAR(50),
ADD COLUMN IF NOT EXISTS next_retry_at DATETIME,
MODIFY COLUMN status ENUM('success', 'partial', 'failed') NOT NULL DEFAULT 'failed';

-- Add indexes for Phase 2 queries
ALTER TABLE device_sync_history 
ADD INDEX IF NOT EXISTS idx_next_retry (next_retry_at),
ADD INDEX IF NOT EXISTS idx_status_created (status, created_at),
ADD INDEX IF NOT EXISTS idx_device_sync (school_id, device_id, created_at);

-- ================================================================
-- SECTION 2: Create new tables for Phase 2
-- ================================================================

-- Sync Checkpoints (Track last successful sync point per device)
CREATE TABLE IF NOT EXISTS device_sync_checkpoints (
  id INT PRIMARY KEY AUTO_INCREMENT,
  school_id INT NOT NULL,
  device_id INT NOT NULL,
  
  -- Last successful sync point
  last_rec_no INT DEFAULT 0,
  last_sync_at DATETIME,
  
  -- Status
  is_active TINYINT(1) DEFAULT 1,
  
  -- Metadata
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  UNIQUE KEY uk_school_device (school_id, device_id),
  KEY idx_school_id (school_id),
  KEY idx_last_sync_at (last_sync_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci 
COMMENT='Tracks last sync checkpoint for each device';

-- Attendance Log Processing (Staging table for log processing)
CREATE TABLE IF NOT EXISTS attendance_log_processing (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  school_id INT NOT NULL,
  device_id INT NOT NULL,
  
  -- Raw log data
  raw_log_data JSON NOT NULL,
  device_user_id VARCHAR(50) NOT NULL,
  log_timestamp DATETIME NOT NULL,
  
  -- Processing results
  processing_status ENUM('matched', 'unmatched', 'duplicate', 'error') NOT NULL,
  student_id INT COMMENT 'NULL if unmatched',
  mapping_id INT COMMENT 'device_user_mapping.id if matched',
  match_confidence DECIMAL(3,2) COMMENT '0.00 to 1.00',
  
  -- Error handling
  error_message TEXT,
  retry_count INT DEFAULT 0,
  last_error_at DATETIME,
  
  -- Metadata
  synced_at DATETIME NOT NULL,
  processed_at DATETIME,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  KEY idx_school_device (school_id, device_id),
  KEY idx_processing_status (processing_status),
  KEY idx_student_id (student_id),
  KEY idx_synced_at (synced_at),
  KEY idx_unmatched (processing_status, school_id),
  KEY idx_log_timestamp (log_timestamp)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci 
COMMENT='Intermediate table for attendance log processing and matching';

-- Sync Errors Log (Track all errors for diagnostics)
CREATE TABLE IF NOT EXISTS sync_errors_log (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  school_id INT NOT NULL,
  device_id INT NOT NULL,
  
  -- Error details
  error_type ENUM('connection', 'authentication', 'validation', 'parsing', 'storage', 'processing') NOT NULL,
  error_message TEXT NOT NULL,
  error_details JSON COMMENT 'Additional error context',
  
  -- Context
  sync_history_id BIGINT COMMENT 'References device_sync_history.id',
  affected_log_count INT DEFAULT 0,
  
  -- Recovery
  resolved_at DATETIME,
  resolution_notes TEXT,
  
  -- Metadata
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  KEY idx_school_device (school_id, device_id),
  KEY idx_error_type (error_type),
  KEY idx_created_at (created_at),
  KEY idx_resolved_at (resolved_at),
  KEY idx_unresolved (resolved_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci 
COMMENT='Diagnostic log for all sync-related errors';

-- ================================================================
-- SECTION 3: Data initialization
-- ================================================================

-- Initialize sync checkpoints for all active devices
INSERT IGNORE INTO device_sync_checkpoints (school_id, device_id, last_rec_no, last_sync_at)
SELECT DISTINCT bd.school_id, bd.id, 0, NOW()
FROM biometric_devices bd
WHERE bd.is_active = 1;

-- ================================================================
-- SECTION 4: Verification queries
-- ================================================================

-- Count all phase 2 tables
SELECT 'Migration Status' as check_type, COUNT(*) as table_count
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = DATABASE() 
AND TABLE_NAME IN (
  'device_sync_history', 
  'device_sync_checkpoints', 
  'attendance_log_processing',
  'sync_errors_log'
);

-- Verify checkpoints created
SELECT 'Sync Checkpoints' as check_type, COUNT(*) as checkpoint_count
FROM device_sync_checkpoints;

-- Verify indexes exist
SELECT 'Indexes Created' as check_type, COUNT(*) as index_count
FROM information_schema.STATISTICS 
WHERE TABLE_SCHEMA = DATABASE() 
AND TABLE_NAME IN (
  'device_sync_history', 
  'device_sync_checkpoints', 
  'attendance_log_processing',
  'sync_errors_log'
)
AND INDEX_NAME != 'PRIMARY';

-- ================================================================
-- SECTION 5: Rollback script (Save this separately!)
-- ================================================================

-- To rollback Phase 2, run:
-- - ALTER TABLE device_sync_history DROP COLUMN IF EXISTS duration_ms;
-- - DROP TABLE IF EXISTS device_sync_checkpoints;
-- - DROP TABLE IF EXISTS attendance_log_processing;
-- - DROP TABLE IF EXISTS sync_errors_log;
```

### Step 2: Apply Migration

```bash
# 1. BACKUP YOUR DATABASE FIRST!
mysqldump -u root -p abildaan > backup_phase2_$(date +%s).sql

# 2. Apply migration
mysql -u root -p abildaan < sql/PHASE_2_MIGRATION.sql

# 3. Verify
mysql -u root -p -e "
  USE abildaan;
  SELECT 
    'device_sync_history' as table_name, COUNT(*) as row_count 
    FROM device_sync_history
  UNION ALL
  SELECT 'device_sync_checkpoints', COUNT(*) FROM device_sync_checkpoints
  UNION ALL
  SELECT 'attendance_log_processing', COUNT(*) FROM attendance_log_processing
  UNION ALL
  SELECT 'sync_errors_log', COUNT(*) FROM sync_errors_log
;"
```

---

## 💻 Backend Implementation

### Phase 2 File Structure

```
src/
├── lib/
│   ├── device-sync/
│   │   ├── index.ts                 (Main exports)
│   │   ├── device-sync.service.ts   (Core sync logic)
│   │   ├── log-processor.service.ts (Processing engine)
│   │   ├── types.ts                 (TypeScript interfaces)
│   │   └── utils.ts                 (Helper functions)
│   ├── dahua-client.ts              (May exist from Dahua integration)
│   └── device-sync.config.ts        (Moved from config/)
├── workers/
│   └── device-sync-worker.ts        (Background job)
└── app/api/
    ├── device-sync/
    │   ├── route.ts                 (Sync endpoints)
    │   └── [deviceId]/route.ts      (Single device endpoints)
    └── logs/
        └── unmatched/route.ts       (Unmatched logs endpoints)
```

### Implementation Details

See [PHASE_2_CODE_REFERENCE.md](./PHASE_2_CODE_REFERENCE.md) for complete code templates and implementations.

### Key Implementation Steps

#### Step 1: Device Sync Service (3-4 hours)
```bash
# 1. Create the service file
touch src/lib/device-sync/device-sync.service.ts

# 2. Implement core methods:
#    - syncDeviceLogsAction()
#    - fetchLogsFromDahua()
#    - validateAndStoreRawLogs()
#    - emitSyncEvents()
#    - recordSyncHistory()

# 3. Tests
#    - Unit tests for each method
#    - Mock Dahua client
#    - Test database persistence
#    - Test error paths
```

#### Step 2: Log Processor Service (2-3 hours)
```bash
# 1. Create the service file
touch src/lib/device-sync/log-processor.service.ts

# 2. Implement core methods:
#    - processAttendanceLog()
#    - findDeviceMapping()
#    - validateLogData()
#    - handleUnmatchedLogs()

# 3. Tests
#    - Device mapping resolution
#    - Duplicate detection
#    - Error handling
#    - Batch processing
```

#### Step 3: API Endpoints (2-3 hours)
```bash
# 1. Create endpoint files
mkdir -p src/app/api/device-sync

# 2. Implement endpoints:
#    - POST /api/device-sync (manual trigger)
#    - GET /api/device-sync/status
#    - GET /api/device-sync/history

# 3. Security:
#    - Enforce multi-tenancy (school_id)
#    - Add authentication checks
#    - Rate limiting

# 4. Tests
#    - Happy path tests
#    - Error scenarios
#    - Security tests
```

#### Step 4: Sync Worker (2-3 hours)
```bash
# 1. Create worker file
touch src/workers/device-sync-worker.ts

# 2. Implement scheduling:
#    - Every 5 minutes
#    - All schools & devices
#    - Error handling & retries

# 3. Monitoring:
#    - Health checks
#    - Status reporting
#    - Alert triggers

# 4. Tests
#    - Scheduling logic
#    - Error scenarios
#    - Recovery behavior
```

---

## ✅ Testing & Validation

### Unit Tests (See test code templates)

```bash
# Run all tests
npm run test

# Run with coverage
npm run test:coverage

# Watch mode during development
npm run test:watch

# Specific test file
npm test -- device-sync.service.test.ts
```

### Integration Tests

```bash
# 1. Set up test database
npm run test:db:setup

# 2. Run integration tests
npm run test:integration

# 3. Test with real Dahua device (staging only)
npm run test:dahua:integration
```

### Functional Validation Checklist

- [ ] **Device Connection**
  - [ ] Can connect to all Dahua devices
  - [ ] Timeout works correctly
  - [ ] Handles connection failures gracefully

- [ ] **Log Fetching**
  - [ ] Fetches logs from device
  - [ ] Handles pagination correctly
  - [ ] Last record number tracking works

- [ ] **Log Processing**
  - [ ] Matches device IDs to students correctly
  - [ ] Detects duplicates
  - [ ] Handles unmatched logs
  - [ ] Performance acceptable (1K logs/min)

- [ ] **Worker Execution**
  - [ ] Runs on schedule (every 5 min)
  - [ ] Processes all schools concurrently
  - [ ] Retries failed syncs
  - [ ] Logs execution details

- [ ] **Data Integrity**
  - [ ] No data loss during sync
  - [ ] No duplicate logs
  - [ ] Sync history created
  - [ ] Checkpoints updated

- [ ] **Multi-Tenancy**
  - [ ] School 1 data isolated from School 2
  - [ ] Logs only match students in same school
  - [ ] API enforces school isolation

- [ ] **Error Handling**
  - [ ] Connection failures → Retry
  - [ ] Processing errors → Logged & analyzed
  - [ ] Sync failures → Recorded in history
  - [ ] Manual override available

### Load Testing

```bash
# Generate test data
npm run seed:test:logs -- --count=100000 --schools=5

# Run load test
npm run test:load -- --logs=100000 --concurrent=20

# Monitor performance
npm run monitor:performance
```

---

## 🚀 Deployment & Go-Live

### Pre-Deployment Checklist

- [ ] All tests passing
- [ ] Code review completed
- [ ] Database backup created
- [ ] Migration tested on staging
- [ ] Performance benchmarks met
- [ ] Monitoring configured
- [ ] Team trained
- [ ] Rollback procedure tested

### Staging Deployment

```bash
# 1. Deploy to staging
npm run deploy:staging

# 2. Run smoke tests
npm run test:smoke:staging

# 3. Manual testing (24 hours minimum)
#    - Verify all devices syncing
#    - Check log processing
#    - Monitor error rates
#    - Test manual sync triggers

# 4. Load testing
npm run test:load:staging -- --duration=1h
```

### Production Deployment

```bash
# 1. Create backup
mysqldump -u root -p abildaan > backup_before_phase2_prod.sql

# 2. Run migration
mysql -u root -p abildaan < sql/PHASE_2_MIGRATION.sql

# 3. Deploy code
git pull origin main
npm install
npm run build
npm run deploy:production

# 4. Start sync worker
# (Method depends on your infrastructure)
npm run worker:start

# 5. Monitor
npm run monitor:realtime
```

### Post-Deployment Monitoring (24-48 hours)

```bash
# Key metrics to monitor:
- Sync success rate (target: >99%)
- Processing latency (target: <5min per 1K logs)
- Error rate (target: <1%)
- Unmatched logs percentage (target: <5%)

# Daily reports
npm run report:daily-sync
npm run report:errors
npm run report:performance
```

---

## 🔧 Troubleshooting

### Common Issues & Solutions

#### 1. "Connection Timeout" Errors

```
Symptom: Sync errors with "Connection timeout to device"
Cause: Device unreachable or network issue
Solution:
  1. Verify device is powered on
  2. Check network connectivity
  3. Increase timeout: DAHUA_TIMEOUT_MS=60000
  4. Check firewall rules
  5. Review device logs
```

#### 2. "Mapping Not Found" for Logs

```
Symptom: Most logs are unmatched (status='unmatched')
Cause: Device user IDs not mapped to students
Solution:
  1. Check device_user_mappings table:
     SELECT * FROM device_user_mappings 
     WHERE school_id = ? AND device_id = ?
  2. Add missing mappings via API
  3. Verify biometric IDs are correct
  4. Check for duplicate students with same biometric ID
```

#### 3. Worker Not Running

```
Symptom: No syncs happening, device_sync_history is empty
Cause: Worker process not starting
Solution:
  1. Check if worker process is running:
     ps aux | grep device-sync-worker
  2. Check worker logs:
     tail -f logs/worker.log
  3. Verify ENABLE_SYNC_WORKER=true
  4. Restart worker:
     npm run worker:restart
  5. Check process manager (PM2, systemd, etc.)
```

#### 4. Slow Performance

```
Symptom: Sync takes 30+ minutes for 100K logs
Cause: Missing indexes or slow queries
Solution:
  1. Check indexes were created:
     SHOW INDEXES FROM attendance_log_processing;
  2. Analyze slow queries:
     SET GLOBAL slow_query_log = 'ON';
     tail -f /var/log/mysql/slow.log
  3. Optimize batch size:
     DEVICE_SYNC_MAX_LOGS_PER_BATCH=500  (try smaller)
  4. Check database server resources
  5. Review query execution plans:
     EXPLAIN ANALYZE SELECT ... FROM attendance_log_processing ...
```

#### 5. High Memory Usage

```
Symptom: Node process consuming excessive memory
Cause: Batch processing not releasing memory
Solution:
  1. Reduce batch size:
     DEVICE_SYNC_MAX_LOGS_PER_BATCH=300
  2. Check for memory leaks:
     npm run test:memory-leak
  3. Implement garbage collection:
     node --expose-gc src/workers/device-sync-worker.ts
  4. Monitor continuously:
     npm run monitor:memory
```

### Debug Mode

```bash
# Enable debug logging
LOG_LEVEL=debug npm run worker:start

# Specific component debug
DEBUG=device-sync:* npm run worker:start
DEBUG=log-processor:* npm run worker:start

# Database query logging
QUERY_LOG=verbose npm run worker:start
```

---

## 📊 Success Metrics

Track these metrics to verify Phase 2 success:

```sql
-- Daily sync success rate
SELECT 
  DATE(created_at) as sync_date,
  ROUND(COUNT(CASE WHEN status='success' THEN 1 END) * 100 / COUNT(*), 2) as success_rate,
  COUNT(*) as total_syncs,
  SUM(logs_fetched) as total_logs_fetched
FROM device_sync_history
WHERE created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY DATE(created_at)
ORDER BY sync_date DESC;

-- Processing match rate
SELECT 
  ROUND(COUNT(CASE WHEN processing_status='matched' THEN 1 END) * 100 / COUNT(*), 2) as match_rate,
  COUNT(CASE WHEN processing_status='matched' THEN 1 END) as matched_logs,
  COUNT(CASE WHEN processing_status='unmatched' THEN 1 END) as unmatched_logs
FROM attendance_log_processing
WHERE created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY);

-- Average sync duration
SELECT 
  AVG(duration_ms) / 1000 as avg_duration_seconds,
  MAX(duration_ms) / 1000 as max_duration_seconds,
  MIN(duration_ms) / 1000 as min_duration_seconds
FROM device_sync_history
WHERE created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY);
```

---

## 📝 Team Responsibilities

### Backend Developer (Primary)
- [ ] Implement DeviceSyncService
- [ ] Implement LogProcessorService
- [ ] Create unit tests
- [ ] Create API endpoints
- [ ] Code review & documentation

### Backend Developer (Secondary)
- [ ] Implement Sync Worker
- [ ] Create integration tests
- [ ] Set up monitoring
- [ ] Performance testing
- [ ] Deployment planning

### Database Engineer
- [ ] Design schema migrations
- [ ] Optimize indexes
- [ ] Performance tuning
- [ ] Backup/recovery procedures
- [ ] Capacity planning

### QA Engineer
- [ ] Test planning & execution
- [ ] Device compatibility testing
- [ ] Load testing
- [ ] Security testing
- [ ] Go-live testing

### Tech Lead
- [ ] Architecture review
- [ ] Blocker resolution
- [ ] Risk management
- [ ] Team coordination
- [ ] Stakeholder updates

---

## 📞 Support & Escalation

### Issues & Questions

1. **Technical Questions** → Tech Lead → Architect
2. **Database Issues** → Database Engineer → DevOps
3. **Device Issues** → Dahua Support + Internal Team
4. **Performance** → Database Engineer → DevOps
5. **Deployment Issues** → DevOps → Cloud Provider

### Emergency Contacts
- Tech Lead: [Contact]
- Database Lead: [Contact]
- On-Call Oncall: [Process]

---

## ✅ Final Checklist

Before moving to Phase 3:

- [ ] All code committed and reviewed
- [ ] All tests passing
- [ ] Monitoring active and healthy
- [ ] Documentation complete
- [ ] Team trained
- [ ] 48+ hours production monitoring
- [ ] Success metrics met
- [ ] Phase 3 roadmap created

---

**Ready?** Let's go! 🚀

**Date:** March 3, 2026  
**Next Phase:** Phase 3 (Testing & Performance Optimization)  
**Est. Go-Live:** March 17, 2026
