# ERD 및 DB 스키마 문서

이 문서는 **HR Core Lite**의 데이터 모델을 설명합니다.  
실제 DDL은 [`../sql/schema.sql`](../sql/schema.sql)에 있습니다.

---

## 1. ERD 개요

![HR System ERD](./images/hr-system-erd.png)

### 관계 요약

```text
Department 1 --- N Employee
Employee   1 --- N AttendanceRecord
Employee   1 --- N LeaveRequest (requester)
Employee   1 --- N LeaveRequest (approver)
LeaveType  1 --- N LeaveRequest
Employee   1 --- N Employee (manager_id 자기참조)
```

---

## 2. 테이블 목록

| 테이블 | 설명 |
|---|---|
| departments | 부서 마스터 |
| employees | 직원 및 로그인 정보 |
| holidays | 공휴일 마스터 |
| attendance_records | 일별 출퇴근 기록 |
| leave_types | 휴가 종류 마스터 |
| leave_requests | 휴가 신청/승인 데이터 |

---

## 3. 설계 원칙

### 3.1 단순화 모델 사용
이번 프로젝트는 기간이 짧기 때문에 `users`와 `employees`를 분리하지 않고  
`employees` 테이블에 로그인 정보까지 포함하는 단순화 모델을 사용합니다.

### 3.2 연차 잔여값은 저장보다 계산 우선
`remaining_annual_leave` 같은 컬럼을 두기보다  
`annual_leave_quota - 승인된 연차 합계`로 계산하는 것을 권장합니다.

### 3.3 결근/휴가 상태는 일부 계산형으로 처리
`ABSENT`, `ON_LEAVE`는 attendance 테이블에 반드시 저장하지 않아도 됩니다.  
달력 또는 월간 조회 API에서 계산해서 보여줄 수 있습니다.

---

## 4. 테이블 상세

## 4.1 departments

| 컬럼 | 타입 | 제약 | 설명 |
|---|---|---|---|
| id | BIGINT | PK | 부서 ID |
| code | VARCHAR(30) | UNIQUE, NOT NULL | 부서 코드 |
| name | VARCHAR(100) | UNIQUE, NOT NULL | 부서명 |
| description | VARCHAR(255) | NULL | 설명 |
| created_at | DATETIME | NOT NULL | 생성일시 |
| updated_at | DATETIME | NOT NULL | 수정일시 |

### 비고
- 부서 코드는 API/프론트에서 식별값처럼 쓸 수 있습니다.
- 예: `HR`, `ENG`, `DESIGN`

---

## 4.2 employees

| 컬럼 | 타입 | 제약 | 설명 |
|---|---|---|---|
| id | BIGINT | PK | 직원 ID |
| employee_no | VARCHAR(30) | UNIQUE, NOT NULL | 사번 |
| login_id | VARCHAR(50) | UNIQUE, NOT NULL | 로그인 ID |
| password_hash | VARCHAR(255) | NOT NULL | 비밀번호 해시 |
| name | VARCHAR(100) | NOT NULL | 이름 |
| email | VARCHAR(100) | UNIQUE, NOT NULL | 이메일 |
| phone | VARCHAR(30) | NULL | 연락처 |
| role | VARCHAR(20) | NOT NULL | `EMPLOYEE`, `MANAGER`, `ADMIN` |
| employment_status | VARCHAR(20) | NOT NULL | `ACTIVE`, `INACTIVE` |
| position_title | VARCHAR(100) | NULL | 직책/직무명 |
| hire_date | DATE | NOT NULL | 입사일 |
| annual_leave_quota | DECIMAL(4,1) | NOT NULL | 연차 부여량 |
| department_id | BIGINT | FK, NOT NULL | 소속 부서 |
| manager_id | BIGINT | FK, NULL | 매니저 직원(상사) ID |
| created_at | DATETIME | NOT NULL | 생성일시 |
| updated_at | DATETIME | NOT NULL | 수정일시 |

### 비고
- `manager_id`는 employees 자기참조(Self Reference)입니다
- `ADMIN`은 `manager_id`가 없을 수 있습니다.
- `employment_status = INACTIVE`이면 로그인 차단을 권장합니다.

---

## 4.3 holidays

| 컬럼 | 타입 | 제약 | 설명 |
|---|---|---|---|
| id | BIGINT | PK | 공휴일 ID |
| holiday_date | DATE | UNIQUE, NOT NULL | 공휴일 날짜 |
| name | VARCHAR(100) | NOT NULL | 공휴일 이름 |
| is_company_holiday | BOOLEAN | NOT NULL | 회사 자체 휴무일 여부 |
| created_at | DATETIME | NOT NULL | 생성일시 |
| updated_at | DATETIME | NOT NULL | 수정일시 |

### 비고
- 법정 공휴일과 회사 휴무일을 모두 표현할 수 있습니다.

---

## 4.4 attendance_records

| 컬럼 | 타입 | 제약 | 설명 |
|---|---|---|---|
| id | BIGINT | PK | 근태 ID |
| employee_id | BIGINT | FK, NOT NULL | 직원 ID |
| work_date | DATE | NOT NULL | 근무 날짜 |
| check_in_at | DATETIME | NULL | 출근 시각 |
| check_out_at | DATETIME | NULL | 퇴근 시각 |
| status | VARCHAR(20) | NOT NULL | `PRESENT`, `LATE`, `REMOTE` 등 |
| memo | VARCHAR(255) | NULL | 메모 |
| created_at | DATETIME | NOT NULL | 생성일시 |
| updated_at | DATETIME | NOT NULL | 수정일시 |

### 중요 제약
- `UNIQUE(employee_id, work_date)`  
  → 같은 직원이 같은 날짜에 중복 출근 기록을 만들지 못하게 함

### 비고
- `ABSENT`는 저장 대신 계산형으로 처리 가능
- `check_out_at`은 처음에는 NULL이고 퇴근 시 채움

---

## 4.5 leave_types

| 컬럼 | 타입 | 제약 | 설명 |
|---|---|---|---|
| id | BIGINT | PK | 휴가 종류 ID |
| code | VARCHAR(30) | UNIQUE, NOT NULL | 휴가 코드 |
| name | VARCHAR(50) | NOT NULL | 휴가명 |
| deducts_from_annual | BOOLEAN | NOT NULL | 연차 차감 여부 |
| color_hex | VARCHAR(7) | NULL | UI 색상 |
| created_at | DATETIME | NOT NULL | 생성일시 |
| updated_at | DATETIME | NOT NULL | 수정일시 |

### 예시 데이터
- `ANNUAL`
- `SICK`
- `OFFICIAL`

---

## 4.6 leave_requests

| 컬럼 | 타입 | 제약 | 설명 |
|---|---|---|---|
| id | BIGINT | PK | 휴가 신청 ID |
| employee_id | BIGINT | FK, NOT NULL | 신청자 |
| approver_id | BIGINT | FK, NULL | 승인자 |
| leave_type_id | BIGINT | FK, NOT NULL | 휴가 종류 |
| start_date | DATE | NOT NULL | 시작일 |
| end_date | DATE | NOT NULL | 종료일 |
| days | DECIMAL(4,1) | NOT NULL | 휴가 일수 |
| reason | VARCHAR(500) | NOT NULL | 신청 사유 |
| status | VARCHAR(20) | NOT NULL | `REQUESTED`, `APPROVED`, `REJECTED`, `CANCELLED` |
| rejection_reason | VARCHAR(500) | NULL | 반려 사유 |
| requested_at | DATETIME | NOT NULL | 신청 시각 |
| decision_at | DATETIME | NULL | 승인/반려 시각 |
| created_at | DATETIME | NOT NULL | 생성일시 |
| updated_at | DATETIME | NOT NULL | 수정일시 |

### 비고
- `approver_id`는 보통 신청자의 매니저가 됩니다.
- `days`는 조회 시 계산해도 되지만, MVP에서는 저장해두면 화면 반영이 편합니다.
- `status`는 승인 흐름의 핵심입니다.

---

## 5. 인덱스 권장 사항

| 테이블 | 인덱스 | 이유 |
|---|---|---|
| employees | idx_employees_department_id | 부서별 직원 조회 |
| employees | idx_employees_manager_id | 팀원 조회 |
| attendance_records | uq_attendance_employee_date | 중복 출근 방지 / 날짜별 조회 |
| leave_requests | idx_leave_requests_employee_dates | 내 휴가 조회, 중복 검증 |
| leave_requests | idx_leave_requests_approver_status | 승인 대기 조회 |
| holidays | uq_holidays_holiday_date | 날짜 중복 방지 |

---

## 6. 상태 값(Enum) 권장

## 6.1 Role
```text
EMPLOYEE
MANAGER
ADMIN
```

## 6.2 EmploymentStatus
```text
ACTIVE
INACTIVE
```

## 6.3 AttendanceStatus
```text
PRESENT
LATE
REMOTE
```

## 6.4 LeaveStatus
```text
REQUESTED
APPROVED
REJECTED
CANCELLED
```

---

## 7. 핵심 제약조건 요약

| 제약 | 설명 |
|---|---|
| employees.employee_no UNIQUE | 사번 중복 방지 |
| employees.login_id UNIQUE | 로그인 ID 중복 방지 |
| employees.email UNIQUE | 이메일 중복 방지 |
| departments.code UNIQUE | 부서 코드 중복 방지 |
| departments.name UNIQUE | 부서명 중복 방지 |
| attendance_records UNIQUE(employee_id, work_date) | 하루 1근태 보장 |
| holidays.holiday_date UNIQUE | 공휴일 중복 방지 |

---

## 8. 데이터 흐름 설명

## 8.1 출근/퇴근
```text
employee
  → attendance_record 생성(출근)
  → attendance_record 수정(퇴근)
```

## 8.2 휴가 신청/승인
```text
employee
  → leave_request 생성(status=REQUESTED)
  → manager/admin 승인(status=APPROVED) 또는 반려(status=REJECTED)
```

## 8.3 남은 연차 조회
```text
employee.annual_leave_quota
  - sum(approved leave_requests where leave_type.deducts_from_annual = true)
```

---

## 9. JPA 매핑 팁

### 권장 연관관계
- `Employee` → `Department` : ManyToOne
- `Employee` → `Employee(manager)` : ManyToOne
- `AttendanceRecord` → `Employee` : ManyToOne
- `LeaveRequest` → `Employee(employee)` : ManyToOne
- `LeaveRequest` → `Employee(approver)` : ManyToOne
- `LeaveRequest` → `LeaveType` : ManyToOne

### 추천 방식
- 양방향 매핑은 꼭 필요한 곳에만 사용
- 응답은 DTO로 분리
- Entity를 그대로 API 응답에 노출하지 않기

---

## 10. SQL 파일 사용 순서

1. `../sql/schema.sql` 실행
2. `../sql/seed.sql` 실행
3. Postman 컬렉션 또는 Swagger로 테스트

---

## 11. 추후 확장 가능한 테이블

아래는 시간이 남을 때 추가할 수 있는 테이블입니다.

- notification
- audit_log
- file_attachment
- salary_statement
- payroll_batch

이번 프로젝트에서는 **확장 설계까지만 고려하고 실제 구현은 생략**하는 것이 좋습니다.