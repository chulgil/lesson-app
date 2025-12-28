# 외부 선생님 등록 시스템 스펙

> 작성일: 2025-12-27
> 상태: 스펙 확정

---

## 개요

외부 선생님이 앱에 가입하여 학생을 관리할 수 있는 온보딩 시스템

### 핵심 결정사항

| 항목 | 결정 |
|------|------|
| 가입 방식 | 공개 가입 + 프로필 심사 |
| 프로필 정보 | 단계별 (최소 → 기본 → 상세) |
| 자격증 검증 | 선택적 인증 (뱃지 부여) |
| 온보딩 | 프로필 완성 유도 + 튜토리얼 |
| 학생 연결 | 초대 + 검색 모두 지원 |
| 공개 프로필 | 선생님이 공개 범위 설정 |
| 수수료 | Phase 1 무료 (추후 결정) |
| 신원 확인 | 휴대폰 인증 |

---

## 1. 가입 플로우

### 1.1 전체 흐름

```
소셜 로그인 → 역할 선택 → 휴대폰 인증 → 필수 프로필 → 튜토리얼 → 대시보드
     ↓              ↓            ↓              ↓
  Google/Kakao   "선생님"     본인 확인      최소 정보
```

### 1.2 단계별 상세

#### Step 1: 소셜 로그인
```dart
// Existing auth flow
enum AuthProvider { google, kakao }
```

#### Step 2: 역할 선택
```dart
enum UserRole { teacher, student }

// First login only
class RoleSelectionScreen {
  // "선생님으로 시작하기" / "학생으로 시작하기"
}
```

#### Step 3: 휴대폰 인증
```dart
class PhoneVerification {
  final String phoneNumber;
  final String verificationCode;
  final DateTime verifiedAt;
  final bool isVerified;
}

// SMS 인증 플로우
// 1. 휴대폰 번호 입력
// 2. 인증번호 발송 (6자리)
// 3. 인증번호 입력 (3분 유효)
// 4. 인증 완료
```

#### Step 4: 필수 프로필 입력
```dart
class TeacherOnboardingStep {
  final String name;           // 이름 (필수)
  final String? profileImage;  // 프로필 사진 (필수)
  final List<Instrument> instruments;  // 악기 (필수, 최소 1개)
  final String introduction;   // 소개글 (필수, 최소 20자)
}
```

#### Step 5: 튜토리얼
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

## 2. 프로필 시스템

### 2.1 프로필 완성도

```dart
enum ProfileCompletionLevel {
  minimum,   // 30% - 필수 항목만 (활동 제한)
  basic,     // 60% - 기본 정보 완성 (제한적 활동)
  standard,  // 80% - 대부분 완성 (정상 활동)
  complete,  // 100% - 모든 항목 완성 (프리미엄 노출)
}
```

### 2.2 프로필 항목

#### 필수 (Minimum) - 30%
| 항목 | 타입 | 설명 |
|------|------|------|
| name | String | 이름 |
| profileImage | String | 프로필 사진 |
| instruments | List<Instrument> | 가르치는 악기 (최소 1개) |
| introduction | String | 소개글 (최소 20자) |

#### 기본 (Basic) - 60%
| 항목 | 타입 | 설명 |
|------|------|------|
| experience | int | 경력 (년) |
| lessonAreas | List<String> | 레슨 가능 지역 |
| lessonTypes | List<LessonType> | 대면/비대면/방문 |
| feeRange | FeeRange | 레슨료 범위 |

#### 상세 (Standard) - 80%
| 항목 | 타입 | 설명 |
|------|------|------|
| education | List<Education> | 학력 |
| certificates | List<Certificate> | 자격증 |
| career | List<Career> | 경력 상세 |

#### 완성 (Complete) - 100%
| 항목 | 타입 | 설명 |
|------|------|------|
| portfolioVideos | List<Video> | 연주 영상 |
| teachingStyle | String | 레슨 스타일 설명 |
| specialties | List<String> | 전문 분야 |

### 2.3 완성도별 기능 제한

```dart
class ProfileRestrictions {
  // Minimum (30%) - 필수만 완성
  static const minimumRestrictions = {
    'canInviteStudents': false,
    'canBeSearched': false,
    'canCreateLessons': false,
    'dashboardAccess': true,  // 대시보드는 접근 가능
  };

  // Basic (60%) - 기본 완성
  static const basicRestrictions = {
    'canInviteStudents': true,
    'canBeSearched': false,   // 검색 노출 불가
    'canCreateLessons': true,
    'maxStudents': 5,         // 학생 수 제한
  };

  // Standard (80%) - 정상 활동
  static const standardRestrictions = {
    'canInviteStudents': true,
    'canBeSearched': true,
    'canCreateLessons': true,
    'maxStudents': null,      // 무제한
  };

  // Complete (100%) - 프리미엄
  static const completeRestrictions = {
    'canInviteStudents': true,
    'canBeSearched': true,
    'canCreateLessons': true,
    'searchPriority': 'high', // 검색 상위 노출
    'premiumBadge': true,     // 프리미엄 뱃지
  };
}
```

---

## 3. 자격증 인증 시스템

### 3.1 인증 플로우

```
자격증 업로드 → 운영팀 검토 → 승인/반려 → 뱃지 부여
     ↓              ↓            ↓
  사진/PDF       1-3일 소요    "인증됨" 표시
```

### 3.2 모델

```dart
enum CertificateStatus {
  pending,    // 검토 중
  approved,   // 승인됨
  rejected,   // 반려됨
}

enum CertificateType {
  musicTeacher,           // 실용음악강사
  cultureArtsEducator,    // 문화예술교육사
  schoolTeacher,          // 정교사 자격증
  conservatory,           // 음악원 수료
  degree,                 // 음대 학위
  performance,            // 연주 경력 증빙
  other,                  // 기타
}

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

enum VerificationBadge {
  phoneVerified,  // 📱 본인인증
  certified,      // ✓ 자격인증
  premium,        // ⭐ 프리미엄 (프로필 100%)
}
```

### 3.3 뱃지 표시

```dart
// Profile UI에서 뱃지 표시
class TeacherBadges extends StatelessWidget {
  final TeacherVerification verification;

  // 📱 본인인증 | ✓ 자격인증 | ⭐ 프리미엄
}
```

---

## 4. 학생 연결 시스템

### 4.1 초대 방식 (기존 requirement.md 기반)

```dart
enum InviteMethod {
  qrCode,     // QR 코드 (대면 레슨 시)
  urlLink,    // URL 링크 (메시지/카카오톡)
  inAppSearch, // 앱 내 검색
}

class TeacherInvite {
  final String teacherId;
  final String inviteCode;    // 6자리 코드
  final String inviteUrl;     // deep link
  final String qrCodeData;    // QR 코드 데이터
  final DateTime expiresAt;   // 유효기간 (7일)
}
```

### 4.2 검색 시스템

```dart
class TeacherSearchFilter {
  final List<Instrument>? instruments;  // 악기
  final String? area;                   // 지역
  final LessonType? lessonType;         // 대면/비대면
  final FeeRange? feeRange;             // 레슨료 범위
  final bool? hasVerifiedCertificate;   // 자격인증 여부
}

class TeacherSearchResult {
  final String teacherId;
  final String name;
  final String profileImage;
  final List<Instrument> instruments;
  final String? area;
  final FeeRange? feeRange;
  final List<VerificationBadge> badges;
  final double? rating;           // 평균 평점 (추후)
  final int studentCount;         // 현재 학생 수
  final ProfileCompletionLevel completionLevel;
}

// Search ranking factors
class SearchRanking {
  // 1. 프로필 완성도 (complete > standard)
  // 2. 자격인증 여부
  // 3. 학생 수 / 리뷰 수 (추후)
  // 4. 최근 활동일
}
```

---

## 5. 공개 프로필 설정

### 5.1 공개 범위 설정

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

enum ProfileVisibility {
  public,      // 모든 사용자에게 공개
  students,    // 연결된 학생에게만 공개
  private,     // 비공개
}
```

### 5.2 기본값

```dart
class DefaultVisibilitySettings {
  static const defaults = ProfileVisibilitySettings(
    isSearchable: true,
    nameVisibility: ProfileVisibility.public,
    photoVisibility: ProfileVisibility.public,
    contactVisibility: ProfileVisibility.students,  // 연결 후 공개
    feeVisibility: ProfileVisibility.public,
    careerVisibility: ProfileVisibility.public,
    certificateVisibility: ProfileVisibility.public,
  );
}
```

### 5.3 공개 프로필 화면

```dart
class PublicTeacherProfile {
  // 검색 결과에서 보이는 프로필
  final String name;
  final String? profileImage;  // visibility에 따라
  final List<Instrument> instruments;
  final String introduction;
  final String? area;
  final FeeRange? feeRange;    // visibility에 따라
  final List<VerificationBadge> badges;
  final int experienceYears;

  // Actions
  // - "연결 요청" 버튼
  // - "프로필 더보기" (연결 후)
}
```

---

## 6. 온보딩 UI 플로우

### 6.1 화면 구성

```
1. WelcomeScreen
   └── "레슨앱에 오신 것을 환영합니다"
   └── [선생님으로 시작] [학생으로 시작]

2. PhoneVerificationScreen
   └── 휴대폰 번호 입력
   └── 인증번호 입력

3. ProfileSetupScreen (Step-by-step)
   └── Step 1: 이름, 사진
   └── Step 2: 악기 선택
   └── Step 3: 소개글 작성
   └── [나중에 완성하기] 옵션

4. TutorialScreen (스킵 가능)
   └── 학생 초대 방법
   └── 레슨 등록 방법
   └── 피드백 작성 방법

5. DashboardScreen
   └── 프로필 완성도 카드 (incomplete일 경우)
   └── "프로필 완성하고 학생 초대하기" CTA
```

### 6.2 프로필 완성 유도

```dart
class ProfileCompletionCard extends StatelessWidget {
  final ProfileCompletionLevel level;
  final int percentage;
  final List<String> nextSteps;  // "경력을 추가하세요", "자격증을 인증하세요"

  // Progress bar + 다음 단계 안내
}
```

---

## 7. 데이터 모델 요약

### Teacher (확장)

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

### Supporting Models

```dart
class Education {
  final String school;
  final String major;
  final String degree;  // 학사, 석사, 박사
  final int? graduationYear;
}

class Career {
  final String organization;
  final String position;
  final int startYear;
  final int? endYear;  // null = 현재
  final String? description;
}

class FeeRange {
  final int minFee;
  final int maxFee;
  final LessonDuration duration;  // 30분, 45분, 60분
}

enum LessonType {
  inPerson,   // 대면
  online,     // 비대면
  visit,      // 방문
}

class Video {
  final String url;
  final String title;
  final String? thumbnailUrl;
  final Duration duration;
}
```

---

## 8. 구현 우선순위

### Phase 1 (MVP)
1. 소셜 로그인 + 역할 선택
2. 휴대폰 인증
3. 필수 프로필 (이름, 사진, 악기, 소개)
4. 튜토리얼 (스킵 가능)
5. 프로필 완성도 표시

### Phase 2
1. 확장 프로필 (경력, 학력, 레슨료)
2. 자격증 인증 시스템
3. 공개 프로필 설정
4. 선생님 검색

### Phase 3
1. 검색 랭킹 알고리즘
2. 리뷰/평점 시스템
3. 프리미엄 기능 (수수료 모델)

---

## 9. 관련 문서

| 문서 | 설명 |
|------|------|
| [requirement.md](../requirement.md) | 양방향 초대 모델, 초대 방식 |
| [trial_lesson_system.md](trial_lesson_system.md) | 체험 레슨 예약 |
| [payment_flow.md](payment_flow.md) | 결제 플로우 |
| [notification_system.md](notification_system.md) | 알림 시스템 |
