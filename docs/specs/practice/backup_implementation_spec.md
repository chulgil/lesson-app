# 백업 시스템 구현 스펙

> 작성일: 2026-01-03
> 상태: Draft
> 관련 문서: [data_backup_strategy.md](data_backup_strategy.md)

---

## 1. 개요

### 1.1 목적

앱 재설치 시에도 녹음 파일과 데이터를 복원할 수 있는 백업 시스템 구현

### 1.2 범위

| 기능 | Phase 1 | Phase 2 | Phase 3 |
|------|:-------:|:-------:|:-------:|
| Files 앱 노출 (iOS) | ✅ | - | - |
| ZIP 백업/복원 | ✅ | - | - |
| iCloud 자동 백업 | - | ✅ | - |
| Google Drive 백업 | - | ✅ | - |
| 서버 백업 | - | - | ✅ |

---

## 2. Phase 1: 기본 백업 기능

### 2.1 Files 앱 노출 (iOS)

#### 2.1.1 Info.plist 설정

```xml
<!-- ios/Runner/Info.plist -->

<!-- Documents 폴더를 Files 앱에 노출 -->
<key>UIFileSharingEnabled</key>
<true/>

<!-- 문서를 제자리에서 열기 허용 -->
<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>
```

#### 2.1.2 폴더 구조

```
Files 앱 → 나의 iPhone → LessonApp/
├── recordings/
│   ├── {repertoireId}/
│   │   ├── recording_uuid.m4a
│   │   └── recording_uuid.m4a.trim
│   └── ...
├── backups/
│   └── backup_2026-01-03.lessonbackup
└── hive/
    └── (Hive DB 파일들)
```

### 2.2 ZIP 백업/복원

#### 2.2.1 백업 데이터 구조

```dart
/// 백업 아카이브 구조
/// .lessonbackup 파일 = ZIP 형식
class BackupArchive {
  /// 녹음 파일들
  final List<RecordingFile> recordings;

  /// Hive DB 스냅샷 (JSON)
  final Map<String, dynamic> hiveSnapshot;

  /// 백업 메타데이터
  final BackupMetadata metadata;
}

class BackupMetadata {
  final String appVersion;
  final String backupVersion;  // '1.0'
  final DateTime createdAt;
  final int recordingCount;
  final int totalSizeBytes;
  final String deviceModel;
  final String osVersion;
}
```

#### 2.2.2 백업 서비스

```dart
// lib/services/backup/backup_service.dart

import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';

class BackupService {
  /// 전체 백업 아카이브 생성
  Future<File> createBackup() async {
    final archive = Archive();

    // 1. 메타데이터 추가
    final metadata = await _createMetadata();
    archive.addFile(ArchiveFile(
      'metadata.json',
      metadata.length,
      utf8.encode(metadata),
    ));

    // 2. Hive DB 스냅샷 추가
    final hiveSnapshot = await _exportHiveToJson();
    archive.addFile(ArchiveFile(
      'hive_snapshot.json',
      hiveSnapshot.length,
      utf8.encode(hiveSnapshot),
    ));

    // 3. 녹음 파일들 추가
    final recordings = await _getRecordingFiles();
    for (final recording in recordings) {
      final relativePath = _getRelativePath(recording.path);
      final bytes = await File(recording.path).readAsBytes();
      archive.addFile(ArchiveFile(
        'recordings/$relativePath',
        bytes.length,
        bytes,
      ));

      // .trim 파일도 포함
      final trimFile = File('${recording.path}.trim');
      if (await trimFile.exists()) {
        final trimBytes = await trimFile.readAsBytes();
        archive.addFile(ArchiveFile(
          'recordings/$relativePath.trim',
          trimBytes.length,
          trimBytes,
        ));
      }
    }

    // 4. ZIP 압축
    final zipBytes = ZipEncoder().encode(archive)!;

    // 5. 파일 저장
    final backupDir = await _getBackupDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupFile = File('${backupDir.path}/backup_$timestamp.lessonbackup');
    await backupFile.writeAsBytes(zipBytes);

    return backupFile;
  }

  /// 백업에서 복원
  Future<RestoreResult> restoreFromBackup(File backupFile) async {
    final bytes = await backupFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    int restoredRecordings = 0;
    int skippedRecordings = 0;

    for (final file in archive) {
      if (file.isFile) {
        if (file.name == 'hive_snapshot.json') {
          // Hive 복원
          await _restoreHiveFromJson(utf8.decode(file.content));
        } else if (file.name.startsWith('recordings/')) {
          // 녹음 파일 복원
          final destPath = await _getRecordingDestPath(file.name);
          final destFile = File(destPath);

          if (await destFile.exists()) {
            skippedRecordings++;
          } else {
            await destFile.parent.create(recursive: true);
            await destFile.writeAsBytes(file.content);
            restoredRecordings++;
          }
        }
      }
    }

    return RestoreResult(
      success: true,
      restoredRecordings: restoredRecordings,
      skippedRecordings: skippedRecordings,
    );
  }

  /// Hive DB를 JSON으로 내보내기
  Future<String> _exportHiveToJson() async {
    final export = <String, dynamic>{};

    // practice_recordings box
    final recordingsBox = Hive.box<PracticeRecording>('practice_recordings');
    export['practice_recordings'] = recordingsBox.values
        .map((r) => r.toJson())
        .toList();

    // practice_tasks box
    final tasksBox = Hive.box<PracticeTask>('practice_tasks');
    export['practice_tasks'] = tasksBox.values
        .map((t) => t.toJson())
        .toList();

    // 기타 box들...

    return jsonEncode(export);
  }

  /// JSON에서 Hive 복원
  Future<void> _restoreHiveFromJson(String json) async {
    final data = jsonDecode(json) as Map<String, dynamic>;

    // practice_recordings 복원
    if (data.containsKey('practice_recordings')) {
      final box = Hive.box<PracticeRecording>('practice_recordings');
      for (final item in data['practice_recordings']) {
        final recording = PracticeRecording.fromJson(item);
        if (!box.containsKey(recording.id)) {
          await box.put(recording.id, recording);
        }
      }
    }

    // 기타 box들...
  }
}

class RestoreResult {
  final bool success;
  final int restoredRecordings;
  final int skippedRecordings;
  final String? errorMessage;

  RestoreResult({
    required this.success,
    this.restoredRecordings = 0,
    this.skippedRecordings = 0,
    this.errorMessage,
  });
}
```

#### 2.2.3 UI 컴포넌트

```dart
// lib/features/settings/presentation/screens/backup_settings_screen.dart

class BackupSettingsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backupState = ref.watch(backupStateProvider);

    return Scaffold(
      appBar: AppBar(title: Text('녹음 백업')),
      body: ListView(
        children: [
          // 백업 현황 카드
          _BackupStatusCard(
            recordingCount: backupState.recordingCount,
            totalSize: backupState.totalSize,
            lastBackup: backupState.lastBackupDate,
          ),

          const Divider(),

          // 수동 백업
          ListTile(
            leading: Icon(Icons.upload),
            title: Text('백업 내보내기'),
            subtitle: Text('모든 녹음과 데이터를 ZIP으로 내보내기'),
            onTap: () => _exportBackup(context, ref),
          ),

          // 복원
          ListTile(
            leading: Icon(Icons.download),
            title: Text('백업에서 복원'),
            subtitle: Text('이전에 내보낸 백업 파일에서 복원'),
            onTap: () => _importBackup(context, ref),
          ),

          const Divider(),

          // Files 앱 안내 (iOS)
          if (Platform.isIOS)
            _FilesAppGuide(),
        ],
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    // 진행 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('백업 생성 중...'),
          ],
        ),
      ),
    );

    try {
      final backupService = ref.read(backupServiceProvider);
      final backupFile = await backupService.createBackup();

      Navigator.pop(context); // 다이얼로그 닫기

      // 공유 시트 열기
      await Share.shareXFiles(
        [XFile(backupFile.path)],
        subject: 'LessonApp 백업',
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('백업 생성 실패: $e')),
      );
    }
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['lessonbackup', 'zip'],
    );

    if (result != null) {
      final file = File(result.files.single.path!);

      // 확인 다이얼로그
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('백업 복원'),
          content: Text('기존 데이터와 중복되는 녹음은 건너뜁니다. 복원하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('취소'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('복원'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final backupService = ref.read(backupServiceProvider);
        final restoreResult = await backupService.restoreFromBackup(file);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '복원 완료: ${restoreResult.restoredRecordings}개 복원, '
              '${restoreResult.skippedRecordings}개 건너뜀',
            ),
          ),
        );
      }
    }
  }
}
```

---

## 3. Phase 2: 클라우드 백업

### 3.1 iCloud 백업 (iOS)

#### 3.1.1 Xcode 설정

1. **Capabilities 추가**
   - Xcode → Runner → Signing & Capabilities
   - "+ Capability" → "iCloud" 선택
   - "iCloud Documents" 체크
   - Container: `iCloud.com.lessonapp.lessonApp`

2. **Entitlements 파일**

```xml
<!-- ios/Runner/Runner.entitlements -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "...">
<plist version="1.0">
<dict>
    <key>com.apple.developer.icloud-container-identifiers</key>
    <array>
        <string>iCloud.com.lessonapp.lessonApp</string>
    </array>
    <key>com.apple.developer.icloud-services</key>
    <array>
        <string>CloudDocuments</string>
    </array>
    <key>com.apple.developer.ubiquity-container-identifiers</key>
    <array>
        <string>iCloud.com.lessonapp.lessonApp</string>
    </array>
</dict>
</plist>
```

#### 3.1.2 iCloud 서비스

```dart
// lib/services/backup/icloud_backup_service.dart

import 'package:icloud_storage/icloud_storage.dart';

class ICloudBackupService {
  static const _containerId = 'iCloud.com.lessonapp.lessonApp';

  final ICloudStorage _iCloud = ICloudStorage();

  /// iCloud 사용 가능 여부 확인
  Future<bool> isAvailable() async {
    if (!Platform.isIOS) return false;
    try {
      await _iCloud.isAvailable(containerId: _containerId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 녹음 파일 업로드
  Future<void> uploadRecording(PracticeRecording recording) async {
    final file = File(recording.filePath);
    if (!await file.exists()) return;

    final relativePath = 'recordings/${recording.repertoireId}/${recording.id}.m4a';

    await _iCloud.upload(
      containerId: _containerId,
      filePath: file.path,
      destinationRelativePath: relativePath,
      onProgress: (progress) {
        // 진행률 업데이트
      },
    );

    // .trim 파일도 업로드
    final trimFile = File('${file.path}.trim');
    if (await trimFile.exists()) {
      await _iCloud.upload(
        containerId: _containerId,
        filePath: trimFile.path,
        destinationRelativePath: '$relativePath.trim',
      );
    }
  }

  /// iCloud에서 녹음 목록 가져오기
  Future<List<ICloudRecordingInfo>> listRecordings() async {
    final files = await _iCloud.gather(
      containerId: _containerId,
      relativePath: 'recordings/',
    );

    return files
        .where((f) => f.relativePath.endsWith('.m4a'))
        .map((f) => ICloudRecordingInfo(
          relativePath: f.relativePath,
          sizeBytes: f.sizeBytes,
          modifiedAt: f.contentChangeDate,
        ))
        .toList();
  }

  /// iCloud에서 녹음 다운로드
  Future<void> downloadRecording(String relativePath) async {
    final localDir = await getApplicationDocumentsDirectory();
    final destPath = '${localDir.path}/$relativePath';

    await Directory(File(destPath).parent.path).create(recursive: true);

    await _iCloud.download(
      containerId: _containerId,
      relativePath: relativePath,
      destinationFilePath: destPath,
      onProgress: (progress) {
        // 진행률 업데이트
      },
    );
  }

  /// 전체 동기화
  Future<SyncResult> syncAll() async {
    final localRecordings = await _getLocalRecordings();
    final cloudRecordings = await listRecordings();

    int uploaded = 0;
    int downloaded = 0;

    // 로컬 → 클라우드 (없는 것 업로드)
    for (final local in localRecordings) {
      final cloudPath = 'recordings/${local.repertoireId}/${local.id}.m4a';
      if (!cloudRecordings.any((c) => c.relativePath == cloudPath)) {
        await uploadRecording(local);
        uploaded++;
      }
    }

    // 클라우드 → 로컬 (없는 것 다운로드)
    for (final cloud in cloudRecordings) {
      final localPath = await _getLocalPathForCloud(cloud.relativePath);
      if (!await File(localPath).exists()) {
        await downloadRecording(cloud.relativePath);
        downloaded++;
      }
    }

    return SyncResult(uploaded: uploaded, downloaded: downloaded);
  }
}
```

### 3.2 Google Drive 백업 (Android)

#### 3.2.1 패키지 설정

```yaml
# pubspec.yaml
dependencies:
  google_sign_in: ^6.2.0
  googleapis: ^13.0.0
  googleapis_auth: ^1.4.0
  extension_google_sign_in_as_googleapis_auth: ^2.0.12
```

#### 3.2.2 Google Cloud Console 설정

1. Google Cloud Console에서 프로젝트 생성
2. Google Drive API 활성화
3. OAuth 2.0 클라이언트 ID 생성 (Android)
4. `android/app/google-services.json` 추가

#### 3.2.3 Google Drive 서비스

```dart
// lib/services/backup/google_drive_backup_service.dart

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

class GoogleDriveBackupService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveAppdataScope],
  );

  drive.DriveApi? _driveApi;

  /// Google 로그인 및 Drive API 초기화
  Future<bool> initialize() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return false;

      final client = await _googleSignIn.authenticatedClient();
      if (client == null) return false;

      _driveApi = drive.DriveApi(client);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 백업 파일 업로드
  Future<void> uploadBackup(File backupFile) async {
    if (_driveApi == null) throw Exception('Not initialized');

    final driveFile = drive.File()
      ..name = backupFile.uri.pathSegments.last
      ..parents = ['appDataFolder'];  // 앱 전용 폴더

    await _driveApi!.files.create(
      driveFile,
      uploadMedia: drive.Media(
        backupFile.openRead(),
        await backupFile.length(),
      ),
    );
  }

  /// 백업 목록 가져오기
  Future<List<DriveBackupInfo>> listBackups() async {
    if (_driveApi == null) throw Exception('Not initialized');

    final result = await _driveApi!.files.list(
      spaces: 'appDataFolder',
      $fields: 'files(id, name, size, modifiedTime)',
      orderBy: 'modifiedTime desc',
    );

    return result.files
        ?.where((f) => f.name?.endsWith('.lessonbackup') ?? false)
        .map((f) => DriveBackupInfo(
          id: f.id!,
          name: f.name!,
          sizeBytes: int.tryParse(f.size ?? '0') ?? 0,
          modifiedAt: f.modifiedTime ?? DateTime.now(),
        ))
        .toList() ?? [];
  }

  /// 백업 파일 다운로드
  Future<File> downloadBackup(String fileId) async {
    if (_driveApi == null) throw Exception('Not initialized');

    final response = await _driveApi!.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/restore_backup.lessonbackup');

    final sink = tempFile.openWrite();
    await response.stream.pipe(sink);
    await sink.close();

    return tempFile;
  }

  /// 가장 최신 백업에서 복원
  Future<RestoreResult?> restoreFromLatest() async {
    final backups = await listBackups();
    if (backups.isEmpty) return null;

    final latestBackup = backups.first;
    final backupFile = await downloadBackup(latestBackup.id);

    final backupService = BackupService();
    return await backupService.restoreFromBackup(backupFile);
  }
}
```

### 3.3 통합 백업 Provider

```dart
// lib/features/settings/presentation/providers/backup_provider.dart

@riverpod
class BackupNotifier extends _$BackupNotifier {
  @override
  Future<BackupState> build() async {
    return BackupState(
      recordingCount: await _getRecordingCount(),
      totalSize: await _getTotalSize(),
      lastBackupDate: await _getLastBackupDate(),
      iCloudEnabled: await _isICloudEnabled(),
      googleDriveEnabled: await _isGoogleDriveEnabled(),
    );
  }

  /// iCloud 백업 토글
  Future<void> toggleICloudBackup(bool enabled) async {
    if (enabled) {
      final iCloud = ICloudBackupService();
      if (await iCloud.isAvailable()) {
        await _savePreference('icloud_backup_enabled', true);
        state = AsyncData(state.value!.copyWith(iCloudEnabled: true));

        // 초기 동기화 시작
        await iCloud.syncAll();
      }
    } else {
      await _savePreference('icloud_backup_enabled', false);
      state = AsyncData(state.value!.copyWith(iCloudEnabled: false));
    }
  }

  /// Google Drive 백업 토글
  Future<void> toggleGoogleDriveBackup(bool enabled) async {
    if (enabled) {
      final gDrive = GoogleDriveBackupService();
      if (await gDrive.initialize()) {
        await _savePreference('gdrive_backup_enabled', true);
        state = AsyncData(state.value!.copyWith(googleDriveEnabled: true));
      }
    } else {
      await _savePreference('gdrive_backup_enabled', false);
      state = AsyncData(state.value!.copyWith(googleDriveEnabled: false));
    }
  }

  /// 새 녹음 자동 백업
  Future<void> onNewRecording(PracticeRecording recording) async {
    final currentState = state.value;
    if (currentState == null) return;

    if (Platform.isIOS && currentState.iCloudEnabled) {
      final iCloud = ICloudBackupService();
      await iCloud.uploadRecording(recording);
    }

    // Android는 주기적 백업으로 처리 (Google Drive API 호출 제한)
  }
}
```

---

## 4. 데이터 모델

### 4.1 백업 관련 모델

```dart
// lib/features/settings/domain/entities/backup_state.dart

@freezed
class BackupState with _$BackupState {
  const factory BackupState({
    required int recordingCount,
    required int totalSize,  // bytes
    DateTime? lastBackupDate,
    @Default(false) bool iCloudEnabled,
    @Default(false) bool googleDriveEnabled,
    @Default(false) bool isSyncing,
    String? lastError,
  }) = _BackupState;
}

@freezed
class BackupMetadata with _$BackupMetadata {
  const factory BackupMetadata({
    required String appVersion,
    required String backupVersion,
    required DateTime createdAt,
    required int recordingCount,
    required int totalSizeBytes,
    required String deviceModel,
    required String osVersion,
  }) = _BackupMetadata;

  factory BackupMetadata.fromJson(Map<String, dynamic> json) =>
      _$BackupMetadataFromJson(json);
}

@freezed
class RestoreResult with _$RestoreResult {
  const factory RestoreResult({
    required bool success,
    @Default(0) int restoredRecordings,
    @Default(0) int skippedRecordings,
    String? errorMessage,
  }) = _RestoreResult;
}
```

---

## 5. 라우트 및 네비게이션

```dart
// lib/core/router/routes/settings_routes.dart

// 백업 설정 화면 라우트 추가
GoRoute(
  path: '/settings/backup',
  name: 'backup-settings',
  builder: (context, state) => const BackupSettingsScreen(),
),
```

---

## 6. 테스트 시나리오

### 6.1 Phase 1 테스트

| 시나리오 | 예상 결과 |
|---------|----------|
| ZIP 백업 생성 | 모든 녹음 + 메타데이터 포함 |
| ZIP 복원 (빈 앱) | 모든 데이터 복원됨 |
| ZIP 복원 (데이터 있음) | 중복 건너뜀, 새 것만 추가 |
| Files 앱에서 확인 | Documents 폴더 접근 가능 |

### 6.2 Phase 2 테스트

| 시나리오 | 예상 결과 |
|---------|----------|
| iCloud 활성화 | 기존 녹음 동기화 시작 |
| 새 녹음 생성 | 자동으로 iCloud 업로드 |
| 앱 삭제 후 재설치 | iCloud에서 복원 옵션 표시 |
| 기기 간 동기화 | 다른 기기에서 녹음 접근 가능 |

---

## 7. 마이그레이션 가이드

### 기존 사용자 마이그레이션

```dart
// lib/services/backup/backup_migration_service.dart

class BackupMigrationService {
  /// 첫 번째 백업 설정 유도
  Future<void> promptFirstBackup(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final hasPrompted = prefs.getBool('backup_prompt_shown') ?? false;

    if (!hasPrompted) {
      final recordings = await _getRecordingCount();

      if (recordings > 0) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('녹음 백업 설정'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${recordings}개의 녹음이 있습니다.'),
                SizedBox(height: 8),
                Text('백업을 설정하면 앱을 삭제해도\n녹음을 복원할 수 있어요.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  prefs.setBool('backup_prompt_shown', true);
                  Navigator.pop(context);
                },
                child: Text('나중에'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/settings/backup');
                },
                child: Text('백업 설정'),
              ),
            ],
          ),
        );
      }

      await prefs.setBool('backup_prompt_shown', true);
    }
  }
}
```

---

## 8. 녹음 파일 관리 (추가 기능)

### 8.1 전체 녹음 파일 화면

사용자가 모든 녹음 파일을 한 곳에서 관리할 수 있는 화면입니다.

#### 8.1.1 접근 경로
- 프로필 > 레슨 녹음 파일
- 백업 설정 > 연결되지 않은 녹음

#### 8.1.2 기능
| 기능 | 설명 |
|------|------|
| 전체 녹음 조회 | 연결된/미연결 녹음 모두 표시 |
| 섹션 연결 변경 | 녹음의 섹션 연결 변경 가능 |
| 녹음 삭제 | 녹음 파일 삭제 |
| 녹음 재생 | RecordingPlayerSheet 모달 사용 |
| 녹음 가져오기 | 외부 파일에서 녹음 가져오기 |

#### 8.1.3 UI 구성
```
전체 녹음 파일
├── [+ 가져오기] [새로고침]  (AppBar)
├── 통계 카드 (전체/연결됨/미연결)
├── 연결되지 않은 녹음 섹션
│   └── 녹음 카드 (🔗 끊김 아이콘)
└── 연결된 녹음 섹션
    └── 녹음 카드 (🔗 연결 아이콘)
```

### 8.2 녹음 가져오기 기능

외부 오디오 파일을 앱으로 가져오는 기능입니다.

#### 8.2.1 지원 형식
- `.m4a` (권장)
- `.mp3`
- `.wav`
- `.aac`
- `.flac`

#### 8.2.2 가져오기 흐름
```
[+ 버튼 클릭]
    ↓
[파일 선택 (FilePicker)]
    ↓
[오디오 길이 분석 (just_audio)]
    ↓
[앱 recordings/imported/ 폴더로 복사]
    ↓
[Hive에 PracticeRecording 저장 (orphan 상태)]
    ↓
[UI 갱신]
```

#### 8.2.3 저장 경로
```
Documents/
└── recordings/
    └── imported/
        └── {uuid}.{extension}
```

### 8.3 관련 파일

| 파일 | 역할 |
|------|------|
| `all_recordings_screen.dart` | 전체 녹음 화면 |
| `orphan_recording_provider.dart` | 녹음 관리 Provider |
| `section_picker_screen.dart` | 섹션 선택 화면 |

---

## 9. 변경 이력

| 날짜 | 버전 | 변경 내용 |
|------|------|----------|
| 2026-01-03 | 1.0 | 초기 스펙 작성 |
| 2026-01-11 | 1.1 | 전체 녹음 화면, 녹음 가져오기 기능 추가 |
