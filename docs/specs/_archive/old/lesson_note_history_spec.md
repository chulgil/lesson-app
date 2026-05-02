# 레슨 노트 히스토리 스펙

> 구현 상태: ✅ 구현 완료
> 작성일: 2026-03-07
> 상태: 스펙 작성 완료
> 이슈: [#68](https://github.com/chulgil/lesson-app/issues/68)
> 관련 문서: [lesson_note_spec.md](lesson_note_spec.md), [teacher_ux_review.md](../design/teacher_ux_review.md)
> 엔티티: [lesson.dart](../../../frontend/lib/features/lessons/domain/entities/lesson.dart)

---

## 1. 개요

### 1.1 배경

레슨 노트(feedback, keyPoints, practiceTips)는 개별 레슨 상세 > 노트 탭에서만 조회 가능.
"김민수 학생의 지난 3개월 노트"를 보려면 레슨을 하나하나 열어야 함.
학부모 상담 시 과거 노트 검색이 불가능.

### 1.2 목표

- 학생별 레슨 노트를 날짜순으로 일괄 조회
- 키워드 검색으로 과거 노트 빠르게 찾기
- 학부모 상담 시 근거 자료로 활용

### 1.3 핵심 결정사항

| 항목 | 결정 |
|------|------|
| 위치 | 학생 상세 화면 - 새 섹션 (기존 섹션 아래) |
| 데이터 소스 | `Lesson` 엔티티의 feedback, keyPoints, practiceTips 필드 |
| 검색 | 클라이언트 사이드 필터링 (MVP), 향후 서버 검색 |
| 기간 필터 | 1개월 / 3개월 / 6개월 / 전체 |

---

## 2. 화면 설계

### 2.1 학생 상세 내 "레슨 노트" 섹션

```
+-------------------------------------------+
| 레슨 노트 히스토리                [전체보기]|
+-------------------------------------------+
|                                           |
| 2026.03.05 (수)                           |
| +---------------------------------------+ |
| | 활 잡는 자세가 많이 좋아졌어요.        | |
| | # 보잉 연습  # 음정 정확도            | |
| +---------------------------------------+ |
|                                           |
| 2026.02.26 (수)                           |
| +---------------------------------------+ |
| | 비브라토 속도 조절이 아직 부족합니다.   | |
| | # 비브라토  # 왼손 이완               | |
| +---------------------------------------+ |
|                                           |
+-------------------------------------------+
```

### 2.2 전체보기 화면 (별도 라우트)

```
+-------------------------------------------+
| <- 레슨 노트     김민수                    |
+-------------------------------------------+
| [검색어 입력...]                           |
+-------------------------------------------+
| [1개월] [3개월] [6개월] [전체]             |
+-------------------------------------------+
|                                           |
| 2026년 3월                                |
| +---------------------------------------+ |
| | 03.05 (수)  바이올린                   | |
| | 활 잡는 자세가 많이 좋아졌어요.        | |
| | # 보잉 연습  # 음정 정확도            | |
| | 연습 팁: 메트로놈 60 BPM으로 스케일    | |
| +---------------------------------------+ |
|                                           |
| +---------------------------------------+ |
| | 02.26 (수)  바이올린                   | |
| | 비브라토 속도 조절이 아직 부족합니다.   | |
| | # 비브라토  # 왼손 이완               | |
| +---------------------------------------+ |
|                                           |
| 2026년 2월                                |
| +---------------------------------------+ |
| | 02.19 (수)  ...                       | |
| +---------------------------------------+ |
+-------------------------------------------+
```

### 2.3 UI 구성 요소

| 요소 | 설명 |
|------|------|
| 노트 카드 | 날짜 + feedback + keyPoints(칩) + practiceTips |
| 검색 바 | feedback, keyPoints, practiceTips 내 키워드 검색 |
| 기간 필터 칩 | 1개월/3개월/6개월/전체 (FilterChip) |
| 월별 그룹 | 헤더로 월 구분 |

### 2.4 노트 카드 구성

```dart
// LessonNoteCard 위젯
- 날짜 헤더: "03.05 (수)  바이올린"
- feedback: 자유 텍스트 (최대 3줄, 더보기)
- keyPoints: Chip 목록 (# 태그 형태)
- practiceTips: 접이식 (탭하면 펼침)
- 탭 시: 해당 레슨 상세로 이동
```

---

## 3. 데이터 흐름

### 3.1 기존 Provider 활용

| Provider | 용도 | 파일 |
|----------|------|------|
| `lessonsByStudentProvider` | 학생별 레슨 목록 | providers.dart |

### 3.2 신규 Provider

```dart
// 학생별 노트가 있는 레슨만 필터링
@riverpod
Future<List<Lesson>> studentLessonNotes(
  StudentLessonNotesRef ref,
  String studentId,
) async {
  final lessons = await ref.watch(lessonsByStudentProvider(studentId).future);
  return lessons
      .where((l) => l.feedback != null || (l.keyPoints?.isNotEmpty ?? false))
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date)); // 최신순
}
```

### 3.3 검색/필터

```dart
// 클라이언트 사이드 필터링 (검색어 + 기간)
@riverpod
Future<List<Lesson>> filteredLessonNotes(
  FilteredLessonNotesRef ref,
  String studentId,
  String query,
  NoteFilterPeriod period,
) async {
  final notes = await ref.watch(studentLessonNotesProvider(studentId).future);
  return notes.where((lesson) {
    // 기간 필터
    final cutoff = period.cutoffDate;
    if (cutoff != null && lesson.date.isBefore(cutoff)) return false;
    // 검색어 필터
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return (lesson.feedback?.toLowerCase().contains(q) ?? false) ||
        (lesson.keyPoints?.any((kp) => kp.toLowerCase().contains(q)) ?? false) ||
        (lesson.practiceTips?.toLowerCase().contains(q) ?? false);
  }).toList();
}

enum NoteFilterPeriod {
  oneMonth,
  threeMonths,
  sixMonths,
  all;

  DateTime? get cutoffDate {
    final now = DateTime.now();
    switch (this) {
      case oneMonth: return now.subtract(const Duration(days: 30));
      case threeMonths: return now.subtract(const Duration(days: 90));
      case sixMonths: return now.subtract(const Duration(days: 180));
      case all: return null;
    }
  }
}
```

---

## 4. 라우트

| 경로 | 화면 | 설명 |
|------|------|------|
| `/students/:id` | StudentDetailScreen | 기존 (노트 섹션 추가) |
| `/students/:id/notes` | LessonNoteHistoryScreen | 전체보기 (신규) |

---

## 5. 구현 계획

### Phase 1: 학생 상세 내 노트 미리보기

1. `studentLessonNotesProvider` 생성
2. `StudentLessonNotesPreview` 위젯 (최근 3개 노트)
3. 학생 상세 화면에 섹션 추가 (RecentLessons 아래)

### Phase 2: 전체보기 화면

1. `LessonNoteHistoryScreen` 생성
2. 라우트 등록 (`/students/:id/notes`)
3. 검색 + 기간 필터 구현
4. 월별 그룹핑 UI

### Phase 3: 상호작용

1. 노트 카드 탭 -> 레슨 상세 이동
2. keyPoints 칩 탭 -> 해당 키워드로 검색 필터링

---

## 6. 관련 파일

| 파일 | 역할 |
|------|------|
| `lessons/domain/entities/lesson.dart` | Lesson 엔티티 (feedback, keyPoints, practiceTips) |
| `students/presentation/screens/student_detail_screen.dart` | 학생 상세 (삽입 위치) |
| `lessons/presentation/screens/lesson_detail_screen.dart` | 레슨 상세 (노트 탭 기존) |
| `lessons/presentation/widgets/lesson_note_widgets.dart` | 기존 노트 위젯 (재사용 가능) |

---

## 7. 변경 이력

| 날짜 | 변경 내용 |
|------|----------|
| 2026-03-07 | 초기 스펙 작성 |
