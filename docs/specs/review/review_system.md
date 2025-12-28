# 레슨 피드백/리뷰 시스템 스펙

> 작성일: 2025-12-27
> 상태: 스펙 확정

---

## 개요

레슨 피드백을 기반으로 선생님 리뷰를 생성하는 통합 시스템

### 핵심 결정사항

| 항목 | 결정 |
|------|------|
| 시스템 범위 | 피드백 기반 리뷰 통합 |
| 피드백 방향 | 선택적 (원하는 경우에만) |
| 리뷰 방향 | 학생→선생님 |
| 작성 시점 | 체험레슨 종료, 연결 종료, 자유 등록 |
| 리뷰 항목 | 총점 + 카테고리 + 텍스트 |
| 공개 범위 | 선생님 선택 |
| 부정 리뷰 | 답변 기능 |
| 활용 | 검색 랭킹 + 뱃지 |

---

## 자녀 프로필 리뷰 처리

> 미성년자 정책에 따라 만 14세 미만 학생은 별도 회원이 아닌 부모 계정의 "자녀 프로필"입니다.
> 자녀 프로필의 리뷰는 **부모가 대신 작성**합니다.

### 리뷰 작성자 유형

```dart
/// 리뷰 작성자 유형
enum ReviewerType {
  student,   // 학생 본인 (만 14세 이상)
  parent,    // 부모 대리 작성 (만 14세 미만 자녀)
}

/// 리뷰 모델 확장
class TeacherReview {
  // ... 기존 필드

  // 작성자 정보
  final ReviewerType reviewerType;
  final String? parentId;           // 부모 대리 작성 시
  final String? childProfileId;     // 자녀 프로필 ID
  final String? studentId;          // 학생 계정 ID

  // 작성자 표시명 (공개 리뷰에서)
  String get displayReviewer {
    if (reviewerType == ReviewerType.parent) {
      return '학부모';  // 또는 '보호자'
    }
    return '학생';
  }
}
```

### 리뷰 작성 권한

| 레슨 수혜자 | 리뷰 작성 권한 | 표시 |
|------------|--------------|------|
| 자녀 프로필 (만 14세 미만) | 부모만 작성 가능 | "학부모" |
| 학생 계정 (만 14세 이상) | 학생 본인 작성 | "학생" |
| 부모 연동된 학생 | 학생 본인만 작성 | "학생" |

### 리뷰 요청 플로우 (자녀 프로필)

```
체험레슨 완료 (자녀 프로필)
    ↓
부모에게 리뷰 요청 알림
    ↓
부모가 리뷰 작성
    ↓
"학부모" 표시로 공개
```

### 리뷰 작성 UI (학부모용)

```
┌─────────────────────────────────────┐
│  ← 리뷰 작성                         │
├─────────────────────────────────────┤
│                                     │
│  자녀: 김민수                        │
│  선생님: 김선생님                     │
│  레슨 횟수: 8회                      │
│                                     │
│  전체 평점                           │
│  ⭐⭐⭐⭐⭐                           │
│                                     │
│  카테고리별 평점                      │
│  ├─ 수업 준비: ⭐⭐⭐⭐⭐              │
│  ├─ 설명력: ⭐⭐⭐⭐⭐                 │
│  ├─ 친절도: ⭐⭐⭐⭐⭐                 │
│  └─ 진도 관리: ⭐⭐⭐⭐⭐              │
│                                     │
│  리뷰 내용                           │
│  ┌─────────────────────────────────┐│
│  │ 아이가 매우 즐겁게 레슨을 받고    ││
│  │ 있습니다. 눈높이에 맞게 설명해    ││
│  │ 주셔서 좋습니다.                 ││
│  └─────────────────────────────────┘│
│                                     │
│  ⓘ 이 리뷰는 '학부모'로 표시됩니다    │
│                                     │
├─────────────────────────────────────┤
│    [취소]              [저장하기]    │
└─────────────────────────────────────┘
```

### 공개 리뷰 표시

```
┌─────────────────────────────────────┐
│  리뷰                               │
│  ──────────────────────────────────│
│  ⭐⭐⭐⭐⭐ 5.0              학부모   │
│  레슨 8회 · 3개월 수강               │
│                                     │
│  "아이가 매우 즐겁게 레슨을 받고     │
│  있습니다. 눈높이에 맞게 설명해      │
│  주셔서 좋습니다."                  │
│                                     │
│  2025.12.20                         │
└─────────────────────────────────────┘
```

---

## 1. 시스템 구조

### 1.1 피드백 → 리뷰 통합 플로우

```
레슨 완료 → 피드백 작성 (선택) → 피드백 누적 → 리뷰 요청 트리거 → 리뷰 작성
                ↓                      ↓                ↓
           비공개 기록            학습 데이터       공개 평가 생성
```

### 1.2 리뷰 요청 트리거

| 트리거 | 시점 | 설명 |
|--------|------|------|
| 체험레슨 종료 | 체험레슨 완료 직후 | 첫 인상 평가 |
| 연결 종료 | 학생-선생님 연결 해제 시 | 최종 평가 |
| 자유 등록 | 언제든지 | 진행 중에도 작성 가능 |

---

## 2. 피드백 시스템 (비공개)

### 2.1 레슨 피드백

```dart
/// Lesson feedback from student to teacher (private)
class LessonFeedback {
  final String id;
  final String lessonId;
  final String studentId;
  final String teacherId;

  // Quick feedback (optional)
  final LessonSatisfaction? satisfaction;  // 만족도
  final String? comment;                    // 한줄 코멘트

  final DateTime createdAt;
}

enum LessonSatisfaction {
  veryGood,   // 😊 매우 좋았어요
  good,       // 🙂 좋았어요
  okay,       // 😐 보통이에요
  notGood,    // 😕 아쉬웠어요
}
```

### 2.2 피드백 수집 UI

```dart
// After lesson completion (optional popup)
class LessonFeedbackSheet extends StatelessWidget {
  // "오늘 레슨은 어땠나요?" (선택사항)
  // 😊 😐 😕 이모지 선택
  // "한줄 메모 (선택)" 입력 필드
  // [건너뛰기] [저장]
}
```

### 2.3 피드백 활용

```dart
class FeedbackAnalytics {
  final String teacherId;
  final int totalFeedbacks;
  final Map<LessonSatisfaction, int> satisfactionCounts;
  final double averageSatisfaction;  // 내부 지표 (비공개)

  // Used for:
  // - 선생님 자기 개선 참고
  // - 리뷰 작성 시 참고 데이터 제공
}
```

---

## 3. 리뷰 시스템 (공개 가능)

### 3.1 리뷰 모델

```dart
enum ReviewTrigger {
  trialLessonComplete,  // 체험레슨 종료
  connectionEnded,      // 연결 종료
  voluntary,            // 자발적 작성
}

class TeacherReview {
  final String id;
  final String studentId;
  final String teacherId;
  final ReviewTrigger trigger;

  // Overall rating
  final int overallRating;  // 1-5 stars

  // Category ratings
  final CategoryRatings categoryRatings;

  // Text review
  final String? reviewText;  // 최소 20자, 최대 500자

  // Metadata
  final int lessonCount;     // 작성 시점 레슨 횟수
  final Duration duration;   // 연결 기간
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Teacher response
  final String? teacherResponse;
  final DateTime? respondedAt;

  // Visibility (teacher controls)
  final bool isPublic;  // 선생님이 공개 여부 설정
}

class CategoryRatings {
  final int preparation;    // 수업 준비
  final int explanation;    // 설명력
  final int friendliness;   // 친절도
  final int progressMgmt;   // 진도 관리

  double get average =>
    (preparation + explanation + friendliness + progressMgmt) / 4;
}
```

### 3.2 리뷰 카테고리 상세

| 카테고리 | 한글명 | 설명 |
|----------|--------|------|
| preparation | 수업 준비 | 레슨 자료, 커리큘럼 준비 |
| explanation | 설명력 | 이해하기 쉬운 설명 |
| friendliness | 친절도 | 학생 배려, 소통 |
| progressMgmt | 진도 관리 | 적절한 난이도, 목표 달성 |

### 3.3 리뷰 작성 규칙

```dart
class ReviewPolicy {
  // 작성 조건
  static const int minLessonsForReview = 1;  // 최소 1회 레슨
  static const int minTextLength = 20;       // 최소 20자
  static const int maxTextLength = 500;      // 최대 500자

  // 수정 규칙
  static const Duration editablePeriod = Duration(days: 7);  // 7일 내 수정 가능

  // 삭제 규칙
  static const bool studentCanDelete = true;   // 학생 삭제 가능
  static const bool teacherCanDelete = false;  // 선생님 삭제 불가
}
```

---

## 4. 리뷰 요청 플로우

### 4.1 체험레슨 종료 시

```dart
// After trial lesson completion
class TrialLessonReviewPrompt {
  // Trigger: 체험레슨 상태가 completed로 변경 시

  // Flow:
  // 1. 체험레슨 완료 확인 화면
  // 2. "체험레슨은 어떠셨나요?" 리뷰 요청 팝업
  // 3. 별점 + 카테고리 + 텍스트 입력
  // 4. [나중에] [작성하기]

  // Note: 정규레슨 전환 여부와 관계없이 요청
}
```

### 4.2 연결 종료 시

```dart
// When student-teacher connection ends
class ConnectionEndReviewPrompt {
  // Trigger: 연결 해제 요청 시

  // Flow:
  // 1. "정말 연결을 해제하시겠습니까?"
  // 2. "마지막으로 리뷰를 남겨주시겠어요?" (기존 리뷰 없는 경우)
  // 3. 리뷰 작성 또는 스킵
  // 4. 연결 해제 완료
}
```

### 4.3 자발적 작성

```dart
// Voluntary review from student
class VoluntaryReviewAccess {
  // 접근 경로:
  // - 선생님 프로필 > "리뷰 작성하기"
  // - 레슨 기록 > 해당 선생님 > "리뷰 작성"
  // - 설정 > 내 리뷰 관리

  // 조건:
  // - 연결된 선생님만 가능
  // - 최소 1회 레슨 완료
  // - 기존 리뷰 있으면 수정 모드
}
```

---

## 5. 리뷰 공개 설정

### 5.1 선생님 공개 설정

```dart
class TeacherReviewSettings {
  final ReviewVisibility defaultVisibility;
  final bool showAverageRating;       // 평균 평점 표시
  final bool showCategoryRatings;     // 카테고리별 평점 표시
  final bool showReviewCount;         // 리뷰 수 표시
  final bool allowNewReviews;         // 새 리뷰 허용
}

enum ReviewVisibility {
  public,      // 모든 리뷰 공개
  selective,   // 선생님이 개별 선택
  summaryOnly, // 평균 점수만 공개
  private,     // 완전 비공개
}
```

### 5.2 개별 리뷰 공개 관리

```dart
// Teacher can manage each review
class ReviewManagement {
  final String reviewId;
  final bool isPublic;        // 공개 여부
  final String? teacherNote;  // 내부 메모 (비공개)
}
```

### 5.3 공개 프로필 표시

```dart
class PublicReviewSummary {
  final double averageRating;         // 4.8
  final int totalReviews;             // 리뷰 23개
  final Map<String, double> categoryAverages;  // 카테고리별 평균
  final List<TeacherReview> publicReviews;     // 공개된 리뷰 목록
}
```

---

## 6. 선생님 답변 기능

### 6.1 답변 모델

```dart
class TeacherResponse {
  final String reviewId;
  final String responseText;  // 최대 300자
  final DateTime createdAt;
  final DateTime? updatedAt;
}
```

### 6.2 답변 규칙

```dart
class ResponsePolicy {
  static const int maxLength = 300;           // 최대 300자
  static const bool canEdit = true;           // 수정 가능
  static const bool canDelete = true;         // 삭제 가능
  static const Duration responseWindow = Duration(days: 30);  // 30일 내 답변
}
```

### 6.3 답변 UI

```dart
// Teacher's review management screen
class ReviewResponseSheet extends StatelessWidget {
  // "학생 리뷰에 답변하기"
  // 원본 리뷰 표시
  // 답변 입력 필드
  // [취소] [답변 등록]

  // 답변 후 공개 리뷰에 함께 표시
}
```

---

## 7. 검색 랭킹 & 뱃지

### 7.1 검색 랭킹 반영

```dart
class TeacherSearchRanking {
  // Ranking factors (가중치)
  static const double ratingWeight = 0.3;       // 평균 평점
  static const double reviewCountWeight = 0.2;  // 리뷰 수
  static const double profileWeight = 0.2;      // 프로필 완성도
  static const double activityWeight = 0.2;     // 최근 활동
  static const double certificationWeight = 0.1; // 자격 인증

  double calculateScore(Teacher teacher) {
    return (teacher.averageRating / 5 * ratingWeight) +
           (min(teacher.reviewCount / 20, 1) * reviewCountWeight) +
           (teacher.profileCompletion * profileWeight) +
           (teacher.activityScore * activityWeight) +
           (teacher.hasCertification ? 1 : 0) * certificationWeight;
  }
}
```

### 7.2 뱃지 시스템

```dart
enum TeacherBadge {
  // Review-based badges
  topRated,       // ⭐ 최고 평점 (4.8+ & 10+ 리뷰)
  studentChoice,  // 👍 학생 추천 (4.5+ & 20+ 리뷰)

  // Existing badges
  verified,       // ✓ 자격 인증
  premium,        // 💎 프리미엄 (프로필 100%)
  phoneVerified,  // 📱 본인 인증
}

class BadgeRequirements {
  static bool isTopRated(Teacher teacher) {
    return teacher.averageRating >= 4.8 &&
           teacher.publicReviewCount >= 10;
  }

  static bool isStudentChoice(Teacher teacher) {
    return teacher.averageRating >= 4.5 &&
           teacher.publicReviewCount >= 20;
  }
}
```

### 7.3 뱃지 표시

```dart
// Profile and search results
class TeacherBadgeDisplay extends StatelessWidget {
  final List<TeacherBadge> badges;

  // ⭐ 최고평점 | ✓ 자격인증 | 📱 본인인증
}
```

---

## 8. 리뷰 작성 UI

### 8.1 리뷰 작성 화면

```dart
class ReviewWriteScreen extends StatelessWidget {
  // Step 1: 총점 (필수)
  // "전체적으로 어떠셨나요?"
  // ⭐⭐⭐⭐⭐ (1-5)

  // Step 2: 카테고리별 평점 (필수)
  // 수업 준비: ⭐⭐⭐⭐⭐
  // 설명력: ⭐⭐⭐⭐⭐
  // 친절도: ⭐⭐⭐⭐⭐
  // 진도 관리: ⭐⭐⭐⭐⭐

  // Step 3: 텍스트 리뷰 (선택, 공개 시 필수)
  // "선생님에 대해 자유롭게 작성해주세요"
  // 최소 20자 / 최대 500자

  // Step 4: 공개 동의
  // ☐ 이 리뷰를 다른 학생들에게 공개합니다
  // (선생님이 공개 설정한 경우에만 표시됩니다)

  // [취소] [저장하기]
}
```

### 8.2 내 리뷰 관리

```dart
class MyReviewsScreen extends StatelessWidget {
  // 학생: 내가 작성한 리뷰 목록
  // - 수정 (7일 이내)
  // - 삭제

  // 선생님: 받은 리뷰 목록
  // - 공개/비공개 설정
  // - 답변 작성
  // - 통계 보기
}
```

---

## 9. 데이터 모델 요약

### Review 관련 모델

```dart
// Main review model
class TeacherReview {
  final String id;
  final String studentId;
  final String teacherId;
  final ReviewTrigger trigger;
  final int overallRating;
  final CategoryRatings categoryRatings;
  final String? reviewText;
  final int lessonCount;
  final Duration connectionDuration;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final TeacherResponse? response;
  final bool isPublic;
  final bool studentWantsPublic;  // 학생 공개 동의
}

// Lesson feedback (private)
class LessonFeedback {
  final String id;
  final String lessonId;
  final String studentId;
  final String teacherId;
  final LessonSatisfaction? satisfaction;
  final String? comment;
  final DateTime createdAt;
}

// Teacher review settings
class TeacherReviewSettings {
  final ReviewVisibility defaultVisibility;
  final bool showAverageRating;
  final bool showCategoryRatings;
  final bool showReviewCount;
  final bool allowNewReviews;
}

// Review statistics
class TeacherReviewStats {
  final double averageRating;
  final int totalReviews;
  final int publicReviews;
  final Map<String, double> categoryAverages;
  final Map<int, int> ratingDistribution;  // 1: 2개, 5: 15개 등
}
```

---

## 10. 구현 우선순위

### Phase 1 (MVP)
1. 레슨 피드백 (이모지 + 한줄 코멘트)
2. 기본 리뷰 작성 (총점 + 텍스트)
3. 체험레슨 종료 시 리뷰 요청

### Phase 2
1. 카테고리별 평점
2. 선생님 공개 설정
3. 선생님 답변 기능
4. 연결 종료 시 리뷰 요청

### Phase 3
1. 검색 랭킹 반영
2. 뱃지 시스템
3. 리뷰 통계 대시보드
4. 자발적 리뷰 작성

---

## 11. 관련 문서

| 문서 | 설명 |
|------|------|
| [teacher_registration.md](teacher_registration.md) | 선생님 등록, 검색 시스템 |
| [trial_lesson_system.md](trial_lesson_system.md) | 체험레슨 플로우 |
| [notification_system.md](notification_system.md) | 리뷰 요청 알림 |
