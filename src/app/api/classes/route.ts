import { NextRequest, NextResponse } from 'next/server';
import { getConnection } from '@/lib/db';

export async function GET(req: NextRequest) {
  let connection;
  
  try {
    const { searchParams } = new URL(req.url);
    const schoolId = parseInt(searchParams.get('school_id') || '1');
    const type = searchParams.get('type'); // Filter by type (e.g., 'tahfiz')

    connection = await getConnection();

    let sql = `
      SELECT 
        id,
        name,
        class_level,
        head_teacher_id
      FROM classes 
      WHERE school_id = ?
    `;
    const params: any[] = [schoolId];

    // Filter for tahfiz classes (WHERE name LIKE '%tahfiz%' OR name = 'tahfiz')
    if (type === 'tahfiz') {
      sql += ` AND (LOWER(name) LIKE '%tahfiz%' OR LOWER(name) = 'tahfiz')`;
    }

    sql += ` ORDER BY class_level, name`;

    const [classes] = await connection.execute(sql, params);

    return NextResponse.json({
      success: true,
      data: classes
    });

  } catch (error: any) {
    console.error('Classes fetch error:', error);
    return NextResponse.json({
      success: false,
      error: 'Failed to fetch classes'
    }, { status: 500 });
  } finally {
    if (connection) await connection.end();
  }
}

export async function POST(req: NextRequest) {
  let connection;
  try {
    const body = await req.json();
    if (!body.name) return NextResponse.json({ error: 'name required' }, { status: 400 });
    connection = await getConnection();
    await connection.execute('INSERT INTO classes (school_id,name,class_level,head_teacher_id,curriculum_id) VALUES (?,?,?,?,?)', [body.school_id || 1, body.name, body.class_level || null, body.head_teacher_id || null, body.curriculum_id || null]);
    const [result] = await connection.execute('SELECT LAST_INSERT_ID() as id');
    return NextResponse.json({ success: true, id: (result as any)[0].id }, { status: 201 });
  } catch (error: any) {
    console.error('Classes POST error:', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  } finally {
    if (connection) await connection.end();
  }
}

export async function PUT(req: NextRequest) {
  let connection;
  try {
    const body = await req.json();
    if (!body.id || !body.name) return NextResponse.json({ error: 'id and name required' }, { status: 400 });
    connection = await getConnection();
    await connection.execute('UPDATE classes SET name=?, class_level=?, head_teacher_id=?, curriculum_id=?, school_id=? WHERE id=?', [body.name, body.class_level || null, body.head_teacher_id || null, body.curriculum_id || null, body.school_id || 1, body.id]);
    return NextResponse.json({ success: true });
  } catch (error: any) {
    console.error('Classes PUT error:', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  } finally {
    if (connection) await connection.end();
  }
}

export async function DELETE(req: NextRequest) {
  let connection;
  try {
    const body = await req.json();
    if (!body.id) return NextResponse.json({ error: 'id required' }, { status: 400 });
    connection = await getConnection();
    await connection.execute('DELETE FROM classes WHERE id=?', [body.id]);
    return NextResponse.json({ success: true });
  } catch (error: any) {
    console.error('Classes DELETE error:', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  } finally {
    if (connection) await connection.end();
  }
}
