# 녹음 파일 동기화 & 다중 기기 지원 설계

> 작성일: 2025-01-11
> 상태: 제안 (Proposal)
> 관련 문서: [Offline-First 아키텍처](./offline_first_architecture.md)

---

## 핵심 원칙: Share-Triggered Sync

> **녹음 파일은 기본적으로 로컬에만 저장됩니다.**
> 서버 업로드는 **공유 시에만** 발생합니다.

| 상황 | 저장 위치 | 동기화 |
|------|----------|--------|
| 일반 녹음 | 로컬만 | ❌ 없음 |
| 선생님에게 공유 | 로컬 + 서버 | ✅ 공유 시 업로드 |
| 타인에게 공유 (향후) | 로컬 + 서버 | ✅ 공유 시 업로드 |
| 대표 녹음 (공유 안 함) | 로컬만 | ❌ 없음 |

---

## 1. 녹음 파일 동기화 설계

### 1.1 현재 구조 분석

```dart
// 현재 Recording 모델 (lib/features/practice/domain/entities/recording.dart)
class Recording {
  final String id;
  final String localPath;        // 로컬 파일 경로
  final String? serverUrl;       // 서버 URL (동기화 후)
  final StorageStatus storageStatus; // local, active, archived, deleted
  // ...
}

// 저장 위치: {앱문서}/recordings/{repertoireId}/{uuid}.m4a
// 포맷: AAC/M4A, 44100Hz, 모노
// 최대 길이: 3분 (180초)
```

### 1.2 Share-Triggered 동기화 아키텍처

```
┌─────────────────────────────────────────────────────────────────────┐
│                  Share-Triggered 녹음 동기화                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  일반 녹음 (공유 안 함)                                              │
│  ┌─────────┐    ┌─────────────┐                                     │
│  │ 녹음    │ -> │ 로컬 저장   │  ──── 끝 (서버 업로드 없음) ────    │
│  │ 완료    │    │ (M4A)       │                                     │
│  └─────────┘    └─────────────┘                                     │
│                                                                      │
│  ════════════════════════════════════════════════════════════════   │
│                                                                      │
│  공유 녹음 (선생님/타인에게 공유 시)                                 │
│  ┌─────────┐    ┌─────────────┐    ┌─────────────┐                  │
│  │ 공유    │ -> │ 서버 업로드 │ -> │ 공유 URL    │                  │
│  │ 버튼    │    │ (즉시)      │    │ 생성        │                  │
│  └─────────┘    └─────────────┘    └─────────────┘                  │
│                        ↓                                             │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                    청크 업로드 엔진                          │    │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐        │    │
│  │  │ Chunk 1 │  │ Chunk 2 │  │ Chunk 3 │  │ Chunk N │ → 병합 │    │
│  │  │  1MB    │  │  1MB    │  │  1MB    │  │  ...    │        │    │
│  │  └─────────┘  └─────────┘  └─────────┘  └─────────┘        │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                        ↓                                             │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                   공유된 녹음 서버 저장소                     │    │
│  │  ┌─────────────┐              ┌─────────────┐               │    │
│  │  │ Hot Storage │  90일 후 → │ Cold Storage│               │    │
│  │  │ (빠른 접근) │              │ (S3 Glacier)│               │    │
│  │  └─────────────┘              └─────────────┘               │    │
│  └─────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
```

### 1.3 핵심 컴포넌트

#### A. RecordingSyncService

```dart
/// 녹음 파일 전용 동기화 서비스 (Share-Triggered)
///
/// 핵심 원칙: 녹음 파일은 공유 시에만 서버에 업로드됩니다.
/// - 일반 녹음: 로컬에만 저장
/// - 공유 녹음: 로컬 + 서버 업로드
class RecordingSyncService {
  final ConnectivityMonitor _connectivity;
  final ChunkedUploader _uploader;
  final RecordingDownloadCache _downloadCache;

  // ========================================
  // 공유 시 업로드 (Share-Triggered)
  // ========================================

  /// 선생님에게 공유 - 서버 업로드 트리거
  Future<ShareResult> shareWithTeacher(Recording recording, String teacherId) async {
    // 1. 이미 업로드된 경우 URL만 반환
    if (recording.serverUrl != null) {
      return ShareResult.success(
        shareUrl: await _generateShareUrl(recording, teacherId),
      );
    }

    // 2. 서버에 업로드
    final uploadResult = await _uploadForShare(recording);
    if (!uploadResult.success) {
      return ShareResult.failed(error: uploadResult.error);
    }

    // 3. 녹음 상태 업데이트
    await _updateRecordingWithServerUrl(recording, uploadResult.serverUrl);

    // 4. 공유 URL 생성 및 반환
    return ShareResult.success(
      shareUrl: await _generateShareUrl(recording, teacherId),
    );
  }

  /// 타인에게 공유 (향후 기능)
  Future<ShareResult> shareWithOthers(Recording recording, ShareOptions options) async {
    // 공유 옵션: 링크 만료 기간, 다운로드 허용 여부 등
    if (recording.serverUrl == null) {
      final uploadResult = await _uploadForShare(recording);
      if (!uploadResult.success) {
        return ShareResult.failed(error: uploadResult.error);
      }
      await _updateRecordingWithServerUrl(recording, uploadResult.serverUrl);
    }

    return ShareResult.success(
      shareUrl: await _generatePublicShareUrl(recording, options),
    );
  }

  /// 공유용 업로드 (내부 메서드)
  Future<UploadResult> _uploadForShare(Recording recording) async {
    // 네트워크 연결 확인
    if (!await _connectivity.isOnline) {
      return UploadResult.failed(error: '인터넷 연결이 필요합니다');
    }

    // 청크 업로드 실행
    return await _uploader.upload(recording);
  }

  // ========================================
  // 녹음 완료 시 (로컬 저장만)
  // ========================================

  /// 녹음 완료 시 - 로컬 저장만 (서버 업로드 없음)
  Future<void> onRecordingComplete(Recording recording) async {
    // 메타데이터만 동기화 (녹음 목록용)
    // 파일 자체는 로컬에만 저장됨
    await _syncMetadataOnly(recording);
  }

  // ========================================
  // 다운로드 관련
  // ========================================

  /// 녹음 재생 요청 시 - 로컬 우선, 없으면 다운로드
  Future<String> getPlayablePath(Recording recording) async {
    // 1. 로컬 파일 확인
    if (await File(recording.localPath).exists()) {
      return recording.localPath;
    }

    // 2. 캐시 확인
    final cachedPath = await _downloadCache.get(recording.id);
    if (cachedPath != null) {
      return cachedPath;
    }

    // 3. 서버에서 다운로드
    if (recording.serverUrl != null) {
      return await _downloadAndCache(recording);
    }

    throw RecordingNotFoundException(recording.id);
  }

  /// 스트리밍 재생 URL 반환 (다운로드 없이)
  Future<String?> getStreamingUrl(Recording recording) async {
    if (recording.storageStatus == StorageStatus.active) {
      return recording.serverUrl;
    }

    // Archived 상태면 복원 요청 필요
    if (recording.storageStatus == StorageStatus.archived) {
      await _requestRestore(recording);
      return null; // 복원 완료 후 재시도 필요
    }

    return null;
  }
}
```

#### B. ChunkedUploader (청크 업로드)

```dart
/// 대용량 파일 청크 업로드
class ChunkedUploader {
  static const int chunkSize = 1024 * 1024; // 1MB
  static const int maxRetries = 3;

  /// 파일을 청크로 분할하여 업로드
  Future<UploadResult> upload(Recording recording) async {
    final file = File(recording.localPath);
    final fileSize = await file.length();
    final totalChunks = (fileSize / chunkSize).ceil();

    // 이전 업로드 진행 상태 확인 (이어서 업로드)
    final progress = await _getUploadProgress(recording.id);
    int startChunk = progress?.lastCompletedChunk ?? 0;

    // 업로드 세션 생성/재개
    final sessionId = progress?.sessionId ??
        await _createUploadSession(recording, totalChunks);

    // 청크별 업로드
    for (int i = startChunk; i < totalChunks; i++) {
      final chunk = await _readChunk(file, i, chunkSize);

      int retries = 0;
      bool success = false;

      while (!success && retries < maxRetries) {
        try {
          await _uploadChunk(sessionId, i, chunk);
          await _saveProgress(recording.id, sessionId, i);
          success = true;

          // 진행률 알림
          _notifyProgress(recording.id, (i + 1) / totalChunks);
        } catch (e) {
          retries++;
          if (retries >= maxRetries) {
            return UploadResult.failed(
              recordingId: recording.id,
              failedAtChunk: i,
              error: e.toString(),
            );
          }
          await Future.delayed(Duration(seconds: retries * 2));
        }
      }
    }

    // 업로드 완료 - 서버에서 청크 병합
    final serverUrl = await _completeUpload(sessionId);

    return UploadResult.success(
      recordingId: recording.id,
      serverUrl: serverUrl,
    );
  }
}
```

#### C. RecordingStorageManager (저장소 관리)

```dart
/// 디바이스 저장공간 관리
class RecordingStorageManager {
  static const int maxLocalStorageMB = 500; // 최대 500MB
  static const int warningThresholdMB = 400; // 400MB 경고

  /// 저장공간 상태 확인
  Future<StorageState> checkStorage() async {
    final usedBytes = await _calculateUsedStorage();
    final usedMB = usedBytes / (1024 * 1024);

    if (usedMB > maxLocalStorageMB) {
      return StorageState.full;
    } else if (usedMB > warningThresholdMB) {
      return StorageState.warning;
    }
    return StorageState.normal;
  }

  /// 자동 정리 (오래된 동기화 완료 녹음 삭제)
  Future<CleanupResult> autoCleanup() async {
    final recordings = await _getLocalRecordings();

    // 정리 대상: 동기화 완료 + 30일 이상 재생 안 함
    final toDelete = recordings.where((r) =>
      r.storageStatus == StorageStatus.active &&
      r.lastPlayedAt != null &&
      DateTime.now().difference(r.lastPlayedAt!).inDays > 30
    ).toList();

    // 오래된 순으로 정렬
    toDelete.sort((a, b) => a.lastPlayedAt!.compareTo(b.lastPlayedAt!));

    int freedBytes = 0;
    int deletedCount = 0;

    for (final recording in toDelete) {
      if (await _deleteLocalFile(recording)) {
        freedBytes += await _getFileSize(recording.localPath);
        deletedCount++;
      }

      // 목표 용량 도달 시 중단
      if (await _calculateUsedStorage() < warningThresholdMB * 1024 * 1024) {
        break;
      }
    }

    return CleanupResult(
      deletedCount: deletedCount,
      freedBytes: freedBytes,
    );
  }

  /// 수동 다운로드 (오프라인 재생용)
  Future<void> downloadForOffline(List<Recording> recordings) async {
    for (final recording in recordings) {
      if (!await File(recording.localPath).exists() &&
          recording.serverUrl != null) {
        await _downloadToLocal(recording);
      }
    }
  }
}
```

### 1.4 녹음 저장 설정

```dart
/// 녹음 저장 설정 (로컬 중심)
@HiveType(typeId: 101)
class RecordingStorageSettings extends HiveObject {
  @HiveField(0)
  final int localStorageLimitMB;  // 로컬 저장 한도 (기본 500MB)

  @HiveField(1)
  final int keepLocalDays;  // 로컬 보관 기간 (기본 무제한)

  @HiveField(2)
  final bool wifiOnlyShare;  // WiFi에서만 공유 업로드 (기본 true)

  @HiveField(3)
  final bool showShareUploadProgress;  // 공유 시 업로드 진행률 표시

  const RecordingStorageSettings({
    this.localStorageLimitMB = 500,
    this.keepLocalDays = -1,  // -1: 무제한
    this.wifiOnlyShare = true,
    this.showShareUploadProgress = true,
  });
}

/// 공유 옵션 (타인 공유 시)
class ShareOptions {
  final Duration? expiresAfter;  // 링크 만료 기간 (null: 무제한)
  final bool allowDownload;       // 다운로드 허용
  final bool requirePassword;     // 비밀번호 필요

  const ShareOptions({
    this.expiresAfter,
    this.allowDownload = false,
    this.requirePassword = false,
  });
}
```

### 1.5 서버 저장소 계층 (공유된 녹음만)

> **참고**: 서버 저장소는 **공유된 녹음**에만 사용됩니다.
> 공유되지 않은 일반 녹음은 로컬에만 저장됩니다.

```
┌─────────────────────────────────────────────────────────────┐
│            서버 스토리지 티어 (공유 녹음 전용)                │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Tier 1: Hot Storage (활성)                                 │
│  ├─ 저장소: S3 Standard                                     │
│  ├─ 대상: 최근 90일 내 공유된 녹음                          │
│  ├─ 접근: 즉시 스트리밍 가능                                │
│  └─ 비용: 중간 (공유 녹음만이므로 전체 비용 낮음)           │
│                                                              │
│  Tier 2: Cold Storage (아카이브)                            │
│  ├─ 저장소: S3 Glacier                                      │
│  ├─ 대상: 90일 이상 경과한 공유 녹음                        │
│  ├─ 접근: 복원 필요 (수 분 ~ 수 시간)                       │
│  └─ 비용: 낮음                                              │
│                                                              │
│  비용 절감 효과:                                             │
│  ├─ 전체 녹음 중 ~5-10%만 서버 저장                         │
│  ├─ 대부분 로컬 저장으로 서버 비용 최소화                   │
│  └─ 공유 시에만 업로드로 대역폭 절약                        │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 1.6 공유 흐름 (UX)

```
┌─────────────────────────────────────────────────────────────┐
│                    선생님에게 녹음 공유                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. 녹음 카드에서 "공유" 버튼 클릭                           │
│     ┌─────────────────────────────────────┐                 │
│     │  🎵 연습 녹음 (1:23)               │                 │
│     │  2025-01-11 14:30                  │                 │
│     │                                     │                 │
│     │  [▶️ 재생]  [📤 공유]  [🗑️ 삭제]   │                 │
│     └─────────────────────────────────────┘                 │
│                                                              │
│  2. 공유 대상 선택 (Bottom Sheet)                           │
│     ┌─────────────────────────────────────┐                 │
│     │  공유 대상 선택                      │                 │
│     │                                     │                 │
│     │  👩‍🏫 김선생님 (담당 선생님)          │                 │
│     │  👥 링크로 공유 (향후)              │                 │
│     └─────────────────────────────────────┘                 │
│                                                              │
│  3. 업로드 진행률 표시                                       │
│     ┌─────────────────────────────────────┐                 │
│     │  📤 업로드 중... 45%               │                 │
│     │  ████████░░░░░░░░░                  │                 │
│     │  1.2MB / 2.7MB                      │                 │
│     └─────────────────────────────────────┘                 │
│                                                              │
│  4. 공유 완료                                                │
│     ┌─────────────────────────────────────┐                 │
│     │  ✅ 김선생님에게 공유되었습니다      │                 │
│     │                                     │                 │
│     │  선생님이 레슨 노트에서             │                 │
│     │  이 녹음을 확인할 수 있습니다       │                 │
│     └─────────────────────────────────────┘                 │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 1.7 공유 상태 표시

```dart
/// 녹음 공유 상태
enum RecordingShareStatus {
  local,        // 로컬에만 저장 (공유 안 함)
  uploading,    // 공유를 위해 업로드 중
  shared,       // 공유 완료 (서버에 있음)
  failed,       // 업로드 실패
}

/// 공유 대상 정보
class ShareTarget {
  final String id;
  final ShareTargetType type;  // teacher, publicLink
  final String name;           // "김선생님", "공개 링크"
  final DateTime sharedAt;
}
```

---

## 2. 다중 기기 지원 설계

### 2.1 다중 기기 시나리오

```
사용자 A (학생)
├─ iPhone (주 기기) - 평상시 연습
├─ iPad (보조) - 레슨 시 사용
└─ Android 태블릿 (예비) - 집에서 사용

필요 기능:
1. 어떤 기기에서 연습해도 기록 동기화
2. 녹음 파일은 필요한 기기에서만 다운로드
3. 동시 수정 시 충돌 해결
4. 기기 분실 시 원격 로그아웃
```

### 2.2 기기 식별 및 관리

#### A. Device 모델

```dart
/// 등록된 기기 정보
@HiveType(typeId: 102)
class RegisteredDevice extends HiveObject {
  @HiveField(0)
  final String deviceId;  // UUID (기기별 고유)

  @HiveField(1)
  final String deviceName;  // "iPhone 15 Pro"

  @HiveField(2)
  final DevicePlatform platform;  // iOS, Android

  @HiveField(3)
  final String osVersion;  // "iOS 17.2"

  @HiveField(4)
  final String appVersion;  // "1.2.0"

  @HiveField(5)
  final DateTime registeredAt;

  @HiveField(6)
  final DateTime lastActiveAt;

  @HiveField(7)
  final bool isCurrentDevice;

  @HiveField(8)
  final DeviceStatus status;  // active, suspended, revoked
}

enum DevicePlatform { iOS, android, web, macOS, windows }
enum DeviceStatus { active, suspended, revoked }
```

#### B. DeviceManager

```dart
/// 기기 관리 서비스
class DeviceManager {
  /// 기기 등록 (첫 로그인 시)
  Future<RegisteredDevice> registerDevice() async {
    final deviceInfo = await _getDeviceInfo();

    final device = RegisteredDevice(
      deviceId: await _getOrCreateDeviceId(),
      deviceName: deviceInfo.name,
      platform: deviceInfo.platform,
      osVersion: deviceInfo.osVersion,
      appVersion: _appVersion,
      registeredAt: DateTime.now(),
      lastActiveAt: DateTime.now(),
      isCurrentDevice: true,
      status: DeviceStatus.active,
    );

    await _api.registerDevice(device);
    await _local.saveDevice(device);

    return device;
  }

  /// 기기 목록 조회
  Future<List<RegisteredDevice>> getDevices() async {
    return await _api.getDevices();
  }

  /// 원격 로그아웃 (다른 기기에서)
  Future<void> revokeDevice(String deviceId) async {
    await _api.revokeDevice(deviceId);
    // 해당 기기는 다음 동기화 시 로그아웃됨
  }

  /// 기기 상태 확인 (앱 시작 시)
  Future<DeviceCheckResult> checkDeviceStatus() async {
    final status = await _api.checkDeviceStatus(_currentDeviceId);

    if (status == DeviceStatus.revoked) {
      await _forceLogout();
      return DeviceCheckResult.revoked;
    }

    if (status == DeviceStatus.suspended) {
      return DeviceCheckResult.suspended;
    }

    // 활성 상태 갱신
    await _api.updateLastActive(_currentDeviceId);
    return DeviceCheckResult.active;
  }
}
```

### 2.3 다중 기기 동기화

#### A. Vector Clock (인과 순서 추적)

```dart
/// 분산 시스템 인과 순서 추적
class VectorClock {
  final Map<String, int> _clock;  // deviceId -> counter

  VectorClock([Map<String, int>? initial])
      : _clock = Map.from(initial ?? {});

  /// 로컬 이벤트 발생 시 증가
  void increment(String deviceId) {
    _clock[deviceId] = (_clock[deviceId] ?? 0) + 1;
  }

  /// 다른 클럭과 병합 (max 값 사용)
  void merge(VectorClock other) {
    for (final entry in other._clock.entries) {
      _clock[entry.key] = max(_clock[entry.key] ?? 0, entry.value);
    }
  }

  /// 인과 관계 비교
  ClockComparison compareTo(VectorClock other) {
    bool thisGreater = false;
    bool otherGreater = false;

    final allKeys = {..._clock.keys, ...other._clock.keys};

    for (final key in allKeys) {
      final thisVal = _clock[key] ?? 0;
      final otherVal = other._clock[key] ?? 0;

      if (thisVal > otherVal) thisGreater = true;
      if (otherVal > thisVal) otherGreater = true;
    }

    if (thisGreater && otherGreater) return ClockComparison.concurrent;
    if (thisGreater) return ClockComparison.after;
    if (otherGreater) return ClockComparison.before;
    return ClockComparison.equal;
  }

  Map<String, int> toJson() => Map.from(_clock);
}

enum ClockComparison { before, after, equal, concurrent }
```

#### B. SyncableEntity (동기화 가능 엔티티)

```dart
/// 동기화 가능한 엔티티 기본 클래스
abstract class SyncableEntity {
  String get id;
  String get deviceId;  // 생성/수정한 기기
  DateTime get updatedAt;
  VectorClock get vectorClock;
  bool get isDeleted;  // 소프트 삭제

  /// 충돌 해결을 위한 우선순위
  int get conflictPriority => 0;

  /// 병합 가능 여부
  bool canMergeWith(SyncableEntity other);

  /// 병합 실행
  SyncableEntity mergeWith(SyncableEntity other);
}
```

#### C. MultiDeviceSyncEngine

```dart
/// 다중 기기 동기화 엔진
class MultiDeviceSyncEngine {
  final String _currentDeviceId;
  final ConflictResolver _resolver;

  /// 동기화 실행
  Future<SyncResult> sync() async {
    // 1. 로컬 변경사항 수집
    final localChanges = await _collectLocalChanges();

    // 2. 서버에 푸시
    final pushResult = await _pushChanges(localChanges);

    // 3. 서버에서 풀
    final serverChanges = await _pullChanges(
      since: await _getLastSyncTime(),
    );

    // 4. 충돌 해결 및 병합
    final resolvedChanges = await _resolveConflicts(
      local: localChanges,
      server: serverChanges,
    );

    // 5. 로컬 적용
    await _applyChanges(resolvedChanges);

    // 6. 동기화 시간 갱신
    await _updateLastSyncTime();

    return SyncResult(
      pushed: pushResult.count,
      pulled: resolvedChanges.length,
      conflicts: resolvedChanges.where((c) => c.hadConflict).length,
    );
  }

  /// 충돌 해결
  Future<List<ResolvedChange>> _resolveConflicts({
    required List<SyncableEntity> local,
    required List<SyncableEntity> server,
  }) async {
    final results = <ResolvedChange>[];

    // 서버 변경사항 맵
    final serverMap = {for (var e in server) e.id: e};

    for (final localEntity in local) {
      final serverEntity = serverMap[localEntity.id];

      if (serverEntity == null) {
        // 충돌 없음 - 로컬만 있음
        results.add(ResolvedChange(
          entity: localEntity,
          hadConflict: false,
        ));
        continue;
      }

      // Vector Clock으로 인과 관계 확인
      final comparison = localEntity.vectorClock.compareTo(
        serverEntity.vectorClock,
      );

      switch (comparison) {
        case ClockComparison.after:
          // 로컬이 최신
          results.add(ResolvedChange(
            entity: localEntity,
            hadConflict: false,
          ));
          break;

        case ClockComparison.before:
          // 서버가 최신
          results.add(ResolvedChange(
            entity: serverEntity,
            hadConflict: false,
          ));
          break;

        case ClockComparison.concurrent:
          // 동시 수정 - 충돌 해결 필요
          final resolved = await _resolver.resolve(
            local: localEntity,
            server: serverEntity,
          );
          results.add(ResolvedChange(
            entity: resolved,
            hadConflict: true,
          ));
          break;

        case ClockComparison.equal:
          // 동일 - 스킵
          break;
      }
    }

    // 서버에만 있는 변경사항 추가
    for (final serverEntity in server) {
      if (!local.any((l) => l.id == serverEntity.id)) {
        results.add(ResolvedChange(
          entity: serverEntity,
          hadConflict: false,
        ));
      }
    }

    return results;
  }
}
```

### 2.4 데이터 유형별 충돌 해결

```dart
/// 충돌 해결 전략
class ConflictResolver {
  Future<SyncableEntity> resolve({
    required SyncableEntity local,
    required SyncableEntity server,
  }) async {
    // 엔티티 타입별 전략 적용
    return switch (local.runtimeType) {
      PracticeRepertoire => _resolveRepertoire(local, server),
      PracticeSection => _resolveSection(local, server),
      Recording => _resolveRecording(local, server),
      Lesson => _resolveLesson(local, server),
      Payment => _resolvePayment(local, server),
      _ => _defaultResolve(local, server),
    };
  }

  /// 레퍼토리 충돌 해결 - 필드별 병합
  SyncableEntity _resolveRepertoire(
    SyncableEntity local,
    SyncableEntity server,
  ) {
    final l = local as PracticeRepertoire;
    final s = server as PracticeRepertoire;

    // 필드별 최신 값 선택
    return l.copyWith(
      name: _newer(l, s).name,
      description: _newer(l, s).description,
      startDate: _newer(l, s).startDate,
      endDate: _newer(l, s).endDate,
      // 섹션은 별도 동기화
      vectorClock: l.vectorClock..merge(s.vectorClock),
    );
  }

  /// 섹션 충돌 해결 - 완료 상태 병합
  SyncableEntity _resolveSection(
    SyncableEntity local,
    SyncableEntity server,
  ) {
    final l = local as PracticeSection;
    final s = server as PracticeSection;

    // dailyStatuses는 날짜별로 병합 (둘 다 유지)
    final mergedStatuses = _mergeDailyStatuses(
      l.dailyStatuses,
      s.dailyStatuses,
    );

    return l.copyWith(
      pieceName: _newer(l, s).pieceName,
      dailyStatuses: mergedStatuses,
      practiceCount: max(l.practiceCount, s.practiceCount),
      totalPracticeSeconds: max(l.totalPracticeSeconds, s.totalPracticeSeconds),
      vectorClock: l.vectorClock..merge(s.vectorClock),
    );
  }

  /// 녹음 충돌 해결 - 클라이언트 우선
  SyncableEntity _resolveRecording(
    SyncableEntity local,
    SyncableEntity server,
  ) {
    // 녹음은 생성한 기기의 버전 우선
    final l = local as Recording;
    final s = server as Recording;

    if (l.deviceId == _currentDeviceId) {
      return l;
    }
    return s;
  }

  /// 레슨 충돌 해결 - 서버 우선 (예약 시간)
  SyncableEntity _resolveLesson(
    SyncableEntity local,
    SyncableEntity server,
  ) {
    final l = local as Lesson;
    final s = server as Lesson;

    // 시간/상태는 서버 우선, 노트는 병합
    return s.copyWith(
      notes: _mergeNotes(l.notes, s.notes),
      vectorClock: l.vectorClock..merge(s.vectorClock),
    );
  }

  /// 결제 충돌 해결 - 서버 항상 우선
  SyncableEntity _resolvePayment(
    SyncableEntity local,
    SyncableEntity server,
  ) {
    return server;  // 금전 관련은 서버가 진실의 원천
  }
}
```

### 2.5 기기 관리 UI

```
┌─────────────────────────────────────────┐
│          연결된 기기 관리                │
├─────────────────────────────────────────┤
│                                          │
│  📱 iPhone 15 Pro (현재 기기)           │
│     마지막 활동: 방금 전                 │
│     버전: 1.2.0                          │
│                                          │
│  📱 iPad Pro 12.9                       │
│     마지막 활동: 2시간 전                │
│     버전: 1.2.0                          │
│     [로그아웃]                           │
│                                          │
│  📱 Galaxy Tab S9                       │
│     마지막 활동: 3일 전                  │
│     버전: 1.1.8 (업데이트 필요)          │
│     [로그아웃]                           │
│                                          │
├─────────────────────────────────────────┤
│  [+ 새 기기 추가]                        │
│                                          │
│  💡 동시 로그인 가능 기기: 최대 5대      │
└─────────────────────────────────────────┘
```

---

## 3. 통합 아키텍처

### 3.1 전체 동기화 흐름

```
┌────────────────────────────────────────────────────────────────────┐
│                         통합 동기화 흐름                            │
├────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  기기 A (iPhone)                    서버                            │
│  ┌─────────────┐                   ┌─────────────┐                 │
│  │ Local Store │ ──Push──────────→ │   API       │                 │
│  │   (Hive)    │ ←─Pull──────────  │  Server     │                 │
│  └─────────────┘                   └──────┬──────┘                 │
│        ↑                                  │                         │
│        │                                  ↓                         │
│        │                           ┌─────────────┐                 │
│        │                           │  Database   │                 │
│        │                           │ (PostgreSQL)│                 │
│        │                           └──────┬──────┘                 │
│        │                                  │                         │
│        │                                  ↓                         │
│  기기 B (iPad)                     ┌─────────────┐                 │
│  ┌─────────────┐                   │   Storage   │                 │
│  │ Local Store │ ←─Pull──────────  │    (S3)     │                 │
│  │   (Hive)    │ ──Push──────────→ │             │                 │
│  └─────────────┘                   └─────────────┘                 │
│                                                                     │
│  동기화 순서:                                                       │
│  1. 메타데이터 먼저 (빠름)                                         │
│  2. 녹음 파일은 조건부 (WiFi, 필요시)                              │
│  3. Vector Clock으로 충돌 감지                                      │
│  4. 정책에 따라 자동 해결                                          │
│                                                                     │
└────────────────────────────────────────────────────────────────────┘
```

### 3.2 구현 우선순위

| 우선순위 | 기능 | 복잡도 | 비고 |
|---------|------|-------|------|
| 1 | 기기 등록/관리 | 낮음 | 인증 시스템과 연동 |
| 2 | 메타데이터 동기화 | 중간 | Vector Clock 필요 |
| 3 | 녹음 파일 업로드 | 중간 | 청크 업로드 |
| 4 | 녹음 파일 다운로드 | 낮음 | 스트리밍 우선 |
| 5 | 충돌 해결 | 높음 | 데이터 유형별 전략 |
| 6 | 저장소 관리 | 낮음 | 자동 정리 |
| 7 | 기기 원격 관리 | 낮음 | 보안 기능 |

---

## 4. API 설계 (참고)

### 4.1 녹음 관련 엔드포인트

```
POST   /api/v1/recordings/upload/init
       - 업로드 세션 생성
       - Response: { sessionId, presignedUrls[] }

PUT    /api/v1/recordings/upload/{sessionId}/chunk/{index}
       - 청크 업로드

POST   /api/v1/recordings/upload/{sessionId}/complete
       - 업로드 완료, 청크 병합
       - Response: { serverUrl }

GET    /api/v1/recordings/{id}/stream
       - 스트리밍 URL 반환

POST   /api/v1/recordings/{id}/restore
       - 아카이브된 녹음 복원 요청
```

### 4.2 동기화 엔드포인트

```
POST   /api/v1/sync/push
       - 로컬 변경사항 푸시
       - Body: { changes[], vectorClock }

GET    /api/v1/sync/pull?since={timestamp}&deviceId={id}
       - 서버 변경사항 풀

POST   /api/v1/sync/resolve
       - 충돌 해결 (수동)
       - Body: { conflictId, resolution }
```

### 4.3 기기 관리 엔드포인트

```
POST   /api/v1/devices/register
GET    /api/v1/devices
DELETE /api/v1/devices/{deviceId}
POST   /api/v1/devices/{deviceId}/revoke
```

---

## 5. 결론

### 핵심 포인트

1. **녹음 파일**: **Share-Triggered Sync** - 공유 시에만 서버 업로드
   - 일반 녹음: 로컬에만 저장 (서버 비용 절감)
   - 선생님/타인 공유: 공유 버튼 클릭 시 업로드
2. **다중 기기**: Vector Clock으로 인과 순서 추적 + 자동 충돌 해결
3. **저장소 관리**: 로컬 중심 + 공유 녹음만 서버 저장

### 비용 절감 효과

| 항목 | 자동 동기화 방식 | Share-Triggered 방식 |
|------|----------------|---------------------|
| 서버 저장 비율 | 100% | ~5-10% |
| 업로드 대역폭 | 높음 | 최소 |
| 서버 비용 | 높음 | 낮음 |
| 사용자 경험 | 자동 | 명시적 공유 |

### 다음 단계

1. 기본 Offline-First 아키텍처 구현 (Phase 1-2)
2. 선생님 공유 기능 구현 (Phase 3)
3. 다중 기기 지원 추가 (Phase 4)
4. 타인 공유 기능 확장 (향후)

---

## 관련 문서

- [Offline-First 아키텍처](./offline_first_architecture.md)
- [데이터 백업 전략](../specs/practice/data_backup_strategy.md)
