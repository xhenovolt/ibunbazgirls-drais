# ⚡ PHASE 2 - Quick Reference & Checklist

**For Busy Developers** - 30-minute orientation  
**Last Updated:** March 3, 2026

---

## 🎯 What is Phase 2?

```
PHASE 1 (✅ DONE)        PHASE 2 (← YOU ARE HERE)        PHASE 3                PHASE 4
Multi-Tenancy    →    Device Sync Engine     →    Testing & Perf.    →    Rollout & Monitor
Foundation              (Real-time log sync)         (Hardening)            (Scale to 100+ schools)
```

### In One Sentence
**Build a system that automatically pulls attendance logs from Dahua biometric devices every 5 minutes, matches them to students, and makes them available for attendance processing.**

### In One Paragraph
Phase 2 deploys the "Device Sync Engine" - a background worker that runs every 5 minutes, connects to all Dahua biometric devices, pulls new attendance logs, validates and processes them, and stores the results. It matches device user IDs to student records and handles failures gracefully with automatic retries.

---

## 📊 Quick Stats

| Aspect | Details |
|--------|---------|
| **Duration** | 2-3 weeks |
| **Team Size** | 3-5 developers |
| **Files to Create** | 6-7 |
| **Database Tables** | 4 new + 1 modified |
| **API Endpoints** | 6 new |
| **Worker Processes** | 1 |
| **Complexity** | Medium-High |
| **Risk Level** | Medium |
| **Estimated Effort** | 80-120 hours |

---

## 🏗️ Architecture (5-Minute Overview)

```
Every 5 minutes:
┌─────────────────────────────────────────────────────┐
│ Sync Worker                                         │
│ ├─ Select all schools with active devices          │
│ └─ For each school:                                │
│    ├─ Get list of biometric devices                │
│    └─ For each device:                             │
│       ├─ Connect to device                         │
│       ├─ Fetch logs since last checkpoint          │
│       ├─ Store raw logs in database                │
│       ├─ Update checkpoint                         │
│       └─ Emit event: "logs fetched"                │
├─────────────────────────────────────────────────────┤
│ Log Processor (Event-Driven)                        │
│ ├─ Listen for "logs fetched" events                │
│ ├─ For each raw log:                               │
│ │  ├─ Find device mapping (device_id + user_id)    │
│ │  ├─ Match to student                             │
│ │  ├─ Check for duplicates                         │
│ │  └─ Update status: matched OR unmatched          │
│ └─ Emit event: "logs processed"                    │
├─────────────────────────────────────────────────────┤
│ Results                                             │
│ ├─ Matched Logs (95%+)  → Ready for attendance      │
│ ├─ Unmatched Logs (5%)  → Manual review queue       │
│ └─ Failed Syncs         → Alerts + retry queue      │
└─────────────────────────────────────────────────────┘
```

---

## 📋 Pre-Launch Checklist

Before you touch any code:

### Infrastructure
- [ ] Dahua API credentials ready
- [ ] Production database backup taken
- [ ] Cron/scheduler available (Node.js process or external)
- [ ] Monitoring system ready
- [ ] Logging system ready

### Knowledge
- [ ] Team read PHASE_2_SPECIFICATION.md (20 min)
- [ ] Core developers reviewed Phase 1 code (60 min)
- [ ] Database engineer reviewed schema (30 min)
- [ ] Everyone reviewed architecture diagram (10 min)

### Setup
- [ ] Dependencies installed: `npm install node-cron`
- [ ] Environment variables configured
- [ ] Test database populated
- [ ] Team assignments finalized

### Sign-offs
- [ ] Tech lead approved timeline
- [ ] Operations approved depl oyment plan
- [ ] All blockers resolved

---

## 🔨 Implementation Checklist

### Week 1: Core Services

#### Day 1-2: DeviceSyncService (50-60 hours)
```
□ Create src/lib/device-sync/device-sync.service.ts

Implement:
  □ constructor(db, dahuaClient, logger)
  □ syncDeviceLogsAction(schoolId, deviceId)
  □ fetchLogsFromDahua(device)
  □ validateAndStoreRawLogs(logs)
  □ emitSyncEvents(schoolId, deviceId)
  □ recordSyncHistory(result)

Tests:
  □ Unit tests for each method
  □ Mock Dahua client
  □ Error scenarios
  □ Rate limiting
```

#### Day 3: LogProcessorService
```
□ Create src/lib/device-sync/log-processor.service.ts

Implement:
  □ processAttendanceLog(schoolId, log)
  □ findDeviceMapping(schoolId, deviceId, userId)
  □ validateLogData(log)
  □ checkForDuplicates(log)
  □ updateLogWithStudentId(logId, studentId)

Tests:
  □ Device mapping resolution
  □ Duplicate detection
  □ Batch processing
  □ Error paths
```

#### Day 4: API Endpoints
```
□ mkdir -p src/app/api/device-sync

POST /api/device-sync
  □ Trigger manual sync
  □ Return job ID
  □ Enforce school isolation

GET /api/device-sync/status
  □ Show current sync status
  □ Last sync time, success count
  □ Active jobs

GET /api/device-sync/history
  □ List past syncs
  □ Pagination
  □ Filtering by status/school

Tests:
  □ Authentication
  □ Authorization
  □ Pagination
  □ Error responses
```

#### Day 5: Database Schema
```
□ Create sql/PHASE_2_MIGRATION.sql

Add tables:
  □ device_sync_checkpoints
  □ attendance_log_processing
  □ sync_errors_log
  □ Alter device_sync_history

Add indexes:
  □ idx_school_device
  □ idx_processing_status
  □ idx_student_id
  □ idx_synced_at

Run migration:
  □ mysqldump backup
  □ Apply migration
  □ Verify tables created
  □ Check indexes
```

### Week 2: Worker & Monitoring

#### Day 1-2: Sync Worker
```
□ Create src/workers/device-sync-worker.ts

Implement:
  □ scheduleDeviceSyncs() - cron job every 5 min
  □ getAllActiveSchools()
  □ syncAllDevicesInSchool(schoolId)
  □ handleSyncFailure(error)
  □ reportHealthStatus()
  □ Graceful shutdown

Tests:
  □ Scheduling
  □ Error handling
  □ Concurrent execution
  □ Resource cleanup
```

#### Day 3: Monitoring Dashboard
```
□ Create monitoring endpoints
  □ /api/device-sync/dashboard - Stats view
  □ /api/device-sync/alerts - Recent failures

Create monitoring queries:
  □ Success rate query
  □ Logs processed per time period
  □ Unmatched logs percentage
  □ Average processing time

Alert thresholds:
  □ Success rate < 95%
  □ Sync delay > 5 min
  □ Unmatched logs > 10%
```

#### Day 4-5: Testing
```
□ Unit test suite (80%+ coverage)
□ Integration tests
□ Load test (100K logs)
□ Multi-tenancy tests
□ Error scenario tests
```

### Week 3: Finalization

#### Day 1: Documentation
```
□ Code comments complete
□ README.md updated
□ Configuration documented
□ Troubleshooting guide
```

#### Day 2: Team Training
```
□ Architecture walkthrough (60 min)
□ Operational procedures (30 min)
□ Troubleshooting guide (30 min)
□ Q&A session
```

#### Day 3-4: Staging Deployment
```
□ Deploy to staging
□ Run smoke tests
□ 24-hour monitoring
□ Load test run
□ Team sign-off
```

#### Day 5: Production Deployment
```
□ Create database backup
□ Apply migration
□ Deploy code with zero-downtime
□ Start worker process
□ Monitor for 24 hours
□ Declare success
```

---

## 🗄️ Database Changes Quick Ref

### New Tables
```sql
device_sync_checkpoints   -- Track last sync point per device
attendance_log_processing -- Staging table for processing
sync_errors_log          -- Error diagnostics
```

### Modified Tables
```sql
device_sync_history      -- Added: duration, logs_matched, worker_id, retry fields
```

### Apply Migration
```bash
mysql -u root -p abildaan < sql/PHASE_2_MIGRATION.sql
```

---

## 📂 Files to Create

```
Phase 2 - Core Files to Create:

src/lib/device-sync/
  ├── index.ts                      (Exports)
  ├── device-sync.service.ts        ⭐ PRIMARY (250 lines)
  ├── log-processor.service.ts      ⭐ PRIMARY (200 lines)
  ├── types.ts                      (Interfaces ~100 lines)
  └── utils.ts                      (Helpers ~100 lines)

src/app/api/
  ├── device-sync/
  │   ├── route.ts                  📍 (POST/GET endpoints, 150 lines)
  │   └── [deviceId]/route.ts       📍 (Single device, 100 lines)
  └── logs/unmatched/route.ts       📍 (Unmatched logs, 100 lines)

src/workers/
  └── device-sync-worker.ts         ⭐ PRIMARY (200 lines)

sql/
  └── PHASE_2_MIGRATION.sql         (200 lines)

Documentation:
  ├── PHASE_2_SPECIFICATION.md      (✅ DONE)
  ├── PHASE_2_IMPLEMENTATION_GUIDE.md (✅ DONE)  
  └── PHASE_2_CHECKLIST_SUMMARY.md  (✅ THIS FILE)

Legend:
⭐ Core business logic (critical)
📍 API endpoints (integration points)
```

---

## 🧪 Testing Checklist

### Unit Tests (Each service)
```
□ DeviceSyncService:
  □ fetchLogsFromDahua() - 3 tests
  □ validateAndStoreRawLogs() - 3 tests
  □ recordSyncHistory() - 2 tests
  
□ LogProcessorService:
  □ findDeviceMapping() - 4 tests
  □ processAttendanceLog() - 3 tests
  □ checkForDuplicates() - 2 tests

□ API Endpoints:
  □ POST /device-sync - 3 tests
  □ GET /device-sync/status - 2 tests
  □ Authentication/Authorization - 3 tests

Target: 80%+ code coverage
```

### Integration Tests
```
□ Full sync flow: Device → Logs → Processing → DB
□ Error handling: Connection → Retry → Recovery
□ Multi-tenancy: School 1 ≠ School 2
□ Duplicate detection: Same device_user_id → Duplicate found
```

### Load Tests
```
□ 100K logs per sync cycle
□ 20 concurrent devices
□ Process within 5 minutes
□ Memory doesn't grow unbounded
```

---

## 🚀 Deployment Checklist

### Pre-Deployment (24 hours before)
```
□ All tests passing (100%)
□ Code review completed
□ Database backup verified
□ Team trained
□ Rollback plan tested
```

### Deployment Steps
```
1. □ Backup database
   mysqldump -u root -p abildaan > backup_phase2.sql

2. □ Create database tables
   mysql -u root -p abildaan < sql/PHASE_2_MIGRATION.sql

3. □ Verify migration
   SELECT COUNT(*) FROM device_sync_checkpoints;

4. □ Deploy code
   git pull, npm install, npm run build

5. □ Start worker
   npm run worker:start
   # OR restart process manager

6. □ Monitor for 1 hour
   Verify first sync completed successfully

7. □ Monitor for 24 hours
   Success rate, error rate, processing latency
```

### Post-Deployment (24-48 hours)
```
□ 24+ hours of successful syncs
□ Success rate > 99%
□ Unmatched logs < 5%
□ No errors in logs
□ All alerts within normal ranges
□ Team ready for on-call
```

---

## 📊 Success Metrics

After go-live, track these daily:

```
Metric                    Target      Current   Status
─────────────────────────────────────────────────────────
Sync Success Rate         > 99%       _____%    □
Logs Matched Rate         > 95%       _____%    □
Processing Latency        < 5 min     ___ min   □
Unmatched Logs (%)        < 5%        _____%    □
Error Rate                < 1%        _____%    □
API Response Time (p95)   < 100ms     ___ ms    □
Worker Uptime             > 99.5%     _____%    □
```

---

## 🔧 Quick Troubleshooting

| Problem | Quick Fix |
|---------|-----------|
| Worker not running | `ps aux \| grep device-sync-worker` then check logs |
| Sync timeout | Increase `DAHUA_TIMEOUT_MS=60000` in .env |
| Unmatched logs | Check device_user_mappings table |
| Slow syncs | Reduce `DEVICE_SYNC_MAX_LOGS_PER_BATCH=500` |
| Memory leak | Reduce batch size or check for large JSON objects |
| Device connection fails | Verify device IP, firewall, credentials |

---

## 📞 Key Commands

```bash
# Development
npm run build                    # Build project
npm run dev                      # Start dev server
npm test                         # Run tests
npm run test:watch             # Watch mode

# Worker
npm run worker:start            # Start sync worker
npm run worker:stop             # Stop sync worker
npm run worker:logs             # View worker logs

# Database
npm run migrate:phase2          # Apply migration
npm run db:verify              # Verify tables created
npm run db:seed:test           # Seed test data

# Monitoring
npm run monitor:sync-status     # View sync stats
npm run report:daily           # Daily report
npm run alert:check            # Check alert thresholds
```

---

## 🎓 Learning Path (For Team)

Recommended reading order:

1. **This file** (5 min) - You are here
2. **PHASE_2_SPECIFICATION.md** (20 min) - Understand requirements
3. **PHASE_2_IMPLEMENTATION_GUIDE.md** (60 min) - Details & steps
4. **Phase 1 Code Review** (60 min) - Understand foundation
5. **Dahua API Docs** (30 min) - Device integration knowledge
6. **Start Coding!** (Week 1-2)

---

## ❓ Common Questions

**Q: Why every 5 minutes?**  
A: Balance between real-time sync and device load. Configurable if needed.

**Q: What if a device doesn't have new logs?**  
A: Sync completes quickly (just checkpoint update), no harm.

**Q: How do we handle devices that go offline?**  
A: Automatic retry with exponential backoff. After 3 failures, alert raised and manual override available.

**Q: What about office hours when device might not be available?**  
A: Worker runs 24/7, failed syncs are retried. Configure quiet hours if needed.

**Q: Can we sync multiple devices in parallel?**  
A: Yes, default is 10 concurrent devices. Configurable.

**Q: What if a device has 50,000 unprocessed logs?**  
A: Batched processing (1K logs at a time), spreads over multiple sync cycles.

**Q: How do we prevent duplicate attendance entries?**  
A: Deduplication logic in log processor + database constraints.

---

## 🏁 Finish Line

Successful Phase 2 means:
- ✅ Device logs are syncing automatically every 5 minutes
- ✅ 95%+ of logs are matched to students
- ✅ Sync success rate is >99%
- ✅ Unmatched logs are in a manual review queue
- ✅ System alerts on failures
- ✅ Team understands how to operate & troubleshoot

Then you're ready for **Phase 3: Testing & Performance Optimization** 🎉

---

**Status:** Ready to Start  
**Created:** March 3, 2026  
**Kick-off Date:** [Your choice]  
**Estimated Go-Live:** +2-3 weeks from kickoff

**Questions?** Check PHASE_2_IMPLEMENTATION_GUIDE.md for detailed answers.

**Let's build!** 🚀
