import { getConnection } from '@/lib/db';

/**
 * Get the next sequential admission number for a school
 * Uses transaction locking to prevent race conditions
 */
export async function getNextAdmissionNumber(schoolId: number = 1): Promise<number> {
  const connection = await getConnection();
  try {
    await connection.beginTransaction();

    // Lock the school_sequence table for this school to prevent race conditions
    const [lockResult]: any = await connection.execute(
      `SELECT MAX(CAST(SUBSTRING(admission_no, POSITION('/' IN admission_no) + 1) AS UNSIGNED)) as max_num
       FROM students
       WHERE school_id = ? AND admission_no IS NOT NULL
       FOR UPDATE`,
      [schoolId]
    );

    let nextNumber = 1;
    if (lockResult && lockResult[0]?.max_num) {
      nextNumber = Math.max(nextNumber, lockResult[0].max_num + 1);
    }

    await connection.commit();
    return nextNumber;
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    await connection.end();
  }
}

/**
 * Format admission number as: YEAR-SCHOOLID-SEQUENCE
 * Example: 2026-001-001 or just sequential: 241
 * 
 * For now using simple sequential per requested spec
 */
export function formatAdmissionNumber(sequenceNumber: number, schoolId: number = 1): string {
  // Simple sequential format: just the number
  // Can be changed to 2026-{schoolId}-{number} format if needed
  return sequenceNumber.toString().padStart(3, '0');
}

/**
 * Verify admission number is unique
 */
export async function isAdmissionNumberUnique(
  admissionNo: string,
  schoolId: number = 1,
  excludeStudentId?: number
): Promise<boolean> {
  const connection = await getConnection();
  try {
    let sql = 'SELECT COUNT(*) as count FROM students WHERE school_id = ? AND admission_no = ?';
    const params: any[] = [schoolId, admissionNo];

    if (excludeStudentId) {
      sql += ' AND id != ?';
      params.push(excludeStudentId);
    }

    const [result]: any = await connection.execute(sql, params);
    return result[0]?.count === 0;
  } finally {
    await connection.end();
  }
}

/**
 * Reassign sequential admission numbers based on admission date
 * This fixes existing data
 */
export async function reassignAdmissionNumbers(
  schoolId: number = 1,
  dryRun: boolean = false
): Promise<{
  updated: number;
  errors: Array<{ studentId: number; error: string }>;
  changes: Array<{ studentId: number; oldNo: string; newNo: string }>;
}> {
  const connection = await getConnection();
  try {
    await connection.beginTransaction();

    // Get all students ordered by admission date
    const [students]: any = await connection.execute(
      `SELECT s.id, s.admission_no, s.admission_date
       FROM students
       WHERE school_id = ?
       AND deleted_at IS NULL
       ORDER BY s.admission_date ASC, s.id ASC`,
      [schoolId]
    );

    const changes: Array<{ studentId: number; oldNo: string; newNo: string }> = [];
    const errors: Array<{ studentId: number; error: string }> = [];
    let updated = 0;

    for (let i = 0; i < students.length; i++) {
      const student = students[i];
      const newAdmissionNo = formatAdmissionNumber(i + 1, schoolId);

      if (student.admission_no !== newAdmissionNo) {
        try {
          if (!dryRun) {
            await connection.execute(
              'UPDATE students SET admission_no = ? WHERE id = ?',
              [newAdmissionNo, student.id]
            );
          }
          changes.push({
            studentId: student.id,
            oldNo: student.admission_no || 'NULL',
            newNo: newAdmissionNo,
          });
          updated++;
        } catch (error: any) {
          errors.push({
            studentId: student.id,
            error: error.message,
          });
        }
      }
    }

    if (!dryRun) {
      await connection.commit();
    } else {
      await connection.rollback();
    }

    return { updated, errors, changes };
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    await connection.end();
  }
}
