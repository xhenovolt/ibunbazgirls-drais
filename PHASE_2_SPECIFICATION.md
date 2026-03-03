# 🚀 DRais Phase 2 - Device Sync Engine Specification

**Status:** Ready for Implementation  
**Duration:** 2-3 weeks  
**Priority:** High  
**Complexity:** Medium-High  
**Date Created:** March 3, 2026

---

## 📌 Executive Summary

Phase 2 builds on Phase 1's multi-tenancy foundation to create the **Device Sync Engine** - a real-time system for pulling attendance logs from Dahua biometric devices, processing them, and matching them to students for automated attendance tracking.

### What This Solves
- ❌ Currently: Manual or limited device integration
- ✅ After Phase 2: Automated, scalable device sync for 100+ schools

### What Gets Delivered
1. **Device Sync Service** - Pulls logs from Dahua devices on schedule
2. **Log Processing Engine** - Matches device IDs to students
3. **Sync Worker** - Background job for continuous synchronization
4. **Monitoring Dashboard** - Track sync health and failures
5. **Admin APIs** - Manual sync triggers and diagnostics

---

## 🎯 Phase 2 Objectives

### Primary Goals
- [ ] Implement Device Sync Service that pulls from Dahua devices
- [ ] Build log processing engine with student mapping
- [ ] Create background worker for scheduled syncs
- [ ] Add monitoring and alerting
- [ ] Maintain 99.9% sync success rate
- [ ] Process 100K+ logs per sync cycle

### Success Metrics
| Metric | Target | Measurement |
|--------|--------|-------------|
| **Sync Success Rate** | 99.9% | device_sync_history success count |
| **Log Match Rate** | 95%+ | matched vs unmatched logs |
| **Processing Speed** | <5min/1K logs | sync duration tracking |
| **Error Recovery** | Auto-retry | retry logic + manual override |
| **API Response Time** | <100ms p95 | monitoring/logging |
| **Uptime** | 99.5% | worker heartbeat |

---

## 📦 Phase 2 Deliverables

### 1. Production Code (5-6 files)

#### 1.1 Core Services
```
src/lib/device-sync-service.ts (250+ lines)
  ├── syncDeviceLogsAction() - Main sync orchestrator
  ├── fetchLogsFromDahua() - Device communication
  ├── validateAndStoreRawLogs() - Data persistence
  ├── emitSyncEvents() - Event publication
  └── recordSyncHistory() - Tracking & diagnostics

src/lib/log-processor-service.ts (200+ lines)
  ├── processAttendanceLog() - Individual log matching
  ├── findDeviceMapping() - Device ID → Student mapping
  ├── updateLogWithStudentId() - Database updates
  ├── handleUnmatchedLogs() - Error handling
  └── emitMatchedEvents() - Downstream notifications
```

#### 1.2 Background Worker
```
src/workers/device-sync-worker.ts (200+ lines)
  ├── scheduleDeviceSyncs() - Main loop (every 5 min)
  ├── getAllActiveDevices() - School enumeration
  ├── executeSync() - Call sync service
  ├── handleSyncFailure() - Retry logic
  └── reportHealthStatus() - Monitoring
```

#### 1.3 API Endpoints
```
src/app/api/device-sync/route.ts (150+ lines)
  ├── POST /api/device-sync - Manual sync trigger
  ├── GET /api/device-sync/status - View sync status
  ├── GET /api/device-sync/history - View sync history

src/app/api/device-sync/[deviceId]/route.ts (100+ lines)
  ├── GET - Single device sync status
  ├── POST - Sync single device (manual)

src/app/api/logs/unmatched/route.ts (100+ lines)
  ├── GET - List unmatched attendance logs
  ├── POST - Retry processing unmatched logs
```

#### 1.4 Utilities
```
src/lib/dahua-client.ts (250+ lines) [MAY ALREADY EXIST]
  ├── DahuaClientFactory - Device-specific client creation
  ├── getAttendanceLogs() - Fetch from device
  ├── getDeviceStatus() - Health check
  ├── handleRetries() - Exponential backoff

src/lib/log-matcher-utils.ts (150+ lines)
  ├── fuzzyMatchUser() - Handle misspellings
  ├── validateLogData() - Data quality checks
  ├── generateMatchScore() - Confidence scoring
  └── detectDuplicates() - Prevent double-counting
```

### 2. Database Schema (1 file)

```
sql/PHASE_2_MIGRATION.sql (~200 lines)
  ├── Alter device_sync_history with additional fields
  ├── Create device_sync_checkpoints table (if not exists)
  ├── Create attendance_log_processing table
  ├── Create sync_errors_log table
  ├── Add indexes for performance
  └── Verification & rollback queries
```

### 3. Documentation (4-5 files)

```
PHASE_2_IMPLEMENTATION_GUIDE.md (400+ lines)
  ├── Step-by-step setup instructions
  ├── Configuration guide
  ├── Testing procedures
  ├── Troubleshooting guide
  └── Team role assignments

PHASE_2_CHECKLIST_SUMMARY.md (300+ lines)
  ├── 30-minute quick start
  ├── Pre-implementation checklist
  ├── Week-by-week breakdown
  ├── Testing checklist
  └── Go-live checklist

PHASE_2_API_REFERENCE.md (200+ lines)
  ├── Device Sync API endpoints
  ├── Webhook specifications
  ├── Error codes & responses
  └── Example requests/responses

PHASE_2_TROUBLESHOOTING_GUIDE.md (200+ lines)
  ├── Common issues & solutions
  ├── Debugging techniques
  ├── Performance tuning
  └── Rollback procedures
```

---

## 🔧 Technical Architecture

### 2.1 Device Sync Service Flow

```
┌─────────────────────────────────────────────────────────────┐
│ Device Sync Worker (Every 5 minutes)                        │
└─────────────────────┬───────────────────────────────────────┘
                      │
      ┌───────────────▼────────────────┐
      │ For each school:               │
      │ - Get active devices           │
      │ - Get last sync checkpoint     │
      │ - Calculate sync window        │
      └───────────────┬────────────────┘
                      │
      ┌───────────────▼────────────────────────────────────────┐
      │ For each device in school:                             │
      │ 1. Create Dahua client                                 │
      │ 2. Fetch logs since last checkpoint                    │
      │ 3. Validate log data                                   │
      │ 4. Store raw logs in database                          │
      │ 5. Update device sync status                           │
      │ 6. Emit event for processing                           │
      │ 7. Record success/failure                              │
      └───────────────┬────────────────────────────────────────┘
                      │
      ┌───────────────▼──────────────────────────────────────┐
      │ Log Processor (Event-driven)                          │
      └───────────────┬──────────────────────────────────────┘
                      │
      ┌───────────────▼──────────────────────────────────────┐
      │ For each raw log:                                    │
      │ 1. Find device mapping (device_id + device_user_id) │
      │ 2. Validate student exists                          │
      │ 3. Check for duplicates                             │
      │ 4. Update log with student_id                       │
      │ 5. Change status to 'matched' or 'unmatched'        │
      │ 6. Emit matched event for dashboard                 │
      └───────────────┬──────────────────────────────────────┘
                      │
      ┌───────────────▼──────────────────────────────────────┐
      │ Results:                                             │
      │ ✅ Matched logs → Ready for attendance processing    │
      │ ✅ Unmatched logs → Manual review queue              │
      │ ✅ Failed syncs → Alerts & retry queue               │
      └──────────────────────────────────────────────────────┘
```

### 2.2 Core Service Interfaces

#### DeviceSyncService
```typescript
interface IDeviceSyncService {
  // Main synchronization method
  syncDeviceLogsAction(
    schoolId: number,
    deviceId: number,
    options?: SyncOptions
  ): Promise<SyncResult>;

  // Sync multiple devices
  syncSchoolDevices(
    schoolId: number
  ): Promise<Map<number, SyncResult>>;

  // Get sync status and history
  getDeviceSyncStatus(
    schoolId: number,
    deviceId: number
  ): Promise<SyncStatus>;

  getSyncHistory(
    schoolId: number,
    deviceId?: number,
    limit?: number
  ): Promise<SyncHistoryRecord[]>;

  // Retry failed sync
  retryFailedSync(
    schoolId: number,
    syncHistoryId: number
  ): Promise<SyncResult>;
}
```

#### LogProcessorService
```typescript
interface ILogProcessorService {
  // Process a single log
  processAttendanceLog(
    schoolId: number,
    log: RawAttendanceLog
  ): Promise<ProcessingResult>;

  // Batch process logs
  processBatchLogs(
    schoolId: number,
    logs: RawAttendanceLog[]
  ): Promise<ProcessingResult[]>;

  // Retry unmatched logs
  retryUnmatchedLogs(
    schoolId: number,
    limit?: number
  ): Promise<ProcessingResult[]>;

  // Get processing statistics
  getProcessingStats(
    schoolId: number,
    dateRange?: DateRange
  ): Promise<ProcessingStats>;
}
```

### 2.3 Data Model Extensions

#### device_sync_history (Extended from Phase 1)
```sql
CREATE TABLE device_sync_history (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  school_id INT NOT NULL,
  device_id INT NOT NULL,
  
  -- Sync details
  sync_start_at DATETIME NOT NULL,
  sync_end_at DATETIME,
  duration_ms INT,
  
  -- Results
  status ENUM('success', 'partial', 'failed') NOT NULL,
  logs_fetched INT DEFAULT 0,
  logs_processed INT DEFAULT 0,
  logs_matched INT DEFAULT 0,
  logs_unmatched INT DEFAULT 0,
  
  -- Tracking
  last_rec_no INT,  -- Last record number from device
  error_message TEXT,
  retry_count INT DEFAULT 0,
  next_retry_at DATETIME,
  
  -- Metadata
  worker_id VARCHAR(50),  -- Which worker instance ran it
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  KEY idx_school_device (school_id, device_id),
  KEY idx_created_at (created_at),
  KEY idx_status (status),
  KEY idx_next_retry (next_retry_at)
);
```

#### device_sync_checkpoints (New)
```sql
CREATE TABLE device_sync_checkpoints (
  id INT PRIMARY KEY AUTO_INCREMENT,
  school_id INT NOT NULL,
  device_id INT NOT NULL,
  
  -- Last successful sync point
  last_rec_no INT DEFAULT 0,
  last_sync_at DATETIME,
  
  -- Metadata
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  UNIQUE KEY uk_school_device (school_id, device_id),
  KEY idx_school_id (school_id)
);
```

#### attendance_log_processing (New)
```sql
CREATE TABLE attendance_log_processing (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  school_id INT NOT NULL,
  device_id INT NOT NULL,
  
  -- Raw log data (as stored from device)
  raw_log_data JSON NOT NULL,
  device_user_id VARCHAR(50) NOT NULL,
  
  -- Processing results
  processing_status ENUM('matched', 'unmatched', 'duplicate', 'error') NOT NULL,
  student_id INT,  -- NULL if unmatched
  mapping_id INT,  -- device_user_mapping.id if matched
  match_confidence DECIMAL(3,2),  -- 0.00 to 1.00
  
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
  KEY idx_unmatched (processing_status, school_id)
);
```

#### sync_errors_log (New)
```sql
CREATE TABLE sync_errors_log (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  school_id INT NOT NULL,
  device_id INT NOT NULL,
  
  -- Error details
  error_type ENUM('connection', 'authentication', 'validation', 'parsing', 'storage', 'processing') NOT NULL,
  error_message TEXT NOT NULL,
  error_details JSON,
  
  -- Context
  sync_history_id BIGINT,
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
  KEY idx_resolved_at (resolved_at)
);
```

---

## 📊 Implementation Timeline

### Week 1: Core Services & API Setup (5 days)
```
Day 1-2: DeviceSyncService implementation
  ├─ Dahua integration
  ├─ Error handling & retries
  ├─ Multi-tenancy enforcement
  └─ Testing

Day 3: LogProcessorService implementation
  ├─ Device mapping logic
  ├─ Duplicate detection
  ├─ Batch processing
  └─ Testing

Day 4: API endpoints
  ├─ Device sync endpoints
  ├─ Status/history endpoints
  ├─ Trigger/retry endpoints
  └─ Testing

Day 5: Database migration & validation
  ├─ Create tables & indexes
  ├─ Data migration (if needed)
  ├─ Performance tuning
  └─ Verification queries
```

### Week 2: Worker & Monitoring (5 days)
```
Day 1-2: Sync Worker implementation
  ├─ Scheduling system
  ├─ Multi-school enumeration
  ├─ Parallel sync execution
  ├─ Health monitoring
  └─ Testing

Day 3: Monitoring dashboard
  ├─ Sync status views
  ├─ Failure alerts
  ├─ Statistics dashboards
  ├─ Manual controls
  └─ Testing

Day 4-5: Integration testing & optimization
  ├─ End-to-end testing
  ├─ Load testing (100K+ logs)
  ├─ Performance tuning
  ├─ Failover scenarios
  ├─ QA validation
```

### Week 3: Documentation & Deployment (5 days)
```
Day 1: Complete documentation
Day 2: Team training & knowledge transfer
Day 3: Staging deployment & testing
Day 4: Production deployment planning
Day 5: Go-live & monitoring
```

---

## 🎬 Getting Started

### Prerequisites
- [x] Phase 1 completed and verified
- [x] Database migration from Phase 1 applied
- [x] Dahua API credentials ready
- [ ] Device sync worker infrastructure (Node.js with cron or similar)
- [ ] Monitoring system setup (optional but recommended)

### Required Decisions
1. **Sync Frequency**: Every 5 minutes (recommended) or configurable per school?
2. **Log Retention**: Keep raw logs indefinitely or purge after X days?
3. **Failure Handling**: Automatic retry with exponential backoff (recommended)?
4. **Monitoring**: Use built-in dashboard or integrate with external tool?
5. **Deployment**: Same process as API server or separate worker container?

### Team Structure (Recommended)
| Role | Count | Tasks |
|------|-------|-------|
| Backend Developers | 2 | Services, APIs, worker |
| Database Engineer | 1 | Schema, indexes, migrations |
| DevOps | 1 | Worker deployment, monitoring |
| QA | 1 | Testing, validation |
| Tech Lead | 1 | Architecture, reviews |

---

## ⚠️ Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| **Device Connection Failures** | High | Medium | Retry logic, fallback mode, manual override |
| **Log Processing Slowness** | Medium | Medium | Batch processing, async workers, indexing |
| **Device ID Mismatches** | Medium | High | Fuzzy matching, manual review queue, validation |
| **Data Duplication** | Medium | Medium | Deduplication logic, idempotency checks |
| **Performance Degradation** | Low | Medium | Load testing, query optimization, caching |
| **Data Consistency** | Low | High | Transaction handling, verification queries |

---

## ✅ Quality Checklist

- [ ] Code coverage >80%
- [ ] Unit tests for all services
- [ ] Integration tests for full flow
- [ ] Load testing (100K+ logs)
- [ ] Multi-tenancy isolation tests
- [ ] Error scenario testing
- [ ] Rollback procedure documented
- [ ] Performance benchmarks documented
- [ ] API documentation complete
- [ ] Team training completed

---

## 📞 Next Steps

1. **Read** PHASE_2_CHECKLIST_SUMMARY.md (20 minutes)
2. **Review** PHASE_2_IMPLEMENTATION_GUIDE.md (60 minutes)
3. **Prepare** infrastructure & team
4. **Schedule** Phase 2 kickoff
5. **Begin** implementation

---

**Status:** Ready to Implement 🚀  
**Date:** March 3, 2026  
**Next Phase:** Phase 3 (Test Coverage & Performance)
