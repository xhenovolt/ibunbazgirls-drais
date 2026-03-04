import { NextRequest, NextResponse } from 'next/server';
import { getConnection } from '@/lib/db';
import { extractTenantContext, logActivity } from '@/lib/multi-tenancy';

/**
 * Device User Mappings by Device API
 * Create or update device mapping for a student using a specific device
 * POST /api/device-mappings/by-device - Create/update mapping with device_id
 */

export async function POST(req: NextRequest) {
  try {
    const tenant = extractTenantContext(req);
    if (!tenant) {
      return NextResponse.json(
        { success: false, error: 'school_id is required' },
        { status: 400 }
      );
    }

    const body = await req.json();
    const { device_id, student_id, device_user_id } = body;

    // Validation
    if (!student_id || !device_user_id) {
      return NextResponse.json(
        { success: false, error: 'student_id and device_user_id are required' },
        { status: 400 }
      );
    }

    const connection = await getConnection();
    try {
      // If no device_id provided, get the first active device for the school
      let finalDeviceId = device_id;

      if (!finalDeviceId) {
        const [devices]: any = await connection.execute(
          `SELECT id FROM biometric_devices
           WHERE school_id = ? AND status = 'active'
           ORDER BY created_at ASC LIMIT 1`,
          [tenant.school_id]
        );

        if (devices.length === 0) {
          return NextResponse.json(
            { success: false, error: 'No biometric device found. Please create a device first.' },
            { status: 404 }
          );
        }

        finalDeviceId = devices[0].id;
      }

      // Verify device belongs to school (only if device_id was provided)
      if (device_id) {
        const [deviceCheck]: any = await connection.execute(
          `SELECT id FROM biometric_devices WHERE id = ? AND school_id = ?`,
          [finalDeviceId, tenant.school_id]
        );

        if (deviceCheck.length === 0) {
          return NextResponse.json(
            { success: false, error: 'Device not found in your school' },
            { status: 404 }
          );
        }
      }

      // Verify student belongs to school
      const [studentCheck]: any = await connection.execute(
        `SELECT id FROM students WHERE id = ? AND school_id = ?`,
        [student_id, tenant.school_id]
      );

      if (studentCheck.length === 0) {
        return NextResponse.json(
          { success: false, error: 'Student not found in your school' },
          { status: 404 }
        );
      }

      // Check for existing mapping for this student + device
      const [existing]: any = await connection.execute(
        `SELECT id FROM device_user_mappings
         WHERE device_id = ? AND student_id = ?`,
        [finalDeviceId, student_id]
      );

      if (existing.length > 0) {
        // Update existing mapping
        await connection.execute(
          `UPDATE device_user_mappings
           SET device_user_id = ?, status = 'active', mappings_sync_status = 'pending'
           WHERE id = ?`,
          [device_user_id, existing[0].id]
        );

        await logActivity(
          tenant.school_id,
          'update',
          'device_mapping',
          existing[0].id,
          null,
          { device_user_id }
        );

        return NextResponse.json({
          success: true,
          data: {
            id: existing[0].id,
            device_id: finalDeviceId,
            student_id,
            device_user_id,
            status: 'active',
          },
        });
      }

      // Check for duplicate mapping (same device + device_user_id)
      const [duplicateCheck]: any = await connection.execute(
        `SELECT id FROM device_user_mappings
         WHERE device_id = ? AND device_user_id = ?`,
        [finalDeviceId, device_user_id]
      );

      if (duplicateCheck.length > 0) {
        return NextResponse.json(
          { success: false, error: 'This biometric ID is already assigned to another student on this device' },
          { status: 409 }
        );
      }

      // Create new mapping
      const [result]: any = await connection.execute(
        `INSERT INTO device_user_mappings
         (school_id, device_id, student_id, device_user_id, status, mappings_sync_status)
         VALUES (?, ?, ?, ?, 'active', 'pending')`,
        [tenant.school_id, finalDeviceId, student_id, device_user_id]
      );

      // Log activity
      await logActivity(
        tenant.school_id,
        'create',
        'device_mapping',
        result.insertId,
        null,
        { device_id: finalDeviceId, student_id, device_user_id }
      );

      return NextResponse.json({
        success: true,
        data: {
          id: result.insertId,
          device_id: finalDeviceId,
          student_id,
          device_user_id,
          status: 'active',
        },
      });
    } finally {
      await connection.end();
    }
  } catch (error: any) {
    console.error('Create mapping by device error:', error);
    return NextResponse.json(
      { success: false, error: error.message },
      { status: 500 }
    );
  }
}
