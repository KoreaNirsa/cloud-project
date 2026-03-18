# 배포 가이드 (AWS)

이 문서는 학생팀이 **최소한의 복잡도로 배포**를 끝낼 수 있도록  
실행 가능한 수준으로 정리한 문서입니다.

---

## 1. 권장 배포 구조

![HR System Overview](./images/hr-system-overview.png)

### 구성
- **Frontend:** React 빌드 결과물을 S3에 업로드하고 CloudFront로 배포
- **Backend:** Spring Boot 애플리케이션을 EC2에 배포
- **Database:** RDS MySQL 8 사용
- **Reverse Proxy:** Nginx가 80/443 요청을 받아 Spring Boot로 전달

---

## 2. 아키텍처 요약

```text
사용자 브라우저
  → CloudFront
    → S3 (React 정적 파일)

사용자 브라우저
  → Nginx (EC2)
    → Spring Boot (8080)
      → RDS MySQL
```

---

## 3. 왜 이 구조를 추천하는가

| 항목 | 이유 |
|---|---|
| S3 + CloudFront | 프론트 배포가 쉽고 빠름 |
| EC2 단일 서버 | 학생 프로젝트에 가장 단순함 |
| RDS | DB 백업/접속 관리가 쉬움 |
| Nginx | 리버스 프록시와 CORS/SSL 대응에 유리 |

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
- Ubuntu 권장
- Java 17 설치
- Nginx 설치
- Spring Boot jar 또는 Docker 실행

## 4.4 RDS
- MySQL 8
- 퍼블릭 오픈 대신 EC2에서 접근 허용 권장
- 보안 그룹으로 접근 제어

---

## 5. 최소 보안 그룹 예시

| 리소스 | 인바운드 허용 |
|---|---|
| CloudFront | 사용자가 HTTPS로 접근 |
| S3 | CloudFront에서만 접근 |
| EC2 | 80, 443 (사용자), 22 (본인 IP만) |
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
2. Java 17 설치
3. 애플리케이션 빌드
4. jar 업로드 또는 GitHub Actions로 배포
5. `application-prod.yml` 또는 환경 변수 설정
6. Nginx reverse proxy 구성
7. `/actuator/health` 또는 기본 API로 헬스체크

## 7.3 프론트 배포
1. `npm run build`
2. S3에 업로드
3. CloudFront 배포
4. 환경 변수에 백엔드 URL 연결
5. SPA 라우팅 에러가 없도록 S3/CloudFront 설정

---

## 8. 백엔드 운영 방식 선택

## 선택지 A. Jar 직접 실행 (권장)
```bash
java -jar hr-core-lite.jar
```

### 장점
- 가장 단순함
- Docker 지식이 없어도 가능

### 단점
- 환경 분리가 Docker보다 약함

## 선택지 B. Docker 실행
```bash
docker run -d -p 8080:8080 --env-file .env hr-core-lite:latest
```

### 장점
- 배포 환경 일관성
- CI/CD 구성하기 좋음

### 단점
- 학생팀에게는 추가 학습이 필요할 수 있음

> **1~2주 프로젝트라면 Jar 직접 실행이 더 현실적**입니다.

---

## 9. Nginx 예시 설정

```nginx
server {
    listen 80;
    server_name api.example.com;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

HTTPS는 발표 일정에 맞춰  
Let's Encrypt 또는 AWS Load Balancer 없이도 진행 가능하지만,  
가능하면 CloudFront/Route53/ACM 구성을 통해 HTTPS를 적용하는 것이 좋습니다.

---

## 10. CORS 체크 포인트

프론트와 백엔드가 서로 다른 도메인에서 동작하면 CORS 설정이 필요합니다.

예시:
- 프론트: `https://hr-core-lite-front.cloudfront.net`
- 백엔드: `https://api.hr-core-lite.com`

### 반드시 확인할 것
- 허용 Origin 설정
- Authorization 헤더 허용
- preflight OPTIONS 응답 확인

---

## 11. 배포 체크리스트

- [ ] RDS 접속 성공
- [ ] schema.sql 실행 완료
- [ ] seed.sql 실행 완료
- [ ] EC2에서 Spring Boot 실행 성공
- [ ] `/api/auth/login` 호출 성공
- [ ] 프론트 `VITE_API_BASE_URL` 반영 완료
- [ ] 브라우저에서 로그인 성공
- [ ] 출근/휴가 신청/승인 실제 동작 확인
- [ ] 발표 계정 준비 완료
- [ ] 장애 시 롤백 방법 확인

---

## 12. GitHub Actions 권장(선택)

### 프론트
- push to main
- build
- S3 sync
- CloudFront invalidation

### 백엔드
- push to main
- gradle build
- jar 업로드 또는 SSH 배포

> 시간이 부족하면 GitHub Actions를 **선택 사항**으로 두고,
> 발표 전에는 수동 배포라도 끝내는 것이 중요합니다.

---

## 13. 발표 전 점검 항목

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

## 14. 장애가 났을 때 우선 확인할 것

| 증상 | 먼저 볼 것 |
|---|---|
| 로그인 실패 | API URL, CORS, JWT secret |
| 서버 500 | application-prod 설정, DB 연결 |
| DB 연결 실패 | RDS endpoint, 보안 그룹, 계정/비밀번호 |
| 프론트에서 API 호출 실패 | CloudFront 캐시, env 값, Nginx proxy |
| 새 코드가 반영 안 됨 | 프론트 재빌드, CloudFront invalidation, EC2 재시작 |

---

## 15. 학생 프로젝트용 현실적인 권장안

가장 추천하는 방식은 아래 조합입니다.

- 프론트: **Vercel** 또는 **S3 + CloudFront**
- 백엔드: **EC2**
- DB: **RDS**
- 도메인/SSL: 여유 있으면 적용, 없으면 생략 가능

다만 이번 문서의 기본 방향은 사용자 요청에 맞춰 **AWS 배포 기준**으로 작성했습니다.