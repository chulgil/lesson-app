# Beta API 통합 테스트

GitHub issue #418의 원격 beta API 종단 시나리오 스캐폴드입니다.

## 필요 환경변수

| 변수 | 필수 | 설명 |
|------|------|------|
| `INTERNAL_API_KEY` | 필수 | beta 게이트 키 (없으면 이 디렉토리 테스트만 skip) |
| `BETA_BASE_URL` | 선택 | 기본값: `https://api-beta.lessonaza.app` |

`INTERNAL_API_KEY`가 없으면 `tests/integration_beta/` 안의 테스트만 skip됩니다.
일반 단위 테스트(`tests/test_*.py`)는 영향받지 않습니다.

## 실행

```bash
cd backend

# 전체 실행
INTERNAL_API_KEY=... make beta-integration

# 시나리오 키워드 필터
INTERNAL_API_KEY=... make beta-integration ONLY=signup

# 시드 리셋 안내 포함 실행
INTERNAL_API_KEY=... BETA_RESET=1 make beta-integration

# pytest 직접 실행
INTERNAL_API_KEY=... uv run pytest tests/integration_beta -v
```

## 시드 전제 (Seed Pool)

`backend/scripts/seeds/ids.py`에 정의된 시드 계정을 재사용합니다.

| 계정 | 이메일 | 역할 |
|------|--------|------|
| seed-teacher-0001 | minyeon@example.com | teacher |
| seed-student-user-0001 | soyeon@example.com | student |
| seed-student-user-0002 | junho@example.com | student |

시드 계정 자체는 수정하지 않습니다. 각 테스트에서 생성하는 임시 계정
(`beta-*-{suffix}@example.com`)은 beta 서버에 누적됩니다.

시드 리셋이 필요한 경우 beta 서버 SSH 접속 후:
```bash
docker compose exec api uv run python scripts/seeds/seed_beta.py --reset
```
또는 `BETA_RESET=1 make beta-integration` 실행 시 안내 메시지가 출력됩니다.

## 시나리오 파일

| 파일 | 시나리오 |
|------|----------|
| `test_signup.py` | Phase 1: 가입 → 역할 선택 → `/me` 검증, 학생 등록, 초대코드 연결 |
| `test_lesson_request.py` | Phase 2: 학생 신청 → 선생님 슬롯 제안 → 학생 확정 / 거절 |
| `test_schedule_edit.py` | Phase 2: 일정 변경 신청 / 승인 / 거절 / 노쇼 정책 |
| `test_lesson_close.py` | Phase 2: 레슨 완료 → 수강권 잔여 회차 -1 → 진행률 갱신 |
| `test_boundaries.py` | Phase 2: 만료 JWT 401, 권한 위반 403/404, KST 자정 경계 |

## 새 API 추가 시

1. `helpers.py`의 `BetaClient`에 해당 엔드포인트 메서드 추가
2. 시나리오에 맞는 파일(`test_*.py`)에 `@pytest.mark.asyncio` 테스트 추가
3. 시드 풀 재사용 원칙 유지 — 시드 계정 직접 수정 금지
4. teardown에서 생성한 리소스 정리 (best-effort `try/except`)
