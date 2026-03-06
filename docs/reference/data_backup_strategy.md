# 녹음 파일 및 Hive DB 백업 전략

> 작성일: 2026-01-03
> 관련 문서: [recording_requirement.md](recording_requirement.md), [recording_persistence_qa.md](../../proposal/recording_persistence_qa.md)

---

## 1. 문제 정의

### 현재 상황

앱 재설치 시 다음 데이터가 모두 초기화됩니다:

| 데이터 | 저장 위치 | 재설치 후 |
|--------|----------|----------|
| 녹음 파일 (.m4a) | Documents/recordings/ | ❌ 삭제됨 |
| Hive DB (메타데이터) | Documents/hive/ | ❌ 삭제됨 |
| 트림 메타데이터 (.trim) | Documents/recordings/ | ❌ 삭제됨 |
| 연습 기록, 설정 등 | Documents/hive/ | ❌ 삭제됨 |

### 사용자 시나리오

1. **앱 삭제 후 재설치**: 새 기기처럼 초기화됨
2. **기기 변경**: 이전 기기 데이터 접근 불가
3. **iOS 개발 모드 재배포**: 컨테이너 UUID 변경으로 경로 무효화 (Issue #9에서 해결)
4. **저장공간 부족으로 앱 삭제**: 데이터 완전 손실

---

## 2. 플랫폼별 저장소 구조 분석

### 2.1 iOS 저장소 구조

```
/var/mobile/Containers/Data/Application/{UUID}/
├── Documents/           ← 앱 주요 데이터 (iCloud 백업 대상)
│   ├── recordings/      ← 녹음 파일
│   └── hive/            ← Hive DB
├── Library/
│   ├── Caches/          ← 캐시 (iCloud 백업 제외)
│   ├── Preferences/     ← UserDefaults
│   └── Application Support/  ← Core Data, SQLite 등
└── tmp/                 ← 임시 파일 (자동 삭제)
```

#### iOS 앱 삭제 시 동작

| 조건 | Documents | Library | Keychain |
|------|-----------|---------|----------|
| 앱 삭제 | ❌ 삭제 | ❌ 삭제 | ❌ 삭제 (iOS 10.3+) |
| 앱 업데이트 | ✅ 유지 | ✅ 유지 | ✅ 유지 |
| iCloud 백업 포함 | ✅ 가능 | ⚠️ 일부 | ✅ 가능 |

#### iOS 데이터 영속성 옵션

| 방법 | 앱 삭제 후 유지 | 복잡도 | 비용 |
|------|:-------------:|:------:|:----:|
| **iCloud Documents** | ✅ | 중간 | 무료 (5GB) |
| **iCloud CloudKit** | ✅ | 높음 | 무료 쿼터 |
| **Files 앱 통합** | ⚠️ 수동 | 낮음 | 무료 |
| **기기 iCloud 백업** | ✅ | 없음 | 사용자 설정 |
| **자체 서버** | ✅ | 높음 | 서버 비용 |

### 2.2 Android 저장소 구조

```
/data/data/{package_name}/           ← 내부 저장소 (루트 필요)
├── files/                           ← getFilesDir()
├── cache/                           ← getCacheDir()
├── databases/                       ← SQLite, Hive
└── shared_prefs/                    ← SharedPreferences

/storage/emulated/0/Android/data/{package_name}/  ← 외부 저장소 (앱 전용)
├── files/                           ← getExternalFilesDir()
└── cache/                           ← getExternalCacheDir()

/storage/emulated/0/                 ← 공용 저장소 (Scoped Storage 제한)
├── Documents/
├── Music/
├── Pictures/
└── Downloads/
```

#### Android 앱 삭제 시 동작

| 저장소 | 앱 삭제 후 | 비고 |
|--------|----------|------|
| 내부 저장소 | ❌ 삭제 | 자동 정리 |
| 외부 앱 전용 | ❌ 삭제 | Android 10+ 자동 정리 |
| 공용 저장소 | ✅ 유지 | Scoped Storage 제한 (Android 11+) |
| Google Drive | ✅ 유지 | 수동 백업 필요 |

#### Android Scoped Storage 제약 (Android 11+)

```dart
// ❌ 더 이상 직접 접근 불가
File('/storage/emulated/0/Documents/myfile.m4a');

// ✅ MediaStore API 또는 SAF(Storage Access Framework) 필요
final result = await FilePicker.platform.saveFile(
  dialogTitle: 'Save recording',
  fileName: 'recording.m4a',
);
```

---

## 3. 경쟁사 앱 백업 전략 분석

### 3.1 음악 레슨/연습 앱

| 앱 | 저장 전략 | 클라우드 | 앱 삭제 후 | 특징 |
|---|---------|---------|-----------|------|
| **Yousician** | 서버 동기화 | ✅ 자체 서버 | ✅ 계정 복원 | 구독 기반, 모든 진도 서버 저장 |
| **Simply Piano** | 서버 동기화 | ✅ 자체 서버 | ✅ 계정 복원 | 구독 기반, 진도만 저장 |
| **Tonara** | 서버 + 로컬 | ✅ 자체 서버 | ⚠️ 부분 복원 | 녹음은 WAV, 선생님에게 전송 |
| **Trala** | 서버 동기화 | ✅ 자체 서버 | ✅ 계정 복원 | AI 피드백, 녹음 분석 |

### 3.2 악보 및 음악 관리 앱

| 앱 | 저장 전략 | 클라우드 | 앱 삭제 후 | 특징 |
|---|---------|---------|-----------|------|
| **forScore** | iCloud + 4SB | ✅ iCloud 동기화 | ✅ 완전 복원 | 4SB 아카이브 형식 |
| **Voice Memos** | iCloud | ✅ iCloud 동기화 | ✅ 완전 복원 | Apple 기본 앱 |
| **GarageBand** | iCloud Drive | ✅ iCloud 동기화 | ✅ 완전 복원 | 프로젝트 단위 |

### 3.3 경쟁사 전략 핵심 요약

```
┌─────────────────────────────────────────────────────────────────┐
│                    경쟁사 백업 전략 패턴                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  [구독 기반 앱] (Yousician, Simply Piano, Trala)                 │
│  ├── 모든 데이터 → 자체 서버 동기화                               │
│  ├── 로그인만 하면 어디서든 복원                                   │
│  └── 장점: 완벽한 복원 / 단점: 서버 비용, 개인정보                  │
│                                                                 │
│  [프리미엄 앱] (forScore)                                        │
│  ├── iCloud 동기화 (기기 간 자동)                                 │
│  ├── 4SB 아카이브 (수동 백업)                                     │
│  ├── Files 앱 통합 (수동 접근)                                    │
│  └── 장점: 사용자 제어권 / 단점: iOS 전용                         │
│                                                                 │
│  [기본 앱] (Voice Memos, GarageBand)                             │
│  ├── iCloud 자동 동기화                                          │
│  └── Apple 생태계 완전 통합                                       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 3.4 forScore 백업 시스템 상세 분석 (모범 사례)

forScore는 음악 앱 중 가장 완성도 높은 백업 시스템을 제공:

**1. 데이터 분류**
- Documents: PDF, 녹음, 트랙 → Files 앱에서 접근 가능
- Private: 어노테이션, 메타데이터, 설정 → 4SB 백업 필요

**2. 백업 형식**
- **4SB Backup**: Private 데이터만 포함 (작은 크기)
- **4SB Archive**: 모든 데이터 포함 (완전 백업)

**3. 복원 옵션**
- iCloud 자동 동기화
- iTunes/Finder 파일 공유
- Files 앱 통합
- 수동 4SB 아카이브 임포트

---

## 4. 백업 대안별 상세 분석

### 4.1 대안 1: 외부 저장소 (Android Only)

#### 구현 방법

```dart
// Android 공용 저장소에 백업
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ExternalStorageBackup {
  Future<void> backupToDocuments() async {
    // Android 11+ 에서는 MediaStore API 필요
    if (Platform.isAndroid) {
      final status = await Permission.manageExternalStorage.request();
      if (status.isGranted) {
        final externalDir = await getExternalStorageDirectory();
        // /storage/emulated/0/Android/data/{package}/files/ → 앱 삭제 시 삭제됨

        // 공용 Documents로 복사 필요
        final publicDir = Directory('/storage/emulated/0/Documents/LessonApp');
        // ... 파일 복사
      }
    }
  }
}
```

#### 장단점

| 장점 | 단점 |
|------|------|
| 서버 비용 없음 | Android 전용 |
| 즉시 구현 가능 | Scoped Storage 제약 (Android 11+) |
| 사용자 제어 가능 | 사용자가 수동으로 백업해야 함 |
| 오프라인 접근 | 기기 분실/파손 시 데이터 손실 |

#### 복잡도: ⭐⭐ (중간)

---

### 4.2 대안 2: 클라우드 저장소 (iCloud / Google Drive)

#### 4.2.1 iCloud Documents (iOS)

```dart
// pubspec.yaml
dependencies:
  icloud_storage: ^0.5.0

// iOS 설정 (Runner.entitlements)
// <key>com.apple.developer.icloud-services</key>
// <array><string>CloudDocuments</string></array>
```

```dart
class ICloudBackupService {
  final ICloudStorage _iCloud = ICloudStorage();

  Future<void> backupRecordings() async {
    final recordings = await getLocalRecordings();

    for (final recording in recordings) {
      await _iCloud.upload(
        containerId: 'iCloud.com.lessonapp.lessonApp',
        filePath: recording.filePath,
        destinationRelativePath: 'recordings/${recording.id}.m4a',
      );
    }
  }

  Future<void> restoreFromICloud() async {
    final files = await _iCloud.listFiles(
      containerId: 'iCloud.com.lessonapp.lessonApp',
      relativePath: 'recordings/',
    );

    for (final file in files) {
      await _iCloud.download(
        containerId: 'iCloud.com.lessonapp.lessonApp',
        relativePath: file.relativePath,
        destinationFilePath: '${await getDocumentsPath()}/recordings/${file.name}',
      );
    }
  }
}
```

#### 4.2.2 Google Drive (Android / Cross-platform)

```dart
// pubspec.yaml
dependencies:
  googleapis: ^13.0.0
  googleapis_auth: ^1.4.0
  google_sign_in: ^6.2.0
```

```dart
class GoogleDriveBackupService {
  late DriveApi _driveApi;

  Future<void> initialize() async {
    final googleUser = await GoogleSignIn(
      scopes: [DriveApi.driveAppdataScope],
    ).signIn();

    final authHeaders = await googleUser?.authHeaders;
    final client = GoogleAuthClient(authHeaders!);
    _driveApi = DriveApi(client);
  }

  Future<void> backupToAppDataFolder() async {
    final file = drive.File()
      ..name = 'backup_${DateTime.now().toIso8601String()}.zip'
      ..parents = ['appDataFolder'];  // 앱 전용 폴더 (사용자 Drive에서 안 보임)

    await _driveApi.files.create(
      file,
      uploadMedia: Media(
        Stream.fromIterable([backupZipBytes]),
        backupZipBytes.length,
      ),
    );
  }
}
```

#### 클라우드 옵션 비교

| 항목 | iCloud Documents | Google Drive |
|------|-----------------|--------------|
| **플랫폼** | iOS 전용 | Cross-platform |
| **무료 용량** | 5GB (계정) | 15GB (계정) |
| **앱 삭제 후** | ✅ 유지 | ✅ 유지 |
| **기기 간 동기화** | ✅ 자동 | ⚠️ 수동 |
| **사용자 인증** | Apple ID (자동) | Google 로그인 필요 |
| **구현 복잡도** | 중간 | 높음 |
| **오프라인 지원** | ✅ | ⚠️ 제한적 |

#### 복잡도: ⭐⭐⭐ (높음)

---

### 4.3 대안 3: 자체 백엔드 서버

#### 아키텍처

```
┌───────────────┐     ┌───────────────┐     ┌───────────────┐
│   Flutter     │────▶│   FastAPI     │────▶│     S3/R2     │
│     App       │◀────│   Backend     │◀────│   Storage     │
└───────────────┘     └───────────────┘     └───────────────┘
        │                     │                     │
        │                     │                     │
        ▼                     ▼                     ▼
   녹음/재생          인증/메타데이터            파일 저장
```

#### API 설계 예시

```python
# FastAPI Backend
from fastapi import FastAPI, UploadFile, Depends
import boto3

app = FastAPI()

@app.post("/api/recordings/upload")
async def upload_recording(
    file: UploadFile,
    user: User = Depends(get_current_user)
):
    # S3/R2에 업로드
    s3_client.upload_fileobj(
        file.file,
        bucket_name,
        f"recordings/{user.id}/{file.filename}"
    )

    # 메타데이터 저장
    await db.recordings.insert_one({
        "user_id": user.id,
        "filename": file.filename,
        "uploaded_at": datetime.utcnow(),
    })

    return {"status": "success"}

@app.get("/api/recordings/list")
async def list_recordings(user: User = Depends(get_current_user)):
    recordings = await db.recordings.find({"user_id": user.id}).to_list()
    return recordings
```

#### 비용 분석 (월간)

| 구성요소 | 사용량 | 비용 (USD) |
|---------|-------|-----------|
| Cloudflare R2 | 10GB | $0.015/GB = $0.15 |
| Railway/Render | 512MB RAM | $5-10 |
| MongoDB Atlas | Free tier | $0 |
| **총 예상** | - | **$5-15/월** |

#### 장단점

| 장점 | 단점 |
|------|------|
| 완전한 제어권 | 서버 비용 발생 |
| 크로스 플랫폼 지원 | 개발/유지보수 필요 |
| 기능 확장 용이 | 보안 책임 |
| 분석/통계 가능 | GDPR 등 규정 준수 필요 |

#### 복잡도: ⭐⭐⭐⭐ (매우 높음)

---

### 4.4 대안 4: 하이브리드 (권장)

#### 개념

```
┌─────────────────────────────────────────────────────────────────┐
│                    하이브리드 백업 전략                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  [1단계: 기본] ─────────────────────────────────────────────────│
│  ├── 로컬 저장 (현재 방식 유지)                                   │
│  ├── Files 앱 노출 (iOS) - Info.plist 설정만                     │
│  └── ZIP 일괄 내보내기 (수동 백업)                                │
│                                                                 │
│  [2단계: 클라우드] (선택적) ─────────────────────────────────────│
│  ├── iOS: iCloud Documents 백업 옵션                            │
│  ├── Android: Google Drive 백업 옵션                            │
│  └── 사용자 선택에 따라 자동 동기화                               │
│                                                                 │
│  [3단계: 서버] (향후) ─────────────────────────────────────────│
│  ├── 계정 시스템 구축 후                                         │
│  ├── 선생님/학부모 공유 녹음만 서버 저장                          │
│  └── 로컬 녹음은 클라우드 옵션 유지                               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

#### 1단계 구현 (즉시)

```xml
<!-- iOS Info.plist -->
<key>UIFileSharingEnabled</key>
<true/>
<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>
```

```dart
// ZIP 내보내기 서비스
class BackupExportService {
  Future<File> createBackupArchive() async {
    final archive = Archive();

    // 녹음 파일 추가
    final recordings = await getLocalRecordings();
    for (final recording in recordings) {
      final file = File(recording.filePath);
      if (await file.exists()) {
        archive.addFile(ArchiveFile(
          'recordings/${recording.id}.m4a',
          await file.length(),
          await file.readAsBytes(),
        ));
      }
    }

    // Hive DB 스냅샷 추가
    final hiveData = await exportHiveToJson();
    archive.addFile(ArchiveFile(
      'metadata/hive_backup.json',
      hiveData.length,
      utf8.encode(hiveData),
    ));

    // ZIP 생성
    final zipEncoder = ZipEncoder();
    final zipBytes = zipEncoder.encode(archive)!;

    final backupFile = File('${await getBackupPath()}/backup_${DateTime.now().toIso8601String()}.lessonbackup');
    await backupFile.writeAsBytes(zipBytes);

    return backupFile;
  }
}
```

---

## 5. 구현 우선순위 및 로드맵

### Phase 1: 즉시 구현 (1-2일)

| 항목 | 작업 | 복잡도 |
|------|------|:------:|
| Files 앱 노출 | Info.plist 설정 | ⭐ |
| ZIP 일괄 내보내기 | archive 패키지 사용 | ⭐⭐ |
| 복원 기능 | ZIP 가져오기 + Hive 복원 | ⭐⭐ |

### Phase 2: 클라우드 백업 (1-2주)

| 항목 | 작업 | 복잡도 |
|------|------|:------:|
| iCloud 백업 (iOS) | icloud_storage 패키지 | ⭐⭐⭐ |
| Google Drive (Android) | googleapis 연동 | ⭐⭐⭐ |
| 자동 백업 옵션 | 설정 화면 추가 | ⭐⭐ |

### Phase 3: 서버 백업 (향후)

| 항목 | 작업 | 복잡도 |
|------|------|:------:|
| FastAPI 백엔드 | 인증, 업로드 API | ⭐⭐⭐⭐ |
| S3/R2 연동 | 파일 저장소 | ⭐⭐⭐ |
| 계정 시스템 | OAuth, 프로필 | ⭐⭐⭐⭐ |

---

## 6. 권장 전략

### 현재 상황에서 최선의 선택

현재 레슨 앱은 **백엔드 서버가 없는 상태**이므로, 다음 전략을 권장합니다:

```
🎯 권장: 하이브리드 1단계 + 2단계 (iCloud/Google Drive)
```

#### 이유

1. **사용자 경험**: 앱 재설치 후 자동 복원 가능
2. **비용**: 서버 비용 없음 (클라우드 무료 쿼터 사용)
3. **신뢰성**: Apple/Google 인프라 사용
4. **개인정보**: 사용자 본인 클라우드에 저장

#### 구현 순서

```
1. Files 앱 노출 (Info.plist) ─────────── 30분
   └── 즉시 수동 백업 가능

2. ZIP 일괄 내보내기 ─────────────────── 1일
   └── 모든 데이터 한번에 백업

3. iCloud 자동 백업 (iOS) ─────────────── 2-3일
   └── 새 녹음 자동 동기화

4. Google Drive 백업 (Android) ─────────── 3-5일
   └── 크로스 플랫폼 지원

5. 복원 UI 및 설정 화면 ─────────────────── 2일
   └── 사용자 친화적 인터페이스
```

---

## 7. 참고 자료

### 공식 문서
- [Apple: Optimizing Your App's Data for iCloud Backup](https://developer.apple.com/documentation/foundation/optimizing-your-app-s-data-for-icloud-backup)
- [Android: Data and file storage overview](https://developer.android.com/training/data-storage)
- [Android: Scoped storage](https://source.android.com/docs/core/storage/scoped)

### Flutter 패키지
- [icloud_storage](https://pub.dev/packages/icloud_storage) - iCloud 연동
- [googleapis](https://pub.dev/packages/googleapis) - Google Drive API
- [archive](https://pub.dev/packages/archive) - ZIP 생성/해제
- [share_plus](https://pub.dev/packages/share_plus) - 파일 공유

### 경쟁사 참고
- [forScore: Understanding Backups, Syncing, and iCloud](https://forscore.co/kb/understanding-backups-syncing-and-icloud/)
- [forScore: Using cloud services](https://forscore.co/kb/cloud-services/)

### 튜토리얼
- [How to implement cloud drive backup in Flutter](https://medium.com/@tutorial.sinktank/how-to-implement-cloud-drive-backup-in-flutter-android-ios-2297a0f718d4)
- [Secure the user data on iCloud Drive with Flutter](https://medium.com/@benovedoz/secure-the-user-data-on-icloud-drive-with-flutter-db2ad4d0a608)

---

## 변경 이력

| 날짜 | 변경 내용 |
|------|----------|
| 2026-01-03 | 초기 문서 작성 |
