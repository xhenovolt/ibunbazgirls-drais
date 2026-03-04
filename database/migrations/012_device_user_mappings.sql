-- Migration: Create device_user_mappings table for device ID management
-- This table maps biometric device user IDs to students and staff members

-- Create biometric_devices table if it doesn't exist
CREATE TABLE IF NOT EXISTS biometric_devices (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  school_id BIGINT NOT NULL DEFAULT 1,
  device_name VARCHAR(100) NOT NULL,
  device_code VARCHAR(50) UNIQUE,
  device_type VARCHAR(50) DEFAULT 'fingerprint',
  location VARCHAR(100),
  status ENUM('active', 'inactive', 'maintenance') DEFAULT 'active',
  last_sync_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP NULL,
  INDEX idx_school_id (school_id),
  INDEX idx_device_code (device_code),
  INDEX idx_status (status),
  CONSTRAINT fk_biometric_devices_school
    FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Biometric device management and tracking';

-- Create device_user_mappings table
CREATE TABLE IF NOT EXISTS device_user_mappings (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  school_id BIGINT NOT NULL DEFAULT 1,
  device_id BIGINT NOT NULL,
  student_id BIGINT,
  staff_id BIGINT,
  device_user_id INT NOT NULL COMMENT 'Device enrolled user ID (biometric ID)',
  status ENUM('active', 'inactive', 'suspended') DEFAULT 'active',
  enrollment_status ENUM('enrolled', 'pending', 'failed') DEFAULT 'enrolled',
  verified BOOLEAN DEFAULT FALSE,
  mappings_sync_status ENUM('pending', 'synced', 'failed') DEFAULT 'pending',
  last_synced_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP NULL,
  UNIQUE KEY uk_school_device_user (school_id, device_user_id),
  UNIQUE KEY uk_device_student (device_id, student_id),
  UNIQUE KEY uk_device_staff (device_id, staff_id),
  INDEX idx_school_id (school_id),
  INDEX idx_device_id (device_id),
  INDEX idx_student_id (student_id),
  INDEX idx_staff_id (staff_id),
  INDEX idx_device_user_id (device_user_id),
  INDEX idx_status (status),
  CONSTRAINT fk_device_user_mappings_school
    FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
  CONSTRAINT fk_device_user_mappings_device
    FOREIGN KEY (device_id) REFERENCES biometric_devices(id) ON DELETE CASCADE,
  CONSTRAINT fk_device_user_mappings_student
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
  CONSTRAINT fk_device_user_mappings_staff
    FOREIGN KEY (staff_id) REFERENCES staff(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Maps biometric device user IDs to students and staff members';

-- Ensure biometric_devices has required indexes
ALTER TABLE biometric_devices ADD INDEX IF NOT EXISTS idx_school_status (school_id, status);

-- Ensure device_user_mappings has required indexes
ALTER TABLE device_user_mappings ADD INDEX IF NOT EXISTS idx_school_device (school_id, device_id);
ALTER TABLE device_user_mappings ADD INDEX IF NOT EXISTS idx_school_student (school_id, student_id);
ALTER TABLE device_user_mappings ADD INDEX IF NOT EXISTS idx_school_staff (school_id, staff_id);
