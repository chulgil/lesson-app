# Offline-First 아키텍처 요약

## 핵심 개념
- **Local-First + Eventual Sync**: 항상 로컬 데이터 우선, 연결 시 자동 동기화
- **Sync Queue**: Hive 기반 영속 큐로 오프라인 작업 저장
- **Conflict Resolution**: 데이터 유형별 충돌 해결 정책

## 동기화 우선순위
1. `critical`: 결제, 예약 - 즉시 동기화
2. `high`: 레슨 노트 - 5분 내
3. `normal`: 연습 기록 - 30분 내

## 녹음 파일 (Share-Triggered Sync)
- **핵심 원칙**: 녹음은 기본적으로 로컬에만 저장
- 서버 업로드는 **공유 시에만** 발생:
  - 선생님에게 공유
  - 타인에게 공유 (향후)
- 비용 절감: 전체 녹음 중 ~5-10%만 서버 저장
- 문서: `docs/proposal/recording_sync_multidevice.md`

## Repository 패턴
```
[domain]_repository.dart        # Interface
local_[domain]_repository.dart  # Hive 구현
remote_[domain]_repository.dart # API 구현
sync_[domain]_repository.dart   # 통합 레이어
```

## 구현 로드맵
1. Phase 1: SyncEngine 기반 구축 (2-3주)
2. Phase 2: Repository 마이그레이션 (3-4주)
3. Phase 3: 백엔드 API (병렬)
4. Phase 4: 고급 기능 (2-3주)

## 문서 위치
`docs/proposal/offline_first_architecture.md`
