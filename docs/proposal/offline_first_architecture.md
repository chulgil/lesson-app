# Offline-First 아키텍처 설계

> 작성일: 2025-01-11
> 상태: 제안 (Proposal)

## 개요

레슨 앱을 인터넷 연결 없이도 사용 가능하도록 설계하고, 연결 시 서버와 자동 동기화하는 **Offline-First** 아키텍처 제안서입니다.

---

## 현재 상태 분석

### Offline-First에 유리한 현재 구조

| 요소 | 현재 상태 | 평가 |
|------|----------|------|
| **Repository 패턴** | Interface + Mock 분리 | ✅ 확장 용이 |
| **로컬 저장소** | Hive 사용 중 | ✅ 이미 로컬 우선 |
| **데이터 모델** | 잘 정의됨 | ✅ 동기화 가능 |
| **Clean Architecture** | Feature-based | ✅ 레이어 분리됨 |

---

## 핵심 개념: Local-First + Eventual Sync

```
┌─────────────────────────────────────────────────────────────┐
│                        앱 (Flutter)                          │
├─────────────────────────────────────────────────────────────┤
│  UI Layer (Screens/Widgets)                                 │
│       ↓                                                      │
│  Providers (Riverpod) - 항상 로컬 데이터 우선               │
│       ↓                                                      │
│  ┌─────────────────────────────────────────────────────┐    │
│  │            Sync-Aware Repository                     │    │
│  │  ┌─────────────┐    ┌─────────────┐                 │    │
│  │  │ Local Store │ ←→ │ Sync Engine │ ←→ Remote API  │    │
│  │  │   (Hive)    │    │  (Queue)    │                 │    │
│  │  └─────────────┘    └─────────────┘                 │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                              ↕
                    ┌─────────────────┐
                    │  Backend (API)  │
                    │   - FastAPI     │
                    │   - PostgreSQL  │
                    └─────────────────┘
```

---

## 데이터 동기화 전략

### 충돌 해결 정책 (Conflict Resolution)

| 데이터 유형 | 충돌 해결 전략 | 이유 |
|------------|---------------|------|
| **연습 기록** | Last-Write-Wins + Merge | 사용자별 독립 데이터 |
| **레슨 예약** | Server-Wins | 선생님/학생 양측 일관성 필요 |
| **결제 정보** | Server-Wins | 금전 관련 정확성 중요 |
| **녹음 파일** | Client-Wins | 디바이스에서만 생성 |
| **설정** | Last-Write-Wins | 사용자 선호도 |

### 동기화 우선순위

```dart
enum SyncPriority {
  critical,   // 결제, 예약 - 즉시 동기화 시도
  high,       // 레슨 노트, 연습 완료 - 5분 내
  normal,     // 연습 기록, 설정 - 30분 내
  low,        // 녹음 파일 - WiFi 연결 시
}
```

---

## 구현 아키텍처

### 폴더 구조

```
lib/
├── core/
│   └── sync/                          # 동기화 엔진
│       ├── sync_engine.dart           # 메인 동기화 로직
│       ├── sync_queue.dart            # 오프라인 작업 큐
│       ├── conflict_resolver.dart     # 충돌 해결
│       ├── connectivity_monitor.dart  # 연결 상태 감시
│       └── models/
│           ├── sync_operation.dart    # 동기화 작업 모델
│           └── sync_status.dart       # 동기화 상태
│
├── features/
│   └── [domain]/
│       └── data/
│           └── repositories/
│               ├── [domain]_repository.dart        # Interface
│               ├── local_[domain]_repository.dart  # Hive 구현
│               ├── remote_[domain]_repository.dart # API 구현
│               └── sync_[domain]_repository.dart   # 통합 Repository
```

---

## 핵심 컴포넌트 설계

### 1. SyncEngine (동기화 엔진)

```dart
/// 오프라인 우선 동기화 엔진
class SyncEngine {
  final SyncQueue _queue;
  final ConnectivityMonitor _connectivity;
  final ConflictResolver _resolver;

  /// 오프라인 작업 추가
  Future<void> enqueue(SyncOperation operation) async {
    await _queue.add(operation);
    if (await _connectivity.isOnline) {
      _processQueue();
    }
  }

  /// 연결 복구 시 큐 처리
  void _processQueue() async {
    while (_queue.isNotEmpty && await _connectivity.isOnline) {
      final op = await _queue.peek();
      try {
        await _executeOperation(op);
        await _queue.remove(op);
      } catch (e) {
        if (_isRetryable(e)) {
          await _queue.retry(op);
        } else {
          await _queue.markFailed(op);
        }
      }
    }
  }
}
```

### 2. SyncOperation (동기화 작업)

```dart
@HiveType(typeId: 100)
class SyncOperation extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final SyncOperationType type; // create, update, delete

  @HiveField(2)
  final String entityType; // lesson, practice, recording...

  @HiveField(3)
  final String entityId;

  @HiveField(4)
  final Map<String, dynamic> payload;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final int retryCount;

  @HiveField(7)
  final SyncPriority priority;

  @HiveField(8)
  final SyncStatus status; // pending, syncing, synced, failed
}
```

### 3. Sync-Aware Repository 패턴

```dart
/// 동기화 인식 Repository (통합 레이어)
class SyncPracticeRepository implements PracticeRepository {
  final LocalPracticeRepository _local;
  final RemotePracticeRepository _remote;
  final SyncEngine _sync;

  @override
  Future<List<PracticeRepertoire>> getRepertoires(String studentId) async {
    // 항상 로컬 우선 반환 (즉시 응답)
    return _local.getRepertoires(studentId);
  }

  @override
  Future<PracticeRepertoire> createRepertoire(PracticeRepertoire rep) async {
    // 1. 로컬에 즉시 저장
    final localRep = await _local.createRepertoire(rep);

    // 2. 동기화 큐에 추가 (백그라운드 처리)
    await _sync.enqueue(SyncOperation(
      type: SyncOperationType.create,
      entityType: 'repertoire',
      entityId: localRep.id,
      payload: localRep.toJson(),
      priority: SyncPriority.normal,
    ));

    return localRep;
  }
}
```

---

## 사용자 경험 시나리오

### 시나리오 1: 완전 오프라인 연습

```
1. 학생이 지하철에서 앱 열기
2. 모든 데이터 로컬에서 즉시 로드 ✅
3. 연습 완료 체크 → 로컬 저장 + 큐에 추가
4. 녹음 저장 → 로컬 파일 + 메타데이터 큐
5. 집에 도착 (WiFi 연결)
6. 백그라운드에서 자동 동기화
7. 선생님 앱에 연습 기록 반영
```

### 시나리오 2: 간헐적 연결

```
1. 카페에서 레슨 노트 작성 (3G 불안정)
2. 저장 시 로컬 즉시 반영
3. 동기화 시도 → 실패 → 자동 재시도 큐
4. 연결 복구 시 자동 동기화
5. 사용자는 끊김 없이 작업 지속
```

### 시나리오 3: 충돌 발생

```
1. 선생님이 레슨 시간 변경 (서버)
2. 학생이 같은 레슨에 메모 추가 (오프라인)
3. 학생 앱 동기화 시도
4. 충돌 감지 → 서버 시간 + 학생 메모 병합
5. 양측에 병합된 데이터 반영
```

---

## 데이터 유형별 동기화 전략

| 데이터 | 로컬 저장 | 동기화 방식 | 충돌 처리 |
|--------|----------|------------|----------|
| **레퍼토리/섹션** | Hive | 양방향 | Last-Write-Wins |
| **연습 완료 상태** | Hive | Push | Merge (날짜별) |
| **녹음 파일** | 파일시스템 | Push (WiFi) | Client-Wins |
| **녹음 메타데이터** | Hive | Push | Client-Wins |
| **레슨 예약** | Hive | Pull 우선 | Server-Wins |
| **결제 정보** | Hive | Pull Only | Server-Wins |
| **사용자 설정** | Hive | Push | Last-Write-Wins |
| **알림 설정** | Hive | 로컬 Only | N/A |

---

## 구현 로드맵

### Phase 1: 기반 구축 (2-3주)
- [ ] SyncEngine 핵심 구현
- [ ] SyncQueue (Hive 기반 영속 큐)
- [ ] ConnectivityMonitor 구현
- [ ] 기본 Conflict Resolver

### Phase 2: Repository 마이그레이션 (3-4주)
- [ ] Local Repository 분리 (현재 Mock → Local)
- [ ] Remote Repository 구현 (API 연동)
- [ ] Sync Repository 통합 레이어
- [ ] Provider 업데이트

### Phase 3: 백엔드 API (병렬 진행)
- [ ] FastAPI 서버 구축
- [ ] 동기화 엔드포인트 (/sync/push, /sync/pull)
- [ ] 충돌 감지 로직
- [ ] 파일 업로드 (녹음)

### Phase 4: 고급 기능 (2-3주)
- [ ] 대용량 파일 동기화 (녹음)
- [ ] 선택적 동기화 (WiFi Only)
- [ ] 동기화 상태 UI
- [ ] 오류 복구 및 재시도

---

## 추가 고려사항

### 녹음 파일 동기화

```dart
// 대용량 파일 전략
class RecordingSyncStrategy {
  /// WiFi 연결 시에만 업로드
  bool shouldSync(PracticeRecording recording) {
    return _connectivity.isWiFi &&
           recording.durationSeconds > 10; // 10초 이상만
  }

  /// 청크 업로드 (대용량 파일)
  Future<void> uploadRecording(String filePath) async {
    final chunks = await _splitIntoChunks(filePath, chunkSize: 1024 * 1024);
    for (final chunk in chunks) {
      await _uploadChunk(chunk);
    }
  }
}
```

### 다중 기기 지원

```dart
// 기기별 고유 ID로 충돌 추적
class DeviceSync {
  final String deviceId = _generateDeviceId();

  SyncOperation createOperation(dynamic entity) {
    return SyncOperation(
      deviceId: deviceId,
      timestamp: DateTime.now(),
      vectorClock: _incrementClock(),
      // ...
    );
  }
}
```

### 초기 동기화 (첫 로그인)

```dart
// 첫 로그인 시 서버 데이터 풀
Future<void> initialSync() async {
  showLoadingDialog('데이터 동기화 중...');

  await Future.wait([
    _syncRepertoires(),
    _syncLessons(),
    _syncStudents(),
  ]);

  await _local.setInitialSyncComplete();
}
```

---

## 결론

### 현재 앱의 강점
1. **Repository 패턴** 이미 적용 → 레이어 교체 용이
2. **Hive 사용 중** → 로컬 저장소 기반 있음
3. **Clean Architecture** → 동기화 레이어 추가 쉬움

### 권장 접근법
1. **단계적 마이그레이션**: Mock → Local + Sync → Remote 연동
2. **연습 기능 우선**: 가장 오프라인 사용이 많은 영역
3. **서버 병렬 개발**: FastAPI로 동기화 API 구축

---

## 관련 문서

- [아키텍처 가이드](../architecture.md)
- [데이터 백업 전략](../specs/practice/data_backup_strategy.md)
- [백업 구현 명세](../specs/practice/backup_implementation_spec.md)
