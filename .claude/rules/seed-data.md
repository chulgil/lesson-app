# 시드 데이터 규칙

## 자동 감지 (백엔드 작업 시)

백엔드 API 작업 시 다음 상황이 감지되면 자동으로 안내:

| 상황 | 행동 |
|------|------|
| API 응답이 빈 배열 / 0건 | "시드 데이터가 없습니다. `/seed <시나리오>` 실행을 권장합니다" |
| 새 모델 추가 | "해당 모델의 시드 시나리오가 필요할 수 있습니다" |
| beta 배포 후 | 핵심 API 헬스체크 자동 실행 |

## 시드 시스템 위치

- 새 시스템: `backend/scripts/seeds/` (모듈형)
- 기존 시스템: `backend/scripts/seed_data.py` (모놀리식, legacy-full로 래핑)
- ID 정의: `backend/scripts/seeds/ids.py`
- dev-login은 시드 ID를 자동 매핑 (`auth_service.py`)

## 시드 실행 (beta 서버)

```bash
# SSH 접속
ssh codenavi   # ~/.ssh/config alias (myssh codenavi 와 동일 키)

# 시드 실행
cd ~/apps/lesson-app-backend/backend
docker-compose -f docker-compose.beta.yml exec -T -w /app app \
  uv run python -m scripts.seeds.runner --preset full --reset
```

## 새 시나리오 추가 시

1. `backend/scripts/seeds/scenarios/<name>.py` 생성
2. `runner.py`의 `SCENARIOS`, `scenario_map` 등록
3. 적절한 프리셋에 추가
4. 필요한 ID는 `ids.py`에 추가
