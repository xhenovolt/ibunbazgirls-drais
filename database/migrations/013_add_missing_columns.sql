-- Migration: Add missing columns to staff_attendance and departments tables

-- Add missing columns to staff_attendance table
ALTER TABLE staff_attendance ADD COLUMN IF NOT EXISTS time_in TIME NULL DEFAULT NULL;
ALTER TABLE staff_attendance ADD COLUMN IF NOT EXISTS time_out TIME NULL DEFAULT NULL;
ALTER TABLE staff_attendance ADD COLUMN IF NOT EXISTS method VARCHAR(50) DEFAULT 'manual';
ALTER TABLE staff_attendance ADD COLUMN IF NOT EXISTS marked_by BIGINT NULL DEFAULT NULL;
ALTER TABLE staff_attendance ADD COLUMN IF NOT EXISTS marked_at TIMESTAMP NULL DEFAULT NULL;

-- Create indexes for staff_attendance
ALTER TABLE staff_attendance ADD INDEX IF NOT EXISTS idx_staff_date (staff_id, date);
ALTER TABLE staff_attendance ADD INDEX IF NOT EXISTS idx_date (date);
ALTER TABLE staff_attendance ADD INDEX IF NOT EXISTS idx_status (status);

-- Add missing columns to departments table
ALTER TABLE departments ADD COLUMN IF NOT EXISTS budget DECIMAL(14, 2) NULL DEFAULT NULL;
ALTER TABLE departments ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE departments ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE departments ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP NULL DEFAULT NULL;

-- Create indexes for departments
ALTER TABLE departments ADD INDEX IF NOT EXISTS idx_school_id (school_id);
ALTER TABLE departments ADD INDEX IF NOT EXISTS idx_name (name);
ALTER TABLE departments ADD INDEX IF NOT EXISTS idx_head_staff_id (head_staff_id);

