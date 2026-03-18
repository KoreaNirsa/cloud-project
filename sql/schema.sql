-- HR Core Lite - MySQL 8 Schema
-- 권장 실행 순서: schema.sql -> seed.sql

CREATE DATABASE IF NOT EXISTS hr_core_lite
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE hr_core_lite;

CREATE TABLE departments (
    id BIGINT NOT NULL AUTO_INCREMENT,
    code VARCHAR(30) NOT NULL,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(255) NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_departments PRIMARY KEY (id),
    CONSTRAINT uq_departments_code UNIQUE (code),
    CONSTRAINT uq_departments_name UNIQUE (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE employees (
    id BIGINT NOT NULL AUTO_INCREMENT,
    employee_no VARCHAR(30) NOT NULL,
    login_id VARCHAR(50) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    phone VARCHAR(30) NULL,
    role VARCHAR(20) NOT NULL COMMENT 'EMPLOYEE, MANAGER, ADMIN',
    employment_status VARCHAR(20) NOT NULL COMMENT 'ACTIVE, INACTIVE',
    position_title VARCHAR(100) NULL,
    hire_date DATE NOT NULL,
    annual_leave_quota DECIMAL(4,1) NOT NULL DEFAULT 15.0,
    department_id BIGINT NOT NULL,
    manager_id BIGINT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_employees PRIMARY KEY (id),
    CONSTRAINT uq_employees_employee_no UNIQUE (employee_no),
    CONSTRAINT uq_employees_login_id UNIQUE (login_id),
    CONSTRAINT uq_employees_email UNIQUE (email),
    CONSTRAINT fk_employees_department FOREIGN KEY (department_id) REFERENCES departments(id),
    CONSTRAINT fk_employees_manager FOREIGN KEY (manager_id) REFERENCES employees(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_employees_department_id ON employees (department_id);
CREATE INDEX idx_employees_manager_id ON employees (manager_id);
CREATE INDEX idx_employees_role ON employees (role);

CREATE TABLE holidays (
    id BIGINT NOT NULL AUTO_INCREMENT,
    holiday_date DATE NOT NULL,
    name VARCHAR(100) NOT NULL,
    is_company_holiday BOOLEAN NOT NULL DEFAULT FALSE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_holidays PRIMARY KEY (id),
    CONSTRAINT uq_holidays_holiday_date UNIQUE (holiday_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE attendance_records (
    id BIGINT NOT NULL AUTO_INCREMENT,
    employee_id BIGINT NOT NULL,
    work_date DATE NOT NULL,
    check_in_at DATETIME NULL,
    check_out_at DATETIME NULL,
    status VARCHAR(20) NOT NULL COMMENT 'PRESENT, LATE, REMOTE',
    memo VARCHAR(255) NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_attendance_records PRIMARY KEY (id),
    CONSTRAINT fk_attendance_records_employee FOREIGN KEY (employee_id) REFERENCES employees(id),
    CONSTRAINT uq_attendance_employee_date UNIQUE (employee_id, work_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_attendance_records_work_date ON attendance_records (work_date);

CREATE TABLE leave_types (
    id BIGINT NOT NULL AUTO_INCREMENT,
    code VARCHAR(30) NOT NULL,
    name VARCHAR(50) NOT NULL,
    deducts_from_annual BOOLEAN NOT NULL DEFAULT TRUE,
    color_hex VARCHAR(7) NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_leave_types PRIMARY KEY (id),
    CONSTRAINT uq_leave_types_code UNIQUE (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE leave_requests (
    id BIGINT NOT NULL AUTO_INCREMENT,
    employee_id BIGINT NOT NULL,
    approver_id BIGINT NULL,
    leave_type_id BIGINT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    days DECIMAL(4,1) NOT NULL,
    reason VARCHAR(500) NOT NULL,
    status VARCHAR(20) NOT NULL COMMENT 'REQUESTED, APPROVED, REJECTED, CANCELLED',
    rejection_reason VARCHAR(500) NULL,
    requested_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    decision_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_leave_requests PRIMARY KEY (id),
    CONSTRAINT fk_leave_requests_employee FOREIGN KEY (employee_id) REFERENCES employees(id),
    CONSTRAINT fk_leave_requests_approver FOREIGN KEY (approver_id) REFERENCES employees(id),
    CONSTRAINT fk_leave_requests_leave_type FOREIGN KEY (leave_type_id) REFERENCES leave_types(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_leave_requests_employee_dates ON leave_requests (employee_id, start_date, end_date);
CREATE INDEX idx_leave_requests_approver_status ON leave_requests (approver_id, status);
CREATE INDEX idx_leave_requests_status ON leave_requests (status);

-- 선택 참고:
-- 1) employee를 user와 분리하고 싶다면 users 테이블을 추가해도 됨
-- 2) 감사 로그가 필요하면 audit_logs 테이블 추가
-- 3) 반차/시간차는 days 값 0.5 또는 시간 단위 컬럼으로 확장 가능