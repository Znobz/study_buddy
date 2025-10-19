CREATE DATABASE IF NOT EXISTS study_buddy;
USE study_buddy;

-- Users
CREATE TABLE IF NOT EXISTS users (
  user_id INT PRIMARY KEY AUTO_INCREMENT,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  academic_level ENUM('high_school','undergraduate','graduate') DEFAULT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Courses
CREATE TABLE IF NOT EXISTS courses (
  course_id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  course_name VARCHAR(255) NOT NULL,
  course_code VARCHAR(50) DEFAULT NULL,
  instructor VARCHAR(255) DEFAULT NULL,
  semester VARCHAR(50) DEFAULT NULL,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Assignments
CREATE TABLE IF NOT EXISTS assignments (
  assignment_id INT PRIMARY KEY AUTO_INCREMENT,
  course_id INT NOT NULL,
  user_id INT NOT NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT DEFAULT NULL,
  due_date DATETIME NOT NULL,
  priority ENUM('low','medium','high') DEFAULT 'medium',
  status ENUM('pending','in_progress','completed') DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (course_id) REFERENCES courses(course_id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Study Sessions
CREATE TABLE IF NOT EXISTS study_sessions (
  session_id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  course_id INT DEFAULT NULL,
  start_time DATETIME NOT NULL,
  end_time DATETIME DEFAULT NULL,
  planned_duration INT DEFAULT NULL COMMENT 'in minutes',
  actual_duration INT DEFAULT NULL COMMENT 'in minutes',
  session_type ENUM('focused','review','assignment') DEFAULT 'focused',
  lockdown_enabled BOOLEAN DEFAULT TRUE,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  FOREIGN KEY (course_id) REFERENCES courses(course_id) ON DELETE SET NULL
);

-- Chat History
CREATE TABLE IF NOT EXISTS chat_history (
  chat_id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  session_id INT DEFAULT NULL,
  question TEXT NOT NULL,
  ai_response TEXT NOT NULL,
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  FOREIGN KEY (session_id) REFERENCES study_sessions(session_id) ON DELETE SET NULL
);

-- Study Materials
CREATE TABLE IF NOT EXISTS study_materials (
  material_id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  course_id INT DEFAULT NULL,
  title VARCHAR(255) NOT NULL,
  file_path VARCHAR(500) DEFAULT NULL,
  material_type ENUM('pdf','notes','slides','video') DEFAULT 'notes',
  uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  FOREIGN KEY (course_id) REFERENCES courses(course_id) ON DELETE SET NULL
);