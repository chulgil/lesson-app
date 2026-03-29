# 배포 가이드

## Beta 서버 (codenavi)

### 접속
```bash
ssh codenavi
cd ~/lesson-app/backend
```

### 최초 설정
```bash
cp .env.beta .env
# .env에서 <REPLACE> 표시된 값을 실제 값으로 교체
```

### 배포 순서
```bash
# 1. 코드 업데이트
git pull origin main

# 2. DB 마이그레이션
docker compose exec backend alembic upgrade head

# 3. 서비스 재시작
docker compose restart backend
```

### 마이그레이션 현황

| # | 파일 | 내용 |
|---|------|------|
| 0001 | initial_postgresql_schema | 초기 스키마 (43 테이블) |
| 0002 | add_missing_tables | 추가 테이블 (21개) |
| 0003 | timestamp_to_timestamptz | 타임스탬프 타임존 변환 |
| 0004 | add_onboarding_completed | users.onboarding_completed |
| 0005 | frontend_backend_alignment | lesson_locations 6컬럼 + teacher_student_relations 15컬럼 + RelationStatus enum |
| 0006 | add_background_image_fields | teachers.background_image + students.background_image_url |
| d91e | add_bank_accounts_column | teachers.bank_accounts + teacher_settings 2컬럼 |
| e34f | frontend_backend_schema_alignment_phase2 | students 주소 4컬럼 + lesson_requests.academy_id |

### 마이그레이션 확인
```bash
# 현재 적용된 버전 확인
docker compose exec backend alembic current

# 미적용 마이그레이션 확인
docker compose exec backend alembic heads
```

### 롤백
```bash
# 한 단계 롤백
docker compose exec backend alembic downgrade -1

# 특정 버전으로 롤백
docker compose exec backend alembic downgrade 0004
```

## API 엔드포인트 요약 (v1)

| 라우터 | 경로 | 엔드포인트 수 |
|--------|------|-------------|
| auth | /auth | 6 |
| users | /users | 6 |
| teachers | /teachers | 9 |
| students | /students | 10 |
| lessons | /lessons | 15+ |
| subscriptions | /subscriptions | 8 |
| practice | /practice | 13 |
| practice-logs | /practice-logs | 8 |
| recordings | /recordings | 7 |
| schedule | /schedule | 7 |
| bookings | /bookings | 9 |
| notifications | /notifications | 4 |
| parents | /parents | 6 |
| relationships | /relationships | 6 |
| invites | /invites | 8 |
| gamification | /gamification | 2 |
| settings | /settings | 16 |
| reviews | /reviews | 5 |
| groups | /groups | 9 |
| locations | /locations | 8 |
| lesson-requests | /schedule/lesson-requests | 7 |
| profile-images | /profile-images | 2 |
