---
name: deploy-prod
description: Production 서버(codenavi)에 백엔드를 배포합니다. 트리거: /deploy-prod, prod 배포, 프로덕션 배포
---

# Production 서버 배포

codenavi 서버(108.61.162.25)에 lesson-app 백엔드를 프로덕션 배포합니다.

**CRITICAL: 모든 단계에서 사용자 확인을 받는다. 자동 진행하지 않는다.**

## 서버 정보

| 항목 | 값 |
|------|-----|
| 서버 | codenavi (108.61.162.25) |
| SSH | `ssh -i ~/.ssh/codenavi_rsa admin@108.61.162.25` |
| 프로젝트 경로 | `~/apps/lesson-app-backend/backend` |
| 컴포즈 파일 | `docker-compose.prod.yml` |
| 컨테이너명 | `lessonaza-api` |
| 도메인 | `https://lesson.chulgil.me` |

## 실행 절차

### 0단계: 사전 확인 (CRITICAL)

배포 전 반드시 사용자에게 확인:
1. beta 환경에서 테스트 완료 여부
2. 배포할 변경사항 요약 (`git log beta-deployed..HEAD` 등)
3. 배포 진행 승인

### 1단계: 로컬 변경사항 푸시

```bash
cd <lesson-app-root>
git status
git push
```

### 2단계: 서버 코드 업데이트

```bash
SSH_CMD="ssh -i ~/.ssh/codenavi_rsa admin@108.61.162.25"
$SSH_CMD "cd ~/apps/lesson-app-backend && git pull"
```

### 3단계: 컨테이너 빌드 및 재시작

```bash
$SSH_CMD "cd ~/apps/lesson-app-backend/backend && docker-compose -f docker-compose.prod.yml up -d --build"
```

### 4단계: DB 마이그레이션

```bash
$SSH_CMD "cd ~/apps/lesson-app-backend/backend && docker-compose -f docker-compose.prod.yml exec -T app uv run alembic upgrade head"
```

### 5단계: 헬스체크

```bash
curl -s https://lesson.chulgil.me/health
```

### 6단계: 결과 보고

```
[Production 배포 완료]
  서버: lesson.chulgil.me
  상태: healthy
  마이그레이션: (내용)
```
