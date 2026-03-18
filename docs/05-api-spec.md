# API 명세서

이 문서는 학생팀이 바로 개발에 들어갈 수 있도록  
**실제 구현 가능한 수준의 REST API 규격**을 정리한 문서입니다.

OpenAPI 원본 파일은 [`../openapi/hr-system-openapi.yaml`](../openapi/hr-system-openapi.yaml) 을 참고하세요.

---

## 1. 공통 규칙

## 1.1 Base URL
```text
Local   : http://localhost:8080/api
Prod    : https://api.example.com/api
```

## 1.2 인증 방식
- MVP 권장: **JWT Bearer Token**
- 로그인 성공 시 access token 발급
- 이후 요청 헤더에 포함

```http
Authorization: Bearer <access-token>
```

> Refresh Token은 확장 포인트입니다.  
> 1~2주 프로젝트라면 access token 단일 방식으로도 충분합니다.

---

## 1.3 공통 응답 형식

### 성공
```json
{
  "success": true,
  "data": {
    "id": 1
  }
}
```

### 실패
```json
{
  "success": false,
  "error": {
    "code": "LEAVE_OVERLAP",
    "message": "이미 겹치는 휴가 신청이 존재합니다."
  }
}
```

---

## 1.4 공통 HTTP 상태 코드

| 상태 코드 | 의미 | 사용 예 |
|---|---|---|
| 200 | 성공 | 조회, 수정 |
| 201 | 생성 성공 | 직원 등록, 휴가 신청 |
| 400 | 잘못된 요청 | 날짜 범위 오류 |
| 401 | 인증 실패 | 로그인 실패, 토큰 없음 |
| 403 | 권한 없음 | 일반 직원이 관리자 API 호출 |
| 404 | 리소스 없음 | 직원/휴가 신청 없음 |
| 409 | 충돌 | 중복 사번, 중복 출근 |
| 422 | 비즈니스 규칙 위반 | 연차 부족, 승인 불가 상태 |

---

## 1.5 역할 표기

| 표기 | 의미 |
|---|---|
| ALL | 로그인 사용자 전체 |
| EMPLOYEE | 일반 직원 |
| MANAGER | 매니저 |
| ADMIN | 관리자 |
| MANAGER/ADMIN | 매니저 또는 관리자 |

---

## 2. 인증(Auth)

## 2.1 로그인
- **POST** `/auth/login`
- 권한: `ALL`

### Request
```json
{
  "loginId": "eng.manager",
  "password": "Passw0rd!"
}
```

### Response
```json
{
  "success": true,
  "data": {
    "accessToken": "jwt-token",
    "employee": {
      "id": 2,
      "name": "김매니저",
      "role": "MANAGER"
    }
  }
}
```

### 실패 코드
- `INVALID_CREDENTIALS`
- `EMPLOYEE_INACTIVE`

---

## 2.2 내 정보 조회
- **GET** `/auth/me`
- 권한: `ALL`

### Response
```json
{
  "success": true,
  "data": {
    "id": 2,
    "employeeNo": "E2026002",
    "name": "김매니저",
    "email": "manager@example.com",
    "role": "MANAGER",
    "department": {
      "id": 2,
      "name": "Engineering"
    }
  }
}
```

---

## 3. 부서(Department)

## 3.1 부서 목록 조회
- **GET** `/departments`
- 권한: `ALL`

### Query Params
| 이름 | 타입 | 필수 | 설명 |
|---|---|---|---|
| keyword | string | N | 부서명/코드 검색 |

### Response
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "code": "HR",
      "name": "HR",
      "description": "인사팀"
    }
  ]
}
```

---

## 3.2 부서 등록
- **POST** `/departments`
- 권한: `ADMIN`

### Request
```json
{
  "code": "ENG",
  "name": "Engineering",
  "description": "개발 조직"
}
```

### 실패 코드
- `DEPARTMENT_CODE_DUPLICATED`
- `DEPARTMENT_NAME_DUPLICATED`

---

## 3.3 부서 수정
- **PATCH** `/departments/{departmentId}`
- 권한: `ADMIN`

### Request
```json
{
  "name": "Engineering Platform",
  "description": "플랫폼 개발 조직"
}
```

---

## 4. 직원(Employee)

## 4.1 직원 목록 조회
- **GET** `/employees`
- 권한: `MANAGER/ADMIN`

### Query Params
| 이름 | 타입 | 필수 | 설명 |
|---|---|---|---|
| departmentId | long | N | 부서 필터 |
| employmentStatus | string | N | ACTIVE / INACTIVE |
| keyword | string | N | 이름/사번 검색 |

### Response
```json
{
  "success": true,
  "data": [
    {
      "id": 3,
      "employeeNo": "E2026003",
      "name": "이직원",
      "role": "EMPLOYEE",
      "employmentStatus": "ACTIVE",
      "department": {
        "id": 2,
        "name": "Engineering"
      },
      "manager": {
        "id": 2,
        "name": "김매니저"
      }
    }
  ]
}
```

---

## 4.2 직원 상세 조회
- **GET** `/employees/{employeeId}`
- 권한: `MANAGER/ADMIN`  
  (본인 상세 조회를 허용하려면 별도 정책 추가 가능)

---

## 4.3 직원 등록
- **POST** `/employees`
- 권한: `ADMIN`

### Request
```json
{
  "employeeNo": "E2026010",
  "loginId": "new.employee",
  "password": "Passw0rd!",
  "name": "신입사원",
  "email": "new.employee@example.com",
  "phone": "010-1111-2222",
  "role": "EMPLOYEE",
  "positionTitle": "Backend Developer",
  "hireDate": "2026-03-18",
  "annualLeaveQuota": 15.0,
  "departmentId": 2,
  "managerId": 2
}
```

### 실패 코드
- `EMPLOYEE_NO_DUPLICATED`
- `LOGIN_ID_DUPLICATED`
- `EMAIL_DUPLICATED`
- `DEPARTMENT_NOT_FOUND`
- `MANAGER_NOT_FOUND`

---

## 4.4 직원 수정
- **PATCH** `/employees/{employeeId}`
- 권한: `ADMIN`

### Request
```json
{
  "email": "updated@example.com",
  "phone": "010-2222-3333",
  "positionTitle": "Senior Backend Developer",
  "departmentId": 2,
  "managerId": 2
}
```

---

## 4.5 직원 상태 변경
- **PATCH** `/employees/{employeeId}/status`
- 권한: `ADMIN`

### Request
```json
{
  "employmentStatus": "INACTIVE"
}
```

---

## 5. 근태(Attendance)

## 5.1 출근
- **POST** `/attendance/check-in`
- 권한: `EMPLOYEE/MANAGER/ADMIN`

### Request
```json
{}
```

> 현재 로그인한 사용자를 기준으로 처리합니다.

### Response
```json
{
  "success": true,
  "data": {
    "attendanceId": 11,
    "workDate": "2026-03-18",
    "checkInAt": "2026-03-18T08:57:00",
    "status": "PRESENT"
  }
}
```

### 실패 코드
- `ATTENDANCE_ALREADY_EXISTS`
- `ATTENDANCE_NOT_ALLOWED_ON_LEAVE`

---

## 5.2 퇴근
- **POST** `/attendance/check-out`
- 권한: `EMPLOYEE/MANAGER/ADMIN`

### Request
```json
{}
```

### Response
```json
{
  "success": true,
  "data": {
    "attendanceId": 11,
    "workDate": "2026-03-18",
    "checkOutAt": "2026-03-18T18:12:00"
  }
}
```

### 실패 코드
- `ATTENDANCE_NOT_FOUND`
- `ATTENDANCE_ALREADY_CHECKED_OUT`

---

## 5.3 내 월간 근태 조회
- **GET** `/attendance/me`
- 권한: `ALL`

### Query Params
| 이름 | 타입 | 필수 | 설명 |
|---|---|---|---|
| month | string | Y | `YYYY-MM` 형식 |

### Response
```json
{
  "success": true,
  "data": {
    "month": "2026-03",
    "records": [
      {
        "workDate": "2026-03-18",
        "checkInAt": "2026-03-18T08:57:00",
        "checkOutAt": "2026-03-18T18:12:00",
        "status": "PRESENT"
      }
    ]
  }
}
```

---

## 5.4 팀 근태 조회
- **GET** `/attendance/team`
- 권한: `MANAGER/ADMIN`

### Query Params
| 이름 | 타입 | 필수 | 설명 |
|---|---|---|---|
| date | string | Y | `YYYY-MM-DD` |

### Response
```json
{
  "success": true,
  "data": [
    {
      "employeeId": 3,
      "employeeName": "이직원",
      "departmentName": "Engineering",
      "status": "PRESENT",
      "checkInAt": "2026-03-18T09:02:00",
      "checkOutAt": null
    }
  ]
}
```

---

## 6. 휴가 종류(Leave Type)

## 6.1 휴가 종류 목록 조회
- **GET** `/leave-types`
- 권한: `ALL`

### Response
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "code": "ANNUAL",
      "name": "연차",
      "deductsFromAnnual": true
    },
    {
      "id": 2,
      "code": "SICK",
      "name": "병가",
      "deductsFromAnnual": false
    }
  ]
}
```

---

## 7. 휴가 신청(Leave Request)

## 7.1 내 휴가 목록 조회
- **GET** `/leave-requests/me`
- 권한: `ALL`

### Query Params
| 이름 | 타입 | 필수 | 설명 |
|---|---|---|---|
| year | int | N | 연도 필터 |
| status | string | N | REQUESTED / APPROVED / REJECTED / CANCELLED |

---

## 7.2 휴가 신청
- **POST** `/leave-requests`
- 권한: `ALL`

### Request
```json
{
  "leaveTypeId": 1,
  "startDate": "2026-03-24",
  "endDate": "2026-03-25",
  "reason": "개인 일정"
}
```

### Response
```json
{
  "success": true,
  "data": {
    "id": 7,
    "status": "REQUESTED",
    "days": 2.0,
    "approver": {
      "id": 2,
      "name": "김매니저"
    }
  }
}
```

### 실패 코드
- `INVALID_DATE_RANGE`
- `LEAVE_OVERLAP`
- `INSUFFICIENT_LEAVE_BALANCE`
- `APPROVER_NOT_FOUND`

---

## 7.3 휴가 수정
- **PATCH** `/leave-requests/{leaveRequestId}`
- 권한: `ALL`  
- 조건: 본인 신청 건 + `REQUESTED` 상태만 수정 가능 권장

### Request
```json
{
  "startDate": "2026-03-25",
  "endDate": "2026-03-26",
  "reason": "일정 변경"
}
```

### 실패 코드
- `LEAVE_REQUEST_NOT_EDITABLE`

---

## 7.4 휴가 취소
- **PATCH** `/leave-requests/{leaveRequestId}/cancel`
- 권한: `ALL`  
- 조건: 본인 신청 건만 가능

### Request
```json
{}
```

### 실패 코드
- `LEAVE_REQUEST_NOT_CANCELLABLE`

---

## 7.5 승인 대기 목록 조회
- **GET** `/leave-requests/pending`
- 권한: `MANAGER/ADMIN`

### Query Params
| 이름 | 타입 | 필수 | 설명 |
|---|---|---|---|
| departmentId | long | N | 관리자 필터 |
| keyword | string | N | 이름 검색 |

### Response
```json
{
  "success": true,
  "data": [
    {
      "id": 7,
      "employee": {
        "id": 3,
        "name": "이직원"
      },
      "leaveType": {
        "id": 1,
        "name": "연차"
      },
      "startDate": "2026-03-24",
      "endDate": "2026-03-25",
      "days": 2.0,
      "status": "REQUESTED"
    }
  ]
}
```

---

## 7.6 휴가 승인
- **PATCH** `/leave-requests/{leaveRequestId}/approve`
- 권한: `MANAGER/ADMIN`

### Request
```json
{}
```

### 실패 코드
- `LEAVE_REQUEST_NOT_FOUND`
- `LEAVE_REQUEST_NOT_APPROVABLE`
- `APPROVAL_FORBIDDEN`
- `SELF_APPROVAL_NOT_ALLOWED`

---

## 7.7 휴가 반려
- **PATCH** `/leave-requests/{leaveRequestId}/reject`
- 권한: `MANAGER/ADMIN`

### Request
```json
{
  "reason": "프로젝트 마감 일정과 겹칩니다."
}
```

### 실패 코드
- `LEAVE_REQUEST_NOT_REJECTABLE`
- `APPROVAL_FORBIDDEN`

---

## 8. 대시보드(Dashboard)

## 8.1 내 대시보드 조회
- **GET** `/dashboard/me`
- 권한: `ALL`

### Response
```json
{
  "success": true,
  "data": {
    "employeeName": "이직원",
    "todayAttendanceStatus": "PRESENT",
    "todayCheckInAt": "2026-03-18T08:57:00",
    "todayCheckOutAt": null,
    "monthlyAttendanceCount": 12,
    "remainingAnnualLeave": 11.0,
    "pendingApprovalCount": 0
  }
}
```

---

## 8.2 팀 대시보드 조회
- **GET** `/dashboard/team`
- 권한: `MANAGER/ADMIN`

### Response
```json
{
  "success": true,
  "data": {
    "teamMemberCount": 5,
    "todayPresentCount": 4,
    "todayLeaveCount": 1,
    "pendingApprovalCount": 2
  }
}
```

---

## 9. 공휴일(Holiday)

## 9.1 공휴일 목록 조회
- **GET** `/holidays`
- 권한: `ALL`

### Query Params
| 이름 | 타입 | 필수 | 설명 |
|---|---|---|---|
| year | int | N | 연도 필터 |

---

## 9.2 공휴일 등록
- **POST** `/holidays`
- 권한: `ADMIN`

### Request
```json
{
  "holidayDate": "2026-05-05",
  "name": "어린이날",
  "isCompanyHoliday": false
}
```

### 실패 코드
- `HOLIDAY_DUPLICATED`

---

## 9.3 공휴일 수정
- **PATCH** `/holidays/{holidayId}`
- 권한: `ADMIN`

### Request
```json
{
  "name": "회사 창립기념일",
  "isCompanyHoliday": true
}
```

---

## 10. 주요 에러 코드 정의

| 에러 코드 | 설명 |
|---|---|
| INVALID_CREDENTIALS | 로그인 ID 또는 비밀번호 불일치 |
| EMPLOYEE_INACTIVE | 비활성 직원 |
| EMPLOYEE_NO_DUPLICATED | 중복 사번 |
| LOGIN_ID_DUPLICATED | 중복 로그인 ID |
| EMAIL_DUPLICATED | 중복 이메일 |
| DEPARTMENT_NOT_FOUND | 존재하지 않는 부서 |
| MANAGER_NOT_FOUND | 존재하지 않는 매니저 |
| ATTENDANCE_ALREADY_EXISTS | 오늘 출근 기록 이미 존재 |
| ATTENDANCE_NOT_FOUND | 오늘 출근 기록 없음 |
| ATTENDANCE_ALREADY_CHECKED_OUT | 이미 퇴근 완료 |
| ATTENDANCE_NOT_ALLOWED_ON_LEAVE | 휴가일 출근 불가 |
| INVALID_DATE_RANGE | 시작일/종료일 오류 |
| LEAVE_OVERLAP | 기존 휴가와 기간 중복 |
| INSUFFICIENT_LEAVE_BALANCE | 연차 부족 |
| APPROVER_NOT_FOUND | 승인자 없음 |
| LEAVE_REQUEST_NOT_EDITABLE | 수정할 수 없는 상태 |
| LEAVE_REQUEST_NOT_CANCELLABLE | 취소할 수 없는 상태 |
| LEAVE_REQUEST_NOT_APPROVABLE | 승인할 수 없는 상태 |
| LEAVE_REQUEST_NOT_REJECTABLE | 반려할 수 없는 상태 |
| APPROVAL_FORBIDDEN | 승인 권한 없음 |
| SELF_APPROVAL_NOT_ALLOWED | 본인 신청 건 본인 승인 불가 |
| HOLIDAY_DUPLICATED | 중복 공휴일 |

---

## 11. 학생팀 구현 팁

### 팁 1. DTO를 먼저 만든다
프론트/백엔드가 동시에 작업하려면 Entity보다  
**Request DTO / Response DTO**를 먼저 확정하는 것이 훨씬 좋습니다.

### 팁 2. 권한은 API에서 최종 검증한다
프론트에서 버튼을 숨겨도 백엔드에서 다시 검증해야 합니다.

### 팁 3. 대시보드 API는 조합형 조회로 따로 만든다
개별 테이블 API를 프론트에서 여러 번 호출하는 방식도 가능하지만  
짧은 프로젝트에서는 `/dashboard/*` 조합 API가 더 편합니다.

### 팁 4. Swagger와 Postman을 모두 쓴다
- 설계 공유: Swagger/OpenAPI
- 수동 검증: Postman

---

## 12. 구현 우선순위 추천

1. `/auth/*`
2. `/departments`, `/employees`
3. `/attendance/*`
4. `/leave-types`, `/leave-requests/*`
5. `/dashboard/*`
6. `/holidays`
7. 배포와 CORS