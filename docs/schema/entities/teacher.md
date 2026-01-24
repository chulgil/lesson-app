# Teacher 관련 엔티티

> 작성일: 2026-01-24
> 상태: 📋 설계 완료 (미구현)
> 관련 스펙: [teacher_registration.md](../../specs/user/teacher_registration.md)

---

## 개요

외부 선생님 등록 시스템의 핵심 엔티티입니다.

```
Teacher (선생님)
    ├── TeacherVerification (인증 정보)
    │   ├── PhoneVerification (휴대폰 인증)
    │   └── Certificate (자격증)
    ├── ProfileVisibilitySettings (공개 설정)
    └── Supporting Models
        ├── Education (학력)
        ├── Career (경력)
        ├── FeeRange (레슨료)
        └── Video (포트폴리오)

검색/온보딩
    ├── TeacherSearchFilter (검색 필터)
    ├── TeacherSearchResult (검색 결과)
    └── TutorialProgress (튜토리얼)
```

---

## Hive TypeId 할당 (예정)

> ⚠️ 구현 시 할당 필요

| TypeId | 엔티티 |
|:------:|--------|
| TBD | Teacher |
| TBD | ProfileCompletionLevel |
| TBD | PhoneVerification |
| TBD | Certificate |
| TBD | CertificateStatus |
| TBD | CertificateType |
| TBD | TeacherVerification |
| TBD | VerificationBadge |
| TBD | ProfileVisibilitySettings |
| TBD | ProfileVisibility |
| TBD | Education |
| TBD | Career |
| TBD | FeeRange |
| TBD | LessonType |
| TBD | Video |

---

## Teacher (선생님)

```dart
class Teacher {
  final String id;
  final String userId;

  // Basic info
  final String name;
  final String? profileImage;
  final List<Instrument> instruments;
  final String introduction;

  // Extended info
  final int? experienceYears;
  final List<String>? lessonAreas;
  final List<LessonType>? lessonTypes;
  final FeeRange? feeRange;
  final List<Education>? education;
  final List<Career>? career;
  final List<String>? specialties;
  final String? teachingStyle;
  final List<Video>? portfolioVideos;

  // Verification
  final TeacherVerification verification;

  // Settings
  final ProfileVisibilitySettings visibilitySettings;

  // Computed
  ProfileCompletionLevel get completionLevel;
  int get completionPercentage;
  List<String> get incompleteFields;
}
```

### 필드 설명

| 필드 | 타입 | 설명 |
|------|------|------|
| id | String | 고유 식별자 |
| userId | String | Auth 사용자 ID |
| name | String | 이름 (필수) |
| profileImage | String? | 프로필 사진 (필수) |
| instruments | List<Instrument> | 가르치는 악기 (필수, 최소 1개) |
| introduction | String | 소개글 (필수, 최소 20자) |
| experienceYears | int? | 경력 (년) |
| lessonAreas | List<String>? | 레슨 가능 지역 |
| lessonTypes | List<LessonType>? | 대면/비대면/방문 |
| feeRange | FeeRange? | 레슨료 범위 |
| education | List<Education>? | 학력 |
| career | List<Career>? | 경력 상세 |
| specialties | List<String>? | 전문 분야 |
| teachingStyle | String? | 레슨 스타일 설명 |
| portfolioVideos | List<Video>? | 연주 영상 |
| verification | TeacherVerification | 인증 정보 |
| visibilitySettings | ProfileVisibilitySettings | 공개 설정 |

---

## ProfileCompletionLevel (프로필 완성도)

```dart
enum ProfileCompletionLevel {
  minimum,   // 30% - 필수 항목만 (활동 제한)
  basic,     // 60% - 기본 정보 완성 (제한적 활동)
  standard,  // 80% - 대부분 완성 (정상 활동)
  complete,  // 100% - 모든 항목 완성 (프리미엄 노출)
}
```

| 레벨 | 완성도 | 기능 제한 |
|------|:------:|----------|
| minimum | 30% | 학생 초대 불가, 검색 노출 불가, 레슨 생성 불가 |
| basic | 60% | 검색 노출 불가, 학생 수 5명 제한 |
| standard | 80% | 정상 활동 가능 |
| complete | 100% | 검색 상위 노출, 프리미엄 뱃지 |

### 완성도별 필수 항목

| 레벨 | 항목 |
|------|------|
| **minimum (30%)** | name, profileImage, instruments, introduction |
| **basic (60%)** | + experience, lessonAreas, lessonTypes, feeRange |
| **standard (80%)** | + education, certificates, career |
| **complete (100%)** | + portfolioVideos, teachingStyle, specialties |

---

## PhoneVerification (휴대폰 인증)

```dart
class PhoneVerification {
  final String phoneNumber;
  final String verificationCode;
  final DateTime verifiedAt;
  final bool isVerified;
}
```

### 인증 플로우

| 단계 | 설명 |
|:----:|------|
| 1 | 휴대폰 번호 입력 |
| 2 | 인증번호 발송 (6자리) |
| 3 | 인증번호 입력 (3분 유효) |
| 4 | 인증 완료 |

---

## Certificate (자격증)

```dart
class Certificate {
  final String id;
  final CertificateType type;
  final String name;              // 자격증명
  final String issuingBody;       // 발급기관
  final DateTime issueDate;       // 발급일
  final String? certificateNumber; // 자격증 번호
  final String imageUrl;          // 증빙 이미지
  final CertificateStatus status;
  final String? rejectionReason;  // 반려 사유
  final DateTime submittedAt;
  final DateTime? reviewedAt;
}
```

### CertificateStatus (자격증 상태)

```dart
enum CertificateStatus {
  pending,    // 검토 중
  approved,   // 승인됨
  rejected,   // 반려됨
}
```

### CertificateType (자격증 유형)

```dart
enum CertificateType {
  musicTeacher,           // 실용음악강사
  cultureArtsEducator,    // 문화예술교육사
  schoolTeacher,          // 정교사 자격증
  conservatory,           // 음악원 수료
  degree,                 // 음대 학위
  performance,            // 연주 경력 증빙
  other,                  // 기타
}
```

---

## TeacherVerification (선생님 인증)

```dart
class TeacherVerification {
  final bool isPhoneVerified;
  final List<Certificate> certificates;
  final bool hasVerifiedCertificate;  // 1개 이상 승인된 자격증

  // Computed badges
  List<VerificationBadge> get badges {
    final list = <VerificationBadge>[];
    if (isPhoneVerified) list.add(VerificationBadge.phoneVerified);
    if (hasVerifiedCertificate) list.add(VerificationBadge.certified);
    return list;
  }
}
```

### VerificationBadge (인증 뱃지)

```dart
enum VerificationBadge {
  phoneVerified,  // 📱 본인인증
  certified,      // ✓ 자격인증
  premium,        // ⭐ 프리미엄 (프로필 100%)
}
```

| 뱃지 | 아이콘 | 조건 |
|------|:------:|------|
| phoneVerified | 📱 | 휴대폰 인증 완료 |
| certified | ✓ | 자격증 1개 이상 승인 |
| premium | ⭐ | 프로필 100% 완성 |

---

## ProfileVisibilitySettings (공개 범위 설정)

```dart
class ProfileVisibilitySettings {
  final bool isSearchable;            // 검색 노출 여부 (기본: true)
  final ProfileVisibility nameVisibility;
  final ProfileVisibility photoVisibility;
  final ProfileVisibility contactVisibility;
  final ProfileVisibility feeVisibility;
  final ProfileVisibility careerVisibility;
  final ProfileVisibility certificateVisibility;
}
```

### ProfileVisibility (공개 범위)

```dart
enum ProfileVisibility {
  public,      // 모든 사용자에게 공개
  students,    // 연결된 학생에게만 공개
  private,     // 비공개
}
```

### 기본값

| 항목 | 기본 공개 범위 |
|------|:-------------:|
| name | public |
| photo | public |
| contact | students |
| fee | public |
| career | public |
| certificate | public |

---

## Education (학력)

```dart
class Education {
  final String school;
  final String major;
  final String degree;  // 학사, 석사, 박사
  final int? graduationYear;
}
```

---

## Career (경력)

```dart
class Career {
  final String organization;
  final String position;
  final int startYear;
  final int? endYear;  // null = 현재
  final String? description;
}
```

---

## FeeRange (레슨료 범위)

```dart
class FeeRange {
  final int minFee;
  final int maxFee;
  final LessonDuration duration;  // 30분, 45분, 60분
}
```

---

## LessonType (레슨 형태)

```dart
enum LessonType {
  inPerson,   // 대면
  online,     // 비대면
  visit,      // 방문
}
```

---

## Video (포트폴리오 영상)

```dart
class Video {
  final String url;
  final String title;
  final String? thumbnailUrl;
  final Duration duration;
}
```

---

## TeacherSearchFilter (검색 필터)

```dart
class TeacherSearchFilter {
  final List<Instrument>? instruments;  // 악기
  final String? area;                   // 지역
  final LessonType? lessonType;         // 대면/비대면
  final FeeRange? feeRange;             // 레슨료 범위
  final bool? hasVerifiedCertificate;   // 자격인증 여부
}
```

---

## TeacherSearchResult (검색 결과)

```dart
class TeacherSearchResult {
  final String teacherId;
  final String name;
  final String profileImage;
  final List<Instrument> instruments;
  final String? area;
  final FeeRange? feeRange;
  final List<VerificationBadge> badges;
  final double? rating;           // 평균 평점
  final int studentCount;         // 현재 학생 수
  final ProfileCompletionLevel completionLevel;
}
```

---

## TutorialProgress (튜토리얼)

```dart
enum TutorialStep {
  welcome,           // "환영합니다! 레슨앱에서 학생을 관리해보세요"
  inviteStudent,     // "학생을 초대하는 방법"
  createLesson,      // "레슨 일정 등록하기"
  writeFeedback,     // "레슨 노트 작성하기"
  completed,         // "준비 완료!"
}

class TutorialProgress {
  final List<TutorialStep> completedSteps;
  final bool canSkip;  // true (스킵 가능)
}
```

---

## InviteMethod (초대 방식)

```dart
enum InviteMethod {
  qrCode,     // QR 코드 (대면 레슨 시)
  urlLink,    // URL 링크 (메시지/카카오톡)
  inAppSearch, // 앱 내 검색
}
```

---

## TeacherInvite (초대 정보)

```dart
class TeacherInvite {
  final String teacherId;
  final String inviteCode;    // 6자리 코드
  final String inviteUrl;     // deep link
  final String qrCodeData;    // QR 코드 데이터
  final DateTime expiresAt;   // 유효기간 (7일)
}
```

---

## 파일 위치 (예정)

```
lib/features/onboarding/domain/entities/teacher.dart
lib/features/onboarding/domain/entities/phone_verification.dart
lib/features/onboarding/domain/entities/certificate.dart
lib/features/onboarding/domain/entities/teacher_verification.dart
lib/features/profile/domain/entities/profile_visibility_settings.dart
lib/features/search/domain/entities/teacher_search_filter.dart
lib/features/search/domain/entities/teacher_search_result.dart
```

---

## 관련 문서

| 문서 | 설명 |
|------|------|
| [teacher_registration.md](../../specs/user/teacher_registration.md) | 선생님 등록 시스템 스펙 |
| [three_party_relationship_spec.md](../../specs/lesson/three_party_relationship_spec.md) | 학원-선생님-학생 관계 |
| [invite_system_v2.md](../../specs/invite/invite_system_v2.md) | 초대 시스템 |
| [review.md](review.md) | 리뷰 시스템 (TeacherBadge 포함) |
