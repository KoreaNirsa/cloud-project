# 배포 가이드 (AWS)

이 문서는 학생팀이 **최소한의 복잡도로 배포**를 끝낼 수 있도록  
실행 가능한 수준으로 정리한 문서입니다.

---

## 1. 권장 배포 구조

![HR System Overview](./images/hr-system-overview.png)

### 구성
- **Frontend:** React 빌드 결과물을 S3에 업로드하고 CloudFront로 배포
- **Backend:** Spring Boot 애플리케이션을 EC2에 배포
- **Database:** RDS 또는 EC2 MySQL 8 사용

---

## 2. 아키텍처 요약

```text
사용자 브라우저
  → CloudFront
    → S3 (React 정적 파일)

사용자 브라우저
  → CloudFront
    → Spring Boot (EC2, 8080)
      → RDS 또는 EC2 MySQL
```

---

## 3. 왜 이 구조를 추천하는가

| 항목 | 이유 |
|---|---|
| S3 + CloudFront | 프론트 배포가 쉽고 빠름 |
| EC2 단일 서버 | 가장 단순한 형태 |
| RDS | DB 백업/접속 관리가 쉬움 |

---

## 4. AWS 리소스 구성

## 4.1 S3
- 정적 파일 저장
- React build 산출물 업로드
- Public access는 CloudFront 정책에 맞게 설정

## 4.2 CloudFront
- 프론트 배포 도메인 역할
- 캐싱
- HTTPS 제공

## 4.3 EC2
- RedHat 또는 Amazon Linux 권장
- Java 21 설치
- Spring Boot jar 실행

## 4.4 RDS 또는 EC2
- MySQL 8
- 보안 그룹으로 접근 제어

---

## 5. 최소 보안 그룹 예시

| 리소스 | 인바운드 허용 |
|---|---|
| CloudFront | 사용자가 HTTPS로 접근 |
| S3 | CloudFront에서만 접근 |
| EC2 | CloudFront에서만 접근, 22 (본인 IP만) |
| RDS | 3306 (EC2 보안 그룹만) |

---

## 6. 환경 변수 예시

## 6.1 백엔드
```properties
SPRING_PROFILES_ACTIVE=prod
DB_URL=jdbc:mysql://<rds-endpoint>:3306/hr_core_lite?serverTimezone=Asia/Seoul
DB_USERNAME=hr_app
DB_PASSWORD=change-me
JWT_SECRET=change-me
CORS_ALLOWED_ORIGINS=https://your-frontend-domain.cloudfront.net
```

## 6.2 프론트엔드
```bash
VITE_API_BASE_URL=https://api.example.com/api
```

---

## 7. 배포 순서 추천

## 7.1 DB 먼저 준비
1. RDS 생성
2. DB 및 계정 생성
3. `sql/schema.sql` 실행
4. `sql/seed.sql` 실행

## 7.2 백엔드 배포
1. EC2 생성
2. Java 21 설치
3. 애플리케이션 빌드
4. jar 업로드 배포

## 7.3 프론트 배포
1. `npm run build`
2. S3에 업로드
3. CloudFront 배포
4. 환경 변수에 백엔드 URL 연결
5. SPA 라우팅 에러가 없도록 S3/CloudFront 설정

---

## 8. 백엔드 운영 방식 선택

## Jar 직접 실행 (권장)
```bash
java -jar hr-core-lite.jar
```

### 장점
- 가장 단순함

### 단점
- 환경 분리가 Docker보다 약함

---

## 9. CORS 체크 포인트

프론트와 백엔드가 서로 다른 도메인에서 동작하면 CORS 설정이 필요합니다. (SecurityConfig 참고)

### 반드시 확인할 것
- 허용 Origin 설정
- Authorization 헤더 허용
- preflight OPTIONS 응답 확인

---

## 11. 배포 체크리스트

- [ ] DB 서버 접속 성공
- [ ] schema.sql 실행 완료
- [ ] seed.sql 실행 완료
- [ ] EC2에서 Spring Boot 실행 성공
- [ ] `/api/auth/login` 호출 성공
- [ ] 프론트 `VITE_API_BASE_URL` 반영 완료
- [ ] 브라우저에서 로그인 성공
- [ ] 출근/휴가 신청/승인 실제 동작 확인
- [ ] 장애 시 롤백 방법 확인

---

## 12. 점검 항목

### 브라우저에서 반드시 해볼 것
1. 로그인
2. 직원 목록 조회
3. 출근
4. 휴가 신청
5. 매니저 계정으로 승인
6. 대시보드 반영

### 서버 측에서 반드시 해볼 것
1. DB 연결 확인
2. 로그 확인
3. 500 에러 없는지 확인
4. CORS 오류 없는지 확인

---

## 13. 장애가 났을 때 우선 확인할 것

| 증상 | 먼저 볼 것 |
|---|---|
| 로그인 실패 | API URL, CORS, JWT secret |
| 서버 500 | application-prod 설정, DB 연결 |
| DB 연결 실패 | RDS endpoint, 보안 그룹, 계정/비밀번호 |
| 프론트에서 API 호출 실패 | CloudFront 캐시, env 값, Nginx proxy |
| 새 코드가 반영 안 됨 | 프론트 재빌드, CloudFront invalidation, EC2 재시작 |
