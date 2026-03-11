# 레슨 노트 시스템 스펙

> 작성일: 2026-03-02
> 상태: 구현 완료 (코드 기반 문서화)
> Pain Point: A(이력 없음), G(인수인계)
> 관련 문서: [flow_with_app.md](flow_with_app.md), [recording_requirement.md](../practice/recording_requirement.md)
> 엔티티: [lesson.dart](../../../frontend/lib/features/lessons/domain/entities/lesson.dart)

<!-- @uses: tokens/colors, tokens/typography -->

---

## 1. 개요

### 1.1 목적

선생님이 레슨 중/후에 피드백, 주요 포인트, 연습 팁을 기록하고,
학생(읽기 전용)과 학부모(향후)가 확인할 수 있는 레슨 노트 시스템.

### 1.2 핵심 결정사항

| 항목 | 결정 |
|------|------|
| 노트 구성 요소 | feedback(텍스트) + keyPoints(배열) + practiceTips(텍스트) |
| 편집 권한 | 선생님만 편집 / 학생·학부모는 읽기 전용 |
| 저장 방식 | Lesson 엔티티에 포함 (별도 테이블 X) |
| 입력 방식 | 인라인 편집 + 바텀시트 (AddTipBottomSheet) |
| 템플릿 지원 | keyPoints, practiceTips에 팁 템플릿 라이브러리 연동 |
| 향후 확장 | 타임라인 뷰, 학부모 열람, AI 음성→텍스트 변환 |

---

## 2. 현재 구현 상태

### 2.1 데이터 모델 (Lesson 엔티티)

**파일**: `frontend/lib/features/lessons/domain/entities/lesson.dart`

```dart
// Lines 160-163 — 레슨 노트 관련 필드
final String? feedback;           // Teacher feedback text
final List<String>? keyPoints;    // List of key teaching points
final String? practiceTips;       // Practice guidance for students
final List<LessonRecording>? recordings;  // Lesson recordings
```

| 필드 | 타입 | 설명 | 예시 |
|------|------|------|------|
| `feedback` | `String?` | 선생님 피드백 (자유 텍스트) | "활 잡는 자세가 많이 좋아졌어요" |
| `keyPoints` | `List<String>?` | 주요 포인트 (배열) | ["보잉 연습", "음정 정확도"] |
| `practiceTips` | `String?` | 연습 팁 (단일 텍스트) | "메트로놈 60 템포로 천천히 연습하기" |
| `recordings` | `List<LessonRecording>?` | 레슨 녹음 파일 | — |

**주요 getter**: `hasFeedback` → `feedback != null && feedback!.isNotEmpty`

### 2.2 파일:위젯 매핑

| 파일 | 위젯 | 역할 | 줄 수 |
|------|------|------|:-----:|
| `lesson_notes_widgets.dart` | `LessonDetailSectionHeader` | 섹션 제목 + 추가 버튼 | L1-45 |
| | `LessonNoteEditor` | 피드백 텍스트 입력 + 저장 상태 인디케이터 | L47-140 |
| | `TeacherFeedbackCard` | 피드백 읽기 전용 표시 | L83-144 |
| | `KeyPointsList` | 포인트 목록 + 삭제 (선생님만) | L147-225 |
| | `PracticeTipsCard` | 연습 팁 카드 + 편집 (선생님만) | L228-305 |
| | `RecordingStatusIndicator` | 녹음 중 타이머 | L308-350 |
| `lesson_detail_screen.dart` | `LessonDetailScreen` | 3탭 화면 (노트/녹음/과제) | 467줄 |
| `add_tip_bottom_sheet.dart` | `AddTipBottomSheet` | 포인트/팁 추가 바텀시트 | 132줄 |

### 2.3 위젯 상세

#### LessonNoteEditor (선생님 전용)

```
┌─────────────────────────────────────────┐
│ 레슨 피드백을 작성하세요...              │
│                                         │
│                                         │
│                                         │
│                                         │
│                                         │
└─────────────────────────────────────────┘
                            저장 중... ⏳  ← 입력 중
                            ✅ 저장됨      ← 저장 완료 (2초 후 사라짐)
```

- 6줄 multiline TextField
- 보더 스타일 컨테이너, light surface 배경
- StatefulWidget (자체 저장 상태 관리)
- 저장 상태 인디케이터: idle → saving (spinner) → saved (체크 아이콘, 2초 후 idle)
- 부모의 debounce(800ms) + 인디케이터 buffer(1200ms) = 저장 완료 시 "저장됨" 표시

#### TeacherFeedbackCard (학생 전용)

```
┌─────────────────────────────────────────┐
│ 📝 선생님 피드백                 1/15 │
│                                         │
│ 활 잡는 자세가 많이 좋아졌어요.         │
│ 다음 시간에는 3번 곡 연습해오세요.      │
└─────────────────────────────────────────┘
```

- 읽기 전용, 날짜 표시 (updatedAt 기반)
- 비어있을 때 빈 상태 메시지 표시
- line-height 1.6으로 가독성 확보

#### KeyPointsList

```
┌─────────────────────────────────────────┐
│ 📌 주요 포인트                    [+]  │
├─────────────────────────────────────────┤
│ ● 보잉 연습                       [✕]  │  ← 선생님만 삭제 가능
│ ● 음정 정확도                     [✕]  │
│ ● 비브라토                        [✕]  │
└─────────────────────────────────────────┘
```

- `isTeacher` 플래그로 편집 모드 제어
- 빈 상태: "주요 포인트를 추가하세요" (선생님) / "아직 등록된 포인트가 없습니다" (학생)

#### PracticeTipsCard

```
┌─────────────────────────────────────────┐
│ 💡 연습 팁                        [✎]  │  ← 선생님만 편집 가능
├─────────────────────────────────────────┤
│ ℹ️ 메트로놈 60 템포로 천천히         │
│    연습하기                             │
└─────────────────────────────────────────┘
```

- info 스타일 (AppColors.info 배경)
- 편집 다이얼로그로 수정/삭제

---

## 3. 사용자 플로우

### 3.1 선생님: 피드백 작성

```
LessonDetailScreen (노트 탭)
    │
    ├─ [피드백 섹션]
    │   └─ LessonNoteEditor 인라인 편집
    │       → 포커스 아웃 시 자동 반영
    │
    ├─ [주요 포인트 섹션]
    │   └─ [+] 버튼 탭
    │       → AddTipBottomSheet 표시
    │       → 직접 입력 또는 템플릿 선택
    │       → onSubmit → _addKeyPoint()
    │       → lesson.copyWith(keyPoints: [..., 새포인트])
    │       → lessonsNotifierProvider.updateLesson()
    │
    └─ [연습 팁 섹션]
        └─ [+] 버튼 탭
            → AddTipBottomSheet 표시
            → onSubmit → _setPracticeTip()
            → lesson.copyWith(practiceTips: 새팁)
            → lessonsNotifierProvider.updateLesson()
```

### 3.2 학생: 피드백 확인

```
LessonDetailScreen (노트 탭)
    │
    ├─ TeacherFeedbackCard (읽기 전용)
    ├─ KeyPointsList (삭제 버튼 숨김)
    └─ PracticeTipsCard (편집 버튼 숨김)
```

---

## 4. 화면 스펙 (LessonDetailScreen — 노트 탭)

### 4.1 선생님 뷰

```
┌─────────────────────────────────────────┐
│ ← 레슨 상세        김서연    2026.01.15 │
├─────────┬─────────┬─────────────────────┤
│ [노트]  │  녹음   │  과제               │
├─────────┴─────────┴─────────────────────┤
│                                         │
│ 📝 레슨 피드백                          │
│ ┌─────────────────────────────────────┐ │
│ │ 활 잡는 자세가 많이 좋아졌어요...   │ │
│ │                                     │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ 📌 주요 포인트                    [+]  │
│ ● 보잉 연습                       [✕]  │
│ ● 음정 정확도                     [✕]  │
│                                         │
│ 💡 연습 팁                        [+]  │
│ ┌─────────────────────────────────────┐ │
│ │ ℹ️ 메트로놈 60 템포로 천천히      │ │
│ │    연습하기                   [✎]  │ │
│ └─────────────────────────────────────┘ │
│                                         │
└─────────────────────────────────────────┘
```

### 4.2 학생 뷰

```
┌─────────────────────────────────────────┐
│ ← 레슨 상세                   2026.01.15│
├─────────┬─────────┬─────────────────────┤
│ [노트]  │  녹음   │  과제               │
├─────────┴─────────┴─────────────────────┤
│                                         │
│ 📝 선생님 피드백                 1/15   │
│ ┌─────────────────────────────────────┐ │
│ │ 활 잡는 자세가 많이 좋아졌어요.    │ │
│ │ 다음 시간에는 3번 곡 연습해오세요. │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ 📌 주요 포인트                          │
│ ● 보잉 연습                             │
│ ● 음정 정확도                           │
│                                         │
│ 💡 연습 팁                              │
│ ┌─────────────────────────────────────┐ │
│ │ ℹ️ 메트로놈 60 템포로 천천히      │ │
│ │    연습하기                         │ │
│ └─────────────────────────────────────┘ │
│                                         │
└─────────────────────────────────────────┘
```

### 4.3 상태표

| 상태 | 선생님 뷰 | 학생 뷰 |
|------|----------|---------|
| 완료+피드백 없음 | ⚠️ 피드백 작성 유도 배너 + LessonNoteEditor | "아직 피드백이 없습니다" |
| 피드백 없음 | LessonNoteEditor (빈 placeholder) | "아직 피드백이 없습니다" |
| 피드백 있음 | LessonNoteEditor (기존 텍스트) | TeacherFeedbackCard + 날짜 |
| 포인트 없음 | [+] 버튼만 표시 | "아직 등록된 포인트가 없습니다" |
| 포인트 있음 | 목록 + 삭제 버튼 + [+] 추가 | 목록만 표시 |
| 팁 없음 | [+] 버튼만 표시 | "아직 등록된 팁이 없습니다" |
| 팁 있음 | 카드 + 편집 버튼 | 카드만 표시 |

---

## 5. 데이터 모델

### 5.1 기존 엔티티 활용

Lesson 엔티티에 이미 포함된 필드를 그대로 사용:

```dart
@HiveType(typeId: 5)
@JsonSerializable()
class Lesson {
  // ... other fields ...

  @HiveField(20) final String? feedback;
  @HiveField(21) final List<String>? keyPoints;
  @HiveField(22) final String? practiceTips;
  @HiveField(23) final List<LessonRecording>? recordings;

  bool get hasFeedback => feedback != null && feedback!.isNotEmpty;
}
```

### 5.2 향후 확장 모델 (Phase 2)

```dart
/// 레슨 노트 타임라인 항목 (향후)
class LessonNoteTimeline {
  final String lessonId;
  final DateTime lessonDate;
  final String? feedback;
  final List<String>? keyPoints;
  final String? practiceTips;
  final String? repertoireName;     // 해당 레슨의 레퍼토리

  /// 타임라인 표시용
  String get monthLabel => '${lessonDate.year}년 ${lessonDate.month}월';
}
```

---

## 6. 파일 구조

```
frontend/lib/features/lessons/
├── domain/
│   └── entities/
│       └── lesson.dart                          ← feedback/keyPoints/practiceTips (L160-163)
├── data/
│   └── repositories/
│       └── mock_lesson_repository.dart          ← Mock 데이터 (lesson_001, lesson_007)
├── presentation/
│   ├── providers/
│   │   ├── lesson_providers.dart                ← lessonProvider (단건 조회)
│   │   ├── lesson_crud_provider.dart            ← lessonsNotifierProvider (CRUD)
│   │   └── lesson_repository_provider.dart      ← Repository 주입
│   ├── screens/
│   │   └── lesson_detail_screen.dart            ← 3탭 화면, _buildNotesTab() (L236-293)
│   └── widgets/
│       └── lesson_detail/
│           ├── lesson_notes_widgets.dart         ← 모든 노트 위젯 (487줄)
│           └── add_tip_bottom_sheet.dart         ← 팁 추가 바텀시트 (132줄)
```

---

## 7. Provider / Repository

### 7.1 기존 Provider (변경 불필요)

```dart
/// 단건 레슨 조회
@riverpod
Future<Lesson?> lesson(LessonRef ref, String lessonId) async {
  return ref.read(lessonRepositoryProvider).getLesson(lessonId);
}

/// 레슨 CRUD
@riverpod
class LessonsNotifier extends _$LessonsNotifier {
  Future<void> updateLesson(Lesson lesson) async {
    await ref.read(lessonRepositoryProvider).updateLesson(lesson);
    ref.invalidateSelf();
  }
}
```

### 7.2 향후 추가 Provider (Phase 2 — 타임라인)

```dart
/// 학생의 레슨 노트 타임라인 (피드백 있는 레슨만)
@riverpod
Future<List<LessonNoteTimeline>> lessonNoteTimeline(
  LessonNoteTimelineRef ref, String studentId,
) async {
  final repository = ref.watch(lessonRepositoryProvider);
  final lessons = await repository.getLessonsForStudent(studentId);
  return lessons
      .where((l) => l.hasFeedback)
      .map((l) => LessonNoteTimeline(
            lessonId: l.id,
            lessonDate: l.date,
            feedback: l.feedback,
            keyPoints: l.keyPoints,
            practiceTips: l.practiceTips,
          ))
      .toList()
    ..sort((a, b) => b.lessonDate.compareTo(a.lessonDate));
}
```

---

## 8. 에러/엣지 케이스

| 상황 | 현재 동작 | 비고 |
|------|----------|------|
| 피드백 저장 실패 | 에러 Snackbar 표시 | lessonsNotifier에서 처리 |
| 포인트 중복 추가 | 허용 (동일 텍스트 가능) | 향후 중복 체크 고려 |
| 팁 빈 문자열 저장 | `null`로 변환 | `isEmpty == true ? null : content` |
| 오프라인 편집 | Hive 로컬 저장 → 동기화 미지원 | 백엔드 연동 시 해결 |
| 긴 피드백 텍스트 | 스크롤 가능 (제한 없음) | — |

---

## 9. 구현 체크리스트

### Phase 1: 기본 노트 시스템 ✅ 완료

- [x] Lesson 엔티티 feedback/keyPoints/practiceTips 필드
- [x] LessonNoteEditor 위젯 (선생님 인라인 편집)
- [x] TeacherFeedbackCard 위젯 (학생 읽기 전용)
- [x] KeyPointsList 위젯 (추가/삭제)
- [x] PracticeTipsCard 위젯 (추가/편집/삭제)
- [x] AddTipBottomSheet (템플릿 지원)
- [x] LessonDetailScreen 3탭 통합
- [x] Mock 데이터 (lesson_001, lesson_007)

### Phase 2: 타임라인 뷰 (예정)

- [ ] LessonNoteTimeline 모델
- [ ] 레슨 노트 타임라인 화면 (월별 그룹)
- [ ] 학생 프로필 → [레슨 기록] 진입
- [ ] 선생님: 학생별 노트 타임라인 조회

### Phase 3: 학부모 열람 (예정)

- [ ] 학부모 대시보드 → 레슨 노트 탭 실데이터 연동
- [ ] 학부모용 TeacherFeedbackCard (읽기 전용)
- [ ] 알림: 새 피드백 등록 시 학부모 알림

### Phase 4: AI 변환 (예정)

- [ ] 레슨 녹음 → Whisper STT → 요약 텍스트
- [ ] AI 피드백 카드 (레슨 녹음 기반 자동 생성)

---

## 10. 변경 이력

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| 1.0 | 2026-03-02 | 초안 — 기존 구현 코드 기반 문서화 |
| 1.1 | 2026-03-11 | LessonNoteEditor 저장 상태 인디케이터 추가 (#108), 레슨 완료 시 피드백 유도 배너 (#112) |
