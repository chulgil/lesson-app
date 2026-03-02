# 연습 공유 시스템 스펙

> 작성일: 2026-03-02
> 상태: 설계 완료
> Pain Point: B(연습 진도 블랙박스), D(학부모 근거 없음)
> 관련 문서: [recording_requirement.md](recording_requirement.md), [subscription_based_relationship.md](../invite/subscription_based_relationship.md)
> 관련 스펙: [parent_dashboard_spec.md](../user/parent_dashboard_spec.md), [practice_report_spec.md](practice_report_spec.md)
> 엔티티: `Recording` in [recording.dart](../../../frontend/lib/features/practice/domain/entities/recording.dart)

<!-- @uses: tokens/colors, tokens/typography -->

---

## 1. 개요

### 1.1 목적

학생의 연습 기록(녹음, 시간, 횟수)을 선생님에게 공유하고,
학부모 대시보드에 실데이터로 연동하여 **"이번 주 연습 했어요?"를 데이터로 답**한다.

### 1.2 핵심 결정사항

| 항목 | 결정 |
|------|------|
| 공유 주체 | 학생이 대표 녹음을 선생님에게 공유 (수동) |
| 공유 시점 | 대표 녹음 설정 후 [공유] 버튼 |
| 공유 범위 | 수강권 유효 시에만 공유 가능 |
| 선생님 수신 | 학생별 연습 현황 탭 (신규) |
| 학부모 연동 | Phase 2에서 학부모 대시보드 실데이터 |
| 기존 활용 | Recording.sharedAt (L92), storageStatus |

---

## 2. 기존 활용 엔티티

### 2.1 Recording (HiveType 22)

**파일**: `frontend/lib/features/practice/domain/entities/recording.dart`

```dart
class Recording {
  final String id;
  final String repertoireId;
  final String studentId;
  final RecordingType type;            // student | teacher | feedback
  final String localPath;
  final int durationSeconds;
  final DateTime recordedAt;

  // Sharing fields
  final DateTime? sharedAt;            // ← Line 92: 공유 시점 (null = 미공유)
  final bool isRepresentative;         // ← 대표 녹음 여부
  final String? serverUrl;             // ← 서버 업로드 URL
  final StorageStatus storageStatus;   // ← local | active | archived | deleted

  bool get isShared => sharedAt != null;
  bool get hasLocalFile => localPath.isNotEmpty;
}
```

### 2.2 이미 구현된 공유 인프라

| 구현 항목 | 파일 | 상태 |
|----------|------|:----:|
| `Recording.sharedAt` 필드 | `recording.dart` L92 | ✅ |
| `Recording.isShared` getter | `recording.dart` | ✅ |
| `markAsShared()` Repository 메서드 | `recording_repository.dart` | ✅ |
| `shareWithTeacher()` Notifier 메서드 | `recording_provider.dart` | ✅ |
| 공유 확인 다이얼로그 | `practice_recording_screen.dart` | ✅ |
| "공유됨" 뱃지 UI | `practice_recording_screen.dart` | ✅ |
| 대표녹음 설정 | `setAsRepresentative()` | ✅ |
| `storageStatus` 전환 | `local → active` on share | ✅ |

---

## 3. 사용자 플로우

### 3.1 학생: 녹음 공유

```
연습 탭 > 레퍼토리 > 섹션 상세
    │
    └─ 녹음 목록
        ├─ [대표] 뱃지가 붙은 녹음
        │   └─ [공유] 버튼 (미공유 + 대표 + 수강권 유효 시)
        │       → 확인 다이얼로그: "선생님에게 공유하시겠습니까?"
        │       → shareWithTeacher()
        │       → sharedAt = DateTime.now()
        │       → storageStatus = active
        │       → "공유됨 ✓" 뱃지 표시
        │
        └─ 기타 녹음 (대표 설정 가능)
```

### 3.2 선생님: 연습 현황 수신 (신규)

```
학생 상세 화면
    │
    └─ [연습 현황] 탭 (신규)
        │
        ├─ 📊 이번 주 요약
        │   ├─ 연습 일수: 5/7일
        │   ├─ 총 연습 시간: 3시간 45분
        │   └─ 공유된 녹음: 2개
        │
        ├─ 📅 주간 연습 캘린더
        │   └─ 월~일 연습 여부 + 시간
        │
        └─ 🎵 공유된 녹음 목록
            ├─ 비발디 여름 1악장   1/15  0:42  120 BPM  [▶]
            └─ 바흐 소나타 2악장   1/12  0:38   96 BPM  [▶]
```

### 3.3 학부모: 대시보드 연동 (Phase 2)

```
학부모 대시보드
    │
    ├─ 퀵스탯: 이번 주 연습 시간 (실데이터)
    ├─ 연습 캘린더: 실 연습 여부 (실데이터)
    └─ 공유된 녹음 재생 가능 (Phase 3)
```

---

## 4. 화면 스펙

### 4.1 학생: 공유 버튼 (기존 UI 확장)

```
┌─────────────────────────────────────────┐
│ 🎵 녹음                                 │
├─────────────────────────────────────────┤
│ ▶ 1/15 14:30   0:42  120 BPM  [대표]  │
│                            [📤 공유]   │  ← 미공유 시
│                                         │
│ ▶ 1/12 16:00   0:38   96 BPM          │
│                           [공유됨 ✓]   │  ← 공유 완료 시
│                                         │
│ ▶ 1/10 15:00   0:35   84 BPM          │
└─────────────────────────────────────────┘
```

### 4.2 선생님: 학생 연습 현황 탭 (신규)

```
┌─────────────────────────────────────────┐
│ ← 김서연                               │
├─────────┬─────────┬─────────────────────┤
│  정보   │  레슨   │ [연습 현황]         │  ← 신규 탭
├─────────┴─────────┴─────────────────────┤
│                                         │
│ 📊 이번 주 연습 요약                    │
│ ┌───────────┬───────────┬───────────┐  │
│ │ 📅        │ ⏱️        │ 🎵        │  │
│ │ 연습 일수  │ 총 시간    │ 공유 녹음 │  │
│ │   5/7일   │ 3시간 45분 │    2개    │  │
│ └───────────┴───────────┴───────────┘  │
│                                         │
│ 📅 주간 연습                            │
│ ┌─────────────────────────────────────┐ │
│ │  월  화  수  목  금  토  일         │ │
│ │  45  30  ──  40  30  60  ──  (분)  │ │
│ │  ●   ●   ○   ●   ●   ●   ○       │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ 🎵 공유된 녹음                          │
│ ┌─────────────────────────────────────┐ │
│ │ 비발디 여름 1악장                    │ │
│ │ 1/15 (수)  0:42  120 BPM     [▶]  │ │
│ ├─────────────────────────────────────┤ │
│ │ 바흐 소나타 2악장                    │ │
│ │ 1/12 (일)  0:38   96 BPM     [▶]  │ │
│ └─────────────────────────────────────┘ │
│                                         │
│       [📈 상세 통계 보기]               │  ← practice_report_spec 연동
└─────────────────────────────────────────┘
```

### 4.3 공유 조건 표

| 조건 | 공유 가능 | 설명 |
|------|:---------:|------|
| 대표 녹음 미설정 | ❌ | "먼저 대표 녹음을 설정하세요" |
| 이미 공유됨 | ❌ | "공유됨 ✓" 뱃지 표시 |
| 수강권 만료 | ❌ | "수강권이 필요합니다" |
| 선생님 미연결 | ❌ | "선생님과 연결이 필요합니다" |
| 대표 + 미공유 + 수강권 유효 | ✅ | [📤 공유] 버튼 활성 |

---

## 5. 데이터 모델

### 5.1 기존 모델 활용 (변경 없음)

Recording 엔티티의 기존 `sharedAt`, `storageStatus`, `isRepresentative` 필드를 그대로 활용.

### 5.2 선생님 뷰 모델 (신규)

```dart
/// 선생님이 보는 학생 연습 현황
class StudentPracticeOverview {
  final String studentId;
  final String studentName;
  final int practiceDaysThisWeek;       // 이번 주 연습 일수
  final int totalPracticeMinutes;       // 이번 주 총 연습 시간 (분)
  final List<SharedRecording> sharedRecordings;  // 공유된 녹음 목록
  final List<DailyPracticeEntry> weeklyEntries;  // 주간 일별 연습

  int get totalDaysInWeek => 7;
  String get formattedTotalTime {
    final hours = totalPracticeMinutes ~/ 60;
    final minutes = totalPracticeMinutes % 60;
    if (hours > 0) return '$hours시간 $minutes분';
    return '$minutes분';
  }
}

/// 공유된 녹음 (선생님 뷰)
class SharedRecording {
  final String recordingId;
  final String repertoireName;
  final String sectionName;
  final DateTime sharedAt;
  final int durationSeconds;
  final int? bpm;
  final String localPath;            // 서버 URL (Phase 2) or local path

  String get formattedDuration => ...;
}

/// 일별 연습 항목
class DailyPracticeEntry {
  final DateTime date;
  final int practiceMinutes;         // 0 = 연습 안함
  final bool hasPracticed;

  DailyPracticeEntry({
    required this.date,
    required this.practiceMinutes,
  }) : hasPracticed = practiceMinutes > 0;
}
```

---

## 6. 파일 구조

```
frontend/lib/features/practice/
├── domain/
│   └── entities/
│       ├── recording.dart                    ← 기존 (sharedAt L92)
│       └── student_practice_overview.dart    ← (신규)
├── data/
│   └── repositories/
│       ├── recording_repository.dart         ← 기존 (markAsShared)
│       └── practice_sharing_repository.dart  ← (신규) 선생님 뷰 데이터
├── presentation/
│   ├── providers/
│   │   ├── recording_provider.dart           ← 기존 (shareWithTeacher)
│   │   └── practice_sharing_provider.dart    ← (신규)
│   └── widgets/
│       ├── student_practice_overview_tab.dart ← (신규) 선생님 측 탭
│       ├── shared_recording_card.dart         ← (신규) 공유 녹음 카드
│       └── weekly_practice_grid.dart          ← (신규) 주간 연습 그리드

frontend/lib/features/students/
└── presentation/
    └── screens/
        └── student_detail_screen.dart         ← [연습 현황] 탭 추가
```

---

## 7. Provider / Repository

### 7.1 학생 측 (기존)

```dart
/// 녹음 공유 (기존 구현)
class RecordingNotifier extends _$RecordingNotifier {
  Future<void> shareWithTeacher() async {
    final representative = state.representativeRecording;
    if (representative == null) return;

    await ref.read(recordingRepositoryProvider).markAsShared(representative.id);
    // sharedAt = DateTime.now(), storageStatus = active
    await _loadRecordings();
  }
}
```

### 7.2 선생님 측 (신규)

```dart
/// 학생의 연습 현황 조회 (선생님 뷰)
@riverpod
Future<StudentPracticeOverview> studentPracticeOverview(
  StudentPracticeOverviewRef ref,
  String studentId,
) async {
  final sharingRepo = ref.watch(practiceSharingRepositoryProvider);
  return sharingRepo.getStudentOverview(studentId);
}

/// 공유된 녹음 목록 (선생님 뷰)
@riverpod
Future<List<SharedRecording>> sharedRecordings(
  SharedRecordingsRef ref,
  String studentId,
) async {
  final sharingRepo = ref.watch(practiceSharingRepositoryProvider);
  return sharingRepo.getSharedRecordings(studentId);
}
```

### 7.3 Repository 인터페이스 (신규)

```dart
abstract class PracticeSharingRepository {
  /// 선생님이 보는 학생 연습 현황
  Future<StudentPracticeOverview> getStudentOverview(String studentId);

  /// 학생이 공유한 녹음 목록
  Future<List<SharedRecording>> getSharedRecordings(String studentId);

  /// 주간 연습 기록 (일별)
  Future<List<DailyPracticeEntry>> getWeeklyPractice(
    String studentId, DateTime weekStart,
  );
}
```

---

## 8. 에러/엣지 케이스

| 상황 | 동작 |
|------|------|
| 수강권 만료 후 공유 시도 | "수강권이 필요합니다" 안내 |
| 이미 공유된 녹음 재공유 | 버튼 숨김 ("공유됨 ✓" 표시) |
| 공유 후 녹음 삭제 | 선생님 측에서 "파일 없음" 표시 |
| 대표 녹음 변경 후 | 새 대표에 [공유] 버튼 표시, 이전 대표 공유 상태 유지 |
| 선생님이 아직 앱 미설치 | 공유 데이터 서버에 저장, 앱 설치 후 조회 |
| 오프라인 상태 | 공유 보류, 온라인 시 자동 전송 (Phase 2) |
| 학부모가 녹음 재생 | Phase 3에서 구현 (현재 통계만) |

---

## 9. 구현 체크리스트

### Phase 1: 학생 → 선생님 공유 강화

- [x] Recording.sharedAt 필드 (기존)
- [x] shareWithTeacher() 메서드 (기존)
- [x] 공유 확인 다이얼로그 (기존)
- [x] "공유됨 ✓" 뱃지 (기존)
- [ ] StudentPracticeOverview 모델
- [ ] SharedRecording 모델
- [ ] PracticeSharingRepository 인터페이스
- [ ] MockPracticeSharingRepository
- [ ] studentPracticeOverview Provider
- [ ] 학생 상세 > [연습 현황] 탭 추가
- [ ] StudentPracticeOverviewTab 위젯
- [ ] SharedRecordingCard 위젯
- [ ] WeeklyPracticeGrid 위젯

### Phase 2: 학부모 대시보드 실데이터

- [ ] 학부모 대시보드 퀵스탯 연동 (이번 주 연습 시간)
- [ ] 학부모 대시보드 연습 캘린더 연동
- [ ] 학부모 대시보드 스트릭 연동
- [ ] practice_report_spec 공유 시스템 연동 섹션

### Phase 3: 학부모 녹음 재생

- [ ] 학부모 대시보드에서 공유 녹음 재생
- [ ] 선생님 코멘트 표시 (피드백 연동)

---

## 10. 변경 이력

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| 1.0 | 2026-03-02 | 초안 — 기존 공유 인프라 + 선생님 뷰 + 학부모 연동 설계 |
