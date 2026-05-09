# 오프라인 동기화 검증

> 작성일: 2026-05-09  
> 소유 범위: frontend/core/sync

## 범위

- `SyncQueueStore`의 마이그레이션 규칙(레거시 `items` 정리, 손상 엔트리 컴팩트)
- `SyncService`의 오프라인 큐잉/복구/재시도/미지원 도메인 처리

## 핵심 수용 기준

- 오프라인 상태에서 `queueMutation()` 호출 시 항목이 `pending`으로 큐에 남아야 한다.
- 온라인 복귀 이벤트 시 pending 큐가 자동으로 동기화되어야 한다.
- API 실패 시 `retryCount`가 증가하고, `maxRetryCount` 미만이면 `pending` 유지, 초과 시 `failed`여야 한다.
- 미지원 도메인 항목은 `errorCode: NO_ADAPTER`로 실패 처리하고 API 호출을 하지 않는다.

## 아티팩트

- `frontend/test/core/sync/sync_queue_store_test.dart`
- `frontend/test/core/sync/sync_service_test.dart`

## 실행 명령

```bash
cd frontend
flutter test test/core/sync/sync_queue_store_test.dart
flutter test test/core/sync/sync_service_test.dart
```
