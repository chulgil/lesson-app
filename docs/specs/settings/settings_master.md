# 설정 시스템 Master Spec

> 구현 상태: ⚠️ 부분 구현 — 백업/녹음만 구현, 교사 설정 UI 미구현
> Last updated: 2026-03-07

## 1. 개요

설정 시스템은 크게 세 가지 영역을 관리한다:

1. **선생님 설정**: 레슨 운영 관련 설정 (악기, 레슨 시간, 타임슬롯, 휴식 시간 등)
2. **녹음 백업**: 녹음 데이터의 백업/복원 (ZIP 아카이브 기반)
3. **녹음 관리**: 전체 녹음 파일 조회, 미연결(orphan) 녹음 관리, 외부 파일 가져오기

은행 금고에 비유하면, 선생님 설정은 "금고 규칙 설정", 백업은 "금고 내용물 복사본 만들기", 녹음 관리는 "금고 안 물건 정리"와 같다.

---

## 2. 핵심 기능

### 2.1 선생님 설정 (TeacherSettings)

| 기능 | 설명 |
|------|------|
| 악기 관리 | 가르치는 악기 목록 추가/제거/순서 변경 |
| 기본 레슨 시간 | 기본 레슨 길이 설정 (분 단위) |
| 커스텀 레슨 시간 | 사용자 정의 레슨 시간 추가/제거/활성화 토글 |
| 가용 타임슬롯 | 레슨 가능 시간대 관리 (요일별 시작/종료 시간) |
| 레슨 간 휴식 시간 | 레슨 사이 휴식 시간 설정 (분 단위) |
| 최소 예약 시간 | 최소 몇 시간 전에 예약해야 하는지 설정 |

### 2.2 녹음 백업

| 기능 | 설명 |
|------|------|
| 전체 백업 생성 | 녹음 파일 + Hive 데이터를 `.lessonbackup` ZIP으로 내보내기 |
| 백업 공유 | 생성된 백업 파일을 시스템 공유 시트로 전달 |
| 백업 복원 | `.lessonbackup` 파일에서 데이터 복원 (중복 파일 건너뛰기) |
| 백업 목록 | 기기에 저장된 백업 파일 목록/공유/삭제 |
| 백업 현황 | 녹음 수, 전체 용량, 마지막 백업 날짜 표시 |

### 2.3 녹음 관리

| 기능 | 설명 |
|------|------|
| 전체 녹음 조회 | 모든 녹음 파일을 연결 상태별로 표시 (연결됨/미연결) |
| 미연결 녹음 관리 | 섹션에 연결되지 않은 녹음 진단 및 관리 |
| 녹음 재연결 | 녹음을 다른 섹션에 연결/변경 |
| 녹음 삭제 | 녹음 파일 영구 삭제 (확인 다이얼로그) |
| 녹음 가져오기 | 외부 오디오 파일 가져오기 (m4a, mp3, wav, aac, flac) |
| 경로 복구 | 앱 재설치 시 녹음 파일 경로 자동 복구 |

---

## 3. 화면/UI 구조

### 3.1 백업 설정 화면 (BackupSettingsScreen)

```
/backup-settings
┌──────────────────────────────────┐
│  <- 녹음 백업                     │
├──────────────────────────────────┤
│                                  │
│  ┌── 백업 현황 ────────────────┐ │
│  │ [아이콘] 백업 현황            │ │
│  │ 마지막 백업: 2026-03-01 14:00│ │
│  │ ─────────────────────────── │ │
│  │ 녹음 파일: 42개  전체 용량: 1.2GB │ │
│  └─────────────────────────────┘ │
│                                  │
│  [진행 바] (백업/복원 중일 때)      │
│  [오류 메시지] (오류 발생 시)       │
│                                  │
│  수동 백업                        │
│  ┌ 전체 백업 내보내기        >  ┐ │
│  │ 모든 녹음과 데이터를 ZIP으로  │ │
│  └─────────────────────────────┘ │
│  ┌ 백업에서 복원              >  ┐ │
│  │ 이전 백업 파일에서 복원       │ │
│  └─────────────────────────────┘ │
│                                  │
│  녹음 관리                        │
│  ┌ 연결되지 않은 녹음    [N]  >  ┐ │
│  │ N개 녹음이 섹션에 미연결      │ │
│  └─────────────────────────────┘ │
│                                  │
│  저장된 백업                      │
│  ┌ 2026-03-01 14:00   [...]  ┐  │
│  │ 156.2 MB                  │  │
│  └───────────────────────────┘  │
└──────────────────────────────────┘
```

### 3.2 전체 녹음 화면 (AllRecordingsScreen)

```
/all-recordings
┌──────────────────────────────────┐
│  <- 전체 녹음 파일     [+] [새로고침] │
├──────────────────────────────────┤
│  ┌── 통계 ──────────────────────┐│
│  │ 전체: 42  연결됨: 38  미연결: 4 ││
│  └──────────────────────────────┘│
│                                  │
│  ■ 연결되지 않은 녹음 (4개)        │
│  ┌──────────────────────────────┐│
│  │ [▶] 연결되지 않음              ││
│  │     2026.03.01 14:30  3:42   ││
│  │                    [🔗] [🗑] ││
│  └──────────────────────────────┘│
│                                  │
│  ■ 연결된 녹음 (38개)             │
│  ┌──────────────────────────────┐│
│  │ [▶] 레퍼토리 > 섹션명          ││
│  │     2026.03.01 10:15  5:20   ││
│  │                    [🔗] [🗑] ││
│  └──────────────────────────────┘│
└──────────────────────────────────┘
```

### 3.3 미연결 녹음 화면 (OrphanRecordingsScreen)

```
/orphan-recordings
┌──────────────────────────────────┐
│  <- 연결되지 않은 녹음  [새로고침]   │
├──────────────────────────────────┤
│  ┌── 진단 정보 ─────────────────┐│
│  │ Hive에 저장된 녹음: 42개       ││
│  │ 섹션 수: 15개                  ││
│  │ 연결되지 않은 녹음: 4개         ││
│  └──────────────────────────────┘│
│                                  │
│  4개의 녹음이 섹션에 연결되지 않음  │
│                                  │
│  ┌──────────────────────────────┐│
│  │ [▶/⏸] 2026.03.01 14:30      ││
│  │       3:42  120bpm           ││
│  │              [🔗 연결] [🗑]  ││
│  │ ━━━━━━━━━━━━━━ (재생 바)     ││
│  └──────────────────────────────┘│
└──────────────────────────────────┘
```

---

## 4. 데이터 모델

### BackupState

```
BackupState
├── recordingCount: int           // 녹음 파일 수
├── totalSizeBytes: int           // 전체 용량 (바이트)
├── lastBackupDate: DateTime?     // 마지막 백업 날짜
├── isBackingUp: bool             // 백업 진행 중
├── isRestoring: bool             // 복원 진행 중
├── progress: double?             // 진행률 (0.0 ~ 1.0)
└── lastError: String?            // 마지막 오류 메시지
```

### BackupMetadata (백업 아카이브 내 메타데이터)

```
BackupMetadata
├── appVersion: String            // 앱 버전
├── backupVersion: String         // 백업 포맷 버전 (현재 "1.0")
├── createdAt: DateTime           // 생성 시각
├── recordingCount: int           // 녹음 수
├── totalSizeBytes: int           // 전체 용량
├── deviceModel: String           // 기기 모델
├── osVersion: String             // OS 버전
└── boxCounts: Map<String, int>   // Hive Box별 항목 수
```

### RestoreResult

```
RestoreResult
├── success: bool                 // 성공 여부
├── restoredRecordings: int       // 복원된 녹음 수
├── skippedRecordings: int        // 건너뛴 녹음 수 (이미 존재)
├── restoredBoxEntries: int       // 복원된 Hive 항목 수
└── errorMessage: String?         // 실패 시 오류 메시지
```

### BackupFileInfo

```
BackupFileInfo
├── file: File                    // 파일 객체
├── createdAt: DateTime           // 생성 시각
└── sizeBytes: int                // 파일 크기
```

### OrphanRecordingsDiagnostic

```
OrphanRecordingsDiagnostic
├── totalRecordingsInHive: int    // Hive 전체 녹음 수
├── totalSections: int            // 전체 섹션 수
├── orphanCount: int              // 미연결 녹음 수
├── recordingsWithFiles: int      // 파일이 존재하는 녹음 수
├── recordingsWithMissingFiles: int // 파일 누락 녹음 수
├── recordingsWithMatchingSections: int // 섹션 매칭된 녹음 수
└── orphans: List<PracticeRecording>   // 미연결 녹음 목록
```

### Provider 구성

| Provider | 용도 |
|----------|------|
| `settingsRepositoryProvider` | SettingsRepository 인스턴스 (Mock/Remote 전환) |
| `teacherSettingsProvider` | 현재 선생님 설정 |
| `teacherSettingsByIdProvider` | 특정 선생님 설정 (ID별) |
| `teacherInstrumentsProvider` | 선생님 악기 목록 |
| `defaultLessonDurationProvider` | 기본 레슨 시간 |
| `availableTimeSlotsProvider` | 가용 타임슬롯 |
| `teacherSettingsNotifierProvider` | 선생님 설정 CRUD |
| `backupServiceProvider` | BackupService 싱글톤 |
| `backupStateProvider` | 백업 상태 (AsyncNotifier) |
| `backupListProvider` | 저장된 백업 목록 |
| `orphanedRecordingsProvider` | 미연결 녹음 목록 |
| `orphanedRecordingsWithDiagnosticProvider` | 미연결 녹음 + 진단 정보 |
| `allRecordingsWithSectionInfoProvider` | 전체 녹음 + 섹션 연결 정보 |
| `orphanRecordingManagerProvider` | 녹음 관리 액션 (재연결, 삭제, 가져오기) |

---

## 5. 구현 파일 위치

> `features/settings/` 기준 상대 경로. 새 파일 추가 시 이 표를 업데이트한다.

| 레이어 | 파일 경로 | 설명 |
|--------|----------|------|
| **Entity** | `settings/domain/entities/backup_state.dart` | BackupState, BackupMetadata, RestoreResult, BackupFileInfo |
| **Service** | `settings/data/services/backup_service.dart` | BackupService (ZIP 아카이브 생성/복원) |
| **Provider** | `settings/presentation/providers/teacher_settings_provider.dart` | 선생님 설정 CRUD |
| **Provider** | `settings/presentation/providers/settings_repository_provider.dart` | SettingsRepository (Mock/Remote 전환) |
| **Provider** | `settings/presentation/providers/settings_providers.dart` | Provider barrel export |
| **Provider** | `settings/presentation/providers/backup_provider.dart` | 백업 상태 관리 (AsyncNotifier) |
| **Provider** | `settings/presentation/providers/orphan_recording_provider.dart` | 미연결 녹음 관리 |
| **Screen** | `settings/presentation/screens/backup_settings_screen.dart` | 녹음 백업 설정 화면 |
| **Screen** | `settings/presentation/screens/all_recordings_screen.dart` | 전체 녹음 파일 관리 화면 |
| **Screen** | `settings/presentation/screens/orphan_recordings_screen.dart` | 미연결 녹음 진단/관리 화면 |
| **Screen** | `settings/presentation/screens/settings_screens.dart` | Screen barrel export |
| **Widget** | `settings/presentation/widgets/backup_widgets.dart` | 백업 관련 재사용 위젯 |

---

## 6. 구현 현황

### 선생님 설정

| 파일 | 상태 |
|------|:----:|
| `settings/presentation/providers/teacher_settings_provider.dart` | 완료 |
| `settings/presentation/providers/settings_repository_provider.dart` | 완료 |
| 선생님 설정 전용 화면 | 미구현 (다른 화면에서 사용) |

### 녹음 백업

| 파일 | 상태 |
|------|:----:|
| `settings/domain/entities/backup_state.dart` | 완료 |
| `settings/data/services/backup_service.dart` | 완료 |
| `settings/presentation/providers/backup_provider.dart` | 완료 |
| `settings/presentation/screens/backup_settings_screen.dart` | 완료 |
| `settings/presentation/widgets/backup_widgets.dart` | 완료 |

### 녹음 관리

| 파일 | 상태 |
|------|:----:|
| `settings/presentation/providers/orphan_recording_provider.dart` | 완료 |
| `settings/presentation/screens/all_recordings_screen.dart` | 완료 |
| `settings/presentation/screens/orphan_recordings_screen.dart` | 완료 |

### 백업 아카이브 포맷

```
backup_2026-03-01T14-30-00.lessonbackup (ZIP)
├── metadata.json                 // 백업 메타데이터
├── hive_snapshot.json            // Hive 데이터 스냅샷
│   ├── practice_recordings       // 녹음 메타데이터
│   ├── practice_repertoires      // 레퍼토리 데이터
│   ├── metronome_settings        // 메트로놈 설정
│   └── smart_recording_settings  // 스마트 녹음 설정
└── recordings/                   // 녹음 파일 (.m4a)
    └── ...
```

### 백업 복원 시 특수 처리

| 처리 | 설명 |
|------|------|
| 파일 경로 업데이트 | 다른 기기 복원 시 앱 문서 경로 자동 변환 |
| 섹션 ID 매핑 | 재설치 시 변경된 섹션 ID를 속성(레퍼토리명+곡명+범위)으로 매칭 |
| 중복 건너뛰기 | 이미 존재하는 녹음/설정은 건너뜀 |
| 버전 호환성 | `1.x` 버전만 호환 |

---

## 코드 반영 추가 (2026-06-03)

> 코드에는 존재하나 본 스펙에 누락되었던 항목 (코드→스펙 단방향 반영). 출처: `features/settings/`.

### A. 앱 릴리스/버전 관리 (App Release) (코드 반영 2026-06-03)

강제 업데이트 게이트와 소식·로드맵 피드를 제공하는 서브시스템. 본 스펙 초안(2026-03)에 없었음.

#### A.1 데이터 모델

> 소스: `settings/domain/entities/app_release.dart`

| 엔티티/enum | 필드 | 설명 |
|------|------|------|
| `AppRoadmapStatus` (enum) | planned / inProgress / shipped | 로드맵 항목 진행 상태 |
| `AppVersionSnapshot` | currentVersion, buildNumber?, latestVersion?, minVersion?, checkedAt | 버전 비교 스냅샷 |
| `AppNewsItem` | id, title, summary, publishedAt, link? | 소식 피드 항목 |
| `AppRoadmapItem` | id, title, summary, status, targetDate? | 로드맵 항목 |
| `AppReleaseSnapshot` | version, news[], roadmap[] | 릴리스 통합 스냅샷 |
| `ReviewPromptPolicy` | completedLessonThreshold(=10), cooldown(=30일) | 평점 프롬프트 정책 값객체 |

- `AppVersionSnapshot.hasUpdate`: latestVersion != currentVersion
- `AppVersionSnapshot.requiresForceUpdate`: currentVersion < minVersion (semver 비교)
- `AppVersionSnapshot.displayVersion`: `currentVersion (buildNumber)`

#### A.2 Repository

> 소스: `settings/domain/repositories/app_release_repository.dart`

| 인터페이스 | 메서드 | 구현체 |
|------|------|------|
| `AppReleaseRepository` | `fetchReleaseSnapshot()` | `LocalAppReleaseRepository`(mock), `RemoteAppReleaseRepository`(api), `CachedAppReleaseRepository`(캐시) |
| `AppReviewClient` | `canRequestReview()`, `requestReview()` | `LocalAppReviewClient` (in_app_review 래퍼) — 평점 스펙은 [app_rating_prompt_spec.md](app_rating_prompt_spec.md) |

#### A.3 Provider

> 소스: `settings/presentation/providers/app_release_provider.dart` (모두 keepAlive)

| Provider | 반환 타입 |
|----------|----------|
| `appReleaseRepositoryProvider` | AppReleaseRepository (mock/remote 전환) |
| `appReleaseSnapshotProvider` | `AppReleaseSnapshot` |
| `appVersionSnapshotProvider` | `AppVersionSnapshot` |
| `appNewsFeedProvider` | `List<AppNewsItem>` |
| `appRoadmapFeedProvider` | `List<AppRoadmapItem>` |
| `reviewPromptPolicyProvider` | `ReviewPromptPolicy` |

#### A.4 화면 / 라우트

| 화면 | 라우트 | 설명 |
|------|------|------|
| `ForceUpdateScreen` | (강제 진입 — requiresForceUpdate 시) | 최소 버전 미달 시 업데이트 강제 |
| `NewsRoadmapScreen` | `/settings/news-roadmap` (`AppRoutes.newsRoadmap`) | 소식 + 로드맵 피드 표시 |

### B. TeacherSettings 누락 필드 (코드 반영 2026-06-03)

> 소스: `profile/domain/entities/teacher_settings.dart` (settings 도메인이 소비). §2.1 표에 없던 필드.

| 필드 | 설명 |
|------|------|
| `disabledDurations` | 비활성화한 레슨 시간(기본+커스텀) 목록 |
| `lessonPriceTable` | `Map<String, Map<String, int>>?` — 악기/레벨별 레슨료 표 |
| `trialLessonFree` | 체험 레슨 무료 여부 |
| `bookingGuidanceMessage` | 예약 안내 메시지 |

---

## 7. 관련 스펙

| 스펙 | 관계 |
|------|------|
| [연습 시스템](../practice/practice_master.md) | 녹음 관리 대상 (PracticeRecording, PracticeSection) |
| [백업 구현 스펙](../practice/backup_implementation_spec.md) | 백업 아카이브 포맷 상세 |
| [학생 홈 프로필 탭](../student_home/student_home_master.md) | 프로필 탭에서 백업/녹음 설정 진입 |
| [앱스토어 평점 유도](app_rating_prompt_spec.md) | AppReviewClient / ReviewPromptPolicy 활용 |
| Issue #15 | 데이터 백업 기능 요구사항 |

---

## 8. 변경 이력

| 날짜 | 변경 내용 |
|------|----------|
| 2026-03-06 | 코드 기반 역설계로 초기 스펙 작성 |
| 2026-06-03 | 코드 반영 — App Release 서브시스템(버전/소식/로드맵/강제업데이트), TeacherSettings 누락 필드 추가 |
| 2026-03-07 | 구현 파일 위치 섹션 추가, 관련 스펙 링크 보강 (practice_master, backup_implementation_spec, student_home_master) |
