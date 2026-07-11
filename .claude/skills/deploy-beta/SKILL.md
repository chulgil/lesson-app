---
name: deploy-beta
description: Beta 서버(codenavi)에 백엔드를 배포합니다. 트리거: /deploy-beta, beta 배포, 베타 배포
---

# Beta 서버 배포

codenavi 서버(108.61.162.25)에 lesson-app 백엔드를 배포합니다.

## 서버 정보

| 항목 | 값 |
|------|-----|
| 서버 | codenavi (108.61.162.25) |
| SSH | `ssh codenavi` (`~/.ssh/config` alias, `myssh codenavi` 와 동일 키) |
| 프로젝트 경로 | `~/apps/lesson-app-backend/backend` |
| 컴포즈 파일 | `docker-compose.beta.yml` |
| 컨테이너명 | `lessonaza-beta-api` |
| 도메인 | `https://api-beta.lessonaza.app` |
| API 문서 | `https://api-beta.lessonaza.app/docs` |

## 실행 절차

### 1단계: 로컬 변경사항 확인 및 푸시

```bash
# lesson-app 디렉토리에서 실행
cd <lesson-app-root>
git status
git push
```

커밋되지 않은 변경사항이 있으면 사용자에게 알리고 커밋 여부를 확인한다.

### 2단계: 서버 접속 및 코드 업데이트

```bash
SSH_CMD="ssh codenavi"

# 코드 풀
$SSH_CMD "cd ~/apps/lesson-app-backend && git pull"
```

### 3단계: 컨테이너 빌드 및 재시작

```bash
# docker-compose V1 사용 (서버에 V2 미설치)
$SSH_CMD "cd ~/apps/lesson-app-backend/backend && docker-compose -f docker-compose.beta.yml up -d --build"
```

**주의**: 서버는 `docker compose` (V2)가 아닌 `docker-compose` (V1)만 설치되어 있다.

### 4단계: DB 마이그레이션

```bash
# -T 플래그 필수 (non-TTY 환경)
$SSH_CMD "cd ~/apps/lesson-app-backend/backend && docker-compose -f docker-compose.beta.yml exec -T app uv run alembic upgrade head"
```

### 5단계: 헬스체크

```bash
curl -s https://api-beta.lessonaza.app/health
# 기대 응답: {"status":"healthy"}
```

### 6단계: 결과 보고

```
[Beta 배포 완료]
  서버: api-beta.lessonaza.app
  상태: healthy
  마이그레이션: (적용된 내용 또는 "변경 없음")
  API 문서: https://api-beta.lessonaza.app/docs
```

## 에러 처리

> **시크릿**: 실제 자격증명은 서버-로컬 `backend/.env.beta` 에만 존재한다 (gitignore,
> 추적 안 됨). 템플릿은 `.env.beta.example`. `git pull` / `reset` 이 `.env.beta` 를
> 덮어쓰지 않는다. `.env.beta` 가 없거나 `<REPLACE>` 가 남아 있으면 OAuth(구글 로그인)
> 토큰 교환이 401 로 실패한다 — `.env.beta.example` 기준으로 실제 값 기입 후 `up -d`.

| 에러 | 원인 | 해결 |
|------|------|------|
| SSH 접속 실패 | 키 경로 또는 권한 | `~/.ssh/config` 의 `codenavi` alias 확인 (키 위치는 `myssh` 함수의 `config_get CODENAVI_KEY` 로 조회) |
| git pull 충돌 | 서버에서 추적 파일 직접 수정 | 충돌 파일 확인 후 `git stash` 또는 커밋. **`reset --hard` 는 추적된 로컬 변경을 파괴하므로 금지** (`.env.beta` 는 untracked 라 안전하나 다른 파일 손실 위험) |
| 구글 로그인 401 | `.env.beta` 의 `GOOGLE_CLIENT_ID/SECRET` placeholder 또는 FE web client 불일치 | `.env.beta` 실제 값 확인 + `run-beta.sh` 의 `GOOGLE_SERVER_CLIENT_ID` 와 동일한지 확인 |
| 빌드 실패 | 의존성 또는 Dockerfile | 서버 로그 확인: `docker-compose logs app` |
| 마이그레이션 실패 | 스키마 충돌 | 로그 확인 후 사용자에게 보고 |
| 헬스체크 실패 | 컨테이너 시작 실패 | `docker logs lessonaza-beta-api --tail 30` 확인 |

## 시드 데이터 (선택)

테스트 계정 초기화가 필요한 경우:

```bash
$SSH_CMD "cd ~/apps/lesson-app-backend/backend && docker-compose -f docker-compose.beta.yml exec -T app uv run python scripts/seed_data.py"
```

## Production 배포

Production 배포는 별도 스킬(`/deploy-prod`)로 분리한다. beta와 다른 점:
- 컴포즈 파일: `docker-compose.prod.yml`
- 컨테이너명: `lessonaza-api`
- 도메인: `https://lesson.chulgil.me`
- **배포 전 사용자 확인 필수**
