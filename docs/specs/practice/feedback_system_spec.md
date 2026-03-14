# 과제 피드백 시스템 스펙

> 작성일: 2026-03-15
> 상태: 스펙 검토 중
> 이슈: #173
> 관련: [quick_feedback_spec](../lesson/quick_feedback_spec.md) | [assignment_ui_simplification](../lesson/assignment_ui_simplification.md) | [practice_sharing_spec](practice_sharing_spec.md)

---

## 개요

### 문제

현재 피드백 시스템은 **선생님→학생 단방향, 좋아요 1종류**만 지원한다.
학생은 피드백에 반응할 수 없고, 학부모는 피드백을 볼 수 없다.

| 현재 | 문제점 |
|------|--------|
| `PracticeItem.hasLike` (bool) | 좋아요 1종류, 선생님만 가능 |
| `Lesson.feedback` (String) | 별도 엔티티 없음, 검색/분류 불가 |
| 학생→선생님 반응 없음 | 양방향 소통 불가 |
| 학부모 과제 탭 하드코딩 | 실데이터 미연동 |

### 업계 분석 (12개 앱 참조)

> ClassDojo, Seesaw, Tonara, SmartMusic, Google Classroom 등

**3-Layer Feedback 아키텍처가 업계 표준:**

```
Layer 1: Quick Reaction (1탭, 매 레슨)
    → 격려/확인 중심, 선생님 부담 최소

Layer 2: Voice + Text Note (2-3탭, 주 1-2회)
    → 구체적 피드백, 연주 시범 포함

Layer 3: Progress Review (포트폴리오, 월 1회)
    → 성장 기록, 학부모 공유
```

### 핵심 설계 원칙

1. **1탭 피드백이 왕** — 선생님이 1탭으로 피드백을 줄 수 있으면 사용률이 극적으로 올라간다 (ClassDojo 증명)
2. **초보자에게는 격려 > 평가** — 긍정 반응 우선, 부정 평가는 텍스트로
3. **피드백 = 다음 과제 트리거** — 끝이 아닌 다음 행동으로 연결
4. **학부모 가시성 = 유지율** — Quick Reaction 알림만으로 불안 해소

---

## Phase 1: Quick Reaction + Feedback 엔티티 (MVP)

### 1.1 Feedback 엔티티 설계

```dart
/// 피드백 엔티티 — 레슨/과제별 피드백을 독립 저장
class LessonFeedback {
  final String id;
  final String lessonId;       // 연결된 레슨
  final String studentId;
  final String teacherId;

  // Quick Reaction (선생님 → 학생)
  final QuickReaction? teacherReaction;
  final DateTime? teacherReactionAt;

  // Student Response (학생 → 선생님)
  final StudentResponse? studentResponse;
  final DateTime? studentResponseAt;

  // Text feedback (기존 Lesson.feedback 대체)
  final String? teacherNote;
  final String? studentNote;    // 학생 질문/감상

  // Voice feedback (Phase 2)
  final String? voiceUrl;
  final int? voiceDurationSeconds;

  final DateTime createdAt;
  final DateTime? updatedAt;
}

/// 선생님 Quick Reaction 유형
enum QuickReaction {
  good,       // 👍 잘했어요
  excellent,  // ⭐ 훌륭해요
  fighting;   // 💪 힘내자

  String get emoji => switch (this) {
    good => '👍',
    excellent => '⭐',
    fighting => '💪',
  };

  String get label => switch (this) {
    good => '잘했어요',
    excellent => '훌륭해요',
    fighting => '힘내자',
  };
}

/// 학생 응답 유형
enum StudentResponse {
  thanks,    // 🙏 감사합니다
  question;  // ❓ 질문있어요

  String get emoji => switch (this) {
    thanks => '🙏',
    question => '❓',
  };

  String get label => switch (this) {
    thanks => '감사합니다',
    question => '질문있어요',
  };
}
```

### 1.2 Quick Reaction UI — 선생님 화면

레슨 완료 후 레슨 카드에 Quick Reaction 버튼 3개 노출:

```
┌──────────────────────────────────────────────┐
│  14:00  김민준 · 바이올린 · 60분        완료  │
│                                              │
│  [👍 잘했어요]  [⭐ 훌륭해요]  [💪 힘내자]    │
│                                              │
│  + 코멘트 추가                                │
└──────────────────────────────────────────────┘
```

**동작:**
- 레슨 `displayStatus == completed`일 때만 표시
- 1탭: 즉시 반응 저장 + 학생에게 알림 (FCM 구현 시)
- 재탭: 토글 (같은 반응 해제, 다른 반응으로 교체)
- "+ 코멘트 추가": 기존 `quick_feedback_spec` 플로우로 이동

### 1.3 Student Response UI — 학생 화면

선생님이 Quick Reaction을 보낸 후 학생 화면에 표시:

```
┌──────────────────────────────────────────────┐
│  3/14 (금) 레슨 · 바이올린 · 14:00          │
│                                              │
│  선생님 피드백: ⭐ 훌륭해요                   │
│  "비브라토 연습 잘 되고 있어요"               │
│                                              │
│  [🙏 감사합니다]  [❓ 질문있어요]             │
└──────────────────────────────────────────────┘
```

**동작:**
- 선생님 반응이 있는 레슨에만 응답 버튼 표시
- 1탭: 즉시 응답 저장
- "❓ 질문있어요": 탭 시 텍스트 입력 필드 확장 (학생 질문 작성)

### 1.4 과제 좋아요 → Quick Reaction 통합

기존 `PracticeItem.hasLike` (bool)을 Quick Reaction으로 대체:

| 현재 | 변경 후 |
|------|---------|
| `hasLike: bool` | `teacherReaction: QuickReaction?` |
| `likedAt: DateTime?` | `teacherReactionAt: DateTime?` |
| thumb_up 아이콘 1개 | Quick Reaction 칩 3개 |

**하위 호환성:** `hasLike`는 `teacherReaction != null`로 매핑. 기존 좋아요 데이터는 `QuickReaction.good`으로 마이그레이션.

### 1.5 좋아요 아이콘 불일치 수정

| 위치 | 현재 | 변경 |
|------|------|------|
| 선생님: `practice_items_section.dart` | `Icons.thumb_up` | Quick Reaction 칩 |
| 학생 홈: `weekly_practice_widget.dart` | `Icons.favorite` (❤️) | Quick Reaction 이모지 표시 |

### 1.6 학부모 가시성

| 항목 | 학부모에게 보이는 것 |
|------|-------------------|
| Quick Reaction | 어떤 반응을 받았는지 (아이콘 + 라벨) |
| 선생님 코멘트 | 전체 텍스트 |
| 학생 응답 | 응답 여부 |
| 연습 현황 | 완료율, 연습 횟수 |

---

## Phase 2: Voice + Text 피드백 (향후)

| 기능 | 설명 |
|------|------|
| 음성 피드백 60초 | 선생님 음성 코멘트, 연주 시범 포함 |
| 피드백 → 과제 연결 | 연습 포인트가 다음 PracticeItem으로 자동 생성 |
| 피드백 템플릿 | 자주 쓰는 문구 저장 (기존 FeedbackPreset 확장) |
| 학부모 알림 | Quick Reaction/피드백 시 학부모 푸시 |

---

## Phase 3: Progress Review (향후)

| 기능 | 설명 |
|------|------|
| 월간 리포트 | 출석, 연습, 성장 포인트 자동 집계 |
| 학부모 공유 | PDF/링크 내보내기 |
| 녹음 비교 | 이번주 vs 지난주 연주 비교 |
| 루브릭 평가 | 항목별 체크리스트 (중급 이상) |

---

## 데이터 모델 변경 요약

### 신규 엔티티
- `LessonFeedback` — 레슨별 피드백 저장
- `QuickReaction` enum — 선생님 반응 3종
- `StudentResponse` enum — 학생 응답 2종

### 수정 엔티티
- `PracticeItem` — `hasLike` → `teacherReaction: QuickReaction?` 전환
- `Lesson` — `feedback` 필드는 유지하되, `LessonFeedback` 엔티티로 점진적 이전

### 신규 Repository/Provider
- `FeedbackRepository` + `MockFeedbackRepository`
- `lessonFeedbackProvider(lessonId)` — 레슨별 피드백 조회
- `studentFeedbackHistoryProvider(studentId)` — 학생별 피드백 히스토리

---

## 구현 체크리스트

### Phase 1 MVP
- [ ] `LessonFeedback` 엔티티 + `QuickReaction`/`StudentResponse` enum
- [ ] `FeedbackRepository` + Mock
- [ ] 선생님 레슨 카드에 Quick Reaction 버튼 3개
- [ ] 학생 레슨 카드에 Student Response 버튼 2개
- [ ] `PracticeItem.hasLike` → `teacherReaction` 마이그레이션
- [ ] `weekly_practice_widget.dart` 아이콘 통일
- [ ] 피드백 히스토리 화면

### Phase 2
- [ ] 음성 피드백 녹음/재생
- [ ] 피드백 → PracticeItem 자동 생성
- [ ] 커스텀 피드백 템플릿 관리
- [ ] 학부모 푸시 알림 연동

### Phase 3
- [ ] 월간 리포트 자동 생성
- [ ] 학부모 공유 (PDF/링크)
- [ ] 녹음 비교 플레이어

---

## 변경 이력

| 날짜 | 변경 내용 |
|------|----------|
| 2026-03-15 | 초안 작성 (업계 12개 앱 분석 기반, #173) |
