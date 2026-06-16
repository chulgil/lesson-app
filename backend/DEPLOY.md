# 배포 가이드

## Beta 서버 (codenavi)

### 접속
```bash
ssh codenavi
cd ~/lesson-app/backend
```

### 최초 설정 (시크릿)

> `docker-compose.beta.yml` 은 `env_file: .env.beta` 를 읽는다. 실제 시크릿은
> **`.env.beta`** 에 채운다 (`.env` 아님 — 과거 가이드 오류).
> `.env.beta` 는 `.gitignore` 처리되어 **git 추적 대상이 아니다** -> `git pull` /
> `git reset --hard` 가 절대 덮어쓰지 않는다. 템플릿은 `.env.beta.example`.

```bash
# 서버에서 1회만 — 템플릿 복사 후 실제 값 기입
cp .env.beta.example .env.beta
# .env.beta 에서 <REPLACE...> 값을 실제 값으로 교체
#   GOOGLE_CLIENT_ID     = web client id (.apps.googleusercontent.com)
#                          [!] 프론트 run-beta.sh 의 GOOGLE_SERVER_CLIENT_ID 와 동일해야 함
#   GOOGLE_CLIENT_SECRET = 위 web client 의 secret (GOCSPX-...)
#   JWT_SECRET_KEY / VULTR_STORAGE_* 등도 동일하게 기입
```

> **일회성 마이그레이션 (기존 서버, `.env.beta` 가 아직 git 추적 중이던 경우)**:
> 추적 해제 커밋을 pull 하기 전에 반드시 백업하고, pull 후 복원/재기입한다.
> ```bash
> cp .env.beta /tmp/.env.beta.bak   # 1) 백업
> git pull origin main              # 2) 추적 해제 커밋 반영
> [ -f .env.beta ] || cp /tmp/.env.beta.bak .env.beta   # 3) 삭제됐으면 복원
> grep -q '<REPLACE' .env.beta && echo '[!] placeholder 남음 — 실제 값 재기입 필요'
> ```

### 배포 순서
```bash
# 1. 코드 업데이트 (.env.beta 는 gitignore 되어 영향 없음)
git pull origin main

# 2. DB 마이그레이션
docker compose -f docker-compose.beta.yml exec app alembic upgrade head

# 3. 서비스 재시작 (env_file 재로딩 위해 up -d 권장)
docker compose -f docker-compose.beta.yml up -d
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
