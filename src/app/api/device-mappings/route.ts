import { NextRequest, NextResponse } from 'next/server';
import { getConnection } from '@/lib/db';
import { extractTenantContext, logActivity } from '@/lib/multi-tenancy';

/**
 * Device User Mappings API
 * This maps biometric IDs on devices to actual students
 * Solves the problem of device ID mismatches
 *
 * GET /api/device-mappings?school_id=1 - List all mappings
 * POST /api/device-mappings - Create mapping
 * PUT /api/device-mappings/[id] - Update mapping
 * DELETE /api/device-mappings/[id] - Delete mapping
 */

export async function GET(req: NextRequest) {
  try {
    const tenant = extractTenantContext(req);
    if (!tenant) {
      return NextResponse.json(
        { success: false, error: 'school_id is required' },
        { status: 400 }
      );
    }

    const { searchParams } = new URL(req.url);
    const deviceId = searchParams.get('device_id');
    const studentId = searchParams.get('student_id');
    const status = searchParams.get('status');

    const connection = await getConnection();
    try {
      let query = `
        SELECT 
          dum.id,
          dum.device_id,
          dum.student_id,
          dum.device_user_id,
          dum.status,
          dum.enrollment_status,
          dum.verified,
          dum.last_synced_at,
          dum.created_at,
          bd.device_name,
          bd.location,
          CONCAT(p.first_name, ' ', p.last_name) as student_name,
          s.admission_no,
          c.name as class_name
        FROM device_user_mappings dum
        JOIN biometric_devices bd ON dum.device_id = bd.id
        JOIN students st ON dum.student_id = st.id
        JOIN people p ON st.person_id = p.id
        LEFT JOIN enrollments e ON st.id = e.student_id AND e.status = 'active'
        LEFT JOIN classes c ON e.class_id = c.id
        WHERE dum.school_id = ?
      `;

      const params: any[] = [tenant.school_id];

      if (deviceId) {
        query += ` AND dum.device_id = ?`;
        params.push(parseInt(deviceId));
      }

      if (studentId) {
        query += ` AND dum.student_id = ?`;
        params.push(parseInt(studentId));
      }

      if (status) {
        query += ` AND dum.status = ?`;
        params.push(status);
      }

      query += ` ORDER BY bd.device_name, dum.device_user_id`;

      const [mappings]: any = await connection.execute(query, params);

      return NextResponse.json({
        success: true,
        data: mappings,
        total: mappings.length,
      });
    } finally {
      await connection.end();
    }
  } catch (error: any) {
    console.error('Fetch mappings error:', error);
    return NextResponse.json(
      { success: false, error: error.message },
      { status: 500 }
    );
  }
}

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
    if (!device_id || !student_id || !device_user_id) {
      return NextResponse.json(
        { success: false, error: 'device_id, student_id, and device_user_id are required' },
        { status: 400 }
      );
    }

    const connection = await getConnection();
    try {
      // Verify device belongs to school
      const [deviceCheck]: any = await connection.execute(
        `SELECT id FROM biometric_devices WHERE id = ? AND school_id = ?`,
        [device_id, tenant.school_id]
      );

      if (deviceCheck.length === 0) {
        return NextResponse.json(
          { success: false, error: 'Device not found in your school' },
          { status: 404 }
        );
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

      // Check for duplicate mapping (same device + device_user_id)
      const [existing]: any = await connection.execute(
        `SELECT id FROM device_user_mappings 
         WHERE device_id = ? AND device_user_id = ?`,
        [device_id, device_user_id]
      );

      if (existing.length > 0) {
        return NextResponse.json(
          { success: false, error: 'This biometric ID is already mapped on this device' },
          { status: 409 }
        );
      }

      // Create mapping
      const [result]: any = await connection.execute(
        `INSERT INTO device_user_mappings 
         (school_id, device_id, student_id, device_user_id, status, mappings_sync_status)
         VALUES (?, ?, ?, ?, 'active', 'pending')`,
        [tenant.school_id, device_id, student_id, device_user_id]
      );

      // Log activity
      await logActivity(
        tenant.school_id,
        'create',
        'device_mapping',
        result.insertId,
        null,
        { device_id, student_id, device_user_id }
      );

      return NextResponse.json({
        success: true,
        data: {
          id: result.insertId,
          device_id,
          student_id,
          device_user_id,
          status: 'active',
        },
      });
    } finally {
      await connection.end();
    }
  } catch (error: any) {
    console.error('Create mapping error:', error);
    return NextResponse.json(
      { success: false, error: error.message },
      { status: 500 }
    );
  }
}
