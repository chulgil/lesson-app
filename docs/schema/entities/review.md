# Review 관련 엔티티

> 작성일: 2026-01-24
> 상태: 📋 설계 완료 (미구현)
> 관련 스펙: [review_system.md](../../specs/review/review_system.md)

---

## 개요

레슨 피드백과 선생님 리뷰 시스템의 핵심 엔티티입니다.

```
TeacherReview (리뷰)
    ├── CategoryRatings (카테고리별 평점)
    ├── TeacherResponse (선생님 답변)
    └── ReviewTrigger (리뷰 트리거)

LessonFeedback (레슨 피드백 - 비공개)
    └── LessonSatisfaction (만족도)

TeacherReviewSettings (선생님 리뷰 설정)
    └── ReviewVisibility (공개 범위)

TeacherReviewStats (리뷰 통계)
```

---

## Hive TypeId 할당 (예정)

> ⚠️ 구현 시 할당 필요

| TypeId | 엔티티 |
|:------:|--------|
| TBD | TeacherReview |
| TBD | ReviewerType |
| TBD | ReviewTrigger |
| TBD | CategoryRatings |
| TBD | LessonFeedback |
| TBD | LessonSatisfaction |
| TBD | TeacherResponse |
| TBD | TeacherReviewSettings |
| TBD | ReviewVisibility |
| TBD | TeacherBadge |
| TBD | TeacherReviewStats |

---

## TeacherReview (선생님 리뷰)

```dart
class TeacherReview {
  final String id;
  final String studentId;
  final String teacherId;
  final ReviewTrigger trigger;

  // 작성자 정보
  final ReviewerType reviewerType;
  final String? parentId;           // 부모 대리 작성 시
  final String? childProfileId;     // 자녀 프로필 ID

  // 평점
  final int overallRating;          // 1-5 stars
  final CategoryRatings categoryRatings;

  // 텍스트 리뷰
  final String? reviewText;         // 최소 20자, 최대 500자

  // 메타데이터
  final int lessonCount;            // 작성 시점 레슨 횟수
  final Duration connectionDuration; // 연결 기간
  final DateTime createdAt;
  final DateTime? updatedAt;

  // 선생님 답변
  final TeacherResponse? response;

  // 공개 설정
  final bool isPublic;              // 선생님이 공개 여부 설정
  final bool studentWantsPublic;    // 학생 공개 동의

  // 작성자 표시명
  String get displayReviewer => reviewerType == ReviewerType.parent ? '학부모' : '학생';
}
```

### 필드 설명

| 필드 | 타입 | 설명 |
|------|------|------|
| id | String | 고유 식별자 |
| studentId | String | 학생 ID |
| teacherId | String | 선생님 ID |
| trigger | ReviewTrigger | 리뷰 요청 트리거 |
| reviewerType | ReviewerType | 작성자 유형 (student/parent) |
| overallRating | int | 전체 평점 (1-5) |
| categoryRatings | CategoryRatings | 카테고리별 평점 |
| reviewText | String? | 리뷰 텍스트 (20-500자) |
| lessonCount | int | 작성 시점 레슨 횟수 |
| isPublic | bool | 공개 여부 |

---

## ReviewerType (작성자 유형)

```dart
enum ReviewerType {
  student,   // 학생 본인 (만 14세 이상)
  parent,    // 부모 대리 작성 (만 14세 미만 자녀)
}
```

| 값 | 설명 | 표시 |
|------|------|------|
| student | 학생 본인 작성 | "학생" |
| parent | 부모 대리 작성 | "학부모" |

---

## ReviewTrigger (리뷰 트리거)

```dart
enum ReviewTrigger {
  trialLessonComplete,  // 체험레슨 종료
  connectionEnded,      // 연결 종료
  voluntary,            // 자발적 작성
}
```

| 값 | 시점 | 설명 |
|------|------|------|
| trialLessonComplete | 체험레슨 완료 직후 | 첫 인상 평가 |
| connectionEnded | 연결 해제 시 | 최종 평가 |
| voluntary | 언제든지 | 진행 중에도 작성 가능 |

---

## CategoryRatings (카테고리별 평점)

```dart
class CategoryRatings {
  final int preparation;    // 수업 준비
  final int explanation;    // 설명력
  final int friendliness;   // 친절도
  final int progressMgmt;   // 진도 관리

  double get average =>
    (preparation + explanation + friendliness + progressMgmt) / 4;
}
```

### 카테고리 설명

| 필드 | 한글명 | 설명 |
|------|--------|------|
| preparation | 수업 준비 | 레슨 자료, 커리큘럼 준비 |
| explanation | 설명력 | 이해하기 쉬운 설명 |
| friendliness | 친절도 | 학생 배려, 소통 |
| progressMgmt | 진도 관리 | 적절한 난이도, 목표 달성 |

---

## LessonFeedback (레슨 피드백 - 비공개)

```dart
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
```

### 필드 설명

| 필드 | 타입 | 설명 |
|------|------|------|
| id | String | 고유 식별자 |
| lessonId | String | 레슨 ID |
| studentId | String | 학생 ID |
| teacherId | String | 선생님 ID |
| satisfaction | LessonSatisfaction? | 만족도 (선택) |
| comment | String? | 한줄 코멘트 (선택) |

---

## LessonSatisfaction (레슨 만족도)

```dart
enum LessonSatisfaction {
  veryGood,   // 😊 매우 좋았어요
  good,       // 🙂 좋았어요
  okay,       // 😐 보통이에요
  notGood,    // 😕 아쉬웠어요
}
```

| 값 | 이모지 | 한글 |
|------|:------:|------|
| veryGood | 😊 | 매우 좋았어요 |
| good | 🙂 | 좋았어요 |
| okay | 😐 | 보통이에요 |
| notGood | 😕 | 아쉬웠어요 |

---

## TeacherResponse (선생님 답변)

```dart
class TeacherResponse {
  final String reviewId;
  final String responseText;  // 최대 300자
  final DateTime createdAt;
  final DateTime? updatedAt;
}
```

### 답변 규칙

| 규칙 | 값 |
|------|-----|
| 최대 길이 | 300자 |
| 수정 가능 | ✓ |
| 삭제 가능 | ✓ |
| 답변 기한 | 30일 이내 |

---

## TeacherReviewSettings (선생님 리뷰 설정)

```dart
class TeacherReviewSettings {
  final ReviewVisibility defaultVisibility;
  final bool showAverageRating;       // 평균 평점 표시
  final bool showCategoryRatings;     // 카테고리별 평점 표시
  final bool showReviewCount;         // 리뷰 수 표시
  final bool allowNewReviews;         // 새 리뷰 허용
}
```

---

## ReviewVisibility (리뷰 공개 범위)

```dart
enum ReviewVisibility {
  public,      // 모든 리뷰 공개
  selective,   // 선생님이 개별 선택
  summaryOnly, // 평균 점수만 공개
  private,     // 완전 비공개
}
```

| 값 | 설명 |
|------|------|
| public | 모든 리뷰 자동 공개 |
| selective | 선생님이 개별 선택 |
| summaryOnly | 평균 점수만 표시 |
| private | 완전 비공개 |

---

## TeacherBadge (선생님 뱃지)

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
```

### 뱃지 획득 조건

| 뱃지 | 조건 | 아이콘 |
|------|------|:------:|
| topRated | 평점 4.8+ & 리뷰 10개+ | ⭐ |
| studentChoice | 평점 4.5+ & 리뷰 20개+ | 👍 |
| verified | 자격증 인증 완료 | ✓ |
| premium | 프로필 완성도 100% | 💎 |
| phoneVerified | 휴대폰 인증 완료 | 📱 |

---

## TeacherReviewStats (리뷰 통계)

```dart
class TeacherReviewStats {
  final double averageRating;
  final int totalReviews;
  final int publicReviews;
  final Map<String, double> categoryAverages;
  final Map<int, int> ratingDistribution;  // 1: 2개, 5: 15개 등
}
```

---

## 리뷰 정책 상수

| 항목 | 값 | 설명 |
|------|-----|------|
| 최소 레슨 횟수 | 1회 | 리뷰 작성 조건 |
| 텍스트 최소 길이 | 20자 | 공개 시 필수 |
| 텍스트 최대 길이 | 500자 | |
| 수정 가능 기간 | 7일 | 작성 후 7일 이내 |
| 학생 삭제 | 가능 | |
| 선생님 삭제 | 불가 | |

---

## 파일 위치 (예정)

```
lib/features/review/domain/entities/teacher_review.dart
lib/features/review/domain/entities/lesson_feedback.dart
lib/features/review/domain/entities/category_ratings.dart
lib/features/review/domain/entities/teacher_response.dart
lib/features/review/domain/entities/teacher_review_settings.dart
lib/features/review/domain/entities/teacher_review_stats.dart
```

---

## 관련 문서

| 문서 | 설명 |
|------|------|
| [review_system.md](../../specs/review/review_system.md) | 리뷰 시스템 스펙 |
| [teacher_registration.md](../../specs/user/teacher_registration.md) | 선생님 등록/검색 |
| [trial_lesson_system.md](../../specs/trial/trial_lesson_system.md) | 체험레슨 시스템 |
