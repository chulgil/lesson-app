---
name: seed
description: Beta 서버 시드 데이터 관리. 트리거: /seed, 시드 데이터, 테스트 데이터
---

# 시드 데이터 관리

Beta 서버(codenavi)의 테스트 데이터를 관리합니다.

## 사용법

```bash
/seed                          # 현재 상태 확인 + 추천
/seed full                     # 전체 데이터 리셋 + 재생성
/seed schedule                 # 스케줄 시나리오만 리셋
/seed minimal                  # 계정만 (최소)
/seed check                    # 데이터 무결성 검사
/seed new <시나리오명>          # 새 시나리오 파일 생성
```

## 실행 절차

### 기본: 시드 실행

1. 로컬 변경사항이 있으면 커밋 + 푸시
2. beta 서버에 배포 (변경된 시드 코드 반영)
3. 시드 실행

```bash
SSH_CMD="ssh -i ~/.ssh/codenavi_rsa admin@108.61.162.25"

# 배포 (시드 코드 변경 시)
$SSH_CMD "cd ~/apps/lesson-app-backend && git pull && cd backend && docker-compose -f docker-compose.beta.yml up -d --build"

# 시드 실행
$SSH_CMD "cd ~/apps/lesson-app-backend/backend && docker-compose -f docker-compose.beta.yml exec -T -w /app app uv run python -m scripts.seeds.runner --preset <preset> --reset"
```

### check: 데이터 무결성 검사

API를 호출하여 핵심 데이터가 정상인지 확인:

```bash
# 1. 선생님/학생 로그인
curl -s -X POST https://beta.lessonaza.app/api/v1/auth/dev-login ...

# 2. 핵심 API 검증
GET /teachers                    # 선생님 검색 가능?
GET /schedule/availability       # 가용시간 설정됨?
GET /schedule/slots?...          # 슬롯 계산 정상?
GET /teachers/{id}/students      # 학생 목록?
GET /subscriptions               # 구독권?
GET /lessons                     # 레슨 이력?
```

각 API의 응답 count가 0이면 해당 시나리오 시드가 필요함을 보고.

### new: 새 시나리오 생성

사용자가 `/seed new lessons` 요청 시:

1. `backend/scripts/seeds/scenarios/lessons.py` 파일 생성
2. 기존 `seed_data.py`에서 해당 섹션 추출 + 모듈화
3. `runner.py`의 `SCENARIOS`와 `scenario_map`에 등록
4. `full` 프리셋에 추가
5. 로컬 테스트 실행

파일 템플릿:

```python
"""Scenario: Lessons — 레슨 이력 데이터.

Depends on: base/accounts
"""
from __future__ import annotations
from datetime import UTC, date, datetime, timedelta
from sqlalchemy import delete
from sqlalchemy.ext.asyncio import AsyncSession
from scripts.seeds.helpers import log_seed
from scripts.seeds.ids import (...)

async def seed_lessons(db: AsyncSession, *, reset: bool = False) -> None:
    """Create lesson history data."""
    from app.models.lesson import Lesson

    if reset:
        await db.execute(delete(Lesson).where(Lesson.id.startswith("seed-")))
        await db.flush()

    print("[Scenario] 레슨 데이터 생성...")
    # ... 데이터 생성
    log_seed("레슨", count, "completed 10, scheduled 5, cancelled 4")
```

## 프리셋 목록

| 프리셋 | 포함 시나리오 | 용도 |
|--------|-------------|------|
| `minimal` | 계정만 | 빠른 테스트, 새 기능 개발 |
| `full` | legacy-full (전체) | 모든 화면 테스트 |
| `schedule-test` | schedule | 스케줄 흐름 테스트 |

## 시드 ID 규칙

모든 시드 데이터는 `seed-` 접두사 ID를 사용:
- `seed-teacher-0001` (User ID)
- `seed-teacher-prof-0001` (Teacher profile ID)
- `seed-student-0001` (Student ID)
- `seed-lesson-0001` (Lesson ID)

ID 정의: `backend/scripts/seeds/ids.py` (단일 소스)

## 자동 감지 규칙 (Claude Code용)

백엔드 기능 작업 시 다음을 자동 확인:

1. **새 모델/엔드포인트 추가 시** → 해당 모델의 시드 시나리오 존재 여부 확인
2. **API 테스트 시 빈 응답** → 시드 데이터 부족 안내
3. **beta 배포 후** → `/seed check` 실행 권장
4. **프론트엔드 화면 작업 시** → 해당 도메인의 시드 데이터 확인

## 파일 구조

```
backend/scripts/seeds/
├── ids.py              # 고정 ID (단일 소스)
├── helpers.py          # upsert, delete 유틸
├── runner.py           # CLI 엔트리포인트
├── base/
│   └── accounts.py     # 계정 (항상 실행)
└── scenarios/
    ├── schedule.py     # 스케줄 (가용시간, 부킹, 요청)
    └── legacy_full.py  # 기존 seed_data.py 래퍼
```
