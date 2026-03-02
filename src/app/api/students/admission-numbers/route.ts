import { NextRequest, NextResponse } from 'next/server';
import { reassignAdmissionNumbers, getNextAdmissionNumber, formatAdmissionNumber } from '@/lib/admissionNumber';

/**
 * POST /api/students/fix-admission-numbers
 * 
 * Query params:
 * - dryRun=true: Preview changes without saving
 * - fix=true: Actually update the database
 */
export async function POST(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);
    const dryRun = searchParams.get('dryRun')?.toLowerCase() === 'true';
    const fix = searchParams.get('fix')?.toLowerCase() === 'true';

    if (!fix && !dryRun) {
      return NextResponse.json(
        { error: 'Please specify either dryRun=true for preview or fix=true to apply changes' },
        { status: 400 }
      );
    }

    const body = await req.json();
    const { school_id = 1 } = body;

    const result = await reassignAdmissionNumbers(school_id, dryRun);

    return NextResponse.json({
      success: true,
      mode: dryRun ? 'dry_run' : 'applied',
      updated: result.updated,
      errors: result.errors,
      changes: result.changes,
      message: dryRun 
        ? `Preview: ${result.updated} admission numbers would be reassigned` 
        : `Successfully reassigned ${result.updated} admission numbers`,
    });
  } catch (error: any) {
    console.error('Error fixing admission numbers:', error);
    return NextResponse.json(
      { success: false, error: error.message },
      { status: 500 }
    );
  }
}

/**
 * GET /api/students/next-admission-number
 * Get the next sequential admission number for a school
 */
export async function GET(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);
    const schoolId = parseInt(searchParams.get('school_id') || '1');

    const nextSeq = await getNextAdmissionNumber(schoolId);
    const formattedNo = formatAdmissionNumber(nextSeq, schoolId);

    return NextResponse.json({
      success: true,
      sequence_number: nextSeq,
      admission_number: formattedNo,
    });
  } catch (error: any) {
    console.error('Error getting next admission number:', error);
    return NextResponse.json(
      { success: false, error: error.message },
      { status: 500 }
    );
  }
}
