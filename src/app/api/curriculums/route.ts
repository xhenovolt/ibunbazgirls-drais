import { NextRequest } from 'next/server';
import { NextResponse } from 'next/server';
import { getConnection } from '@/lib/db';

export async function GET() {
  try {
    const conn = await getConnection();
    const [rows] = await conn.execute('SELECT id,code,name FROM curriculums ORDER BY id');
    await conn.end();
    return NextResponse.json({ data: rows });
  } catch (error: any) {
    console.error('Curriculum GET error:', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    if (!body.code || !body.name) return NextResponse.json({ error: 'code & name required' }, { status: 400 });
    const conn = await getConnection();
    await conn.execute('INSERT INTO curriculums (code,name) VALUES (?,?)', [body.code, body.name]);
    const [result] = await conn.execute('SELECT LAST_INSERT_ID() as id');
    await conn.end();
    const lastId = (result as any).length > 0 ? (result as any)[0].id : null;
    return NextResponse.json({ success: true, id: lastId }, { status: 201 });
  } catch (error: any) {
    console.error('Curriculum POST error:', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

export async function PUT(req: NextRequest) {
  try {
    const body = await req.json();
    if (!body.id || !body.code || !body.name) return NextResponse.json({ error: 'id, code & name required' }, { status: 400 });
    const conn = await getConnection();
    await conn.execute('UPDATE curriculums SET code=?, name=? WHERE id=?', [body.code, body.name, body.id]);
    await conn.end();
    return NextResponse.json({ success: true });
  } catch (error: any) {
    console.error('Curriculum PUT error:', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

export async function DELETE(req: NextRequest) {
  try {
    const body = await req.json();
    if (!body.id) return NextResponse.json({ error: 'id required' }, { status: 400 });
    const conn = await getConnection();
    await conn.execute('DELETE FROM curriculums WHERE id=?', [body.id]);
    await conn.end();
    return NextResponse.json({ success: true });
  } catch (error: any) {
    console.error('Curriculum DELETE error:', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
