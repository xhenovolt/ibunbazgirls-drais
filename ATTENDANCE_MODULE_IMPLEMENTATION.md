# Attendance Module - Full Stack Implementation

## Overview

A comprehensive full-stack attendance management system for the Drais LMS that integrates with biometric devices (Dahua, ZKTeco, etc.), automatically fetches logs, matches them with students/staff, and provides rich analytics and dashboards.

## Architecture

### Database Schema

The module uses the following key tables:

#### `biometric_devices`
Stores device configuration and sync status.

```sql
- id: Device identifier
- school_id: School this device belongs to
- device_id: Device serial/MAC address
- device_name: Human-readable name (e.g., "Main Gate")
- ip_address: Device IP address
- port: API port (default 80 or 443)
- location_name: Physical location
- api_url: Device API endpoint
- is_active: Whether device is actively synced
- last_sync_time: Last successful sync
- sync_status: online | offline | error
```

#### `device_users`
Maps device user IDs to actual students/teachers.

```sql
- id: Record ID
- school_id: School ID
- device_user_id: User ID on the device
- person_type: 'student' | 'teacher'
- person_id: References students.id or teachers.id
- is_enrolled: Whether this user is active on device
```

#### `attendance_logs`
Raw logs from biometric devices.

```sql
- id: Log entry ID
- school_id: School ID
- device_id: Which device recorded this
- device_user_id: User ID on device
- scan_timestamp: When the scan occurred
- received_timestamp: When we received it
- verification_status: success | failed | unknown
- device_log_id: Unique ID from device (prevents duplicates)
- processing_status: pending | processed | error | duplicate
- mapped_device_user_id: Matched student/teacher ID
- raw_data: Full JSON payload from device
```

#### `daily_attendance`
Processed and final attendance records by student/teacher per day.

```sql
- id: Record ID
- school_id: School ID
- person_type: 'student' | 'teacher'
- person_id: Student/teacher ID
- attendance_date: Date of attendance
- status: present | late | absent | excused | on_leave
- first_arrival_time: First valid scan time
- last_departure_time: Final scan time (if exit recorded)
```

## API Routes

### Device Management

#### `GET /api/attendance/devices`
List all configured attendance devices.

**Query Parameters:**
- `school_id` (required): School ID
- `device_type`: 'all' | 'dahua' | 'zkteco' | 'other'
- `status`: Filter by sync status

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "device_name": "Main Gate",
      "device_type": "dahua",
      "ip_address": "192.168.1.100",
      "port": 80,
      "status": "online",
      "last_sync": "2026-03-02T10:30:00Z"
    }
  ]
}
```

#### `POST /api/attendance/devices/test-connection`
Test connection to a device before adding it.

**Body:**
```json
{
  "device_type": "dahua",
  "ip_address": "192.168.1.100",
  "port": 80,
  "device_name": "Main Gate"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Connection successful",
  "response_time": 145
}
```

### Log Fetching & Processing

#### `POST /api/attendance/devices/fetch-logs`
Fetch logs from a specific device and store in database.

**Body:**
```json
{
  "device_id": 1,
  "force_refresh": false
}
```

**Response:**
```json
{
  "success": true,
  "message": "Fetched and stored 42 logs",
  "logs_count": 42,
  "stored_count": 42
}
```

#### `POST /api/attendance/devices/process-logs`
Process pending logs and match with students/staff.

**Body:**
```json
{
  "school_id": 1,
  "device_id": null,  // Optional, process all if null
  "limit": 100
}
```

**Response:**
```json
{
  "success": true,
  "message": "Processed 42 logs",
  "processed": 42,
  "matched": 38,
  "unmatched": 4
}
```

### Analytics

#### `GET /api/attendance/devices/analytics`
Get comprehensive attendance analytics for dashboard.

**Query Parameters:**
- `school_id` (required): School ID
- `device_id` (optional): Filter by device
- `days`: Number of days to analyze (default 7)

**Response:**
```json
{
  "success": true,
  "data": {
    "dailyCount": [
      {
        "date": "2026-03-02",
        "present": 450,
        "absent": 30,
        "late": 15
      }
    ],
    "lateEntries": [
      {
        "name": "NALUBANGA MARIAM",
        "type": "student",
        "time": "08:15:30",
        "delay_minutes": 15
      }
    ],
    "absentStudents": [
      {
        "id": 123,
        "name": "JOHN DOE",
        "class": "Senior Six"
      }
    ],
    "methodDistribution": [
      {
        "method": "21",
        "count": 450
      }
    ],
    "topDevices": [
      {
        "name": "Main Gate",
        "count": 485
      }
    ],
    "summary": {
      "total_scans": 500,
      "matched_records": 485,
      "unmatched_records": 15,
      "present_today": 450,
      "absent_today": 30,
      "late_today": 15
    }
  }
}
```

## React Components

### `AttendanceDashboard`
Main dashboard component showing analytics and statistics.

**Features:**
- Real-time analytics cards (total scans, present, absent, late)
- Daily attendance trend line chart
- Scan method distribution pie chart
- Top devices by scan count
- Recent late arrivals
- Absent students list

**Props:**
```typescript
{
  schoolId?: number  // Default: 1
}
```

**Usage:**
```tsx
import AttendanceDashboard from '@/components/attendance/AttendanceDashboard';

export default function Page() {
  return <AttendanceDashboard schoolId={1} />;
}
```

### `DeviceManagementModal`
Modal for adding, managing, and configuring devices.

**Features:**
- List existing devices
- Add new devices with connection testing
- Fetch logs from devices manually
- Auto-detection of device type

**Props:**
```typescript
interface DeviceModalProps {
  isOpen: boolean;
  onClose: () => void;
  schoolId: number;
  onDeviceAdded?: (device: Device) => void;
}
```

**Usage:**
```tsx
import DeviceManagementModal from '@/components/attendance/DeviceManagementModal';
import { useState } from 'react';

export default function MyComponent() {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <>
      <button onClick={() => setIsOpen(true)}>Open Devices</button>
      <DeviceManagementModal
        isOpen={isOpen}
        onClose={() => setIsOpen(false)}
        schoolId={1}
      />
    </>
  );
}
```

## Device Log Format

The module expects device logs in this format (example: Dahua devices):

```
found=10
records[0].RecNo=1
records[0].CardNo=
records[0].CardName=
records[0].CreateTime=1771782789
records[0].Type=Entry
records[0].Method=21
...
records[9].RecNo=10
records[9].CreateTime=1771783768
records[9].Type=Entry
```

### Supported Fields
- `RecNo`: Record number/unique ID
- `CardNo`: Card/ID number
- `CardName`: Name on card
- `CreateTime`: Unix timestamp
- `Type`: 'Entry' or 'Exit'
- `Method`: Verification method ID
- `UserID`: User ID on device
- `Door`: Door number
- `ReaderID`: Reader device ID
- `ErrorCode`: Error code if failed

## Workflow

### 1. Add a Device
1. Click "Devices" button in dashboard
2. Click "Add New Device"
3. Enter device details:
   - Device name (e.g., "Main Gate")
   - IP address (e.g., 192.168.1.100)
   - Port (typically 80 or 443)
   - Device type (Dahua, ZKTeco, etc.)
   - Location name
4. Click "Test Connection" to verify device is accessible
5. Click "Add Device" to save to database

### 2. Fetch Logs
1. In device list, click "Fetch Logs" for a device
2. System connects to device API and fetches logs
3. Logs are stored in `attendance_logs` table
4. Device sync status is updated

### 3. Process Logs
1. Click "Process Logs" button in dashboard
2. System matches logs with students/staff using:
   - CardNo matching student/teacher ID
   - UserID matching device_users table
3. Creates daily_attendance records
4. Marks logs as processed or unmatched

### 4. View Analytics
Dashboard automatically updates with:
- Total scans received
- Matched vs unmatched records
- Daily attendance trends
- Late arrivals
- Absent students
- Device performance
- Scan method distribution

## Configuration

### Device Registration
Before logs can be matched with students:
1. Go to device settings
2. Note the `device_user_id` for each student/staff on the device
3. Map these in the `device_users` table with their actual person_id

### Attendance Rules
Configure in `attendance_rules` table:
- Arrival time window (e.g., 06:00 - 08:00)
- Late threshold (e.g., 15 minutes after 08:00)
- Absence cutoff time (e.g., 09:00)
- Rule priority

## Error Handling

The system handles:
- **Connection failures**: Device offline, network issues
- **Invalid IPs**: Device not reachable
- **Malformed logs**: Invalid timestamps, missing fields
- **Duplicate logs**: Uses `device_log_id` to prevent duplicates
- **Unmatched records**: Logs that don't match any student/staff
- **Processing errors**: Logged with detailed error messages

All errors are traceable in:
- `attendance_logs.processing_status` (error)
- `attendance_logs.process_error_message`
- `biometric_devices.sync_status` (error)

## Performance Considerations

### Indexing
- `school_id + scan_timestamp` for fast log queries
- `processing_status` for finding pending logs
- `device_log_id` for duplicate detection
- `device_user_id + scan_timestamp` for matching

### Partitioning
- `attendance_logs` partitioned by month for faster queries with large datasets
- Automatic partition creation recommended quarterly

### Batch Processing
- Process logs in batches (default 100 per request)
- Can handle 1M+ logs efficiently
- Async processing recommended for large syncs

### Caching
- Analytics cached/refreshed on-demand
- Device list cached with 5-minute TTL
- Manual refresh button for immediate updates

## Automation

### Scheduled Sync (Recommended)
Use a cron job or queue to:

```bash
# Fetch logs from all devices every 5 minutes
0 */5 * * * * curl -X POST https://your-domain/api/attendance/devices/fetch-logs \
  -H "Content-Type: application/json" \
  -d '{"device_id": null, "force_refresh": false}'

# Process pending logs every 5 minutes
0 */5 * * * * curl -X POST https://your-domain/api/attendance/devices/process-logs \
  -H "Content-Type: application/json" \
  -d '{"school_id": 1}'
```

### Auto-Refresh Dashboard
Enable "Auto-refresh" toggle to refresh analytics every 60 seconds.

## Integration with Existing System

### Adding to Existing Pages
```tsx
// In your attendance page
import AttendanceDashboard from '@/components/attendance/AttendanceDashboard';

export default function AttendancePage() {
  return (
    <div>
      <h1>Attendance Management</h1>
      <AttendanceDashboard schoolId={1} />
    </div>
  );
}
```

### Linking from Navigation
Add to your navigation:
```tsx
<Link href="/attendance/dashboard">
  📊 Attendance Dashboard
</Link>
```

## Troubleshooting

### Device Not Connecting
1. Check IP address and port are correct
2. Ensure device is on the same network
3. Check firewall/network policies
4. Verify API endpoint is correct for device model

### Logs Not Matching
1. Ensure students are mapped in `device_users` table
2. Check device_user_id matches actual IDs on device
3. Verify CardNo field exists in device logs
4. Check logs processing status for error messages

### Performance Issues
1. Check database indexes are created
2. Verify partition strategy is in place
3. Reduce date range in analytics queries
4. Enable pagination for large result sets

### Missing Unmatched Logs
Unmatched logs appear in dashboard only if:
1. Logs are processed but person_id is NULL
2. To show: enable "Show unmatched" toggle (if added to UI)

## Example Usage - Complete Flow

```typescript
// 1. Add device
const deviceResponse = await fetch('/api/attendance/devices', {
  method: 'POST',
  body: JSON.stringify({
    school_id: 1,
    device_name: 'Main Gate',
    ip_address: '192.168.1.100',
    port: 80,
    device_type: 'dahua',
    location_name: 'Main Entrance'
  })
});

// 2. Fetch logs
const logsResponse = await fetch('/api/attendance/devices/fetch-logs', {
  method: 'POST',
  body: JSON.stringify({
    device_id: 1,
    force_refresh: false
  })
});

// 3. Process logs
const processResponse = await fetch('/api/attendance/devices/process-logs', {
  method: 'POST',
  body: JSON.stringify({
    school_id: 1,
    device_id: 1,
    limit: 100
  })
});

// 4. Get analytics
const analyticsResponse = await fetch(
  '/api/attendance/devices/analytics?school_id=1&days=7'
);
const analytics = await analyticsResponse.json();
console.log(`Present today: ${analytics.data.summary.present_today}`);
```

## Files Created/Modified

### New API Routes
- `/src/app/api/attendance/devices/fetch-logs/route.ts` - Device log fetching
- `/src/app/api/attendance/devices/process-logs/route.ts` - Log processing
- `/src/app/api/attendance/devices/analytics/route.ts` - Analytics endpoint

### New Components
- `/src/components/attendance/AttendanceDashboard.tsx` - Main dashboard
- `/src/components/attendance/DeviceManagementModal.tsx` - Device management

### Enhanced Files
- `/src/app/api/attendance/devices/route.ts` - Device listing/management
- `/src/app/api/attendance/devices/test-connection/route.ts` - Connection testing

## Next Steps

1. **Database Migration**: Run ATTENDANCE_SCHEMA.sql to create tables
2. **Device Setup**: Add your first device through the modal
3. **Test Connection**: Verify device is reachable
4. **Fetch Logs**: Get initial logs from device
5. **Map Users**: Ensure device users are mapped to students/staff
6. **Process Logs**: Run log processing to match attendance
7. **Monitor Dashboard**: View analytics and trends

## Support

For issues or questions:
1. Check device logs in `attendance_logs` table
2. Review error messages in `process_error_message` field
3. Check device status in `biometric_devices.sync_status`
4. Enable debug logging in API routes
