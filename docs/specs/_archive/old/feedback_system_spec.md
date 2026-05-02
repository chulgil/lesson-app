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
Layer 1: 좋아요 + 코멘트 (1탭, 매 레슨)
    → 확인/격려 중심, 선생님 부담 최소

Layer 2: Voice + Text Note (2-3탭, 주 1-2회)
    → 구체적 피드백, 연주 시범 포함

Layer 3: Progress Review (포트폴리오, 월 1회)
    → 성장 기록, 학부모 공유
```

### 핵심 설계 원칙

1. **1탭 피드백이 왕** — 선택지가 1개여야 0.3초 만에 피드백 가능. 3개면 매번 고민 (Hick's Law)
2. **초보자에게는 격려 > 평가** — 긍정 반응만, 부정 평가는 코멘트로
3. **피드백 = 다음 과제 트리거** — 끝이 아닌 다음 행동으로 연결
4. **학부모 가시성 = 유지율** — 좋아요 알림만으로 불안 해소

### 설계 결정 1: 선생님 좋아요 1개 (Quick Reaction 3종 → 폐기)

**변경 전:** 👍⭐💪 3개 중 선택 → **변경 후:** 👍 좋아요 1개

| 근거 | 설명 |
|------|------|
| **Hick's Law** | 3개 선택지 = 매번 2-3초 고민. 하루 30-40개 과제에 누적되면 피드백 포기 |
| **행동 동일** | 👍⭐💪 어떤 것이든 학생 반응은 "선생님이 확인했다" → 연습 지속. 차이 없음 |
| **💪 리스크** | "힘내자"가 부정적으로 해석될 수 있음. 부정 뉘앙스는 코멘트가 적합 |
| **YouTube 검증** | 10억+ 사용자가 좋아요 1개로 충분함을 증명 |
| **확장 가능** | 필요하면 나중에 반응 추가 가능. 먼저 1개로 사용률 확보가 우선 |

### 설계 결정 2: 학생 응답 버튼 제거 (🙏❓ → 메모 텍스트)

**변경 전:** 🙏 감사합니다 / ❓ 질문있어요 버튼 2개 → **변경 후:** "메모 남기기" 텍스트 필드 (선택)

| 근거 | 설명 |
|------|------|
| **🙏 정보량 = 0** | 모든 학생이 예의상 탭. 100% 탭하면 신호 아님. 읽음 확인은 앱이 자동 처리 |
| **안 누르면 무례?** | 🙏 버튼 존재 자체가 "안 누르면 감사 안 하는 것" 부담을 생성 |
| **❓는 피드백 응답이 아님** | 질문은 선생님 👍 유무와 무관하게 가능해야 함. "레슨 메모" 기능이 적합 |
| **❓ 탭해도 결국 텍스트 작성** | 별도 버튼 없이 텍스트 필드 하나가 더 직관적 |
| **Instagram/YouTube** | 좋아요에 "감사합니다" 응답 버튼은 없음. 당연히 감사한 것 |

---

## Phase 1: 좋아요 + 코멘트 + Feedback 엔티티 (MVP)

### 1.1 Feedback 엔티티 설계

```dart
/// 피드백 엔티티 — 레슨/과제별 피드백을 독립 저장
class LessonFeedback {
  final String id;
  final String lessonId;       // 연결된 레슨
  final String studentId;
  final String teacherId;

  // 좋아요 (선생님 → 학생, 1탭)
  final bool hasLike;
  final DateTime? likedAt;

  // Text feedback (기존 Lesson.feedback 대체)
  final String? teacherNote;   // 선생님 코멘트
  final String? studentNote;   // 학생 메모/질문 (자유 텍스트)

  // Voice feedback (Phase 2)
  final String? voiceUrl;
  final int? voiceDurationSeconds;

  final DateTime createdAt;
  final DateTime? updatedAt;
}
```

> **QuickReaction enum 폐기** — 기존 코드의 `QuickReaction`은 `hasLike: bool`로 단순화.
> **StudentResponse enum 폐기** — 🙏❓ 버튼 제거, 학생 메모는 `studentNote` 텍스트 필드로 통합.
> `PracticeItem.teacherReaction` 필드는 `hasLike`로 역매핑 후 제거.

### 1.2 좋아요 UI — 선생님 화면

레슨 완료 후 과제 항목마다 좋아요 버튼 1개 노출:

```
┌──────────────────────────────────────────────┐
│  14:00  김민준 · 바이올린 · 60분        완료  │
│                                              │
│  ☐ 스케일 G장조 3회                    [👍]  │
│  ☐ 비브라토 연습 10분                  [👍]  │
│                                              │
│  + 코멘트 추가                                │
└──────────────────────────────────────────────┘
```

**동작:**
- 레슨 `displayStatus == completed`일 때만 표시
- 1탭: 즉시 좋아요 토글 + 학생에게 알림 (FCM 구현 시)
- 재탭: 좋아요 해제
- "+ 코멘트 추가": 기존 `quick_feedback_spec` 플로우로 이동 (구체적 피드백)

### 1.3 학생 화면 — 피드백 확인 + 메모

선생님 피드백 표시 + 학생 메모 (선택적 텍스트 입력):

```
┌──────────────────────────────────────────────┐
│  3/14 (금) 레슨 · 바이올린 · 14:00          │
│                                              │
│  선생님 피드백: 👍                            │
│  "비브라토 연습 잘 되고 있어요"               │
│                                              │
│  메모 남기기 (선택)                    [연필]  │
└──────────────────────────────────────────────┘
```

**동작:**
- 선생님 피드백(👍 또는 코멘트)이 있는 레슨에 표시
- 읽음 확인은 앱이 자동 처리 (별도 🙏 버튼 불필요)
- "메모 남기기" 탭 → 텍스트 입력 필드 확장 (질문, 감상, 어려운 점 등 자유 작성)
- 선생님 👍 유무와 무관하게 항상 접근 가능 (과제/레슨 단위)

### 1.4 기존 코드 정리 (QuickReaction → hasLike)

현재 `PracticeItem`에 `QuickReaction` 관련 필드가 이미 추가되어 있음. 단순화:

| 현재 (제거) | 변경 후 (유지) |
|------------|---------------|
| `teacherReaction: QuickReaction?` | `hasLike: bool` (기존 필드 그대로) |
| `teacherReactionAt: DateTime?` | `likedAt: DateTime?` (기존 필드 그대로) |
| `studentResponse: StudentResponse?` | **제거** (메모 텍스트로 대체) |
| `studentResponseAt: DateTime?` | **제거** |
| `QuickReaction` enum | **제거** |
| `StudentResponse` enum | **제거** |

**마이그레이션:** `teacherReaction != null` → `hasLike = true`로 매핑 후 `QuickReaction`/`StudentResponse` 관련 필드 모두 제거.

### 1.5 좋아요 아이콘 통일

| 위치 | 현재 | 변경 |
|------|------|------|
| 선생님: `practice_items_section.dart` | `QuickReaction` 칩 3개 | 👍 토글 버튼 1개 |
| 학생 홈: `weekly_practice_widget.dart` | `Icons.favorite` (❤️) | 👍 표시 |

### 1.6 학부모 가시성

| 항목 | 학부모에게 보이는 것 |
|------|-------------------|
| 좋아요 | 👍 받았는지 여부 |
| 선생님 코멘트 | 전체 텍스트 |
| 학생 메모 | 메모 내용 (있는 경우) |
| 연습 현황 | 완료율, 연습 횟수 |

---

## Phase 2: Voice + Text 피드백 (향후)

| 기능 | 설명 |
|------|------|
| 음성 피드백 60초 | 선생님 음성 코멘트, 연주 시범 포함 |
| 피드백 → 과제 연결 | 연습 포인트가 다음 PracticeItem으로 자동 생성 |
| 피드백 템플릿 | 자주 쓰는 문구 저장 (기존 FeedbackPreset 확장) |
| 학부모 알림 | 좋아요/피드백 시 학부모 푸시 |

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
- `LessonFeedback` — 레슨별 피드백 저장 (좋아요 + 코멘트 + 학생 메모)

### 수정 엔티티
- `PracticeItem` — `QuickReaction`/`StudentResponse` 관련 필드 제거, 기존 `hasLike` 유지
- `Lesson` — `feedback` 필드는 유지하되, `LessonFeedback` 엔티티로 점진적 이전

### 제거
- `QuickReaction` enum — 좋아요 1개로 단순화
- `StudentResponse` enum — 학생 메모 텍스트로 대체

### 신규 Repository/Provider
- `FeedbackRepository` + `MockFeedbackRepository`
- `lessonFeedbackProvider(lessonId)` — 레슨별 피드백 조회
- `studentFeedbackHistoryProvider(studentId)` — 학생별 피드백 히스토리

---

## 구현 체크리스트

### Phase 1 MVP
- [ ] `LessonFeedback` 엔티티 생성
- [ ] `FeedbackRepository` + Mock
- [ ] `QuickReaction` + `StudentResponse` enum 제거, `hasLike` 복원
- [ ] 선생님 과제 항목에 👍 토글 버튼 1개
- [ ] 학생 레슨 카드에 "메모 남기기" 텍스트 필드
- [ ] `weekly_practice_widget.dart` 아이콘 👍 통일
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
| 2026-03-15 | Quick Reaction 3종 → 좋아요 1개로 단순화 (Hick's Law, 행동 동일성 근거) |
| 2026-03-15 | Student Response 🙏❓ 2종 → "메모 남기기" 텍스트 필드로 통합 (정보량=0, 읽음확인 자동화) |
