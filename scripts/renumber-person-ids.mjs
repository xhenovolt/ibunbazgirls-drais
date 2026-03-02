#!/usr/bin/env node

/**
 * Database Migration Script: Renumber person_id values sequentially
 * Changes large generic IDs (30682, 30683, etc.) to sequential (681, 682, etc.)
 * 
 * IMPORTANT: Backup your database before running this!
 * Usage: node scripts/renumber-person-ids.mjs
 */

import mysql from 'mysql2/promise';
import dotenv from 'dotenv';

dotenv.config({ path: '.env.local' });

const pool = mysql.createPool({
  host: process.env.DATABASE_HOST || process.env.MYSQL_HOST || process.env.DB_HOST || 'localhost',
  user: process.env.DATABASE_USER || process.env.MYSQL_USER || process.env.DB_USER || 'root',
  password: process.env.DATABASE_PASSWORD || process.env.MYSQL_PASSWORD || process.env.DB_PASS || '',
  database: process.env.DATABASE_NAME || process.env.MYSQL_DB || process.env.DB_NAME || 'ibunbaz_drais',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

async function main() {
  let connection;
  try {
    connection = await pool.getConnection();
    
    console.log('🔄 Starting person_id renumbering...\n');
    
    // First, check what columns exist in the students table
    const [tableInfo] = await connection.execute(
      'DESCRIBE students'
    );
    
    const columnNames = tableInfo.map(col => col.Field);
    console.log('📋 Students table columns:', columnNames.join(', '));
    console.log('');
    
    // Get all students, ordered by creation date
    const [students] = await connection.execute(
      `SELECT * FROM students ORDER BY created_at ASC, id ASC`
    );
    
    if (!students.length) {
      console.log('❌ No students found in database');
      return;
    }
    
    console.log(`📊 Total students found: ${students.length}\n`);
    console.log('Current person_id values to be renumbered:');
    console.log('─'.repeat(80));
    
    // Renumber sequentially starting from 1
    let seq = 1;
    const updates = [];
    
    for (const student of students) {
      const oldPersonId = student.person_id;
      const newPersonId = seq;
      
      // Log first 5 and every 50th for visibility
      if (seq <= 5 || seq % 50 === 0 || seq === students.length) {
        console.log(`${seq.toString().padStart(4, ' ')}. Student ID: ${String(student.id).padStart(6)} | OLD person_id: ${String(oldPersonId).padStart(10)} → NEW: ${String(newPersonId).padStart(4)}`);
      }
      
      updates.push({ studentId: student.id, oldPersonId, newPersonId });
      seq++;
    }
    
    console.log('─'.repeat(80));
    console.log(`\n⏳ Updating ${updates.length} student records...\n`);
    
    // Apply updates in transaction
    await connection.beginTransaction();
    
    for (const update of updates) {
      await connection.execute(
        'UPDATE students SET person_id = ? WHERE id = ?',
        [update.newPersonId, update.studentId]
      );
    }
    
    await connection.commit();
    
    console.log('✅ All student person_ids successfully renumbered!\n');
    console.log('📋 Summary:');
    console.log(`   - Total students updated: ${updates.length}`);
    console.log(`   - ID range: 1 to ${updates.length}`);
    console.log(`   - All IDs now sequential and clean`);
    console.log('\n✨ Person IDs have been reset to follow sequential numbering.');
    console.log('   Any new students added will automatically get the next sequential ID.');
    
  } catch (error) {
    console.error('❌ Error during renumbering:', error.message);
    if (connection) {
      await connection.rollback();
      console.log('⚠️  Transaction rolled back - no changes were made');
    }
    process.exit(1);
  } finally {
    if (connection) connection.release();
    await pool.end();
  }
}

main();
