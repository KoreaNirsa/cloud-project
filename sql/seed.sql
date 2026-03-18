USE hr_core_lite;

-- 비밀번호 안내
-- 아래 password_hash 값의 {noop}Passw0rd! 는 데모/학습용입니다.
-- Spring Security에서 DelegatingPasswordEncoder 사용 시 동작할 수 있습니다.
-- 최종 발표 전에는 BCrypt로 교체하는 것을 권장합니다.

INSERT INTO departments (id, code, name, description) VALUES
(1, 'HR', 'HR', '인사팀'),
(2, 'ENG', 'Engineering', '개발 조직'),
(3, 'DESIGN', 'Design', '디자인 조직');

INSERT INTO employees (
    id, employee_no, login_id, password_hash, name, email, phone,
    role, employment_status, position_title, hire_date, annual_leave_quota,
    department_id, manager_id
) VALUES
(1, 'E2026001', 'hr.admin', '{noop}Passw0rd!', '한관리', 'hr.admin@example.com', '010-1000-1000',
 'ADMIN', 'ACTIVE', 'HR Admin', '2024-01-02', 15.0, 1, NULL),
(2, 'E2026002', 'eng.manager', '{noop}Passw0rd!', '김매니저', 'eng.manager@example.com', '010-2000-2000',
 'MANAGER', 'ACTIVE', 'Engineering Manager', '2023-05-01', 15.0, 2, NULL),
(3, 'E2026003', 'eng.employee', '{noop}Passw0rd!', '이직원', 'eng.employee@example.com', '010-3000-3000',
 'EMPLOYEE', 'ACTIVE', 'Backend Developer', '2025-02-03', 15.0, 2, 2),
(4, 'E2026004', 'eng.employee2', '{noop}Passw0rd!', '박직원', 'eng.employee2@example.com', '010-4000-4000',
 'EMPLOYEE', 'ACTIVE', 'Frontend Developer', '2025-06-10', 15.0, 2, 2),
(5, 'E2026005', 'design.member', '{noop}Passw0rd!', '최디자이너', 'design.member@example.com', '010-5000-5000',
 'EMPLOYEE', 'ACTIVE', 'Product Designer', '2025-07-15', 15.0, 3, NULL);

INSERT INTO holidays (id, holiday_date, name, is_company_holiday) VALUES
(1, '2026-01-01', '신정', FALSE),
(2, '2026-03-01', '삼일절', FALSE),
(3, '2026-05-05', '어린이날', FALSE),
(4, '2026-10-09', '한글날', FALSE);

INSERT INTO leave_types (id, code, name, deducts_from_annual, color_hex) VALUES
(1, 'ANNUAL', '연차', TRUE, '#4F46E5'),
(2, 'SICK', '병가', FALSE, '#059669'),
(3, 'OFFICIAL', '공가', FALSE, '#DC2626');

INSERT INTO attendance_records (
    id, employee_id, work_date, check_in_at, check_out_at, status, memo
) VALUES
(1, 2, '2026-03-17', '2026-03-17 09:02:00', '2026-03-17 18:11:00', 'PRESENT', NULL),
(2, 3, '2026-03-17', '2026-03-17 09:18:00', '2026-03-17 18:03:00', 'LATE', NULL),
(3, 4, '2026-03-17', '2026-03-17 08:55:00', '2026-03-17 18:06:00', 'PRESENT', NULL),
(4, 2, '2026-03-18', '2026-03-18 08:59:00', NULL, 'PRESENT', NULL),
(5, 3, '2026-03-18', '2026-03-18 09:10:00', NULL, 'PRESENT', NULL);

INSERT INTO leave_requests (
    id, employee_id, approver_id, leave_type_id, start_date, end_date, days,
    reason, status, rejection_reason, requested_at, decision_at
) VALUES
(1, 3, 2, 1, '2026-02-20', '2026-02-20', 1.0, '개인 일정', 'APPROVED', NULL,
 '2026-02-10 10:00:00', '2026-02-11 11:00:00'),
(2, 4, 2, 1, '2026-03-24', '2026-03-25', 2.0, '가족 행사', 'REQUESTED', NULL,
 '2026-03-18 14:00:00', NULL),
(3, 3, 2, 2, '2026-01-14', '2026-01-14', 1.0, '병원 방문', 'APPROVED', NULL,
 '2026-01-13 15:10:00', '2026-01-13 16:00:00');

-- 데모용 계정
-- hr.admin / Passw0rd!
-- eng.manager / Passw0rd!
-- eng.employee / Passw0rd!