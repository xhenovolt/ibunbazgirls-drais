# DRais Platform 2.0 - Comprehensive Architecture Redesign
## Scaling from 1 School to 100+ Schools with Multi-Tenant Architecture

**Document Version:** 2.0  
**Date:** March 2026  
**Scope:** Complete system redesign for enterprise SaaS scaling  
**Target:** 100+ schools, 20+ devices per school, 100,000+ logs/day  

---

## 📋 EXECUTIVE SUMMARY

DRais is transitioning from a single-tenant platform to a **multi-tenant enterprise SaaS solution** serving hundreds of schools with independent biometric attendance systems. This document outlines the complete architectural redesign addressing:

- **Multi-tenancy enforcement** at every database and API layer
- **Device management abstraction** for heterogeneous biometric devices
- **Scalable event-driven architecture** for real-time attendance processing
- **Security hardening** with role-based access control (RBAC)
- **Performance optimization** for 100,000+ daily logs
- **Operational visibility** via comprehensive audit and monitoring

---

## 🏗️ PART 1: DATABASE ARCHITECTURE REDESIGN

### 1.1 Current State Problems

❌ **Current Issues:**
- No school isolation (single-tenant hardcoded)
- Device abstraction missing (biometric IDs stored directly in students table)
- Attendance logs lack device context
- No device sync history or failure tracking
- Duplicate detection not systematic
- Audit trail incomplete

### 1.2 Proposed Multi-Tenant Schema

```sql
-- ============================================================================
-- CORE MULTI-TENANT TABLES
-- ============================================================================

-- 1. SCHOOLS TABLE - Multi-tenant root
CREATE TABLE schools (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL UNIQUE,
  short_code VARCHAR(10) NOT NULL UNIQUE,
  email VARCHAR(255),
  phone VARCHAR(20),
  address TEXT,
  country VARCHAR(100),
  timezone VARCHAR(50) DEFAULT 'Africa/Nairobi',
  
  -- License & subscription
  subscription_tier ENUM('free', 'standard', 'enterprise') DEFAULT 'standard',
  max_students INT DEFAULT 500,
  max_devices INT DEFAULT 5,
  max_staff INT DEFAULT 50,
  
  -- Configuration
  financial_year_start DATE,
  school_year_start DATE,
  school_year_end DATE,
  school_calendar_id INT,
  
  -- Features enabled
  enable_fingerprint BOOLEAN DEFAULT TRUE,
  enable_facial_recognition BOOLEAN DEFAULT FALSE,
  enable_sms_alerts BOOLEAN DEFAULT FALSE,
  enable_api_access BOOLEAN DEFAULT FALSE,
  
  -- Status & audit
  status ENUM('active', 'suspended', 'archived') DEFAULT 'active',
  logo_url VARCHAR(500),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  created_by INT,
  
  KEY idx_status (status),
  KEY idx_subscription (subscription_tier),
  CONSTRAINT fk_schools_creator FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. BIOMETRIC DEVICES TABLE - Device abstraction layer
CREATE TABLE biometric_devices (
  id INT PRIMARY KEY AUTO_INCREMENT,
  school_id INT NOT NULL,
  
  -- Device identification
  device_code VARCHAR(50) NOT NULL,
  device_name VARCHAR(255) NOT NULL,
  model VARCHAR(100),
  serial_number VARCHAR(100) UNIQUE,
  
  -- Device type & capabilities
  device_type ENUM('dahua', 'hikvision', 'zk_technology', 'generic', 'other') DEFAULT 'dahua',
  capabilities JSON, -- {"fingerprint": true, "face": true, "iris": false}
  
  -- Network configuration
  ip_address VARCHAR(45),
  port INT DEFAULT 5000,
  protocol ENUM('http', 'https') DEFAULT 'http',
  username VARCHAR(100),
  password_encrypted VARCHAR(500),
  
  -- Sync configuration
  location_name VARCHAR(255), -- main_gate, classroom_3, office
  sync_interval_minutes INT DEFAULT 5,
  last_sync_at TIMESTAMP NULL,
  last_rec_no INT DEFAULT 0,
  sync_error_count INT DEFAULT 0,
  last_error_message TEXT,
  last_error_at TIMESTAMP NULL,
  
  -- Device status
  status ENUM('online', 'offline', 'error', 'disabled') DEFAULT 'offline',
  connected_at TIMESTAMP NULL,
  disconnected_at TIMESTAMP NULL,
  check_in_interval INT DEFAULT 60, -- seconds
  
  -- Maintenance
  firmware_version VARCHAR(50),
  last_firmware_update_at TIMESTAMP NULL,
  
  -- Audit
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  created_by INT NOT NULL,
  
  UNIQUE KEY unique_school_device (school_id, device_code),
  KEY idx_school_status (school_id, status),
  KEY idx_device_type (device_type),
  KEY idx_last_sync (last_sync_at),
  CONSTRAINT fk_device_school FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
  CONSTRAINT fk_device_creator FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. DEVICE USER MAPPINGS - Biometric ID abstraction
CREATE TABLE device_user_mappings (
  id INT PRIMARY KEY AUTO_INCREMENT,
  school_id INT NOT NULL,
  device_id INT NOT NULL,
  student_id INT NOT NULL,
  
  -- Device-specific IDs
  device_user_id INT NOT NULL, -- rec_no from device
  device_user_pin VARCHAR(50),
  
  -- Mapping metadata
  status ENUM('active', 'inactive', 'sync_pending', 'error') DEFAULT 'active',
  verification_method ENUM('fingerprint', 'face', 'pin', 'multi') DEFAULT 'fingerprint',
  quality_score INT, -- 0-100 biometric quality
  
  -- Last activity
  last_verified_at TIMESTAMP NULL,
  last_synced_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  -- Audit
  mapping_set_by INT,
  mapping_set_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  UNIQUE KEY unique_device_mapping (device_id, student_id),
  UNIQUE KEY unique_device_user (device_id, device_user_id),
  KEY idx_school_mappings (school_id),
  KEY idx_student_mappings (student_id),
  KEY idx_mapping_status (status),
  CONSTRAINT fk_mapping_school FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
  CONSTRAINT fk_mapping_device FOREIGN KEY (device_id) REFERENCES biometric_devices(id) ON DELETE CASCADE,
  CONSTRAINT fk_mapping_student FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
  CONSTRAINT fk_mapping_setter FOREIGN KEY (mapping_set_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. ATTENDANCE LOGS - Multi-device context
CREATE TABLE attendance_logs (
  id INT PRIMARY KEY AUTO_INCREMENT,
  school_id INT NOT NULL,
  device_id INT NOT NULL,
  student_id INT,
  
  -- Raw device data (never modified)
  device_user_id INT NOT NULL,
  device_rec_no INT NOT NULL,
  
  -- Timestamp data
  log_datetime DATETIME NOT NULL,
  timezone_offset VARCHAR(10),
  
  -- Verification & event
  verification_method ENUM('fingerprint', 'face', 'pin', 'multi', 'unknown') DEFAULT 'unknown',
  event_type ENUM('checkin', 'checkout', 'break_start', 'break_end') DEFAULT 'checkin',
  
  -- Processing state
  processing_status ENUM('unmatched', 'pending', 'matched', 'error') DEFAULT 'unmatched',
  matching_confidence INT, -- 0-100, null if unmatched
  
  -- Metadata
  raw_data JSON, -- Store full device response
  
  -- Audit
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  processed_at TIMESTAMP NULL,
  
  UNIQUE KEY unique_device_log (school_id, device_id, device_rec_no),
  KEY idx_school_date (school_id, log_datetime),
  KEY idx_student_date (student_id, log_datetime),
  KEY idx_device_date (device_id, log_datetime),
  KEY idx_processing_status (processing_status),
  KEY idx_unmatched (school_id, processing_status),
  CONSTRAINT fk_log_school FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
  CONSTRAINT fk_log_device FOREIGN KEY (device_id) REFERENCES biometric_devices(id) ON DELETE CASCADE,
  CONSTRAINT fk_log_student FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. UNMATCHED LOGS - For manual resolution (new)
CREATE TABLE unmatched_attendance_logs (
  id INT PRIMARY KEY AUTO_INCREMENT,
  school_id INT NOT NULL,
  device_id INT NOT NULL,
  
  -- Raw device data
  device_user_id INT NOT NULL,
  device_rec_no INT NOT NULL,
  log_datetime DATETIME NOT NULL,
  
  -- Metadata
  verification_method VARCHAR(50),
  quality_score INT,
  
  -- Admin resolution
  resolution_status ENUM('pending', 'matched', 'duplicate', 'invalid', 'ignored') DEFAULT 'pending',
  suggested_student_id INT,
  resolved_by INT,
  resolved_at TIMESTAMP NULL,
  resolution_notes TEXT,
  
  -- Audit
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  UNIQUE KEY unique_unmatched (school_id, device_id, device_rec_no),
  KEY idx_unmatched_pending (school_id, resolution_status),
  KEY idx_device_unmatched (device_id),
  CONSTRAINT fk_unmatched_school FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
  CONSTRAINT fk_unmatched_device FOREIGN KEY (device_id) REFERENCES biometric_devices(id) ON DELETE CASCADE,
  CONSTRAINT fk_unmatched_resolver FOREIGN KEY (resolved_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. DEVICE SYNC HISTORY - Operational visibility
CREATE TABLE device_sync_history (
  id INT PRIMARY KEY AUTO_INCREMENT,
  school_id INT NOT NULL,
  device_id INT NOT NULL,
  
  -- Sync details
  sync_start_at TIMESTAMP NOT NULL,
  sync_end_at TIMESTAMP,
  duration_seconds INT,
  
  -- Results
  logs_fetched INT DEFAULT 0,
  logs_processed INT DEFAULT 0,
  logs_unmatched INT DEFAULT 0,
  
  -- Status & errors
  status ENUM('success', 'partial', 'failed') DEFAULT 'failed',
  error_code VARCHAR(50),
  error_message TEXT,
  raw_response JSON,
  
  -- Pagination (for devices with many logs)
  start_rec_no INT,
  end_rec_no INT,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  KEY idx_device_syncs (device_id, sync_start_at),
  KEY idx_school_syncs (school_id, sync_start_at),
  CONSTRAINT fk_sync_school FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
  CONSTRAINT fk_sync_device FOREIGN KEY (device_id) REFERENCES biometric_devices(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- AUDIT & COMPLIANCE
-- ============================================================================

-- 7. ACTIVITY LOGS - Comprehensive audit trail
CREATE TABLE activity_logs (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  school_id INT NOT NULL,
  user_id INT,
  
  -- Action context
  action_type VARCHAR(50) NOT NULL, -- 'student_create', 'device_remap', 'log_delete'
  entity_type VARCHAR(50), -- 'student', 'device', 'attendance_log'
  entity_id INT,
  
  -- Changes (before/after)
  old_values JSON,
  new_values JSON,
  change_summary TEXT,
  
  -- Request context
  ip_address VARCHAR(45),
  user_agent TEXT,
  request_id VARCHAR(100),
  
  -- Audit
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  KEY idx_school_logs (school_id, timestamp),
  KEY idx_user_logs (user_id, timestamp),
  KEY idx_action_type (action_type),
  KEY idx_entity (entity_type, entity_id),
  CONSTRAINT fk_activity_school FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
  CONSTRAINT fk_activity_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
PARTITION BY RANGE (YEAR(timestamp)) (
  PARTITION p2025 VALUES LESS THAN (2026),
  PARTITION p2026 VALUES LESS THAN (2027),
  PARTITION p2027 VALUES LESS THAN (2028),
  PARTITION pmax VALUES LESS THAN MAXVALUE
);

-- 8. DUPLICATE DETECTION RECORDS
CREATE TABLE potential_duplicates (
  id INT PRIMARY KEY AUTO_INCREMENT,
  school_id INT NOT NULL,
  
  -- Duplicate group
  primary_student_id INT NOT NULL,
  secondary_student_id INT NOT NULL,
  
  -- Detection metadata
  similarity_score INT, -- 0-100, how confident we are
  match_reason VARCHAR(255), -- 'same_name', 'same_name_dob'
  detected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  -- Resolution
  status ENUM('pending', 'merged', 'ignored', 'false_positive') DEFAULT 'pending',
  resolved_by INT,
  resolved_at TIMESTAMP NULL,
  merge_notes TEXT,
  
  UNIQUE KEY unique_duplicate_pair (school_id, primary_student_id, secondary_student_id),
  KEY idx_pending_duplicates (school_id, status),
  CONSTRAINT fk_dup_school FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
  CONSTRAINT fk_dup_primary FOREIGN KEY (primary_student_id) REFERENCES students(id),
  CONSTRAINT fk_dup_secondary FOREIGN KEY (secondary_student_id) REFERENCES students(id),
  CONSTRAINT fk_dup_resolver FOREIGN KEY (resolved_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- USERS & AUTHORIZATION
-- ============================================================================

-- 9. UPDATED USERS TABLE
ALTER TABLE users ADD COLUMN school_id INT;
ALTER TABLE users ADD COLUMN role ENUM('super_admin', 'school_admin', 'teacher', 'staff', 'parent', 'student') DEFAULT 'staff';
ALTER TABLE users ADD KEY idx_school_users (school_id);
ALTER TABLE users ADD CONSTRAINT FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE;

-- 10. RBAC PERMISSIONS (new)
CREATE TABLE role_permissions (
  id INT PRIMARY KEY AUTO_INCREMENT,
  school_id INT,
  role VARCHAR(50) NOT NULL,
  
  -- Permission (granular)
  permission VARCHAR(100) NOT NULL,
  
  UNIQUE KEY unique_role_perm (school_id, role, permission),
  KEY idx_role_perms (role),
  CONSTRAINT fk_perm_school FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 💻 PART 2: BACKEND ARCHITECTURE REDESIGN

### 2.1 API Structure (RESTful + Event-Driven)

```
/api/v2/

├── /schools
│   ├── GET    /                    # List schools (super admin only)
│   ├── POST   /                    # Create school
│   ├── GET    /:school_id          # Get school details
│   ├── PUT    /:school_id          # Update school
│   └── DELETE /:school_id          # Archive school
│
├── /devices                        # Device Management
│   ├── GET    /:school_id          # List devices for school
│   ├── POST   /:school_id          # Register new device
│   ├── GET    /:school_id/:id      # Get device details
│   ├── PUT    /:school_id/:id      # Update device config
│   ├── DELETE /:school_id/:id      # Remove device
│   ├── POST   /:school_id/:id/sync # Manual sync trigger
│   ├── GET    /:school_id/:id/sync-history  # Sync status
│   └── POST   /:school_id/:id/test # Test connection
│
├── /attendance
│   ├── GET    /:school_id/today    # Today's attendance summary
│   ├── GET    /:school_id/by-student/:id  # Student's attendance
│   ├── GET    /:school_id/logs     # Attendance logs (paginated)
│   ├── GET    /:school_id/unmatched  # Unmatched logs (for resolution)
│   └── POST   /:school_id/resolve-unmatched  # Resolve unmatched
│
├── /mappings                       # Device User Mappings
│   ├── GET    /:school_id/:device_id  # All mappings for device
│   ├── POST   /:school_id/:device_id  # Create mapping
│   ├── PUT    /:school_id/:device_id/:id  # Update mapping
│   ├── DELETE /:school_id/:device_id/:id  # Remove mapping
│   └── GET    /:school_id/bulk-sync   # Sync all students to devices
│
├── /duplicates                     # Duplicate Management
│   ├── GET    /:school_id          # List potential duplicates
│   ├── POST   /:school_id/scan     # Trigger duplicate scan
│   ├── POST   /:school_id/merge    # Merge duplicate records
│   └── GET    /:school_id/:id/history  # Merge history
│
└── /audit                          # Compliance & Audit
    ├── GET    /:school_id/activity-logs
    ├── GET    /:school_id/device-sync-history
    └── GET    /:school_id/reports
```

### 2.2 Recommended Backend Architecture

**Use Node.js/Express with these layers:**

```
├── api/
│   ├── middleware/
│   │   ├── auth.ts              # JWT validation, school context
│   │   ├── rbac.ts              # Permission checking
│   │   ├── school-context.ts    # Inject school_id into requests
│   │   └── error-handler.ts     # Centralized error handling
│   │
│   ├── routes/
│   │   ├── schools.ts
│   │   ├── devices.ts
│   │   ├── mappings.ts
│   │   ├── attendance.ts
│   │   ├── duplicates.ts
│   │   └── audit.ts
│   │
│   └── controllers/
│       ├── SchoolController.ts
│       ├── DeviceController.ts
│       ├── AttendanceController.ts
│       └── DuplicateController.ts
│
├── services/
│   ├── DeviceSyncService.ts     # Poll devices, fetch logs
│   ├── MappingResolverService.ts # Match logs to students
│   ├── DuplicateDetectionService.ts
│   ├── SchoolAuthService.ts     # Multi-tenant auth
│   └── AuditService.ts
│
├── workers/                      # Background Jobs
│   ├── device-sync-worker.ts    # Fetch logs every 5 mins
│   ├── log-processor-worker.ts  # Match device logs to students
│   ├── duplicate-scanner-worker.ts  # Run at 2 AM daily
│   └── health-check-worker.ts   # Check device status
│
├── integrations/
│   ├── dahua-client.ts          # Dahua API wrapper
│   ├── hikvision-client.ts      # Hikvision API (future)
│   └── device-factory.ts        # Polymorphic device handling
│
├── lib/
│   ├── database.ts
│   ├── cache.ts                 # Redis for rate limiting
│   ├── logger.ts                # Winston or Bunyan
│   ├── encryption.ts            # Device password encryption
│   └── validators.ts            # Input validation
│
└── types/
    ├── school.ts
    ├── device.ts
    ├── attendance.ts
    └── error.ts
```

### 2.3 Device Sync Engine

```typescript
// Pseudo-code: DeviceSyncService.ts

class DeviceSyncService {
  async syncDeviceLogsAction(schoolId: number, deviceId: number) {
    const device = await getDevice(schoolId, deviceId);
    const dahuaClient = DahuaClientFactory.create(device);
    
    try {
      // 1. Get last sync point
      const lastRecNo = device.last_rec_no || 0;
      
      // 2. Fetch new logs from device
      const logs = await dahuaClient.getAttendanceLogs({
        startRecNo: lastRecNo + 1,
        pageSize: 1000
      });
      
      // 3. Store raw logs (unprocessed)
      await insertAttendanceLogs(schoolId, deviceId, logs);
      
      // 4. Update device sync status
      await updateDeviceLastSync(deviceId, logs[logs.length - 1]?.rec_no);
      
      // 5. Emit event for log processor
      await eventBus.emit('attendance.logs.fetched', {
        schoolId, deviceId,
        logCount: logs.length
      });
      
      // 6. Record sync success
      await recordSyncHistory(schoolId, deviceId, {
        status: 'success',
        logsFetched: logs.length
      });
      
    } catch (error) {
      await recordSyncHistory(schoolId, deviceId, {
        status: 'failed',
        errorMessage: error.message
      });
      throw error;
    }
  }
}
```

### 2.4 Mapping Resolver Service

```typescript
class MappingResolverService {
  async processAttendanceLog(schoolId: number, log: AttendanceLog) {
    // 1. Find mapping: device_id + device_user_id -> student_id
    const mapping = await getDeviceUserMapping(
      schoolId,
      log.device_id,
      log.device_user_id
    );
    
    if (!mapping) {
      // No mapping found -> unmatched log
      await storeUnmatchedLog(schoolId, log);
      return;
    }
    
    // 2. Update log with student_id
    await updateAttendanceLog(log.id, {
      student_id: mapping.student_id,
      processing_status: 'matched'
    });
    
    // 3. Emit event for analytics/dashboard
    await eventBus.emit('attendance.log.matched', {
      schoolId,
      studentId: mapping.student_id,
      timestamp: log.log_datetime
    });
  }
}
```

### 2.5 Queue & Event System

Use **Bull** (Redis-backed) or **BullMQ** for job queue:

```typescript
// Device polling job (every 5 minutes)
const deviceSyncQueue = new Queue('device-sync', {
  defaultJobOptions: {
    attempts: 3,
    backoff: { type: 'exponential', delay: 2000 },
    removeOnComplete: true
  }
});

deviceSyncQueue.process(async (job) => {
  const { schoolId, deviceId } = job.data;
  return await deviceSyncService.syncDevice(schoolId, deviceId);
});

// Schedule recurring job
const schedule = require('node-schedule');
schedule.scheduleJob('*/5 * * * *', async () => {
  const devices = await getAllActiveDevices();
  for (const device of devices) {
    await deviceSyncQueue.add({
      schoolId: device.school_id,
      deviceId: device.id
    });
  }
});
```

---

## 🎨 PART 3: FRONTEND ARCHITECTURE REDESIGN

### 3.1 Component Structure

```
src/components/
├── admin/
│   ├── MultiTenantDashboard.tsx
│   ├── SchoolManagement.tsx
│   └── SuperAdminPanel.tsx
│
├── schools/
│   ├── SchoolSettingsPanel.tsx
│   ├── SubscriptionManager.tsx
│   └── FeatureToggle.tsx
│
├── devices/
│   ├── DeviceManagementDashboard.tsx
│   ├── DeviceRegistration.tsx
│   ├── DeviceStatusMonitor.tsx      # Real-time status
│   ├── DeviceSyncHistory.tsx        # Sync status & errors
│   ├── DeviceConnectionTest.tsx
│   └── BulkDeviceMapping.tsx        # Map all students
│
├── attendance/
│   ├── AttendanceDashboardV2.tsx
│   ├── RealTimeSummary.tsx
│   ├── LateArrivalsList.tsx
│   ├── AbsenteesList.tsx
│   └── DeviceActivityIndicator.tsx
│
├── mappings/
│   ├── DeviceUserMappingManager.tsx   # NEW: Manage biometric IDs
│   ├── MappingConflictResolver.tsx
│   └── BulkMappingWizard.tsx
│
├── unmatched/
│   ├── UnmatchedLogsPanel.tsx         # NEW: Resolve unmatched
│   ├── UnmatchedLogRow.tsx
│   ├── AutoMatchingSuggestions.tsx
│   └── ManualMatchingUI.tsx
│
├── duplicates/
│   ├── DuplicatesManager.tsx          # ENHANCED: Better UX
│   ├── DuplicateGroupViewer.tsx
│   └── MergeHistoryViewer.tsx
│
└── audit/
    ├── ActivityAuditLog.tsx
    ├── DeviceSyncTimeline.tsx
    └── ComplianceReport.tsx
```

### 3.2 Real-Time Features (WebSocket)

```typescript
// lib/websocket.ts
import { io } from 'socket.io-client';

const socket = io(process.env.NEXT_PUBLIC_API_URL, {
  auth: {
    token: localStorage.getItem('authToken'),
    schoolId: getCurrentSchoolId()
  }
});

// Subscribe to real-time events
socket.on('device.status.changed', (data) => {
  // Update device status in real-time
  updateDeviceStatus(data.deviceId, data.status);
});

socket.on('attendance.log.synced', (data) => {
  // Real-time attendance updates
  addAttendanceLog(data);
  updateDailySummary();
});

```

### 3.3 Key UI Improvements

**Device Management Dashboard:**
- ✅ Real-time status (online/offline/error)
- ✅ Last sync time with countdown timer
- ✅ Sync history with error details
- ✅ Manual sync button with live progress
- ✅ Device health metrics (uptime, success rate)

**Attendance Dashboard:**
- ✅ Daily summary by device
- ✅ Late arrivals flagged in red
- ✅ Absentees highlighted
- ✅ Device activity heatmap
- ✅ Sync failure alerts

**Unmatched Logs Panel:**
- ✅ List of unresolved device IDs
- ✅ Auto-matching suggestions (similar names)
- ✅ Manual matching interface
- ✅ Bulk resolve with confirmation

---

## 🔒 PART 4: SECURITY ARCHITECTURE

### 4.1 Multi-Tenant Isolation

```typescript
// Middleware: Enforce school_id on every request
export const enforceSchoolContext = async (req, res, next) => {
  // Get school_id from JWT token
  const schoolId = req.user.school_id;
  
  if (!schoolId) {
    return res.status(403).json({ error: 'No school context' });
  }
  
  // Inject into request
  req.schoolId = schoolId;
  
  // CRITICAL: All queries must include school_id
  next();
};

// Example: Prevent data leakage
app.get('/api/students', enforceSchoolContext, async (req, res) => {
  // MUST filter by school_id
  const students = await Student.find({ 
    school_id: req.schoolId  // <- Always filter!
  });
  res.json(students);
});
```

### 4.2 RBAC Permission Matrix

```
PERMISSION                    | SUPER_ADMIN | SCHOOL_ADMIN | TEACHER | STAFF
------------------------------|-------------|--------------|---------|-------
schools.view_all              | ✓           |              |         |
schools.create                | ✓           |              |         |
schools.update                | ✓           | ✓ (own)      |         |
schools.delete                | ✓           |              |         |
                              |             |              |         |
devices.list                  | ✓           | ✓            |  ✓      | ✓
devices.register              | ✓           | ✓            |         |
devices.sync                  | ✓           | ✓            |         |
devices.remap_user            | ✓           | ✓            |         |
                              |             |              |         |
attendance.view               | ✓           | ✓            | ✓       | ✓
attendance.delete_log         | ✓           | ✓            |         |
                              |             |              |         |
audit.view                    | ✓           | ✓            |         |
duplicates.merge              | ✓           | ✓            |         |
```

### 4.3 Encryption Strategy

```typescript
// Device passwords stored encrypted
const devicePassword = await encrypt(plainPassword, schoolId);

// API keys for school -> signed with school_id
const schoolApiKey = jwt.sign(
  { school_id: schoolId, scope: 'api' },
  process.env.API_KEY_SECRET,
  { expiresIn: '1 year' }
);

// Audit data encrypted at rest
const auditEntry = await encrypt(JSON.stringify({
  old_values: {...},
  new_values: {...}
}), schoolId);
```

---

## 📊 PART 5: SCALABILITY & PERFORMANCE

### 5.1 Database Optimization

```sql
-- Indexing strategy
CREATE INDEX idx_attendance_query 
  ON attendance_logs(school_id, log_datetime, student_id);

CREATE INDEX idx_unmatched_resolution 
  ON unmatched_attendance_logs(school_id, resolution_status, created_at);

CREATE INDEX idx_device_health 
  ON biometric_devices(school_id, status, last_sync_at);

-- Partitioning by school_id (optional for very large deployments)
ALTER TABLE attendance_logs 
PARTITION BY LIST (school_id) (
  PARTITION p1 VALUES IN (1,2,3,4,5),
  PARTITION p2 VALUES IN (6,7,8,9,10),
  ...
);
```

### 5.2 Caching Strategy

```typescript
// Redis cache for device status
redis.set(
  `device:${schoolId}:${deviceId}:status`,
  'online',
  'EX', 60  // 1 minute TTL
);

// Cache unmatched logs count
redis.set(
  `school:${schoolId}:unmatched_count`,
  unmatched.length,
  'EX', 300  // 5 minutes
);

// Cache duplicate scan results (run hourly)
redis.set(
  `school:${schoolId}:duplicates`,
  JSON.stringify(duplicates),
  'EX', 3600  // 1 hour
);
```

### 5.3 Load Estimation

| Component | Daily Volume | Size |
|-----------|-------------|------|
| **Attendance Logs** | 100,000 | 300 bytes each = 30 MB/day |
| **Sync History** | 1,000 syncs | 500 bytes each = 500 KB/day |
| **Activity Logs** | 50,000 | 1 KB each = 50 MB/day |
| **Total DB Growth/Day** | — | ~100 MB |
| **Yearly Growth** | — | ~36 GB |

**Server Requirements for 100 Schools, 5 syncs/day:**
- **Database:** 1 TB SSD (3 years data)
- **Memory:** 16 GB RAM (Redis + app)
- **CPU:** 8 vCPUs
- **Concurrency:** 500 concurrent requests

---

## 🚀 PART 6: MIGRATION PLAN

### Phase 1: Foundation (Weeks 1-4)
1. Create new multi-tenant schema alongside old
2. Deploy new API layer (backwards compatible)
3. Build multi-tenant context injection

### Phase 2: Data Migration (Weeks 5-8)
1. Migrate schools (school_id=1 for current)
2. Migrate students, devices, mappings
3. Migrate attendance logs (historical)

### Phase 3: Testing (Weeks 9-10)
1. Integration tests for all flows
2. Load testing (1000s of logs/second)
3. Multi-tenant isolation tests

### Phase 4: Rollout (Weeks 11-12)
1. Feature flag old vs. new API
2. Gradual traffic shift (10% -> 50% -> 100%)
3. Monitor errors & rollback capability

---

## ⚠️ RISK ANALYSIS

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| **Data Loss in Migration** | Medium | Critical | Full backup before each phase, shadow writes |
| **Multi-tenant Data Leakage** | Medium | Critical | Automated tests, penetration testing |
| **Device Sync Failures** | High | Medium | Retry logic, alerting, manual override |
| **Biometric ID Conflicts** | High | Medium | Validation rules, duplicate detection |
| **Performance Degradation** | Medium | Medium | Load testing, CDN for assets, database optimization |

---

## 📈 SUCCESS METRICS

- ✅ Zero multi-tenant authorization breaches
- ✅ 99.9% device sync success rate
- ✅ <5% unmatched attendance logs
- ✅ <100ms API response time (p95)
- ✅ <5 minute duplicate scan time (100K logs)

---

## 🔥 FINAL THOUGHTS

**This is enterprise SaaS architecture.** It's designed to:
1. **Never have to rewrite core logic** for 5+ years
2. **Scale to 1000+ schools** without architectural changes
3. **Maintain data isolation** with zero leakage risk
4. **Provide operational visibility** via comprehensive audit trails
5. **Handle device ecosystem diversity** via abstraction layer

The key architectural decision: **Device abstraction via `device_user_mappings` table**. This single table solves:
- Same student across multiple devices
- Different IDs per device
- Easy remapping without modifying students table
- Device replacement without data loss

If you build this correctly now, you won't rewrite it in 2 years.

---

**Ready to implement? Start with Phase 1 (foundation) first. The migration is complex but methodical.**
