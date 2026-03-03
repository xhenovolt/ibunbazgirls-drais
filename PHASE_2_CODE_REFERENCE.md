# 💻 PHASE 2 - Code Reference & Templates

**For Developers** - Copy-paste ready code templates  
**Last Updated:** March 3, 2026

---

## 📂 File Structure

```
src/
├── lib/
│   ├── device-sync/
│   │   ├── index.ts                    ← Start here
│   │   ├── device-sync.service.ts      ← Core logic
│   │   ├── log-processor.service.ts    ← Log processing
│   │   ├── types.ts                    ← Interfaces
│   │   └── utils.ts                    ← Helpers
│   └── device-sync.config.ts           ← Configuration
├── workers/
│   └── device-sync-worker.ts           ← Background job
├── app/api/
│   ├── device-sync/
│   │   ├── route.ts                    ← Main endpoints
│   │   └── [deviceId]/route.ts         ← Single device endpoints
│   └── logs/
│       └── unmatched/route.ts          ← Unmatched logs
└── config/
    └── device-sync.config.ts           ← Environment variables
```

---

## 1. Types & Interfaces

### File: `src/lib/device-sync/types.ts`

```typescript
/**
 * Device Sync Engine Type Definitions
 * Phase 2 - Device Sync Engine
 */

// ============================================
// API REQUEST/RESPONSE TYPES
// ============================================

export interface SyncRequest {
  schoolId: number;
  deviceId?: number;  // If omitted, sync all devices in school
  options?: {
    forceFullSync?: boolean;  // Ignore checkpoint, re-sync all
    dryRun?: boolean;         // Don't save results
  };
}

export interface SyncResponse {
  jobId: string;
  schoolId: number;
  deviceIds: number[];
  status: 'initiated' | 'in_progress' | 'completed' | 'failed';
  message: string;
}

export interface SyncStatusResponse {
  schoolId: number;
  deviceId?: number;
  currentSyncs: SyncStatus[];
  lastSync?: SyncHistoryRecord;
  nextSyncAt: Date;
}

// ============================================
// DOMAIN TYPES
// ============================================

export interface Device {
  id: number;
  schoolId: number;
  name: string;
  ipAddress: string;
  model: string;
  port: number;
  username: string;
  password: string;  // Encrypted
  isActive: boolean;
  lastSyncAt?: Date;
}

export interface RawAttendanceLog {
  rec_no: number;                    // Record number from device
  device_user_id: string;            // ID on device
  person_name?: string;              // Name from device
  timestamp: Date;                   // When attendance was recorded
  door_id?: number;                  // Door number
  verify_mode?: string;              // How verified (face, card, etc)
  in_out_type?: number;              // 0=in, 1=out
  reserved?: string;                 // Extra data from device
}

export interface ProcessedAttendanceLog {
  id?: bigint;
  schoolId: number;
  deviceId: number;
  rawLogData: RawAttendanceLog;
  processingStatus: 'matched' | 'unmatched' | 'duplicate' | 'error';
  studentId?: number;
  mappingId?: number;
  matchConfidence?: number;  // 0.00 to 1.00
  errorMessage?: string;
  retryCount: number;
  lastErrorAt?: Date;
  syncedAt: Date;
  processedAt?: Date;
}

export interface DeviceUserMapping {
  id: number;
  schoolId: number;
  deviceId: number;
  deviceUserId: string;
  studentId: number;
  createdAt: Date;
  updatedAt: Date;
}

export interface DeviceSyncCheckpoint {
  id: number;
  schoolId: number;
  deviceId: number;
  lastRecNo: number;
  lastSyncAt?: Date;
  isActive: boolean;
}

export interface DeviceSyncHistory {
  id: bigint;
  schoolId: number;
  deviceId: number;
  syncStartAt: Date;
  syncEndAt?: Date;
  durationMs?: number;
  status: 'success' | 'partial' | 'failed';
  logsFetched: number;
  logsProcessed: number;
  logsMatched: number;
  logsUnmatched: number;
  lastRecNo?: number;
  errorMessage?: string;
  retryCount: number;
  nextRetryAt?: Date;
  workerId?: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface SyncError {
  id: bigint;
  schoolId: number;
  deviceId: number;
  errorType: 'connection' | 'authentication' | 'validation' | 'parsing' | 'storage' | 'processing';
  errorMessage: string;
  errorDetails?: any;
  syncHistoryId?: bigint;
  affectedLogCount: number;
  resolvedAt?: Date;
  resolutionNotes?: string;
}

// ============================================
// SERVICE INTERFACES
// ============================================

export interface ISyncResult {
  success: boolean;
  schoolId: number;
  deviceId: number;
  logsFetched: number;
  logsProcessed: number;
  logsMatched: number;
  logsUnmatched: number;
  duration: number;  // milliseconds
  error?: Error;
}

export interface IProcessingResult {
  totalLogs: number;
  matchedCount: number;
  unmatchedCount: number;
  duplicateCount: number;
  errorCount: number;
  averageConfidence: number;
}

export interface SyncStatus {
  schoolId: number;
  deviceId: number;
  startedAt: Date;
  progress: {
    total: number;
    processed: number;
    percentage: number;
  };
}

export interface SyncHistoryRecord extends DeviceSyncHistory {}

// ============================================
// SERVICE CONFIGURATION
// ============================================

export interface DeviceSyncConfig {
  syncIntervalMinutes: number;
  syncTimeoutMinutes: number;
  maxLogsPerBatch: number;
  maxConcurrentDevices: number;
  retryMaxAttempts: number;
  retryBackoffMs: number;
  dahua: {
    timeoutMs: number;
    maxPageSize: number;
    defaultRegion: string;
  };
  features: {
    enableSync: boolean;
    enableProcessor: boolean;
    enableWorker: boolean;
    enableAlerts: boolean;
  };
}

// ============================================
// DATABASE TYPES
// ============================================

export interface DatabaseRow {
  [key: string]: any;
}

export interface QueryResult {
  rowCount: number;
  rows: DatabaseRow[];
  lastInsertId?: number;
}

// ============================================
// EVENT TYPES
// ============================================

export interface SyncEvent {
  type: 'sync.started' | 'sync.completed' | 'sync.failed' | 'logs.fetched' | 'logs.processed';
  schoolId: number;
  deviceId: number;
  timestamp: Date;
  data: any;
}

// ============================================
// UTILITIES
// ============================================

export type Nullable<T> = T | null | undefined;
export type AsyncResult<T> = Promise<{ success: boolean; data?: T; error?: Error }>;
```

---

## 2. Device Sync Service

### File: `src/lib/device-sync/device-sync.service.ts`

```typescript
/**
 * Device Sync Service
 * Fetches attendance logs from Dahua biometric devices
 * Phase 2 - Device Sync Engine
 */

import { Logger } from 'pino';
import { 
  RawAttendanceLog, 
  DeviceSyncHistory, 
  ISyncResult,
  Device
} from './types';
import { getDahuaClient } from '../dahua-client';
import { Database } from '../database';

export class DeviceSyncService {
  private logger: Logger;
  private db: Database;
  private timeout: number = 30000; // 30 seconds default

  constructor(logger: Logger, db: Database) {
    this.logger = logger;
    this.db = db;
  }

  /**
   * Main sync orchestrator
   * Fetches logs from a device and stores them
   */
  async syncDeviceLogsAction(
    schoolId: number,
    deviceId: number,
    options?: { forceFullSync?: boolean }
  ): Promise<ISyncResult> {
    const startTime = Date.now();
    
    try {
      // 1. Get device details
      const device = await this.getDeviceDetails(schoolId, deviceId);
      if (!device) {
        throw new Error(`Device ${deviceId} not found in school ${schoolId}`);
      }

      // 2. Get last sync checkpoint
      const checkpoint = await this.getLastCheckpoint(schoolId, deviceId, options?.forceFullSync);
      
      // 3. Create Dahua client
      const dahuaClient = getDahuaClient(device);
      
      // 4. Fetch logs from device
      const logs = await this.fetchLogsFromDahua(dahuaClient, device, checkpoint.lastRecNo);
      
      // 5. Validate and store raw logs
      const storedCount = await this.validateAndStoreRawLogs(schoolId, deviceId, logs);
      
      // 6. Update checkpoint
      if (logs.length > 0) {
        const lastLog = logs[logs.length - 1];
        await this.updateCheckpoint(schoolId, deviceId, lastLog.rec_no);
      }
      
      // 7. Emit event for log processor
      await this.emitSyncEvents(schoolId, deviceId, logs.length);
      
      // 8. Record success
      const duration = Date.now() - startTime;
      await this.recordSyncHistory(schoolId, deviceId, {
        status: 'success',
        logsFetched: logs.length,
        durationMs: duration,
      });

      this.logger.info({
        event: 'sync_completed',
        schoolId,
        deviceId,
        logsFetched: logs.length,
        durationMs: duration,
      });

      return {
        success: true,
        schoolId,
        deviceId,
        logsFetched: logs.length,
        logsProcessed: logs.length,
        logsMatched: 0,  // Will be set by processor
        logsUnmatched: 0, // Will be set by processor
        duration,
      };
    } catch (error) {
      const duration = Date.now() - startTime;
      
      // Record failure
      await this.recordSyncHistory(schoolId, deviceId, {
        status: 'failed',
        errorMessage: error instanceof Error ? error.message : 'Unknown error',
        durationMs: duration,
      });

      this.logger.error({
        event: 'sync_failed',
        schoolId,
        deviceId,
        error: error instanceof Error ? error.message : 'Unknown error',
        durationMs: duration,
      });

      return {
        success: false,
        schoolId,
        deviceId,
        logsFetched: 0,
        logsProcessed: 0,
        logsMatched: 0,
        logsUnmatched: 0,
        duration,
        error: error instanceof Error ? error : new Error(String(error)),
      };
    }
  }

  /**
   * Fetch logs from Dahua device with pagination
   */
  private async fetchLogsFromDahua(
    dahuaClient: any,  // Dahua client instance
    device: Device,
    startRecNo: number
  ): Promise<RawAttendanceLog[]> {
    const allLogs: RawAttendanceLog[] = [];
    let pageNum = 0;
    let hasMore = true;

    while (hasMore) {
      try {
        const pageSize = 1000;
        const response = await Promise.race([
          dahuaClient.getAttendanceLogs({
            startRecNo: startRecNo + (pageNum * pageSize),
            pageSize,
          }),
          new Promise((_, reject) =>
            setTimeout(() => reject(new Error('Dahua timeout')), this.timeout)
          ),
        ]);

        if (!response || !response.logs || response.logs.length === 0) {
          hasMore = false;
          break;
        }

        // Transform device response to our format
        const transformedLogs = response.logs.map((deviceLog: any) => ({
          rec_no: deviceLog.RecNo || deviceLog.rec_no,
          device_user_id: deviceLog.EmployeeNo || deviceLog.device_user_id,
          person_name: deviceLog.Name || deviceLog.person_name,
          timestamp: new Date(deviceLog.Time || deviceLog.timestamp),
          door_id: deviceLog.DoorID || deviceLog.door_id,
          verify_mode: deviceLog.VerifyMode || deviceLog.verify_mode,
          in_out_type: deviceLog.InOutType || deviceLog.in_out_type,
          reserved: deviceLog.Reserved || deviceLog.reserved,
        }));

        allLogs.push(...transformedLogs);
        pageNum++;

        if (transformedLogs.length < pageSize) {
          hasMore = false;
        }
      } catch (error) {
        this.logger.error({
          event: 'fetch_logs_error',
          page: pageNum,
          error: error instanceof Error ? error.message : 'Unknown error',
        });
        
        // Continue with what we have if there's an error
        if (allLogs.length > 0) {
          break;
        }
        throw error;
      }
    }

    return allLogs;
  }

  /**
   * Validate and store raw attendance logs
   */
  private async validateAndStoreRawLogs(
    schoolId: number,
    deviceId: number,
    logs: RawAttendanceLog[]
  ): Promise<number> {
    if (logs.length === 0) {
      return 0;
    }

    // Validate each log
    const validLogs = logs.filter(log => {
      if (!log.rec_no || !log.device_user_id || !log.timestamp) {
        this.logger.warn({
          event: 'invalid_log_skipped',
          log: JSON.stringify(log),
        });
        return false;
      }
      return true;
    });

    // Batch insert
    const query = `
      INSERT IGNORE INTO attendance_log_processing 
      (school_id, device_id, raw_log_data, device_user_id, log_timestamp, 
       processing_status, synced_at)
      VALUES (?, ?, ?, ?, ?, 'unmatched', NOW())
    `;

    let insertedCount = 0;
    for (const log of validLogs) {
      try {
        await this.db.query(query, [
          schoolId,
          deviceId,
          JSON.stringify(log),
          log.device_user_id,
          log.timestamp,
        ]);
        insertedCount++;
      } catch (error) {
        // Log error but continue with next log
        this.logger.error({
          event: 'log_insert_error',
          deviceId,
          error: error instanceof Error ? error.message : 'Unknown error',
        });
      }
    }

    return insertedCount;
  }

  /**
   * Emit events for downstream processors
   */
  private async emitSyncEvents(
    schoolId: number,
    deviceId: number,
    logCount: number
  ): Promise<void> {
    // Emit to event bus (implement based on your event system)
    // This could be EventEmitter, Redis pub/sub, message queue, etc.
    
    const event = {
      type: 'logs.fetched',
      schoolId,
      deviceId,
      logCount,
      timestamp: new Date(),
    };

    this.logger.info({
      event: 'sync_event_emitted',
      eventData: event,
    });

    // TODO: Publish to event bus
    // await eventBus.emit('attendance.logs.fetched', event);
  }

  /**
   * Record sync in history table
   */
  private async recordSyncHistory(
    schoolId: number,
    deviceId: number,
    result: {
      status: 'success' | 'partial' | 'failed';
      logsFetched?: number;
      errorMessage?: string;
      durationMs?: number;
    }
  ): Promise<void> {
    const query = `
      INSERT INTO device_sync_history 
      (school_id, device_id, sync_start_at, sync_end_at, status, 
       logs_fetched, duration_ms, error_message)
      VALUES (?, ?, NOW(), NOW(), ?, ?, ?, ?)
    `;

    try {
      await this.db.query(query, [
        schoolId,
        deviceId,
        result.status,
        result.logsFetched || 0,
        result.durationMs || 0,
        result.errorMessage,
      ]);
    } catch (error) {
      this.logger.error({
        event: 'sync_history_insert_error',
        error: error instanceof Error ? error.message : 'Unknown error',
      });
    }
  }

  /**
   * Get last checkpoint for device
   */
  private async getLastCheckpoint(
    schoolId: number,
    deviceId: number,
    forceFullSync?: boolean
  ): Promise<{ lastRecNo: number }> {
    if (forceFullSync) {
      return { lastRecNo: 0 };
    }

    try {
      const result = await this.db.query(
        'SELECT last_rec_no FROM device_sync_checkpoints WHERE school_id = ? AND device_id = ?',
        [schoolId, deviceId]
      );

      if (result.rows.length > 0) {
        return { lastRecNo: result.rows[0].last_rec_no || 0 };
      }
    } catch (error) {
      this.logger.error({
        event: 'checkpoint_fetch_error',
        error: error instanceof Error ? error.message : 'Unknown error',
      });
    }

    return { lastRecNo: 0 };
  }

  /**
   * Update checkpoint
   */
  private async updateCheckpoint(
    schoolId: number,
    deviceId: number,
    lastRecNo: number
  ): Promise<void> {
    try {
      await this.db.query(
        `UPDATE device_sync_checkpoints 
         SET last_rec_no = ?, last_sync_at = NOW() 
         WHERE school_id = ? AND device_id = ?`,
        [lastRecNo, schoolId, deviceId]
      );
    } catch (error) {
      this.logger.error({
        event: 'checkpoint_update_error',
        error: error instanceof Error ? error.message : 'Unknown error',
      });
    }
  }

  /**
   * Get device details
   */
  private async getDeviceDetails(schoolId: number, deviceId: number): Promise<Device | null> {
    try {
      const result = await this.db.query(
        `SELECT * FROM biometric_devices 
         WHERE id = ? AND school_id = ? AND is_active = 1`,
        [deviceId, schoolId]
      );

      if (result.rows.length > 0) {
        const row = result.rows[0];
        return {
          id: row.id,
          schoolId: row.school_id,
          name: row.name,
          ipAddress: row.ip_address,
          model: row.model,
          port: row.port,
          username: row.username,
          password: row.password, // Should be decrypted
          isActive: row.is_active === 1,
          lastSyncAt: row.last_sync_at,
        };
      }
    } catch (error) {
      this.logger.error({
        event: 'device_fetch_error',
        error: error instanceof Error ? error.message : 'Unknown error',
      });
    }

    return null;
  }
}

export default DeviceSyncService;
```

---

## 3. Log Processor Service

### File: `src/lib/device-sync/log-processor.service.ts`

```typescript
/**
 * Attendance Log Processor Service
 * Matches device logs to students via device user mappings
 * Phase 2 - Device Sync Engine
 */

import { Logger } from 'pino';
import {
  ProcessedAttendanceLog,
  RawAttendanceLog,
  IProcessingResult,
  DeviceUserMapping,
} from './types';
import { Database } from '../database';

export class LogProcessorService {
  private logger: Logger;
  private db: Database;

  constructor(logger: Logger, db: Database) {
    this.logger = logger;
    this.db = db;
  }

  /**
   * Process a single attendance log
   */
  async processAttendanceLog(
    schoolId: number,
    logId: bigint
  ): Promise<{ matched: boolean; studentId?: number; error?: string }> {
    try {
      // 1. Fetch the raw log
      const logResult = await this.db.query(
        `SELECT * FROM attendance_log_processing 
         WHERE id = ? AND school_id = ?`,
        [logId, schoolId]
      );

      if (logResult.rows.length === 0) {
        throw new Error('Log not found');
      }

      const log = logResult.rows[0];
      const rawLogData = JSON.parse(log.raw_log_data);

      // 2. Find device mapping
      const mapping = await this.findDeviceMapping(
        schoolId,
        log.device_id,
        log.device_user_id
      );

      if (!mapping) {
        // Mark as unmatched
        await this.updateLogStatus(logId, 'unmatched', null, null);
        return { matched: false };
      }

      // 3. Validate student exists
      if (!(await this.validateStudentExists(mapping.student_id))) {
        await this.updateLogStatus(logId, 'error', null, 'Student not found');
        return { 
          matched: false, 
          error: 'Student not found' 
        };
      }

      // 4. Check for duplicates
      if (await this.isDuplicateLog(schoolId, mapping.student_id, rawLogData.timestamp)) {
        await this.updateLogStatus(logId, 'duplicate', mapping.student_id, null);
        return { matched: false };
      }

      // 5. Update log with student_id
      await this.updateLogStatus(logId, 'matched', mapping.student_id, null, mapping.id);

      this.logger.info({
        event: 'log_matched',
        logId,
        studentId: mapping.student_id,
      });

      return { matched: true, studentId: mapping.student_id };
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      await this.updateLogStatus(
        logId,
        'error',
        null,
        errorMsg
      );

      this.logger.error({
        event: 'log_processing_error',
        logId,
        error: errorMsg,
      });

      return { matched: false, error: errorMsg };
    }
  }

  /**
   * Batch process logs for a school
   */
  async processBatchLogs(
    schoolId: number,
    limit: number = 1000
  ): Promise<IProcessingResult> {
    try {
      const logsResult = await this.db.query(
        `SELECT id FROM attendance_log_processing 
         WHERE school_id = ? AND processing_status = 'unmatched'
         ORDER BY synced_at ASC
         LIMIT ?`,
        [schoolId, limit]
      );

      let matchedCount = 0;
      let unmatchedCount = 0;
      let duplicateCount = 0;
      let errorCount = 0;

      for (const logRow of logsResult.rows) {
        const result = await this.processAttendanceLog(schoolId, logRow.id);

        if (result.error) {
          errorCount++;
        } else if (result.matched) {
          matchedCount++;
        } else {
          unmatchedCount++;
        }
      }

      // Get duplicate count
      const dupResult = await this.db.query(
        `SELECT COUNT(*) as count FROM attendance_log_processing 
         WHERE school_id = ? AND processing_status = 'duplicate'`,
        [schoolId]
      );
      duplicateCount = dupResult.rows[0].count;

      return {
        totalLogs: logsResult.rows.length,
        matchedCount,
        unmatchedCount,
        duplicateCount,
        errorCount,
        averageConfidence: 1.0, // All are 1.0 or 0.0 for exact matches
      };
    } catch (error) {
      this.logger.error({
        event: 'batch_processing_error',
        error: error instanceof Error ? error.message : 'Unknown error',
      });

      return {
        totalLogs: 0,
        matchedCount: 0,
        unmatchedCount: 0,
        duplicateCount: 0,
        errorCount: 0,
        averageConfidence: 0,
      };
    }
  }

  /**
   * Find device user mapping (device_id + device_user_id -> student_id)
   */
  private async findDeviceMapping(
    schoolId: number,
    deviceId: number,
    deviceUserId: string
  ): Promise<DeviceUserMapping | null> {
    try {
      const result = await this.db.query(
        `SELECT * FROM device_user_mappings 
         WHERE school_id = ? AND device_id = ? AND device_user_id = ?`,
        [schoolId, deviceId, deviceUserId]
      );

      if (result.rows.length > 0) {
        const row = result.rows[0];
        return {
          id: row.id,
          schoolId: row.school_id,
          deviceId: row.device_id,
          deviceUserId: row.device_user_id,
          studentId: row.student_id,
          createdAt: new Date(row.created_at),
          updatedAt: new Date(row.updated_at),
        };
      }
    } catch (error) {
      this.logger.error({
        event: 'mapping_lookup_error',
        error: error instanceof Error ? error.message : 'Unknown error',
      });
    }

    return null;
  }

  /**
   * Check if student exists
   */
  private async validateStudentExists(studentId: number): Promise<boolean> {
    try {
      const result = await this.db.query(
        'SELECT id FROM students WHERE id = ? LIMIT 1',
        [studentId]
      );
      return result.rows.length > 0;
    } catch (error) {
      this.logger.error({
        event: 'student_validation_error',
        error: error instanceof Error ? error.message : 'Unknown error',
      });
      return false;
    }
  }

  /**
   * Check if log is duplicate (same student on same device same minute)
   */
  private async isDuplicateLog(
    schoolId: number,
    studentId: number,
    timestamp: Date
  ): Promise<boolean> {
    try {
      // Considered duplicate if there's another matched log within same minute
      const timeWindow = new Date(timestamp);
      timeWindow.setSeconds(0, 0);
      const endWindow = new Date(timeWindow);
      endWindow.setMinutes(endWindow.getMinutes() + 1);

      const result = await this.db.query(
        `SELECT COUNT(*) as count FROM attendance_log_processing 
         WHERE school_id = ? AND student_id = ? 
         AND processing_status = 'matched'
         AND log_timestamp >= ? AND log_timestamp < ?`,
        [schoolId, studentId, timeWindow, endWindow]
      );

      return result.rows[0].count > 0;
    } catch (error) {
      this.logger.error({
        event: 'duplicate_check_error',
        error: error instanceof Error ? error.message : 'Unknown error',
      });
      return false;
    }
  }

  /**
   * Update log processing status
   */
  private async updateLogStatus(
    logId: bigint,
    status: 'matched' | 'unmatched' | 'duplicate' | 'error',
    studentId: number | null = null,
    errorMessage: string | null = null,
    mappingId: number | null = null
  ): Promise<void> {
    try {
      await this.db.query(
        `UPDATE attendance_log_processing 
         SET processing_status = ?, student_id = ?, error_message = ?, 
             mapping_id = ?, processed_at = NOW()
         WHERE id = ?`,
        [status, studentId, errorMessage, mappingId, logId]
      );
    } catch (error) {
      this.logger.error({
        event: 'log_update_error',
        logId,
        error: error instanceof Error ? error.message : 'Unknown error',
      });
    }
  }

  /**
   * Get unmatched logs for manual review
   */
  async getUnmatchedLogs(
    schoolId: number,
    limit: number = 100,
    offset: number = 0
  ) {
    try {
      const result = await this.db.query(
        `SELECT * FROM attendance_log_processing 
         WHERE school_id = ? AND processing_status = 'unmatched'
         ORDER BY synced_at DESC
         LIMIT ? OFFSET ?`,
        [schoolId, limit, offset]
      );

      return result.rows.map(row => ({
        id: row.id,
        schoolId: row.school_id,
        deviceId: row.device_id,
        deviceUserId: row.device_user_id,
        rawLogData: JSON.parse(row.raw_log_data),
        syncedAt: new Date(row.synced_at),
      }));
    } catch (error) {
      this.logger.error({
        event: 'unmatched_logs_fetch_error',
        error: error instanceof Error ? error.message : 'Unknown error',
      });
      return [];
    }
  }
}

export default LogProcessorService;
```

---

## 4. Device Sync Worker

### File: `src/workers/device-sync-worker.ts`

```typescript
/**
 * Device Sync Worker
 * Background job that runs every 5 minutes
 * Syncs all devices for all schools
 * Phase 2 - Device Sync Engine
 */

import cron from 'node-cron';
import { Logger, pino } from 'pino';
import { DeviceSyncService } from '../lib/device-sync/device-sync.service';
import { LogProcessorService } from '../lib/device-sync/log-processor.service';
import { Database } from '../lib/database';
import { deviceSyncConfig } from '../config/device-sync.config';

let isWorkerRunning = false;

export class DeviceSyncWorker {
  private logger: Logger;
  private db: Database;
  private syncService: DeviceSyncService;
  private processorService: LogProcessorService;
  private cronJob?: cron.ScheduledTask;
  private workerId: string;

  constructor(logger?: Logger, db?: Database) {
    this.logger = logger || pino();
    this.db = db || new Database();
    this.syncService = new DeviceSyncService(this.logger, this.db);
    this.processorService = new LogProcessorService(this.logger, this.db);
    this.workerId = `worker-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;

    this.logger.info({
      event: 'worker_created',
      workerId: this.workerId,
    });
  }

  /**
   * Start the worker
   */
  async start(): Promise<void> {
    if (isWorkerRunning) {
      this.logger.warn('Worker already running');
      return;
    }

    isWorkerRunning = true;

    // Schedule based on config
    const interval = `*/${deviceSyncConfig.syncIntervalMinutes} * * * *`;
    
    this.cronJob = cron.schedule(interval, async () => {
      await this.executeSync();
    });

    // Log startup
    this.logger.info({
      event: 'worker_started',
      workerId: this.workerId,
      interval: `Every ${deviceSyncConfig.syncIntervalMinutes} minutes`,
    });

    // Run first sync immediately
    await this.executeSync();
  }

  /**
   * Stop the worker
   */
  async stop(): Promise<void> {
    if (this.cronJob) {
      this.cronJob.stop();
    }
    isWorkerRunning = false;
    
    this.logger.info({
      event: 'worker_stopped',
      workerId: this.workerId,
    });
  }

  /**
   * Main sync execution loop
   */
  private async executeSync(): Promise<void> {
    const syncStartTime = Date.now();

    try {
      // 1. Get all schools with active devices
      const schools = await this.getAllActiveSchools();

      if (schools.length === 0) {
        this.logger.debug('No schools with active devices');
        return;
      }

      // 2. Sync each school's devices
      for (const schoolId of schools) {
        await this.syncSchoolDevices(schoolId);
      }

      // 3. Process logs for all schools
      for (const schoolId of schools) {
        await this.processSchoolLogs(schoolId);
      }

      const duration = Date.now() - syncStartTime;
      this.logger.info({
        event: 'sync_cycle_completed',
        workerId: this.workerId,
        schoolCount: schools.length,
        durationMs: duration,
      });
    } catch (error) {
      this.logger.error({
        event: 'sync_cycle_failed',
        workerId: this.workerId,
        error: error instanceof Error ? error.message : 'Unknown error',
        durationMs: Date.now() - syncStartTime,
      });
    }
  }

  /**
   * Get all schools with active devices
   */
  private async getAllActiveSchools(): Promise<number[]> {
    try {
      const result = await this.db.query(
        `SELECT DISTINCT school_id FROM biometric_devices 
         WHERE is_active = 1`
      );

      return result.rows.map(row => row.school_id);
    } catch (error) {
      this.logger.error({
        event: 'get_schools_error',
        error: error instanceof Error ? error.message : 'Unknown error',
      });
      return [];
    }
  }

  /**
   * Sync all devices in a school
   */
  private async syncSchoolDevices(schoolId: number): Promise<void> {
    try {
      // Get all active devices for this school
      const devicesResult = await this.db.query(
        `SELECT id FROM biometric_devices 
         WHERE school_id = ? AND is_active = 1`,
        [schoolId]
      );

      const devices = devicesResult.rows.map(row => row.id);

      if (devices.length === 0) {
        return;
      }

      // Sync devices concurrently (but respect max concurrent limit)
      const maxConcurrent = deviceSyncConfig.maxConcurrentDevices;
      for (let i = 0; i < devices.length; i += maxConcurrent) {
        const batch = devices.slice(i, i + maxConcurrent);
        const promises = batch.map(deviceId =>
          this.syncDeviceWithRetry(schoolId, deviceId)
        );

        await Promise.allSettled(promises);
      }
    } catch (error) {
      this.logger.error({
        event: 'sync_school_error',
        schoolId,
        error: error instanceof Error ? error.message : 'Unknown error',
      });
    }
  }

  /**
   * Sync device with retry logic
   */
  private async syncDeviceWithRetry(
    schoolId: number,
    deviceId: number,
    attempt: number = 1
  ): Promise<void> {
    try {
      const result = await this.syncService.syncDeviceLogsAction(schoolId, deviceId);

      if (!result.success && attempt < deviceSyncConfig.retryMaxAttempts) {
        // Calculate backoff
        const backoffMs = deviceSyncConfig.retryBackoffMs * Math.pow(2, attempt - 1);
        
        this.logger.info({
          event: 'sync_retry',
          schoolId,
          deviceId,
          attempt,
          nextRetryMs: backoffMs,
        });

        // Wait before retry
        await new Promise(resolve => setTimeout(resolve, backoffMs));

        // Retry
        await this.syncDeviceWithRetry(schoolId, deviceId, attempt + 1);
      }
    } catch (error) {
      this.logger.error({
        event: 'sync_device_error',
        schoolId,
        deviceId,
        attempt,
        error: error instanceof Error ? error.message : 'Unknown error',
      });
    }
  }

  /**
   * Process all unmatched logs for a school
   */
  private async processSchoolLogs(schoolId: number): Promise<void> {
    try {
      const result = await this.processorService.processBatchLogs(schoolId, 5000);

      this.logger.info({
        event: 'logs_processed',
        schoolId,
        ...result,
      });
    } catch (error) {
      this.logger.error({
        event: 'process_logs_error',
        schoolId,
        error: error instanceof Error ? error.message : 'Unknown error',
      });
    }
  }

  /**
   * Get worker health status
   */
  async getHealthStatus() {
    return {
      workerId: this.workerId,
      isRunning: isWorkerRunning,
      uptime: process.uptime(),
      memoryUsage: process.memoryUsage(),
      timestamp: new Date(),
    };
  }
}

// Export worker instance
export let syncWorker: DeviceSyncWorker | null = null;

/**
 * Start the worker (call from your main server initialization)
 */
export async function startDeviceSyncWorker() {
  if (!deviceSyncConfig.features.enableWorker) {
    console.log('Device sync worker is disabled');
    return;
  }

  syncWorker = new DeviceSyncWorker();
  await syncWorker.start();
}

/**
 * Stop the worker (call on graceful shutdown)
 */
export async function stopDeviceSyncWorker() {
  if (syncWorker) {
    await syncWorker.stop();
  }
}
```

---

## 5. API Endpoints

### File: `src/app/api/device-sync/route.ts`

```typescript
/**
 * Device Sync API Endpoints
 * POST /api/device-sync - Trigger manual sync
 * GET /api/device-sync/status - Check sync status
 * GET /api/device-sync/history - View sync history
 */

import { NextRequest, NextResponse } from 'next/server';
import { enrichTenantContext } from '@/lib/multi-tenancy';
import { DeviceSyncService } from '@/lib/device-sync/device-sync.service';
import { Database } from '@/lib/database';
import { pino } from 'pino';

const logger = pino();
const db = new Database();
const syncService = new DeviceSyncService(logger, db);

/**
 * POST /api/device-sync
 * Trigger manual device sync
 */
export async function POST(request: NextRequest) {
  try {
    const tenantContext = await enrichTenantContext(request);
    
    if (!tenantContext) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      );
    }

    const body = await request.json();
    const { deviceId, forceFullSync } = body;

    if (!deviceId) {
      return NextResponse.json(
        { error: 'deviceId is required' },
        { status: 400 }
      );
    }

    // Trigger sync
    const result = await syncService.syncDeviceLogsAction(
      tenantContext.schoolId,
      deviceId,
      { forceFullSync }
    );

    return NextResponse.json({
      success: result.success,
      schoolId: result.schoolId,
      deviceId: result.deviceId,
      logsFetched: result.logsFetched,
      duration: result.duration,
      error: result.error?.message,
    });
  } catch (error) {
    logger.error('POST /api/device-sync error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

/**
 * GET /api/device-sync/status
 * Get sync status
 */
export async function GET(request: NextRequest) {
  try {
    const tenantContext = await enrichTenantContext(request);
    
    if (!tenantContext) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      );
    }

    // Get sync status from database
    const result = await db.query(
      `SELECT * FROM device_sync_history 
       WHERE school_id = ? 
       ORDER BY created_at DESC 
       LIMIT 10`,
      [tenantContext.schoolId]
    );

    return NextResponse.json({
      schoolId: tenantContext.schoolId,
      recentSyncs: result.rows,
    });
  } catch (error) {
    logger.error('GET /api/device-sync/status error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
```

---

## How to Use These Templates

1. **Start with types.ts** - Copy the interfaces first
2. **Implement DeviceSyncService** - Core business logic
3. **Implement LogProcessorService** - Processing capabilities
4. **Create API endpoints** - User-facing interfaces
5. **Add Worker** - Background execution
6. **Test thoroughly** - Unit + integration tests

See [PHASE_2_IMPLEMENTATION_GUIDE.md](./PHASE_2_IMPLEMENTATION_GUIDE.md) for detailed instructions on each step.

---

**Status:** Ready to Code 💻  
**Complexity:** Medium-High  
**Time Per File:** 2-4 hours
