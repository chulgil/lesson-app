# Recording 엔티티

> 마지막 업데이트: 2026-03-11

## 개요

연습 녹음 관련 엔티티입니다. `Recording`은 Hive 기반 로컬 저장을 지원하며,
스마트 녹음(자동 트림/무음 구간 감지) 관련 클래스는 별도 파일에 정의되어 있습니다.

---

## Dart 엔티티 — Recording

```dart
// lib/features/practice/domain/entities/recording.dart

@HiveType(typeId: 22)
@immutable
class Recording {
  @HiveField(0)  final String id;
  @HiveField(1)  final String repertoireId;
  @HiveField(2)  final String studentId;
  @HiveField(3)  final RecordingType type;
  @HiveField(4)  final String localPath;
  @HiveField(5)  final String? serverUrl;
  @HiveField(6)  final int durationSeconds;
  @HiveField(7)  final bool isRepresentative;
  @HiveField(8)  final DateTime recordedAt;
  @HiveField(9)  final DateTime? sharedAt;
  @HiveField(10) final StorageStatus storageStatus;
  @HiveField(11) final String? title;
}
```

---

## 필드 설명 — Recording

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `id` | String | ✅ | 고유 ID |
| `repertoireId` | String | ✅ | 레퍼토리 ID |
| `studentId` | String | ✅ | 학생 ID |
| `type` | RecordingType | ✅ | 녹음 유형 |
| `localPath` | String | ✅ | 로컬 파일 경로 |
| `serverUrl` | String? | - | 서버 URL |
| `durationSeconds` | int | ✅ | 녹음 길이 (초) |
| `isRepresentative` | bool | - | 대표 녹음 여부 (기본: false) |
| `recordedAt` | DateTime | ✅ | 녹음 일시 |
| `sharedAt` | DateTime? | - | 선생님 공유 일시 |
| `storageStatus` | StorageStatus | - | 저장 상태 (기본: local) |
| `title` | String? | - | 녹음 제목 |

### 계산 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `formattedDuration` | String | mm:ss 형식 문자열 |
| `isShared` | bool | 공유 여부 (sharedAt != null) |
| `hasLocalFile` | bool | 로컬 파일 존재 여부 |

### 상수

| 상수 | 값 | 설명 |
|------|-----|------|
| `minRecordingSeconds` | 5 | 최소 녹음 길이 (초) |
| `maxRecordingSeconds` | 180 | 최대 녹음 길이 (3분) |

---

## SmartRecordingState

스마트 녹음 기능 상태 (자동 트림, 무음 구간 감지).

### 필드

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `isEnabled` | bool | - | 스마트 녹음 활성화 (기본: true) |
| `threshold` | double | - | 음량 감지 임계값 (기본: 0.40) |
| `phase` | RecordingPhase | - | 현재 녹음 단계 (기본: waiting) |
| `trimmedStart` | Duration | - | 시작 트림 길이 |
| `trimmedEnd` | Duration | - | 끝 트림 길이 |
| `originalFilePath` | String? | - | 원본 파일 경로 (복구용) |
| `soundStartTime` | DateTime? | - | 소리 최초 감지 시점 |
| `soundEndTime` | DateTime? | - | 소리 마지막 중단 시점 |
| `silencePeriods` | List\<SilencePeriod\> | - | 무음 구간 목록 |
| `middleSilenceStartTime` | DateTime? | - | 현재 중간 무음 시작 시점 |

### 상수

| 상수 | 값 | 설명 |
|------|-----|------|
| `minThreshold` | 0.20 | 최소 임계값 |
| `maxThreshold` | 0.60 | 최대 임계값 |
| `defaultThreshold` | 0.40 | 기본 임계값 |
| `minSilenceDuration` | 3초 | 트림 대상 최소 무음 길이 |
| `defaultMiddleSilenceThreshold` | 5초 | 기본 중간 무음 임계값 |
| `silenceBuffer` | 3초 | 무음 건너뛸 때 전후 버퍼 |

---

## SmartRecordingSettings

스마트 녹음 영구 설정.

### 필드

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `smartRecordingEnabled` | bool | - | 활성화 여부 (기본: true) |
| `trimThreshold` | double | - | 트림 임계값 (기본: 0.40) |
| `middleSilenceSkipEnabled` | bool | - | 중간 무음 건너뛰기 (기본: true) |
| `middleSilenceThreshold` | int | - | 중간 무음 임계값 초 (기본: 5, 범위: 5-30) |

---

## SilencePeriod

녹음 중 감지된 무음 구간.

### 필드

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `startTime` | Duration | ✅ | 무음 시작 시점 (녹음 시작 기준 상대값) |
| `endTime` | Duration | ✅ | 무음 종료 시점 |

---

## AudioSegment

재생 가능한 오디오 구간 (무음 제외 부분).

### 필드

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `start` | Duration | ✅ | 시작 위치 |
| `end` | Duration | ✅ | 종료 위치 |

---

## TrimResult

트림 작업 결과.

### 필드

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `success` | bool | ✅ | 성공 여부 |
| `trimmedFilePath` | String | ✅ | 트림된 파일 경로 |
| `originalFilePath` | String? | - | 원본 파일 경로 |
| `trimmedStart` | Duration | - | 시작 트림 길이 |
| `trimmedEnd` | Duration | - | 끝 트림 길이 |
| `errorMessage` | String? | - | 오류 메시지 |

---

## Enum

### RecordingType (HiveType: 20)

| 값 | 설명 |
|-----|------|
| `student` | 학생 연습 녹음 |
| `teacher` | 선생님 참고 음원 |
| `feedback` | AI 변환 피드백 (텍스트 저장) |

### StorageStatus (HiveType: 21)

| 값 | 설명 |
|-----|------|
| `local` | 로컬 저장만 |
| `active` | 서버 활성 저장 (빠른 접근) |
| `archived` | S3 아카이브 (지연 재생) |
| `deleted` | 서버에서 삭제됨 |

### RecordingPhase

| 값 | 설명 |
|-----|------|
| `waiting` | 소리 입력 대기 (무음 감지) |
| `recording` | 녹음 진행 중 (소리 감지) |
| `ending` | 종료 단계 (소리 중단, 재개 가능) |

### RecordingFilterType

녹음 목록 필터 유형 (별도 파일: `recording_filter_type.dart`).

| 값 | 설명 |
|-----|------|
| `all` | 전체 |
| `weekly` | 선택 날짜 포함 주간 (월-일) |
| `daily` | 선택 날짜만 |

---

## Hive TypeId

| 타입 | TypeId |
|------|--------|
| RecordingType | 20 |
| StorageStatus | 21 |
| Recording | 22 |

---

## 관련 파일

- Entity: `features/practice/domain/entities/recording.dart`
- Smart Recording: `features/practice/domain/entities/smart_recording.dart`
- Filter Type: `features/practice/domain/entities/recording_filter_type.dart`
- Provider: `features/practice/presentation/providers/`

## 변경 이력

- 2026-03-11: 초기 스키마 문서 생성
