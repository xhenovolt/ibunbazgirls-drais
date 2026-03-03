import { NextRequest, NextResponse } from 'next/server';
import { getConnection } from '@/lib/db';

export async function GET(req: NextRequest) {
  let connection;
  
  try {
    const { searchParams } = new URL(req.url);
    const schoolId = parseInt(searchParams.get('school_id') || '1');
    const studentId = searchParams.get('student_id');

    connection = await getConnection();

    let sql = `
      SELECT 
        sc.student_id,
        sc.contact_id,
        sc.relationship,
        sc.is_primary,
        c.id,
        c.contact_type,
        c.occupation,
        c.alive_status,
        cp.first_name as contact_first_name,
        cp.last_name as contact_last_name,
        cp.phone as contact_phone,
        cp.email as contact_email,
        cp.address as contact_address,
        sp.first_name as student_first_name,
        sp.last_name as student_last_name,
        s.admission_no,
        cl.name as class_name
      FROM student_contacts sc
      JOIN contacts c ON sc.contact_id = c.id
      JOIN people cp ON c.person_id = cp.id
      JOIN students s ON sc.student_id = s.id
      JOIN people sp ON s.person_id = sp.id
      LEFT JOIN enrollments e ON s.id = e.student_id AND e.status = 'active'
      LEFT JOIN classes cl ON e.class_id = cl.id
      WHERE s.school_id = ?
    `;

    const params = [schoolId];

    if (studentId) {
      sql += ' AND sc.student_id = ?';
      params.push(parseInt(studentId));
    }

    sql += ' ORDER BY sp.first_name, sp.last_name, sc.is_primary DESC';

    const [rows] = await connection.execute(sql, params);

    return NextResponse.json({
      success: true,
      data: rows
    });

  } catch (error: any) {
    console.error('Contacts fetch error:', error);
    return NextResponse.json({
      success: false,
      error: 'Failed to fetch contacts'
    }, { status: 500 });
  } finally {
    if (connection) await connection.end();
  }
}

export async function POST(req: NextRequest) {
  let connection;
  
  try {
    const body = await req.json();
    const {
      student_id,
      first_name,
      last_name,
      phone,
      email,
      address,
      contact_type,
      occupation,
      relationship,
      is_primary = 0
    } = body;

    if (!student_id || !first_name || !last_name || !phone || !contact_type) {
      return NextResponse.json({
        success: false,
        error: 'Student ID, first name, last name, phone number, and contact type are required'
      }, { status: 400 });
    }

    connection = await getConnection();
    await connection.beginTransaction();

    try {
      // Get school ID from student
      const [studentRows] = await connection.execute(
        'SELECT school_id FROM students WHERE id = ?',
        [student_id]
      );

      if (!Array.isArray(studentRows) || studentRows.length === 0) {
        throw new Error('Student not found');
      }

      const schoolId = studentRows[0].school_id;

      // Insert person record for contact
      const [personResult] = await connection.execute(`
        INSERT INTO people (school_id, first_name, last_name, phone, email, address)
        VALUES (?, ?, ?, ?, ?, ?)
      `, [schoolId, first_name, last_name, phone, email, address]);

      const personId = personResult.insertId;

      // Insert contact record
      const [contactResult] = await connection.execute(`
        INSERT INTO contacts (school_id, person_id, contact_type, occupation, alive_status)
        VALUES (?, ?, ?, ?, 'alive')
      `, [schoolId, personId, contact_type, occupation]);

      const contactId = contactResult.insertId;

      // Link student to contact
      await connection.execute(`
        INSERT INTO student_contacts (student_id, contact_id, relationship, is_primary)
        VALUES (?, ?, ?, ?)
      `, [student_id, contactId, relationship, is_primary]);

      await connection.commit();

      return NextResponse.json({
        success: true,
        message: 'Contact added successfully',
        data: { contact_id: contactId }
      });

    } catch (error) {
      await connection.rollback();
      throw error;
    }

  } catch (error: any) {
    console.error('Contact creation error:', error);
    return NextResponse.json({
      success: false,
      error: 'Failed to create contact'
    }, { status: 500 });
  } finally {
    if (connection) await connection.end();
  }
}
