-- MySQL dump 10.13  Distrib 8.0.44, for Linux (x86_64)
--
-- Host: localhost    Database: drais_school
-- ------------------------------------------------------
-- Server version	8.0.44-0ubuntu0.24.04.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `academic_years`
--

DROP TABLE IF EXISTS `academic_years`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `academic_years` (
  `id` bigint NOT NULL,
  `school_id` bigint NOT NULL,
  `name` varchar(20) NOT NULL,
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `status` varchar(20) DEFAULT 'active'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `attendance_audit_logs`
--

DROP TABLE IF EXISTS `attendance_audit_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `attendance_audit_logs` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `school_id` bigint NOT NULL,
  `entity_type` enum('daily_attendance','manual_entry','device','rule') COLLATE utf8mb4_unicode_ci NOT NULL,
  `entity_id` bigint NOT NULL,
  `change_type` enum('create','update','delete','process') COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_id` bigint DEFAULT NULL,
  `user_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ip_address` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_agent` text COLLATE utf8mb4_unicode_ci,
  `old_values` json DEFAULT NULL,
  `new_values` json DEFAULT NULL,
  `change_summary` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `timestamp` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_school_id` (`school_id`),
  KEY `idx_entity` (`entity_type`,`entity_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_timestamp` (`timestamp`),
  KEY `idx_change_type` (`change_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `attendance_logs`
--

DROP TABLE IF EXISTS `attendance_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `attendance_logs` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `school_id` bigint NOT NULL,
  `device_id` bigint NOT NULL,
  `device_user_id` int NOT NULL,
  `scan_timestamp` timestamp NOT NULL,
  `received_timestamp` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `verification_status` enum('success','failed','unknown') COLLATE utf8mb4_unicode_ci DEFAULT 'success',
  `biometric_quality` int DEFAULT NULL,
  `device_log_id` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `device_sync_count` int DEFAULT '1',
  `processing_status` enum('pending','processed','error','duplicate') COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `process_error_message` text COLLATE utf8mb4_unicode_ci,
  `mapped_device_user_id` bigint DEFAULT NULL,
  `is_duplicate` tinyint(1) DEFAULT '0',
  `duplicate_of_log_id` bigint DEFAULT NULL,
  `raw_data` json DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_school_duplicate` (`school_id`,`device_id`,`device_user_id`,`scan_timestamp`,`device_log_id`),
  KEY `idx_school_scan` (`school_id`,`scan_timestamp`),
  KEY `idx_device_user_scan` (`device_user_id`,`scan_timestamp`),
  KEY `idx_processing_status` (`processing_status`),
  KEY `idx_received_timestamp` (`received_timestamp`),
  KEY `idx_scan_timestamp` (`scan_timestamp`),
  KEY `idx_device_id` (`device_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `attendance_processing_queue`
--

DROP TABLE IF EXISTS `attendance_processing_queue`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `attendance_processing_queue` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `school_id` bigint NOT NULL,
  `job_type` enum('process_device_logs','calculate_daily_attendance','recalculate_date_range','rule_recalculation','sync_device') COLLATE utf8mb4_unicode_ci NOT NULL,
  `parameters` json DEFAULT NULL,
  `status` enum('queued','processing','completed','failed','retrying') COLLATE utf8mb4_unicode_ci DEFAULT 'queued',
  `priority` int DEFAULT '0',
  `attempted_count` int DEFAULT '0',
  `max_attempts` int DEFAULT '3',
  `result` json DEFAULT NULL,
  `error_message` text COLLATE utf8mb4_unicode_ci,
  `error_details` json DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `started_at` timestamp NULL DEFAULT NULL,
  `completed_at` timestamp NULL DEFAULT NULL,
  `next_retry_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_school_status` (`school_id`,`status`),
  KEY `idx_status` (`status`),
  KEY `idx_priority` (`priority`),
  KEY `idx_created_at` (`created_at`),
  KEY `idx_next_retry` (`next_retry_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `attendance_reconciliation`
--

DROP TABLE IF EXISTS `attendance_reconciliation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `attendance_reconciliation` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `school_id` bigint NOT NULL DEFAULT '1',
  `attendance_session_id` bigint DEFAULT NULL,
  `student_id` bigint NOT NULL,
  `manual_status` enum('present','absent','late','excused') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `manual_marked_by` bigint DEFAULT NULL,
  `manual_marked_at` timestamp NULL DEFAULT NULL,
  `biometric_status` enum('present','absent','late') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `biometric_marked_at` timestamp NULL DEFAULT NULL,
  `reconciliation_status` enum('matched','conflict','biometric_only','manual_only') COLLATE utf8mb4_unicode_ci DEFAULT 'matched',
  `conflict_resolution` enum('trust_biometric','trust_manual','manual_correction') COLLATE utf8mb4_unicode_ci DEFAULT 'trust_biometric',
  `resolved_at` timestamp NULL DEFAULT NULL,
  `resolved_by` bigint DEFAULT NULL,
  `resolution_notes` text COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_session_student` (`attendance_session_id`,`student_id`),
  KEY `idx_reconciliation_status` (`reconciliation_status`),
  KEY `idx_student` (`student_id`),
  KEY `idx_created_at` (`created_at`),
  KEY `fk_reconciliation_school` (`school_id`),
  CONSTRAINT `attendance_reconciliation_ibfk_1` FOREIGN KEY (`school_id`) REFERENCES `schools` (`id`) ON DELETE CASCADE,
  CONSTRAINT `attendance_reconciliation_ibfk_2` FOREIGN KEY (`attendance_session_id`) REFERENCES `attendance_sessions` (`id`) ON DELETE SET NULL,
  CONSTRAINT `attendance_reconciliation_ibfk_3` FOREIGN KEY (`student_id`) REFERENCES `students` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Hybrid attendance reconciliation (manual vs biometric)';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `attendance_reports`
--

DROP TABLE IF EXISTS `attendance_reports`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `attendance_reports` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `school_id` bigint NOT NULL DEFAULT '1',
  `report_type` enum('daily_summary','weekly_trend','monthly_summary','class_analysis','student_profile','period_comparison') COLLATE utf8mb4_unicode_ci DEFAULT 'daily_summary',
  `date_from` date DEFAULT NULL,
  `date_to` date DEFAULT NULL,
  `class_id` bigint DEFAULT NULL,
  `stream_id` bigint DEFAULT NULL,
  `academic_year_id` bigint DEFAULT NULL,
  `report_data` longtext COLLATE utf8mb4_unicode_ci,
  `generated_by` bigint DEFAULT NULL,
  `generated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `expires_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_school` (`school_id`),
  KEY `idx_generated_at` (`generated_at`),
  KEY `idx_report_type` (`report_type`),
  CONSTRAINT `attendance_reports_ibfk_1` FOREIGN KEY (`school_id`) REFERENCES `schools` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Cached attendance reports';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `attendance_rules`
--

DROP TABLE IF EXISTS `attendance_rules`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `attendance_rules` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `school_id` bigint NOT NULL,
  `rule_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `rule_description` text COLLATE utf8mb4_unicode_ci,
  `arrival_start_time` time DEFAULT NULL,
  `arrival_end_time` time DEFAULT NULL,
  `late_threshold_minutes` int DEFAULT '15',
  `absence_cutoff_time` time DEFAULT NULL,
  `closing_time` time DEFAULT NULL,
  `applies_to` enum('students','teachers','all') COLLATE utf8mb4_unicode_ci DEFAULT 'students',
  `applies_to_classes` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `auto_excuse_after_days` int DEFAULT '0',
  `ignore_duplicate_scans_within_minutes` int DEFAULT '2',
  `is_active` tinyint(1) DEFAULT '1',
  `effective_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `priority` int DEFAULT '100',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_school_id` (`school_id`),
  KEY `idx_is_active` (`is_active`),
  KEY `idx_effective_date` (`effective_date`),
  KEY `idx_priority` (`priority`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `attendance_sessions`
--

DROP TABLE IF EXISTS `attendance_sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `attendance_sessions` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `school_id` bigint NOT NULL DEFAULT '1',
  `class_id` bigint NOT NULL,
  `stream_id` bigint DEFAULT NULL,
  `term_id` bigint DEFAULT NULL,
  `academic_year_id` bigint DEFAULT NULL,
  `subject_id` bigint DEFAULT NULL,
  `teacher_id` bigint DEFAULT NULL,
  `session_date` date NOT NULL,
  `session_start_time` time DEFAULT NULL,
  `session_end_time` time DEFAULT NULL,
  `session_type` enum('morning_check','lesson','assembly','afternoon_check','custom') COLLATE utf8mb4_unicode_ci DEFAULT 'lesson',
  `attendance_type` enum('manual','biometric','hybrid') COLLATE utf8mb4_unicode_ci DEFAULT 'manual',
  `status` enum('draft','open','submitted','locked','finalized') COLLATE utf8mb4_unicode_ci DEFAULT 'draft',
  `notes` text COLLATE utf8mb4_unicode_ci,
  `submitted_at` timestamp NULL DEFAULT NULL,
  `submitted_by` bigint DEFAULT NULL,
  `finalized_at` timestamp NULL DEFAULT NULL,
  `finalized_by` bigint DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_class_date` (`class_id`,`session_date`),
  KEY `idx_status` (`status`),
  KEY `idx_academic_year` (`academic_year_id`),
  KEY `idx_teacher` (`teacher_id`),
  KEY `idx_session_date` (`session_date`),
  KEY `fk_attendance_sessions_school` (`school_id`),
  KEY `fk_attendance_sessions_stream` (`stream_id`),
  CONSTRAINT `attendance_sessions_ibfk_1` FOREIGN KEY (`school_id`) REFERENCES `schools` (`id`) ON DELETE CASCADE,
  CONSTRAINT `attendance_sessions_ibfk_2` FOREIGN KEY (`class_id`) REFERENCES `classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `attendance_sessions_ibfk_3` FOREIGN KEY (`stream_id`) REFERENCES `streams` (`id`) ON DELETE SET NULL,
  CONSTRAINT `attendance_sessions_ibfk_4` FOREIGN KEY (`school_id`) REFERENCES `schools` (`id`) ON DELETE CASCADE,
  CONSTRAINT `attendance_sessions_ibfk_5` FOREIGN KEY (`class_id`) REFERENCES `classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `attendance_sessions_ibfk_6` FOREIGN KEY (`stream_id`) REFERENCES `streams` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Attendance session tracking for class-level periods';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `attendance_users`
--

DROP TABLE IF EXISTS `attendance_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `attendance_users` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `school_id` bigint NOT NULL,
  `email` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `username` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `password_hash` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `first_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `last_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `phone` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `role` enum('admin','director','teacher','parent','student','staff') COLLATE utf8mb4_unicode_ci DEFAULT 'staff',
  `is_active` tinyint(1) DEFAULT '1',
  `email_verified` tinyint(1) DEFAULT '0',
  `last_login_at` timestamp NULL DEFAULT NULL,
  `last_login_ip` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `password_changed_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`),
  UNIQUE KEY `username` (`username`),
  KEY `idx_school_id` (`school_id`),
  KEY `idx_email` (`email`),
  KEY `idx_role` (`role`),
  KEY `idx_is_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `audit_log`
--

DROP TABLE IF EXISTS `audit_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `audit_log` (
  `id` bigint NOT NULL,
  `actor_user_id` bigint DEFAULT NULL,
  `action` varchar(100) NOT NULL,
  `entity_type` varchar(100) NOT NULL,
  `entity_id` bigint DEFAULT NULL,
  `changes_json` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_bin,
  `ip` varchar(64) DEFAULT NULL,
  `user_agent` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `audit_log_chk_1` CHECK (json_valid(`changes_json`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `balance_reminders`
--

DROP TABLE IF EXISTS `balance_reminders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `balance_reminders` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `school_id` bigint DEFAULT NULL,
  `student_id` bigint NOT NULL,
  `term_id` bigint NOT NULL,
  `reminder_type` enum('email','sms','both') DEFAULT 'both',
  `threshold_amount` decimal(14,2) DEFAULT NULL,
  `message` text,
  `sent_at` timestamp NULL DEFAULT NULL,
  `status` enum('pending','sent','failed') DEFAULT 'pending',
  `response_data` json DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_reminders_school` (`school_id`),
  KEY `idx_reminders_student` (`student_id`),
  KEY `idx_reminders_status` (`status`),
  KEY `idx_reminders_sent` (`sent_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='Balance reminder tracking';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `biometric_devices`
--

DROP TABLE IF EXISTS `biometric_devices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `biometric_devices` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `school_id` bigint NOT NULL DEFAULT '1',
  `device_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `device_code` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `device_type` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT 'fingerprint',
  `manufacturer` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `model` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `serial_number` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `location` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ip_address` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `mac_address` varchar(17) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fingerprint_capacity` int DEFAULT '3000',
  `enrollment_count` int DEFAULT '0',
  `status` enum('active','inactive','maintenance','offline') COLLATE utf8mb4_unicode_ci DEFAULT 'active',
  `last_sync_at` timestamp NULL DEFAULT NULL,
  `sync_status` enum('synced','pending','failed') COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `sync_error_message` text COLLATE utf8mb4_unicode_ci,
  `last_sync_record_count` int DEFAULT '0',
  `battery_level` int DEFAULT NULL,
  `storage_used_percent` decimal(5,2) DEFAULT NULL,
  `is_master` tinyint(1) DEFAULT '0',
  `api_key` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `api_secret` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `device_code` (`device_code`),
  UNIQUE KEY `serial_number` (`serial_number`),
  UNIQUE KEY `unique_device_code` (`device_code`),
  UNIQUE KEY `unique_serial` (`serial_number`),
  KEY `idx_school` (`school_id`),
  KEY `idx_status` (`status`),
  KEY `idx_sync_status` (`sync_status`),
  CONSTRAINT `biometric_devices_ibfk_1` FOREIGN KEY (`school_id`) REFERENCES `schools` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Biometric device management and tracking';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `branches`
--

DROP TABLE IF EXISTS `branches`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `branches` (
  `id` bigint NOT NULL,
  `school_id` bigint NOT NULL,
  `name` varchar(150) NOT NULL,
  `phone` varchar(30) DEFAULT NULL,
  `email` varchar(150) DEFAULT NULL,
  `address` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `class_results`
--

DROP TABLE IF EXISTS `class_results`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `class_results` (
  `id` bigint NOT NULL,
  `student_id` bigint NOT NULL,
  `class_id` bigint NOT NULL,
  `subject_id` bigint NOT NULL,
  `term_id` bigint DEFAULT NULL,
  `result_type_id` bigint NOT NULL,
  `score` decimal(5,2) DEFAULT NULL,
  `grade` varchar(10) DEFAULT NULL,
  `remarks` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `class_subjects`
--

DROP TABLE IF EXISTS `class_subjects`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `class_subjects` (
  `id` bigint NOT NULL,
  `class_id` bigint NOT NULL,
  `subject_id` bigint NOT NULL,
  `teacher_id` bigint DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `classes`
--

DROP TABLE IF EXISTS `classes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `classes` (
  `id` bigint NOT NULL,
  `school_id` bigint DEFAULT NULL,
  `name` varchar(50) NOT NULL,
  `curriculum_id` int DEFAULT NULL,
  `class_level` int DEFAULT NULL,
  `head_teacher_id` bigint DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `contacts`
--

DROP TABLE IF EXISTS `contacts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `contacts` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `school_id` bigint NOT NULL,
  `person_id` bigint NOT NULL,
  `contact_type` varchar(30) NOT NULL,
  `occupation` varchar(120) DEFAULT NULL,
  `alive_status` varchar(20) DEFAULT NULL,
  `date_of_death` date DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `counties`
--

DROP TABLE IF EXISTS `counties`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `counties` (
  `id` bigint NOT NULL,
  `district_id` bigint NOT NULL,
  `name` varchar(150) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `curriculums`
--

DROP TABLE IF EXISTS `curriculums`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `curriculums` (
  `id` tinyint NOT NULL,
  `code` varchar(30) NOT NULL,
  `name` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `dahua_attendance_logs`
--

DROP TABLE IF EXISTS `dahua_attendance_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dahua_attendance_logs` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `device_id` bigint NOT NULL,
  `student_id` bigint DEFAULT NULL,
  `card_no` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_id` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `event_time` datetime NOT NULL,
  `event_type` enum('Entry','Exit','Unknown') COLLATE utf8mb4_unicode_ci DEFAULT 'Entry',
  `method` enum('fingerprint','card','face','password','unknown') COLLATE utf8mb4_unicode_ci DEFAULT 'unknown',
  `status` enum('present','absent','late','processed') COLLATE utf8mb4_unicode_ci DEFAULT 'processed',
  `raw_log_id` bigint DEFAULT NULL,
  `matched_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_device` (`device_id`),
  KEY `idx_student` (`student_id`),
  KEY `idx_card` (`card_no`),
  KEY `idx_event_time` (`event_time`),
  KEY `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Normalized Dahua attendance logs';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `dahua_devices`
--

DROP TABLE IF EXISTS `dahua_devices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dahua_devices` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `school_id` bigint NOT NULL DEFAULT '1',
  `device_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `device_code` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ip_address` varchar(45) COLLATE utf8mb4_unicode_ci NOT NULL,
  `port` int DEFAULT '80',
  `api_url` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `username` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `password` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `device_type` enum('attendance','access_control','hybrid') COLLATE utf8mb4_unicode_ci DEFAULT 'attendance',
  `protocol` enum('http','https') COLLATE utf8mb4_unicode_ci DEFAULT 'http',
  `status` enum('active','inactive','offline','error') COLLATE utf8mb4_unicode_ci DEFAULT 'active',
  `last_sync` timestamp NULL DEFAULT NULL,
  `last_sync_status` enum('success','failed','pending') COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `last_error_message` text COLLATE utf8mb4_unicode_ci,
  `auto_sync_enabled` tinyint(1) DEFAULT '1',
  `sync_interval_minutes` int DEFAULT '15',
  `late_threshold_minutes` int DEFAULT '30',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `device_code` (`device_code`),
  UNIQUE KEY `unique_dahua_code` (`device_code`),
  KEY `idx_school` (`school_id`),
  KEY `idx_status` (`status`),
  KEY `idx_ip` (`ip_address`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Dahua biometric device configuration and settings';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `dahua_raw_logs`
--

DROP TABLE IF EXISTS `dahua_raw_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dahua_raw_logs` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `device_id` bigint NOT NULL,
  `raw_data` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `record_count` int DEFAULT '0',
  `parsed_successfully` tinyint(1) DEFAULT '0',
  `parse_errors` text COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_device` (`device_id`),
  KEY `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Raw Dahua device logs storage';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `dahua_sync_history`
--

DROP TABLE IF EXISTS `dahua_sync_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dahua_sync_history` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `device_id` bigint NOT NULL,
  `sync_type` enum('manual','scheduled','automatic') COLLATE utf8mb4_unicode_ci DEFAULT 'manual',
  `records_fetched` int DEFAULT '0',
  `records_processed` int DEFAULT '0',
  `records_failed` int DEFAULT '0',
  `status` enum('in_progress','success','failed','partial') COLLATE utf8mb4_unicode_ci DEFAULT 'in_progress',
  `started_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `completed_at` timestamp NULL DEFAULT NULL,
  `error_details` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`id`),
  KEY `idx_device` (`device_id`),
  KEY `idx_started` (`started_at`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Dahua device sync history tracking';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `daily_attendance`
--

DROP TABLE IF EXISTS `daily_attendance`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `daily_attendance` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `school_id` bigint NOT NULL,
  `person_type` enum('student','teacher') COLLATE utf8mb4_unicode_ci NOT NULL,
  `person_id` bigint NOT NULL,
  `attendance_date` date NOT NULL,
  `status` enum('present','late','absent','excused','on_leave','pending') COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `first_arrival_time` time DEFAULT NULL,
  `last_departure_time` time DEFAULT NULL,
  `arrival_device_id` bigint DEFAULT NULL,
  `is_manual_entry` tinyint(1) DEFAULT '0',
  `manual_entry_id` bigint DEFAULT NULL,
  `is_late` tinyint(1) DEFAULT '0',
  `late_minutes` int DEFAULT '0',
  `late_reason` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `excuse_type` enum('medical','parental','official','other','none') COLLATE utf8mb4_unicode_ci DEFAULT 'none',
  `excuse_note` text COLLATE utf8mb4_unicode_ci,
  `marking_rule_id` bigint DEFAULT NULL,
  `processing_metadata` json DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `processed_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_school_person_date` (`school_id`,`person_type`,`person_id`,`attendance_date`),
  KEY `idx_school_date` (`school_id`,`attendance_date`),
  KEY `idx_person` (`person_type`,`person_id`),
  KEY `idx_status` (`status`),
  KEY `idx_is_manual` (`is_manual_entry`),
  KEY `idx_is_late` (`is_late`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `department_workplans`
--

DROP TABLE IF EXISTS `department_workplans`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `department_workplans` (
  `id` bigint NOT NULL,
  `department_id` bigint NOT NULL,
  `title` varchar(200) NOT NULL,
  `description` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `start_datetime` datetime DEFAULT NULL,
  `end_datetime` datetime DEFAULT NULL,
  `status` varchar(20) DEFAULT 'pending',
  `created_by` bigint DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `departments`
--

DROP TABLE IF EXISTS `departments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `departments` (
  `id` bigint NOT NULL,
  `school_id` bigint NOT NULL,
  `name` varchar(120) NOT NULL,
  `head_staff_id` bigint DEFAULT NULL,
  `description` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `device_sync_checkpoints`
--

DROP TABLE IF EXISTS `device_sync_checkpoints`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `device_sync_checkpoints` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `school_id` bigint NOT NULL,
  `device_id` bigint NOT NULL,
  `last_synced_device_time` timestamp NULL DEFAULT NULL,
  `last_synced_remote_time` timestamp NULL DEFAULT NULL,
  `total_logs_synced` bigint DEFAULT '0',
  `failed_sync_attempts` int DEFAULT '0',
  `is_syncing` tinyint(1) DEFAULT '0',
  `sync_status` enum('success','partial','failed') COLLATE utf8mb4_unicode_ci DEFAULT 'success',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_device` (`school_id`,`device_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `device_sync_logs`
--

DROP TABLE IF EXISTS `device_sync_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `device_sync_logs` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `school_id` bigint NOT NULL DEFAULT '1',
  `device_id` bigint NOT NULL,
  `sync_type` enum('attendance_download','fingerprint_upload','logs_fetch','device_sync') COLLATE utf8mb4_unicode_ci DEFAULT 'attendance_download',
  `sync_direction` enum('pull','push','bidirectional') COLLATE utf8mb4_unicode_ci DEFAULT 'pull',
  `status` enum('pending','in_progress','success','partial_success','failed') COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `records_processed` int DEFAULT '0',
  `records_synced` int DEFAULT '0',
  `records_failed` int DEFAULT '0',
  `error_message` text COLLATE utf8mb4_unicode_ci,
  `details_json` json DEFAULT NULL,
  `started_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `completed_at` timestamp NULL DEFAULT NULL,
  `duration_seconds` int DEFAULT NULL,
  `initiated_by` bigint DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_device` (`device_id`),
  KEY `idx_started_at` (`started_at`),
  KEY `idx_status` (`status`),
  KEY `idx_sync_type` (`sync_type`),
  KEY `fk_sync_logs_school` (`school_id`),
  CONSTRAINT `device_sync_logs_ibfk_1` FOREIGN KEY (`school_id`) REFERENCES `schools` (`id`) ON DELETE CASCADE,
  CONSTRAINT `device_sync_logs_ibfk_2` FOREIGN KEY (`device_id`) REFERENCES `biometric_devices` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Device synchronization operation logs';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `device_users`
--

DROP TABLE IF EXISTS `device_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `device_users` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `school_id` bigint NOT NULL,
  `device_user_id` int NOT NULL,
  `person_type` enum('student','teacher') COLLATE utf8mb4_unicode_ci NOT NULL,
  `person_id` bigint NOT NULL,
  `device_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_enrolled` tinyint(1) DEFAULT '1',
  `enrollment_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `unenrollment_date` timestamp NULL DEFAULT NULL,
  `biometric_quality` int DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_school_device_user` (`school_id`,`device_user_id`),
  KEY `idx_school_id` (`school_id`),
  KEY `idx_person` (`person_type`,`person_id`),
  KEY `idx_is_enrolled` (`is_enrolled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `districts`
--

DROP TABLE IF EXISTS `districts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `districts` (
  `id` bigint NOT NULL,
  `name` varchar(150) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `document_types`
--

DROP TABLE IF EXISTS `document_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `document_types` (
  `id` bigint NOT NULL,
  `code` varchar(60) NOT NULL,
  `label` varchar(120) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `documents`
--

DROP TABLE IF EXISTS `documents`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `documents` (
  `id` bigint NOT NULL,
  `school_id` bigint NOT NULL,
  `owner_type` varchar(30) NOT NULL,
  `owner_id` bigint NOT NULL,
  `document_type_id` bigint NOT NULL,
  `file_name` varchar(200) NOT NULL,
  `file_url` varchar(255) NOT NULL,
  `mime_type` varchar(100) DEFAULT NULL,
  `file_size` bigint DEFAULT NULL,
  `issued_by` varchar(150) DEFAULT NULL,
  `issue_date` date DEFAULT NULL,
  `notes` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `uploaded_by` bigint DEFAULT NULL,
  `uploaded_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `enrollments`
--

DROP TABLE IF EXISTS `enrollments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `enrollments` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `student_id` bigint NOT NULL,
  `class_id` bigint DEFAULT NULL,
  `theology_class_id` bigint DEFAULT NULL,
  `stream_id` bigint DEFAULT NULL,
  `academic_year_id` bigint DEFAULT NULL,
  `term_id` bigint DEFAULT NULL,
  `status` varchar(20) DEFAULT 'active',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=681 DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `events`
--

DROP TABLE IF EXISTS `events`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `events` (
  `id` bigint NOT NULL,
  `school_id` bigint NOT NULL,
  `title` varchar(200) NOT NULL,
  `description` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `start_datetime` datetime NOT NULL,
  `end_datetime` datetime NOT NULL,
  `location` varchar(120) DEFAULT NULL,
  `status` varchar(20) DEFAULT 'upcoming',
  `created_by` bigint DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `exams`
--

DROP TABLE IF EXISTS `exams`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `exams` (
  `id` bigint NOT NULL,
  `school_id` bigint NOT NULL,
  `class_id` bigint NOT NULL,
  `subject_id` bigint NOT NULL,
  `term_id` bigint DEFAULT NULL,
  `name` varchar(120) NOT NULL,
  `body` varchar(50) DEFAULT NULL,
  `date` date DEFAULT NULL,
  `start_time` time DEFAULT NULL,
  `end_time` time DEFAULT NULL,
  `status` varchar(20) DEFAULT 'scheduled'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `expenditures`
--

DROP TABLE IF EXISTS `expenditures`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `expenditures` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `school_id` bigint DEFAULT NULL,
  `category_id` bigint NOT NULL,
  `wallet_id` bigint DEFAULT NULL,
  `amount` decimal(14,2) NOT NULL,
  `description` text NOT NULL,
  `vendor_name` varchar(150) DEFAULT NULL,
  `vendor_contact` varchar(100) DEFAULT NULL,
  `invoice_number` varchar(100) DEFAULT NULL,
  `receipt_url` varchar(255) DEFAULT NULL,
  `expense_date` date DEFAULT NULL,
  `status` enum('pending','approved','paid','cancelled') DEFAULT 'pending',
  `approved_by` bigint DEFAULT NULL,
  `approved_at` timestamp NULL DEFAULT NULL,
  `created_by` bigint DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_expenditures_school` (`school_id`),
  KEY `idx_expenditures_category` (`category_id`),
  KEY `idx_expenditures_wallet` (`wallet_id`),
  KEY `idx_expenditures_date` (`expense_date`),
  KEY `idx_expenditures_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='Expenditure tracking for school expenses';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `feature_flags`
--

DROP TABLE IF EXISTS `feature_flags`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `feature_flags` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `school_id` bigint DEFAULT NULL,
  `route_name` varchar(255) NOT NULL DEFAULT 'default',
  `route_path` varchar(255) NOT NULL DEFAULT '/',
  `label` varchar(255) NOT NULL DEFAULT 'Feature',
  `flag_name` varchar(100) NOT NULL,
  `flag_key` varchar(100) NOT NULL,
  `description` text,
  `is_enabled` tinyint(1) DEFAULT '0',
  `is_new` tinyint(1) DEFAULT '0',
  `version_tag` varchar(50) DEFAULT 'v_current',
  `category` varchar(100) DEFAULT 'general',
  `priority` int DEFAULT '0',
  `date_added` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `expires_at` timestamp NULL DEFAULT NULL,
  `flag_type` enum('boolean','percentage','user_list','variant') DEFAULT 'boolean',
  `variant_data` json DEFAULT NULL,
  `rollout_percentage` int DEFAULT '0',
  `enabled_users` json DEFAULT NULL,
  `notes` text,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_flag_school` (`school_id`,`flag_key`),
  KEY `idx_flag_enabled` (`is_enabled`,`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `fee_invoices`
--

DROP TABLE IF EXISTS `fee_invoices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `fee_invoices` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `school_id` bigint DEFAULT NULL,
  `invoice_no` varchar(50) NOT NULL,
  `student_id` bigint NOT NULL,
  `academic_year_id` bigint DEFAULT NULL,
  `term_id` bigint DEFAULT NULL,
  `fee_structure_id` bigint DEFAULT NULL,
  `total_amount` decimal(14,2) DEFAULT '0.00',
  `discount_amount` decimal(14,2) DEFAULT '0.00',
  `waive_amount` decimal(14,2) DEFAULT '0.00',
  `paid_amount` decimal(14,2) DEFAULT '0.00',
  `balance_amount` decimal(14,2) DEFAULT '0.00',
  `status` enum('draft','issued','partial','paid','overdue','cancelled') DEFAULT 'draft',
  `issue_date` date DEFAULT NULL,
  `due_date` date DEFAULT NULL,
  `notes` text,
  `created_by` bigint DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_finv_school` (`school_id`),
  KEY `idx_finv_student` (`student_id`),
  KEY `idx_finv_status` (`status`),
  KEY `idx_finv_no` (`invoice_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='Fee invoices';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `fee_payment_allocations`
--

DROP TABLE IF EXISTS `fee_payment_allocations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `fee_payment_allocations` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `payment_id` bigint NOT NULL,
  `fee_item_id` bigint NOT NULL,
  `allocated_amount` decimal(14,2) NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_payment` (`payment_id`),
  KEY `idx_fee_item` (`fee_item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `fee_payments`
--

DROP TABLE IF EXISTS `fee_payments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `fee_payments` (
  `id` bigint NOT NULL,
  `student_id` bigint NOT NULL,
  `fee_item_id` bigint DEFAULT NULL,
  `term_id` bigint NOT NULL,
  `multi_term_ids` json DEFAULT NULL,
  `wallet_id` bigint NOT NULL,
  `amount` decimal(14,2) NOT NULL,
  `method` varchar(30) DEFAULT NULL,
  `discount_type` enum('percentage','fixed') DEFAULT NULL,
  `discount_reason` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `approved_by` bigint DEFAULT NULL,
  `approved_at` timestamp NULL DEFAULT NULL,
  `receipt_url` varchar(255) DEFAULT NULL,
  `invoice_url` varchar(255) DEFAULT NULL,
  `notes` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `paid_by` varchar(150) DEFAULT NULL,
  `payer_contact` varchar(50) DEFAULT NULL,
  `reference` varchar(120) DEFAULT NULL,
  `receipt_no` varchar(40) DEFAULT NULL,
  `payment_status` enum('pending','completed','failed','refunded') DEFAULT 'completed',
  `gateway_reference` varchar(255) DEFAULT NULL,
  `gateway_response` json DEFAULT NULL,
  `mpesa_receipt` varchar(100) DEFAULT NULL,
  `phone_number` varchar(20) DEFAULT NULL,
  `ledger_id` bigint DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY `idx_fp_student` (`student_id`),
  KEY `idx_fp_status` (`payment_status`),
  KEY `idx_fp_date` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `fee_structures`
--

DROP TABLE IF EXISTS `fee_structures`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `fee_structures` (
  `id` bigint NOT NULL,
  `school_id` bigint NOT NULL,
  `class_id` bigint NOT NULL,
  `section_id` bigint DEFAULT NULL,
  `term_id` bigint NOT NULL,
  `academic_year` varchar(9) DEFAULT NULL,
  `item` varchar(120) NOT NULL,
  `fee_type` enum('tuition','uniform','transport','boarding','examination','activity','books','other') DEFAULT 'tuition',
  `is_mandatory` tinyint(1) DEFAULT '1',
  `amount` decimal(14,2) NOT NULL,
  `description` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `due_date` date DEFAULT NULL,
  `late_fee_amount` decimal(14,2) DEFAULT '0.00',
  `is_active` tinyint(1) DEFAULT '1',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY `idx_fs_class` (`class_id`),
  KEY `idx_fs_year` (`academic_year`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `finance_categories`
--

DROP TABLE IF EXISTS `finance_categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `finance_categories` (
  `id` bigint NOT NULL,
  `school_id` bigint NOT NULL,
  `type` varchar(20) NOT NULL,
  `category_type` enum('income','expense','transfer') DEFAULT 'income',
  `parent_id` bigint DEFAULT NULL,
  `is_system` tinyint(1) DEFAULT '0',
  `color` varchar(20) DEFAULT '#3B82F6',
  `icon` varchar(50) DEFAULT 'DollarSign',
  `is_active` tinyint(1) DEFAULT '1',
  `name` varchar(120) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `financial_reports`
--

DROP TABLE IF EXISTS `financial_reports`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `financial_reports` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `school_id` bigint DEFAULT NULL,
  `report_type` enum('income_statement','balance_sheet','cash_flow','fee_collection','expense_analysis','budget_variance') DEFAULT 'income_statement',
  `report_name` varchar(150) DEFAULT NULL,
  `report_period` enum('daily','weekly','monthly','term','yearly') DEFAULT 'monthly',
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `academic_year_id` bigint DEFAULT NULL,
  `term_id` bigint DEFAULT NULL,
  `report_data` json DEFAULT NULL,
  `generated_by` bigint DEFAULT NULL,
  `generated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `status` enum('generating','completed','failed') DEFAULT 'completed',
  `error_message` text,
  PRIMARY KEY (`id`),
  KEY `idx_frep_school` (`school_id`),
  KEY `idx_frep_type` (`report_type`),
  KEY `idx_frep_period` (`start_date`,`end_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='Financial reports storage';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `fingerprints`
--

DROP TABLE IF EXISTS `fingerprints`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `fingerprints` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `school_id` bigint DEFAULT NULL,
  `student_id` bigint DEFAULT NULL,
  `staff_id` bigint DEFAULT NULL,
  `fingerprint_data` longblob NOT NULL,
  `finger_position` varchar(20) DEFAULT NULL,
  `quality_score` int DEFAULT NULL,
  `enrollment_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `is_verified` tinyint(1) DEFAULT '0',
  `verified_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_student` (`student_id`),
  KEY `idx_staff` (`staff_id`),
  KEY `idx_school` (`school_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ledger`
--

DROP TABLE IF EXISTS `ledger`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ledger` (
  `id` bigint NOT NULL,
  `school_id` bigint NOT NULL,
  `wallet_id` bigint NOT NULL,
  `category_id` bigint NOT NULL,
  `tx_type` varchar(10) NOT NULL,
  `amount` decimal(14,2) NOT NULL,
  `reference` varchar(120) DEFAULT NULL,
  `description` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `student_id` bigint DEFAULT NULL,
  `staff_id` bigint DEFAULT NULL,
  `created_by` bigint DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ledger_accounts`
--

DROP TABLE IF EXISTS `ledger_accounts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ledger_accounts` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `school_id` bigint DEFAULT NULL,
  `account_code` varchar(50) NOT NULL,
  `account_name` varchar(150) NOT NULL,
  `account_type` enum('asset','liability','income','expense','equity') DEFAULT 'asset',
  `account_subtype` varchar(50) DEFAULT NULL,
  `parent_id` bigint DEFAULT NULL,
  `balance_type` enum('debit','credit') DEFAULT 'debit',
  `opening_balance` decimal(14,2) DEFAULT '0.00',
  `current_balance` decimal(14,2) DEFAULT '0.00',
  `currency` varchar(10) DEFAULT 'TZS',
  `is_active` tinyint(1) DEFAULT '1',
  `is_system` tinyint(1) DEFAULT '0',
  `description` text,
  `created_by` bigint DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_ledger_school` (`school_id`),
  KEY `idx_ledger_code` (`account_code`),
  KEY `idx_ledger_type` (`account_type`),
  KEY `idx_ledger_parent` (`parent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='General ledger accounts';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ledger_entries`
--

DROP TABLE IF EXISTS `ledger_entries`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ledger_entries` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `school_id` bigint DEFAULT NULL,
  `transaction_id` bigint NOT NULL,
  `account_id` bigint NOT NULL,
  `entry_date` date DEFAULT NULL,
  `description` text,
  `debit_amount` decimal(14,2) DEFAULT '0.00',
  `credit_amount` decimal(14,2) DEFAULT '0.00',
  `balance_after` decimal(14,2) DEFAULT NULL,
  `currency` varchar(10) DEFAULT 'TZS',
  `reference_type` varchar(50) DEFAULT NULL,
  `reference_id` bigint DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_lent_school` (`school_id`),
  KEY `idx_lent_transaction` (`transaction_id`),
  KEY `idx_lent_account` (`account_id`),
  KEY `idx_lent_date` (`entry_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='General ledger entries';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ledger_transactions`
--

DROP TABLE IF EXISTS `ledger_transactions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ledger_transactions` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `school_id` bigint DEFAULT NULL,
  `transaction_no` varchar(50) NOT NULL,
  `transaction_date` date DEFAULT NULL,
  `transaction_type` enum('journal','payment','receipt','adjustment','transfer') DEFAULT 'journal',
  `description` text,
  `reference_no` varchar(100) DEFAULT NULL,
  `reference_type` varchar(50) DEFAULT NULL,
  `reference_id` bigint DEFAULT NULL,
  `total_amount` decimal(14,2) DEFAULT '0.00',
  `status` enum('draft','posted','voided') DEFAULT 'draft',
  `posted_by` bigint DEFAULT NULL,
  `posted_at` timestamp NULL DEFAULT NULL,
  `created_by` bigint DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_ltrx_school` (`school_id`),
  KEY `idx_ltrx_no` (`transaction_no`),
  KEY `idx_ltrx_date` (`transaction_date`),
  KEY `idx_ltrx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='General ledger transactions';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `living_statuses`
--

DROP TABLE IF EXISTS `living_statuses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `living_statuses` (
  `id` tinyint NOT NULL,
  `code` varchar(20) NOT NULL,
  `label` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `manual_attendance_entries`
--

DROP TABLE IF EXISTS `manual_attendance_entries`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `manual_attendance_entries` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `school_id` bigint NOT NULL,
  `daily_attendance_id` bigint NOT NULL,
  `person_type` enum('student','teacher') COLLATE utf8mb4_unicode_ci NOT NULL,
  `person_id` bigint NOT NULL,
  `attendance_date` date NOT NULL,
  `status` enum('present','late','absent','excused','on_leave') COLLATE utf8mb4_unicode_ci NOT NULL,
  `arrival_time` time DEFAULT NULL,
  `departure_time` time DEFAULT NULL,
  `reason` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `notes` text COLLATE utf8mb4_unicode_ci,
  `override_type` enum('status_change','new_entry','excuse_update','time_correction') COLLATE utf8mb4_unicode_ci DEFAULT 'status_change',
  `previous_status` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `previous_arrival_time` time DEFAULT NULL,
  `previous_departure_time` time DEFAULT NULL,
  `created_by_user_id` bigint DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `deleted_by_user_id` bigint DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_school_id` (`school_id`),
  KEY `idx_daily_attendance` (`daily_attendance_id`),
  KEY `idx_person` (`person_type`,`person_id`),
  KEY `idx_attendance_date` (`attendance_date`),
  KEY `idx_created_by` (`created_by_user_id`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `mobile_money_transactions`
--

DROP TABLE IF EXISTS `mobile_money_transactions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `mobile_money_transactions` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `school_id` bigint DEFAULT NULL,
  `student_id` bigint DEFAULT NULL,
  `transaction_type` enum('deposit','withdrawal','payment','refund') DEFAULT 'payment',
  `provider` enum('mpesa','airtel','tigo','vodacom','other') DEFAULT 'mpesa',
  `phone_number` varchar(20) DEFAULT NULL,
  `amount` decimal(14,2) DEFAULT '0.00',
  `currency` varchar(10) DEFAULT 'TZS',
  `transaction_ref` varchar(100) DEFAULT NULL,
  `conversation_id` varchar(100) DEFAULT NULL,
  `original_transaction_id` varchar(100) DEFAULT NULL,
  `transaction_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `status` enum('pending','processing','completed','failed','cancelled') DEFAULT 'pending',
  `result_code` varchar(20) DEFAULT NULL,
  `result_desc` text,
  `balance` decimal(14,2) DEFAULT NULL,
  `receipt_url` varchar(255) DEFAULT NULL,
  `metadata` json DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_momo_school` (`school_id`),
  KEY `idx_momo_student` (`student_id`),
  KEY `idx_momo_provider` (`provider`),
  KEY `idx_momo_status` (`status`),
  KEY `idx_momo_ref` (`transaction_ref`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='Mobile money transaction tracking';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nationalities`
--

DROP TABLE IF EXISTS `nationalities`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `nationalities` (
  `id` int NOT NULL,
  `code` varchar(3) NOT NULL,
  `name` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `notification_preferences`
--

DROP TABLE IF EXISTS `notification_preferences`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notification_preferences` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL,
  `school_id` bigint DEFAULT NULL,
  `channel` varchar(50) NOT NULL,
  `enabled` tinyint(1) DEFAULT '1',
  `do_not_disturb` tinyint(1) DEFAULT '0',
  `dnd_until` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_user_channel` (`user_id`,`channel`),
  KEY `idx_preferences_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='User notification preferences';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `notification_queue`
--

DROP TABLE IF EXISTS `notification_queue`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notification_queue` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `notification_id` bigint NOT NULL,
  `recipient_user_id` bigint DEFAULT NULL,
  `channel` varchar(50) DEFAULT 'in_app',
  `attempts` int DEFAULT '0',
  `max_attempts` int DEFAULT '3',
  `last_attempt_at` timestamp NULL DEFAULT NULL,
  `next_attempt_at` timestamp NULL DEFAULT NULL,
  `status` enum('pending','sent','failed','cancelled') DEFAULT 'pending',
  `payload` json DEFAULT NULL,
  `error_message` text,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_queue_status` (`status`,`next_attempt_at`),
  KEY `idx_queue_recipient` (`recipient_user_id`),
  KEY `idx_queue_notification` (`notification_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='Notification delivery queue';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `notification_templates`
--

DROP TABLE IF EXISTS `notification_templates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notification_templates` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `school_id` bigint DEFAULT NULL,
  `code` varchar(120) NOT NULL,
  `title_template` varchar(255) DEFAULT NULL,
  `message_template` text,
  `default_channel` varchar(50) DEFAULT 'in_app',
  `priority` enum('low','normal','high','critical') DEFAULT 'normal',
  `is_system` tinyint(1) DEFAULT '0',
  `is_active` tinyint(1) DEFAULT '1',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_template_code` (`school_id`,`code`),
  KEY `idx_templates_system` (`is_system`,`is_active`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb3 COMMENT='Reusable notification templates';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `notifications`
--

DROP TABLE IF EXISTS `notifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notifications` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `school_id` bigint DEFAULT NULL,
  `actor_user_id` bigint DEFAULT NULL,
  `action` varchar(120) NOT NULL,
  `entity_type` varchar(50) DEFAULT NULL,
  `entity_id` bigint DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `message` text,
  `metadata` json DEFAULT NULL,
  `priority` enum('low','normal','high','critical') DEFAULT 'normal',
  `channel` varchar(50) DEFAULT 'in_app',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `read_count` int DEFAULT '0',
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_notifications_school_created` (`school_id`,`created_at`),
  KEY `idx_notifications_actor` (`actor_user_id`),
  KEY `idx_notifications_action` (`action`),
  KEY `idx_notifications_entity` (`entity_type`,`entity_id`),
  KEY `idx_notifications_priority` (`priority`,`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='Core notifications storage';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `orphan_statuses`
--

DROP TABLE IF EXISTS `orphan_statuses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `orphan_statuses` (
  `id` tinyint NOT NULL,
  `code` varchar(20) NOT NULL,
  `label` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `parishes`
--

DROP TABLE IF EXISTS `parishes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `parishes` (
  `id` bigint NOT NULL,
  `subcounty_id` bigint NOT NULL,
  `name` varchar(150) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `password_resets`
--

DROP TABLE IF EXISTS `password_resets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `password_resets` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL,
  `token` varchar(255) NOT NULL,
  `expires_at` timestamp NOT NULL,
  `used` tinyint(1) DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `token` (`token`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_token` (`token`),
  KEY `idx_expires` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `payroll_definitions`
--

DROP TABLE IF EXISTS `payroll_definitions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `payroll_definitions` (
  `id` bigint NOT NULL,
  `school_id` bigint NOT NULL,
  `name` varchar(120) NOT NULL,
  `type` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `people`
--

DROP TABLE IF EXISTS `people`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `people` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `school_id` bigint DEFAULT NULL,
  `first_name` varchar(100) NOT NULL,
  `last_name` varchar(100) NOT NULL,
  `other_name` varchar(100) DEFAULT NULL,
  `gender` varchar(15) DEFAULT NULL,
  `date_of_birth` date DEFAULT NULL,
  `phone` varchar(30) DEFAULT NULL,
  `email` varchar(150) DEFAULT NULL,
  `address` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `photo_url` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=681 DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `permissions`
--

DROP TABLE IF EXISTS `permissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `permissions` (
  `id` bigint NOT NULL,
  `code` varchar(120) NOT NULL,
  `description` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `promotion_audit_log`
--

DROP TABLE IF EXISTS `promotion_audit_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `promotion_audit_log` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `school_id` bigint NOT NULL DEFAULT '1',
  `promotion_id` bigint DEFAULT NULL,
  `student_id` bigint NOT NULL,
  `action_type` enum('promoted','demoted','dropped','status_changed','criteria_applied','cancelled') NOT NULL,
  `from_class_id` bigint DEFAULT NULL,
  `to_class_id` bigint DEFAULT NULL,
  `from_academic_year_id` bigint DEFAULT NULL,
  `to_academic_year_id` bigint DEFAULT NULL,
  `status_before` varchar(50) DEFAULT NULL,
  `status_after` varchar(50) DEFAULT NULL,
  `criteria_applied` json DEFAULT NULL,
  `performed_by` bigint NOT NULL,
  `reason` text,
  `ip_address` varchar(45) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_school_id` (`school_id`),
  KEY `idx_student_id` (`student_id`),
  KEY `idx_action_type` (`action_type`),
  KEY `idx_performed_by` (`performed_by`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `promotion_criteria`
--

DROP TABLE IF EXISTS `promotion_criteria`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `promotion_criteria` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `school_id` bigint NOT NULL DEFAULT '1',
  `name` varchar(100) NOT NULL,
  `description` text,
  `criteria_type` enum('marks','average','attendance','conduct','custom') DEFAULT 'marks',
  `condition_json` json NOT NULL,
  `is_active` tinyint(1) DEFAULT '1',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_school_id` (`school_id`),
  KEY `idx_is_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `promotions`
--

DROP TABLE IF EXISTS `promotions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `promotions` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `school_id` bigint NOT NULL DEFAULT '1',
  `student_id` bigint NOT NULL,
  `from_class_id` bigint DEFAULT '0',
  `to_class_id` bigint NOT NULL,
  `from_academic_year_id` bigint DEFAULT NULL,
  `to_academic_year_id` bigint DEFAULT NULL,
  `promotion_status` enum('promoted','not_promoted','pending','deferred') DEFAULT 'pending',
  `criteria_used` json DEFAULT NULL,
  `remarks` text,
  `promoted_by` bigint DEFAULT NULL,
  `approval_status` enum('pending','approved','rejected') DEFAULT 'pending',
  `approved_by` bigint DEFAULT NULL,
  `term_used` varchar(50) DEFAULT NULL,
  `promotion_reason` enum('criteria_based','manual','appeal','correction') DEFAULT 'manual',
  `prerequisite_met` tinyint(1) DEFAULT '1',
  `additional_notes` text,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_promotion_cycle` (`school_id`,`student_id`,`from_academic_year_id`),
  KEY `idx_school_id` (`school_id`),
  KEY `idx_student_id` (`student_id`),
  KEY `idx_from_class` (`from_class_id`),
  KEY `idx_to_class` (`to_class_id`),
  KEY `idx_promotion_status` (`promotion_status`),
  KEY `idx_approval_status` (`approval_status`),
  KEY `idx_promoted_by` (`promoted_by`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `receipts`
--

DROP TABLE IF EXISTS `receipts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `receipts` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `school_id` bigint DEFAULT NULL,
  `student_id` bigint DEFAULT NULL,
  `payment_id` bigint DEFAULT NULL,
  `receipt_no` varchar(60) NOT NULL,
  `invoice_no` varchar(60) DEFAULT NULL,
  `amount` decimal(14,2) NOT NULL,
  `payment_method` varchar(30) DEFAULT NULL,
  `reference` varchar(120) DEFAULT NULL,
  `payer_name` varchar(150) DEFAULT NULL,
  `payer_contact` varchar(50) DEFAULT NULL,
  `notes` text,
  `file_url` varchar(255) DEFAULT NULL,
  `qr_code_data` text,
  `invoice_url` varchar(255) DEFAULT NULL,
  `metadata` json DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_receipts_school` (`school_id`),
  KEY `idx_receipts_student` (`student_id`),
  KEY `idx_receipts_no` (`receipt_no`),
  KEY `idx_receipts_date` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='Receipt tracking';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `report_card_metrics`
--

DROP TABLE IF EXISTS `report_card_metrics`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `report_card_metrics` (
  `report_card_id` bigint NOT NULL,
  `total_score` decimal(7,2) DEFAULT NULL,
  `average_score` decimal(5,2) DEFAULT NULL,
  `min_score` decimal(5,2) DEFAULT NULL,
  `max_score` decimal(5,2) DEFAULT NULL,
  `position` int DEFAULT NULL,
  `promoted` tinyint(1) DEFAULT '0',
  `promotion_class_id` bigint DEFAULT NULL,
  `computed_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `report_card_subjects`
--

DROP TABLE IF EXISTS `report_card_subjects`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `report_card_subjects` (
  `id` bigint NOT NULL,
  `report_card_id` bigint NOT NULL,
  `subject_id` bigint NOT NULL,
  `total_score` decimal(5,2) DEFAULT NULL,
  `grade` varchar(10) DEFAULT NULL,
  `remarks` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `position` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `report_cards`
--

DROP TABLE IF EXISTS `report_cards`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `report_cards` (
  `id` bigint NOT NULL,
  `student_id` bigint NOT NULL,
  `term_id` bigint NOT NULL,
  `overall_grade` varchar(10) DEFAULT NULL,
  `class_teacher_comment` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `headteacher_comment` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `dos_comment` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `requirements_master`
--

DROP TABLE IF EXISTS `requirements_master`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `requirements_master` (
  `id` bigint NOT NULL,
  `school_id` bigint NOT NULL,
  `name` varchar(120) NOT NULL,
  `description` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `result_types`
--

DROP TABLE IF EXISTS `result_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `result_types` (
  `id` bigint NOT NULL,
  `school_id` bigint NOT NULL,
  `name` varchar(120) NOT NULL,
  `code` varchar(60) DEFAULT NULL,
  `description` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `weight` decimal(5,2) DEFAULT NULL,
  `deadline` varchar(255) DEFAULT NULL,
  `status` varchar(20) DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `results`
--

DROP TABLE IF EXISTS `results`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `results` (
  `id` bigint NOT NULL,
  `exam_id` bigint NOT NULL,
  `student_id` bigint NOT NULL,
  `score` decimal(5,2) DEFAULT NULL,
  `grade` varchar(5) DEFAULT NULL,
  `remarks` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `role_permissions`
--

DROP TABLE IF EXISTS `role_permissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `role_permissions` (
  `role_id` bigint NOT NULL,
  `permission_id` bigint NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `roles`
--

DROP TABLE IF EXISTS `roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `roles` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `school_id` bigint NOT NULL,
  `name` varchar(80) NOT NULL,
  `description` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `salary_payments`
--

DROP TABLE IF EXISTS `salary_payments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `salary_payments` (
  `id` bigint NOT NULL,
  `staff_id` bigint NOT NULL,
  `wallet_id` bigint NOT NULL,
  `amount` decimal(14,2) NOT NULL,
  `method` varchar(30) DEFAULT NULL,
  `reference` varchar(120) DEFAULT NULL,
  `ledger_id` bigint DEFAULT NULL,
  `paid_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `school_info`
--

DROP TABLE IF EXISTS `school_info`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `school_info` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `school_id` bigint NOT NULL DEFAULT '1',
  `school_name` varchar(255) NOT NULL,
  `school_motto` varchar(255) DEFAULT NULL,
  `school_address` text,
  `school_contact` varchar(20) DEFAULT NULL,
  `school_email` varchar(255) DEFAULT NULL,
  `school_logo` varchar(255) DEFAULT NULL,
  `registration_number` varchar(100) DEFAULT NULL,
  `website` varchar(255) DEFAULT NULL,
  `founded_year` int DEFAULT NULL,
  `principal_name` varchar(255) DEFAULT NULL,
  `principal_email` varchar(255) DEFAULT NULL,
  `principal_phone` varchar(20) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_school` (`school_id`),
  KEY `idx_school_id` (`school_id`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `school_settings`
--

DROP TABLE IF EXISTS `school_settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `school_settings` (
  `id` bigint NOT NULL,
  `school_id` bigint NOT NULL,
  `key_name` varchar(120) NOT NULL,
  `value_text` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `schools`
--

DROP TABLE IF EXISTS `schools`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `schools` (
  `id` bigint NOT NULL,
  `name` varchar(150) NOT NULL,
  `legal_name` varchar(200) DEFAULT NULL,
  `short_code` varchar(50) DEFAULT NULL,
  `email` varchar(150) DEFAULT NULL,
  `phone` varchar(30) DEFAULT NULL,
  `currency` varchar(10) DEFAULT 'UGX',
  `address` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `logo_url` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `staff`
--

DROP TABLE IF EXISTS `staff`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `staff` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `school_id` bigint NOT NULL,
  `branch_id` bigint DEFAULT '1',
  `person_id` bigint NOT NULL,
  `staff_no` varchar(50) DEFAULT NULL,
  `department_id` bigint DEFAULT NULL,
  `role_id` bigint DEFAULT NULL,
  `position` varchar(100) DEFAULT NULL,
  `employment_type` enum('permanent','contract','volunteer','part-time') DEFAULT 'permanent',
  `qualification` varchar(255) DEFAULT NULL,
  `experience_years` int DEFAULT '0',
  `hire_date` date DEFAULT NULL,
  `salary` decimal(14,2) DEFAULT NULL,
  `bank_name` varchar(150) DEFAULT NULL,
  `bank_account_no` varchar(100) DEFAULT NULL,
  `nssf_no` varchar(100) DEFAULT NULL,
  `tin_no` varchar(100) DEFAULT NULL,
  `status` varchar(20) DEFAULT 'active',
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `staff_attendance`
--

DROP TABLE IF EXISTS `staff_attendance`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `staff_attendance` (
  `id` bigint NOT NULL,
  `staff_id` bigint NOT NULL,
  `date` date NOT NULL,
  `status` varchar(20) DEFAULT 'present',
  `notes` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `staff_salaries`
--

DROP TABLE IF EXISTS `staff_salaries`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `staff_salaries` (
  `id` bigint NOT NULL,
  `staff_id` bigint NOT NULL,
  `month` year DEFAULT NULL,
  `period_month` tinyint DEFAULT NULL,
  `definition_id` bigint NOT NULL,
  `amount` decimal(14,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `streams`
--

DROP TABLE IF EXISTS `streams`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `streams` (
  `id` bigint NOT NULL,
  `school_id` bigint NOT NULL,
  `class_id` bigint NOT NULL,
  `name` varchar(50) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `student_attendance`
--

DROP TABLE IF EXISTS `student_attendance`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `student_attendance` (
  `id` bigint NOT NULL,
  `student_id` bigint NOT NULL,
  `date` date NOT NULL,
  `status` varchar(20) DEFAULT 'present',
  `method` varchar(50) DEFAULT 'manual',
  `time_in` time DEFAULT NULL,
  `time_out` time DEFAULT NULL,
  `notes` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `marked_at` timestamp NULL DEFAULT NULL,
  `marked_by` int DEFAULT NULL,
  `attendance_session_id` bigint DEFAULT NULL COMMENT 'Link to attendance session',
  `term_id` bigint DEFAULT NULL COMMENT 'Academic term',
  `academic_year_id` bigint DEFAULT NULL COMMENT 'Academic year',
  `stream_id` bigint DEFAULT NULL COMMENT 'Student stream/section',
  `subject_id` bigint DEFAULT NULL COMMENT 'Subject (if applicable)',
  `teacher_id` bigint DEFAULT NULL COMMENT 'Teacher who took attendance',
  `device_id` bigint DEFAULT NULL COMMENT 'Biometric device ID',
  `biometric_timestamp` timestamp NULL DEFAULT NULL COMMENT 'Biometric capture timestamp',
  `confidence_score` decimal(5,2) DEFAULT NULL COMMENT 'Biometric confidence score',
  `override_reason` text COMMENT 'Reason for admin override',
  `is_locked` tinyint(1) DEFAULT '0' COMMENT 'Attendance locked status',
  `locked_at` timestamp NULL DEFAULT NULL COMMENT 'When attendance was locked',
  KEY `idx_session` (`attendance_session_id`),
  KEY `idx_device` (`device_id`),
  KEY `idx_is_locked` (`is_locked`),
  KEY `idx_biometric_timestamp` (`biometric_timestamp`),
  KEY `idx_stream` (`stream_id`),
  KEY `idx_teacher` (`teacher_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `student_contacts`
--

DROP TABLE IF EXISTS `student_contacts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `student_contacts` (
  `student_id` bigint NOT NULL,
  `contact_id` bigint NOT NULL,
  `relationship` varchar(50) DEFAULT NULL,
  `is_primary` tinyint(1) DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `student_curriculums`
--

DROP TABLE IF EXISTS `student_curriculums`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `student_curriculums` (
  `student_id` bigint NOT NULL,
  `curriculum_id` tinyint NOT NULL,
  `active` tinyint(1) DEFAULT '1',
  `assigned_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `student_education_levels`
--

DROP TABLE IF EXISTS `student_education_levels`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `student_education_levels` (
  `id` bigint NOT NULL,
  `student_id` bigint NOT NULL,
  `education_type` varchar(20) NOT NULL,
  `level_name` varchar(120) NOT NULL,
  `institution` varchar(150) DEFAULT NULL,
  `year_completed` year DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `student_family_status`
--

DROP TABLE IF EXISTS `student_family_status`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `student_family_status` (
  `student_id` bigint NOT NULL,
  `orphan_status_id` tinyint DEFAULT NULL,
  `primary_guardian_name` varchar(150) DEFAULT NULL,
  `primary_guardian_contact` varchar(60) DEFAULT NULL,
  `primary_guardian_occupation` varchar(120) DEFAULT NULL,
  `father_name` varchar(150) DEFAULT NULL,
  `father_living_status_id` tinyint DEFAULT NULL,
  `father_occupation` varchar(120) DEFAULT NULL,
  `father_contact` varchar(60) DEFAULT NULL,
  `notes` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `student_fee_items`
--

DROP TABLE IF EXISTS `student_fee_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `student_fee_items` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `student_id` bigint NOT NULL,
  `section_id` bigint DEFAULT NULL,
  `academic_year` varchar(9) DEFAULT NULL,
  `fee_structure_id` bigint DEFAULT NULL,
  `fee_type` varchar(50) DEFAULT NULL,
  `due_date` date DEFAULT NULL,
  `late_fee` decimal(14,2) DEFAULT '0.00',
  `status` enum('pending','partial','paid','overdue','waived') DEFAULT 'pending',
  `waived_by` bigint DEFAULT NULL,
  `waived_reason` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `approved_by` bigint DEFAULT NULL,
  `approved_at` timestamp NULL DEFAULT NULL,
  `last_payment_date` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `term_id` bigint NOT NULL,
  `item` varchar(120) NOT NULL,
  `amount` decimal(14,2) NOT NULL,
  `discount` decimal(14,2) DEFAULT '0.00',
  `paid` decimal(14,2) DEFAULT '0.00',
  `balance` decimal(14,2) GENERATED ALWAYS AS (((`amount` - `discount`) - `paid`)) STORED,
  PRIMARY KEY (`id`),
  KEY `idx_sfi_student` (`student_id`),
  KEY `idx_sfi_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `student_fingerprints`
--

DROP TABLE IF EXISTS `student_fingerprints`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `student_fingerprints` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `school_id` bigint NOT NULL DEFAULT '1',
  `student_id` bigint NOT NULL,
  `device_id` bigint DEFAULT NULL,
  `finger_position` enum('thumb','index','middle','ring','pinky','unknown') COLLATE utf8mb4_unicode_ci DEFAULT 'unknown',
  `hand` enum('left','right') COLLATE utf8mb4_unicode_ci DEFAULT 'right',
  `template_data` longblob,
  `template_format` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `biometric_uuid` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `quality_score` int DEFAULT '0',
  `enrollment_timestamp` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `is_active` tinyint(1) DEFAULT '1',
  `status` enum('active','inactive','revoked') COLLATE utf8mb4_unicode_ci DEFAULT 'active',
  `last_matched_at` timestamp NULL DEFAULT NULL,
  `match_count` int DEFAULT '0',
  `notes` text COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_student` (`student_id`),
  KEY `idx_device` (`device_id`),
  KEY `idx_status` (`status`),
  KEY `idx_biometric_uuid` (`biometric_uuid`),
  KEY `idx_student_device` (`student_id`,`device_id`),
  KEY `fk_fingerprints_school` (`school_id`),
  CONSTRAINT `student_fingerprints_ibfk_1` FOREIGN KEY (`school_id`) REFERENCES `schools` (`id`) ON DELETE CASCADE,
  CONSTRAINT `student_fingerprints_ibfk_2` FOREIGN KEY (`student_id`) REFERENCES `students` (`id`) ON DELETE CASCADE,
  CONSTRAINT `student_fingerprints_ibfk_3` FOREIGN KEY (`device_id`) REFERENCES `biometric_devices` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Student biometric fingerprint credentials';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `student_hafz_progress_summary`
--

DROP TABLE IF EXISTS `student_hafz_progress_summary`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `student_hafz_progress_summary` (
  `student_id` bigint NOT NULL,
  `juz_memorized` int DEFAULT '0',
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `student_next_of_kin`
--

DROP TABLE IF EXISTS `student_next_of_kin`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `student_next_of_kin` (
  `id` bigint NOT NULL,
  `student_id` bigint NOT NULL,
  `sequence` tinyint NOT NULL,
  `name` varchar(150) NOT NULL,
  `address` varchar(255) DEFAULT NULL,
  `occupation` varchar(120) DEFAULT NULL,
  `contact` varchar(60) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `student_profiles`
--

DROP TABLE IF EXISTS `student_profiles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `student_profiles` (
  `student_id` bigint NOT NULL,
  `place_of_birth` varchar(150) DEFAULT NULL,
  `place_of_residence` varchar(150) DEFAULT NULL,
  `district_id` bigint DEFAULT NULL,
  `nationality_id` int DEFAULT NULL,
  `passport_document_id` bigint DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `student_requirements`
--

DROP TABLE IF EXISTS `student_requirements`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `student_requirements` (
  `id` bigint NOT NULL,
  `student_id` bigint NOT NULL,
  `term_id` bigint NOT NULL,
  `requirement_id` bigint NOT NULL,
  `brought` tinyint(1) DEFAULT '0',
  `date_reported` date DEFAULT NULL,
  `notes` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `students`
--

DROP TABLE IF EXISTS `students`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `students` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `school_id` bigint DEFAULT NULL,
  `person_id` bigint NOT NULL,
  `class_id` int DEFAULT NULL,
  `theology_class_id` int DEFAULT NULL,
  `admission_no` varchar(50) DEFAULT NULL,
  `village_id` bigint DEFAULT NULL,
  `admission_date` date DEFAULT NULL,
  `status` varchar(20) DEFAULT 'active',
  `promotion_status` enum('promoted','not_promoted','pending') DEFAULT 'pending',
  `last_promoted_at` datetime DEFAULT NULL,
  `previous_class_id` bigint DEFAULT NULL,
  `previous_year_id` bigint DEFAULT NULL,
  `notes` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_students_villages` (`village_id`),
  KEY `idx_promotion_status` (`promotion_status`),
  KEY `idx_last_promoted` (`last_promoted_at`),
  KEY `idx_previous_class` (`previous_class_id`),
  CONSTRAINT `fk_students_villages` FOREIGN KEY (`village_id`) REFERENCES `villages` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=662 DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `subcounties`
--

DROP TABLE IF EXISTS `subcounties`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `subcounties` (
  `id` bigint NOT NULL,
  `county_id` bigint NOT NULL,
  `name` varchar(150) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `subjects`
--

DROP TABLE IF EXISTS `subjects`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `subjects` (
  `id` bigint NOT NULL,
  `school_id` bigint NOT NULL,
  `name` varchar(120) NOT NULL,
  `code` varchar(20) DEFAULT NULL,
  `subject_type` varchar(20) DEFAULT 'core'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tahfiz_attendance`
--

DROP TABLE IF EXISTS `tahfiz_attendance`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tahfiz_attendance` (
  `id` bigint NOT NULL,
  `school_id` bigint NOT NULL,
  `student_id` bigint NOT NULL,
  `group_id` bigint NOT NULL,
  `date` date NOT NULL,
  `status` enum('present','absent','late','excused') DEFAULT 'present',
  `remarks` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `recorded_by` bigint DEFAULT NULL,
  `recorded_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tahfiz_books`
--

DROP TABLE IF EXISTS `tahfiz_books`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tahfiz_books` (
  `id` bigint NOT NULL,
  `school_id` bigint NOT NULL,
  `title` varchar(100) NOT NULL,
  `description` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `total_units` int DEFAULT NULL,
  `unit_type` varchar(50) DEFAULT 'verse',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tahfiz_groups`
--

DROP TABLE IF EXISTS `tahfiz_groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tahfiz_groups` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `school_id` bigint NOT NULL,
  `name` varchar(100) NOT NULL,
  `teacher_id` bigint NOT NULL,
  `notes` text,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_school_id` (`school_id`),
  KEY `idx_teacher_id` (`teacher_id`),
  KEY `idx_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tahfiz_plans`
--

DROP TABLE IF EXISTS `tahfiz_plans`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tahfiz_plans` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `school_id` bigint NOT NULL,
  `book_id` bigint DEFAULT NULL,
  `teacher_id` bigint NOT NULL,
  `class_id` bigint DEFAULT NULL,
  `stream_id` bigint DEFAULT NULL,
  `group_id` bigint DEFAULT NULL,
  `assigned_date` date NOT NULL,
  `portion_text` varchar(255) NOT NULL,
  `portion_unit` varchar(50) DEFAULT 'verse',
  `expected_length` int DEFAULT NULL,
  `type` varchar(20) NOT NULL DEFAULT 'tilawa',
  `notes` text,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_school_date` (`school_id`,`assigned_date`),
  KEY `idx_teacher` (`teacher_id`),
  KEY `idx_book_id` (`book_id`),
  KEY `idx_group_id` (`group_id`),
  KEY `idx_class_id` (`class_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tahfiz_records`
--

DROP TABLE IF EXISTS `tahfiz_records`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tahfiz_records` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `school_id` bigint NOT NULL,
  `plan_id` bigint NOT NULL,
  `student_id` bigint NOT NULL,
  `group_id` bigint DEFAULT NULL,
  `presented` tinyint(1) DEFAULT '0',
  `presented_length` int DEFAULT '0',
  `retention_score` decimal(5,2) DEFAULT NULL,
  `mark` decimal(5,2) DEFAULT NULL,
  `status` varchar(30) DEFAULT 'pending',
  `notes` text,
  `recorded_by` bigint DEFAULT NULL,
  `recorded_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_school_student` (`school_id`,`student_id`),
  KEY `idx_plan` (`plan_id`),
  KEY `idx_student_id` (`student_id`),
  KEY `idx_status` (`status`),
  KEY `idx_recorded_at` (`recorded_at`),
  KEY `fk_tr_group` (`group_id`),
  CONSTRAINT `tahfiz_records_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `students` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tahfiz_records_ibfk_2` FOREIGN KEY (`plan_id`) REFERENCES `tahfiz_plans` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tahfiz_records_ibfk_3` FOREIGN KEY (`group_id`) REFERENCES `tahfiz_groups` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tahfiz_results`
--

DROP TABLE IF EXISTS `tahfiz_results`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tahfiz_results` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `school_id` bigint NOT NULL DEFAULT '1',
  `student_id` bigint NOT NULL,
  `group_id` bigint DEFAULT NULL,
  `term_id` bigint DEFAULT NULL,
  `academic_year_id` bigint DEFAULT NULL,
  `portion_id` bigint DEFAULT NULL,
  `result_date` date DEFAULT NULL,
  `pages_memorized` int DEFAULT '0',
  `pages_reviewed` int DEFAULT '0',
  `juz_completed` int DEFAULT '0',
  `memorization_percentage` decimal(5,2) DEFAULT '0.00',
  `accuracy_score` decimal(5,2) DEFAULT '0.00',
  `overall_score` decimal(5,2) DEFAULT '0.00',
  `remarks` text,
  `recorded_by` bigint DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_school_student` (`school_id`,`student_id`),
  KEY `idx_result_date` (`result_date`),
  KEY `idx_term_academic_year` (`term_id`,`academic_year_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tahfiz_seven_metrics`
--

DROP TABLE IF EXISTS `tahfiz_seven_metrics`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tahfiz_seven_metrics` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `school_id` bigint NOT NULL DEFAULT '1',
  `result_id` bigint NOT NULL,
  `fluency_score` decimal(5,2) DEFAULT '0.00',
  `accuracy_score` decimal(5,2) DEFAULT '0.00',
  `tajweed_score` decimal(5,2) DEFAULT '0.00',
  `consistency_score` decimal(5,2) DEFAULT '0.00',
  `participation_score` decimal(5,2) DEFAULT '0.00',
  `attitude_score` decimal(5,2) DEFAULT '0.00',
  `improvement_score` decimal(5,2) DEFAULT '0.00',
  `overall_score` decimal(5,2) DEFAULT '0.00',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `result_id` (`result_id`),
  KEY `idx_school_id` (`school_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `terms`
--

DROP TABLE IF EXISTS `terms`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `terms` (
  `id` int NOT NULL AUTO_INCREMENT,
  `school_id` int NOT NULL DEFAULT '1',
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `code` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  `academic_year_id` int DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT '1',
  `notes` text COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_school_id` (`school_id`),
  KEY `idx_academic_year_id` (`academic_year_id`),
  KEY `idx_dates` (`start_date`,`end_date`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `user_notifications`
--

DROP TABLE IF EXISTS `user_notifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_notifications` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `notification_id` bigint NOT NULL,
  `user_id` bigint NOT NULL,
  `school_id` bigint DEFAULT NULL,
  `is_read` tinyint(1) DEFAULT '0',
  `is_archived` tinyint(1) DEFAULT '0',
  `channel` varchar(50) DEFAULT 'in_app',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `read_at` timestamp NULL DEFAULT NULL,
  `archived_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_user_notification` (`notification_id`,`user_id`),
  KEY `idx_user_notifications_user` (`user_id`,`is_read`,`is_archived`),
  KEY `idx_user_notifications_school` (`school_id`,`user_id`),
  KEY `idx_user_notifications_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='Per-user notification state';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `user_sessions`
--

DROP TABLE IF EXISTS `user_sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_sessions` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL,
  `session_token` varchar(255) NOT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` varchar(255) DEFAULT NULL,
  `expires_at` timestamp NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `session_token` (`session_token`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_session_token` (`session_token`),
  KEY `idx_expires_at` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Temporary view structure for view `v_class_attendance_summary`
--

DROP TABLE IF EXISTS `v_class_attendance_summary`;
/*!50001 DROP VIEW IF EXISTS `v_class_attendance_summary`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_class_attendance_summary` AS SELECT 
 1 AS `school_id`,
 1 AS `class_id`,
 1 AS `class_name`,
 1 AS `attendance_date`,
 1 AS `total_students`,
 1 AS `present_count`,
 1 AS `late_count`,
 1 AS `absent_count`,
 1 AS `excused_count`,
 1 AS `attendance_percentage`,
 1 AS `attending_today`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_today_arrivals`
--

DROP TABLE IF EXISTS `v_today_arrivals`;
/*!50001 DROP VIEW IF EXISTS `v_today_arrivals`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_today_arrivals` AS SELECT 
 1 AS `school_id`,
 1 AS `person_id`,
 1 AS `student_id_number`,
 1 AS `student_name`,
 1 AS `class_name`,
 1 AS `status`,
 1 AS `first_arrival_time`,
 1 AS `device_location`,
 1 AS `arrival_status`,
 1 AS `arrival_device_id`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `villages`
--

DROP TABLE IF EXISTS `villages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `villages` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `parish_id` bigint NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` text,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  KEY `idx_villages_parish` (`parish_id`),
  KEY `idx_villages_name` (`name`),
  KEY `idx_villages_deleted` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='Villages table for location hierarchy';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `waivers_discounts`
--

DROP TABLE IF EXISTS `waivers_discounts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `waivers_discounts` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `school_id` bigint DEFAULT NULL,
  `student_id` bigint NOT NULL,
  `term_id` bigint NOT NULL,
  `fee_item_id` bigint DEFAULT NULL,
  `waiver_type` enum('full','partial') DEFAULT 'partial',
  `discount_type` enum('percentage','fixed') DEFAULT 'fixed',
  `amount` decimal(14,2) NOT NULL,
  `reason` text NOT NULL,
  `approved_by` bigint DEFAULT NULL,
  `approved_at` timestamp NULL DEFAULT NULL,
  `status` enum('pending','approved','rejected') DEFAULT 'pending',
  `rejection_reason` text,
  `created_by` bigint DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_waivers_school` (`school_id`),
  KEY `idx_waivers_student` (`student_id`),
  KEY `idx_waivers_term` (`term_id`),
  KEY `idx_waivers_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='Fee waivers and discounts tracking';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Final view structure for view `v_class_attendance_summary`
--

/*!50001 DROP VIEW IF EXISTS `v_class_attendance_summary`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_class_attendance_summary` AS select `c`.`school_id` AS `school_id`,`c`.`id` AS `class_id`,`c`.`name` AS `class_name`,coalesce(cast(`da`.`attendance_date` as date),curdate()) AS `attendance_date`,count(distinct `s`.`id`) AS `total_students`,sum((case when (`da`.`status` in ('present','late')) then 1 else 0 end)) AS `present_count`,sum((case when (`da`.`status` = 'late') then 1 else 0 end)) AS `late_count`,sum((case when (`da`.`status` = 'absent') then 1 else 0 end)) AS `absent_count`,sum((case when (`da`.`status` = 'excused') then 1 else 0 end)) AS `excused_count`,round(((sum((case when (`da`.`status` in ('present','late')) then 1 else 0 end)) / nullif(count(distinct `s`.`id`),0)) * 100),2) AS `attendance_percentage`,count(distinct (case when (`da`.`status` in ('present','late')) then `s`.`id` end)) AS `attending_today` from ((`classes` `c` left join `students` `s` on((`c`.`id` = `s`.`class_id`))) left join `daily_attendance` `da` on((`s`.`id` = (select `daily_attendance`.`person_id` from `daily_attendance` where ((`daily_attendance`.`person_id` = `da`.`person_id`) and (`daily_attendance`.`person_type` = 'student') and (`daily_attendance`.`attendance_date` = curdate())) limit 1)))) where (`c`.`school_id` is not null) group by `c`.`school_id`,`c`.`id`,`c`.`name` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_today_arrivals`
--

/*!50001 DROP VIEW IF EXISTS `v_today_arrivals`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_today_arrivals` AS select `da`.`school_id` AS `school_id`,`da`.`person_id` AS `person_id`,`s`.`admission_no` AS `student_id_number`,concat(`p`.`first_name`,' ',`p`.`last_name`) AS `student_name`,`cl`.`name` AS `class_name`,`da`.`status` AS `status`,`da`.`first_arrival_time` AS `first_arrival_time`,`bd`.`location` AS `device_location`,(case when (`da`.`is_late` = true) then concat(`da`.`late_minutes`,' mins late') else 'On time' end) AS `arrival_status`,`da`.`arrival_device_id` AS `arrival_device_id` from ((((`daily_attendance` `da` left join `students` `s` on((`s`.`id` = (select `students`.`id` from `students` where ((`students`.`person_id` = `da`.`person_id`) and (`da`.`person_type` = 'student')) limit 1)))) left join `people` `p` on((`da`.`person_id` = `p`.`id`))) left join `classes` `cl` on((`s`.`class_id` = `cl`.`id`))) left join `biometric_devices` `bd` on((`da`.`arrival_device_id` = `bd`.`id`))) where ((cast(`da`.`attendance_date` as date) = curdate()) and (`da`.`person_type` = 'student')) order by `da`.`first_arrival_time` desc */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-02-27 18:02:08
