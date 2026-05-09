# 이슈: 오프라인 모드 검증

**우선순위:** 높음  
**상태:** 완료  

**종료 요약:**

- `frontend/test/core/sync/sync_queue_store_test.dart`
- `frontend/test/core/sync/sync_service_test.dart` 추가 및 통과
- 하네스/스펙 및 공지 문서 업데이트 완료

**실행 명령:**

```bash
cd frontend
flutter --no-version-check test test/core/sync/sync_queue_store_test.dart test/core/sync/sync_service_test.dart
```

**완료 조건 확인:**  
✅ 관련 테스트 추가 및 통과
✅ 문서/하네스 갱신  
**영역:** frontend/core/sync

## 배경

Hive 로컬 큐 기반 오프라인 동기화 흐름이 실제 운영 동작(오프라인 큐잉, 재접속 동기화, 실패 재시도, 미지원 도메인 실패 처리)에 대해 회귀 테스트가 없어 변경 리스크가 높음.

## 정의

- `sync` 영속 스토어 마이그레이션 점검
- 오프라인 큐잉 동작 점검
- 네트워크 복구 시 자동 동기화 점검
- 재시도 정책 점검
- `NO_ADAPTER` 실패 정책 점검

## 완료 조건

- 관련 테스트 추가 및 통과
- 문서/하네스 갱신
- 다음 이슈로 이어지는 잔여 리스크 없음
