# Onboarding System Master Spec (v1 — Legacy)

> ⚠️ **v2 재설계됨**: [onboarding_quest_v2.md](onboarding_quest_v2.md) 참조
> 구현 상태: ✅ v1 구현 완료 (Mock 모드) → v2 퀘스트 시스템으로 대체 예정
> Last updated: 2026-05-07 (프로필 사진 선택 정책/악기 선택 시트 회귀 기준 반영)

## 1. 개요

선생님(Teacher) 가입 후 초기 설정을 안내하는 온보딩 시스템. 마치 새 학교 첫 날의 오리엔테이션처럼, 휴대폰 인증 -> 프로필 설정 -> 튜토리얼의 3단계를 거쳐 앱 사용을 시작한다.

## 2. 핵심 기능

### 2.1 온보딩 단계 (OnboardingStep)

| 단계 | 번호 | 설명 |
|------|------|------|
| `roleSelect` | 1 | 역할 선택 (선생님/학생) |
| `phoneVerification` | 2 | 휴대폰 번호 인증 |
| `profileSetup` | 3 | 프로필 정보 입력 |
| `tutorial` | 4 | 앱 사용법 튜토리얼 |
| `completed` | 5 | 온보딩 완료 |

> 현재 UI 구현에서는 Step 1(역할 선택)은 별도 화면 없이 바로 Step 2부터 시작함.

### 2.2 휴대폰 인증 (PhoneVerificationScreen)

**플로우:**
1. 휴대폰 번호 입력 (010-XXXX-XXXX 형식, 자동 포매팅)
2. "인증번호 받기" 버튼 -> SMS 전송 시뮬레이션
3. 6자리 인증번호 입력 (타이머 3분)
4. 인증 성공 시 프로필 설정 화면으로 이동

**세부 동작:**
- 한국 휴대폰 번호 검증: `01[0-9]{8,9}` 패턴
- 인증 코드 유효 시간: 180초 (3분)
- 인증 코드 재발송: 전송 후 60초 경과 시 가능
- 최대 시도 횟수 초과 시 에러 메시지
- 디버그 모드: 아무 6자리 코드로 인증 통과 (테스트용)
- 뒤로가기: 로그인 화면으로 이동
- 휴대폰 번호 변경: 인증번호 입력 화면에서 "번호 변경" 버튼

**타이머 표시:**
- 잔여 시간 30초 초과: primary 색상
- 잔여 시간 30초 이하: error 색상 (빨간색)

### 2.3 프로필 설정 (ProfileSetupScreen)

**필수 입력 항목:**

| 항목 | 검증 조건 |
|------|-----------|
| 이름 | 비어있지 않음 |
| 악기 | 1개 이상 선택 |
| 소개글 | 20자 이상 (최대 500자) |

**선택 입력 항목:**

| 항목 | UX/검증 조건 |
|------|--------------|
| 프로필 사진 | 선택 항목이다. 사진이 없어도 다음 단계로 진행할 수 있어야 한다. |

**프로필 사진 UX 원칙:**
- 사진은 신뢰 형성에 도움이 되는 선택 항목으로 안내한다.
- 문구는 “전문적인 사진을 추가하면 학생과 학부모가 선생님을 더 신뢰하고 기억하기 쉽습니다.” 수준의 권장 톤으로 유지한다.
- 프로필 사진 미등록 상태를 오류나 미완료로 표현하지 않는다.
- 갤러리/카메라 선택 바텀시트는 Notebook × Score 불투명 시트(`NotebookBottomSheet`)로 표시한다.
- 갤러리/카메라 선택, 크롭, 저장 중 사용자가 취소하면 조용히 원래 화면으로 돌아온다.
- 권한/플러그인/파일 처리 오류가 발생하면 “사진을 불러오지 못했습니다. 권한을 확인하거나 다시 시도해주세요.” 안내를 표시한다.

**악기 선택:**
- 바텀시트에서 `InstrumentList.all` 목록 표시
- 복수 선택 가능
- 선택된 악기는 Chip 형태로 표시 (삭제 가능)
- 악기 선택 바텀시트는 route 배경이 투명하더라도 본문이 불투명한 Notebook surface를 반드시 가져야 한다.

**미완료 필드 안내:**
- 폼 하단에 warning 색상 배너로 누락 항목 표시
- 프로필 사진을 제외한 모든 필수 항목 입력 시 "다음" 버튼 활성화

### 2.4 튜토리얼 (TutorialScreen)

**페이지 구성 (PageView):**

| TutorialStep | 아이콘 | 내용 |
|--------------|--------|------|
| `welcome` | waving_hand | 환영 메시지 |
| `inviteStudent` | qr_code | 학생 초대 방법 |
| `createLesson` | calendar_month | 레슨 생성 방법 |
| `writeFeedback` | edit_note | 피드백 작성 방법 |
| `completed` | celebration | 완료 축하 |

**네비게이션:**
- "이전" / "다음" 버튼 (첫 페이지: "다음"만 표시)
- 마지막 페이지: "시작하기" 버튼
- "건너뛰기" 버튼: 모든 페이지에서 사용 가능
- 페이지 인디케이터: 활성 페이지는 넓은 pill 형태 (24px), 비활성은 원형 (8px)

### 2.5 학생 온보딩 (Student Onboarding)

> 구현 상태: ✅ 구현 완료 (v2 — 2026-03-11)

**플로우:**
```
역할 선택 → 초대 코드 입력 (선택) → 프로필 설정 → 튜토리얼 → 학생 홈
```

#### 2.5.1 초대 코드 입력 (StudentInviteCodeScreen)
- 선생님으로부터 받은 6자리 초대 코드 입력
- "코드 없이 시작하기" 버튼으로 독립 사용 가능
- 코드 입력 성공 시 프로필 설정으로 이동
- 코드 없이 시작 시에도 프로필 설정으로 이동

#### 2.5.2 학생 프로필 설정 (StudentProfileSetupScreen)
- **필수 입력**: 이름, 악기 (1개)
- 악기 선택: ChoiceChip 그리드 (바이올린, 비올라, 첼로, 피아노, 플루트, 클라리넷, 기타, 드럼, 성악, 작곡)
- 2단계 진행 표시: [1 프로필] → [2 튜토리얼]
- 모든 필수 항목 입력 시 "다음" 버튼 활성화

#### 2.5.3 학생 튜토리얼 (StudentTutorialScreen)
| 페이지 | 아이콘 | 내용 |
|--------|--------|------|
| 환영 | waving_hand | 환영 메시지 |
| 레슨 확인 | calendar_month | 레슨 일정 확인/관리 안내 |
| 연습 기록 | fitness_center | 연습 기록 안내 |
| 선생님 소통 | people | 피드백 확인 안내 |

**네비게이션:** 선생님 튜토리얼과 동일 패턴 (이전/다음/건너뛰기)

### 2.6 상태 관리 (TeacherOnboardingNotifier)

`@Riverpod(keepAlive: true)` 어노테이션으로 앱 생명주기 동안 유지.

**주요 메서드:**

| 메서드 | 동작 |
|--------|------|
| `goToStep(step)` | 특정 단계로 이동 |
| `startPhoneVerification(phone)` | 인증 코드 생성 및 전송 시작 |
| `resendVerificationCode()` | 인증 코드 재발송 |
| `verifyCode(code)` | 인증 코드 검증 |
| `updateProfile(profile)` | 프로필 데이터 업데이트 |
| `submitProfile()` | 프로필 유효성 검증 후 튜토리얼로 이동 |
| `completeTutorialStep(step)` | 튜토리얼 단계 완료 표시 |
| `skipTutorial()` | 튜토리얼 건너뛰기 |
| `completeOnboarding()` | 온보딩 완료 처리 |

### 2.7 프로필 생성 (CurrentTeacherProfileNotifier)

온보딩 완료 시 `TeacherProfile` 엔티티 생성:
- 온보딩 데이터(이름, 사진, 악기, 소개)를 프로필로 변환
- 휴대폰 인증 정보를 `TeacherVerification`에 포함
- `MockTeacherProfileRepository`를 통해 저장

### 2.8 Teacher Profile Repository

- `EnvironmentConfig.useMockData` 기반으로 Mock/Remote 전환
- 현재 Remote API 미구현 -> mock 전용 (empty 옵션 지원)

## 3. 화면/UI 구조

### 진행 표시기 (Progress Indicator)

각 화면 상단에 3단계 진행 표시:
```
[1 휴대폰 인증] ---- [2 프로필 설정] ---- [3 튜토리얼]
```
- 현재 단계: primary 색상 원형 + 번호
- 완료 단계: primary 색상 원형 + 체크 아이콘
- 미진행 단계: border 색상 원형 + 번호

### 화면 흐름

```
로그인 -> PhoneVerificationScreen -> ProfileSetupScreen -> TutorialScreen -> 홈 화면
                                                                      ↑
                                                              (건너뛰기 가능)
```

### 라우트

| 화면 | 라우트 |
|------|--------|
| 휴대폰 인증 | `AppRoutes.teacherPhoneVerification` |
| 프로필 설정 | `AppRoutes.teacherProfileSetup` |
| 튜토리얼 | `AppRoutes.teacherTutorial` |
| 학생 프로필 설정 | `AppRoutes.studentProfileSetup` (`/student/onboarding/profile-setup`) |
| 학생 튜토리얼 | `AppRoutes.studentTutorial` (`/student/onboarding/tutorial`) |

## 4. Enum 정의 (Dart)

> 모든 enum은 `features/profile/domain/entities/teacher_onboarding.dart`에 정의.

```dart
enum OnboardingStep {
  roleSelect,         // 역할 선택
  phoneVerification,  // 휴대폰 인증
  profileSetup,       // 프로필 설정
  tutorial,           // 튜토리얼
  completed;          // 완료
}

enum TutorialStep {
  welcome,        // "Welcome to Lessonaza!"
  inviteStudent,  // 학생 초대 방법
  createLesson,   // 레슨 생성 방법
  writeFeedback,  // 피드백 작성 방법
  completed;      // 완료 축하
}
```

---

## 5. 데이터 모델

### TeacherOnboardingState

| 필드 | 타입 | 설명 |
|------|------|------|
| `userId` | `String?` | 현재 사용자 ID |
| `currentStep` | `OnboardingStep` | 현재 단계 |
| `phoneVerification` | `PhoneVerification?` | 인증 상태 |
| `profile` | `TeacherOnboardingProfile?` | 프로필 데이터 |
| `tutorialProgress` | `TutorialProgress` | 튜토리얼 진행도 |
| `startedAt` | `DateTime` | 온보딩 시작 시간 |
| `completedAt` | `DateTime?` | 온보딩 완료 시간 |

### PhoneVerification

| 필드 | 타입 | 설명 |
|------|------|------|
| `phoneNumber` | `String` | 휴대폰 번호 |
| `verificationCode` | `String` | 인증 코드 (mock: "123456") |
| `codeSentAt` | `DateTime` | 코드 전송 시간 |
| `isVerified` | `bool` | 인증 완료 여부 |
| `verifiedAt` | `DateTime?` | 인증 완료 시간 |
| `attemptCount` | `int` | 시도 횟수 |

### TeacherOnboardingProfile

| 필드 | 타입 | 설명 |
|------|------|------|
| `name` | `String` | 선생님 이름 |
| `profileImage` | `String?` | 프로필 이미지 URL |
| `instruments` | `List<String>` | 가르치는 악기 목록 |
| `introduction` | `String` | 자기소개 |

### 주요 Providers

| Provider | 타입 | 설명 |
|----------|------|------|
| `teacherOnboardingNotifierProvider` | `Notifier<TeacherOnboardingState>` | 온보딩 상태 관리 (keepAlive) |
| `currentTeacherProfileProvider` | `Future<TeacherProfile?>` | 현재 프로필 조회 |
| `teacherNeedsOnboardingProvider` | `Future<bool>` | 온보딩 필요 여부 |
| `teacherOnboardingCompletedProvider` | `StateProvider<bool>` | 런타임 온보딩 완료 플래그 (레거시/호환) |
| `onboardingProgressStorageProvider` | `AsyncNotifier<OnboardingProgressStorageState>` | Hive 기반 사용자별 온보딩 완료/데모 오버레이 dismiss 저장 |
| `teacherProfileRepositoryProvider` | `Provider<TeacherProfileRepository>` | Repository 제공 |
| `phoneNumberProvider` | `StateProvider<String>` | 전화번호 입력 상태 |
| `verificationCodeProvider` | `StateProvider<String>` | 인증코드 입력 상태 |
| `isPhoneNumberValidProvider` | `Provider<bool>` | 전화번호 유효성 |
| `isVerificationCodeValidProvider` | `Provider<bool>` | 인증코드 유효성 |
| `isProfileFormValidProvider` | `Provider<bool>` | 프로필 폼 유효성 |
| `profileMissingFieldsProvider` | `Provider<List<String>>` | 누락 필드 목록 |

### 로컬 진행 상태 저장

온보딩 완료 여부와 홈 데모 대시보드 오버레이 dismiss 여부는 앱 재시작 후에도 유지되어야 하므로 Hive 기반 storage provider가 관리한다.

| 항목 | 값 |
|------|-----|
| Provider | `onboardingProgressStorageProvider` |
| State | `OnboardingProgressStorageState` |
| Hive box | `onboarding_progress` |
| 완료 key | `teacher:<userId>:completed` |
| 오버레이 dismiss key | `teacher:<userId>:demoOverlayDismissed` |

규칙:
- user id scoped key를 사용해 같은 기기의 다른 선생님 계정 상태가 섞이지 않게 한다.
- 이 provider는 `features/onboarding/onboarding_facade.dart`에서 public API로 export한다.
- 다른 feature는 `onboarding/presentation/providers/...`를 직접 import하지 않고 facade만 import한다.
- domain entity에 Hive annotation을 추가하지 않는다.
- 완료 처리 시 런타임 플래그와 storage provider를 함께 갱신한다.

### 홈 데모 대시보드 오버레이

튜토리얼을 완료하거나 건너뛰어 홈으로 진입한 선생님에게 Notebook x Score 스타일의 데모 안내를 1회 표시한다.

| 조건 | 동작 |
|------|------|
| `teacherOnboardingCompleted == false` | 표시하지 않음 |
| `demoOverlayDismissed == false` | `DemoDashboardOverlay` 표시 |
| 확인 버튼 클릭 | `dismissDemoOverlay()` 호출 후 숨김 |
| 앱 재시작 | Hive 저장 상태를 기준으로 유지 |

UI 문구는 `AppStrings`에 모으고, 홈 feature는 onboarding facade를 통해 storage provider를 읽는다.

## 6. 구현 파일 위치

> `features/onboarding/` 기준 상대 경로. 새 파일 추가 시 이 표를 업데이트한다.

| 레이어 | 파일 경로 | 설명 |
|--------|----------|------|
| **Entity (Enum)** | `profile/domain/entities/teacher_onboarding.dart` | OnboardingStep, TutorialStep, TeacherOnboardingState, PhoneVerification 등 |
| **Entity (Extension)** | `onboarding/domain/entities/onboarding_step.dart` | OnboardingStep UI 헬퍼 (label, stepNumber, progress) |
| **Provider** | `onboarding/presentation/providers/onboarding_providers.dart` | TeacherOnboardingNotifier 등 모든 온보딩 Provider |
| **Provider** | `onboarding/presentation/providers/teacher_profile_repository_provider.dart` | TeacherProfileRepository Provider |
| **Provider** | `onboarding/presentation/providers/onboarding_progress_storage_provider.dart` | Hive 기반 온보딩 완료/데모 오버레이 저장 Provider |
| **Facade** | `onboarding/onboarding_facade.dart` | 온보딩 public provider boundary |
| **Widget** | `home/presentation/widgets/demo_dashboard_overlay.dart` | 온보딩 완료 후 홈 최초 진입 데모 오버레이 |
| **Screen** | `onboarding/presentation/screens/phone_verification_screen.dart` | 휴대폰 인증 화면 |
| **Screen** | `onboarding/presentation/screens/profile_setup_screen.dart` | 프로필 설정 화면 |
| **Screen** | `onboarding/presentation/screens/tutorial_screen.dart` | 튜토리얼 화면 |
| **Screen** | `onboarding/presentation/screens/student_profile_setup_screen.dart` | 학생 프로필 설정 화면 |
| **Screen** | `onboarding/presentation/screens/student_tutorial_screen.dart` | 학생 튜토리얼 화면 |
| **Repository** | `repositories/teacher_profile_repository.dart` | TeacherProfileRepository 인터페이스 + Mock (레거시 위치) |
| **Route** | `core/router/routes/auth_routes.dart` | 온보딩 라우트 정의 |

---

## 7. 구현 현황

| 기능 | 상태 |
|------|------|
| 온보딩 상태 관리 (Riverpod) | 구현 완료 |
| 휴대폰 인증 화면 | 구현 완료 |
| 인증번호 입력 및 검증 | 구현 완료 |
| 프로필 설정 화면 | 구현 완료 |
| 악기 선택 바텀시트 | 구현 완료 |
| 프로필 이미지 선택 | Mock 구현 (고정 URL) |
| 튜토리얼 PageView | 구현 완료 |
| 튜토리얼 건너뛰기 | 구현 완료 |
| 진행 표시기 | 구현 완료 |
| 온보딩 완료 후 홈 이동 | 구현 완료 |
| 온보딩 완료 상태 Hive 저장 | 구현 완료 |
| 홈 데모 대시보드 오버레이 1회 표시 | 구현 완료 |
| 프로필 생성 및 저장 | 구현 완료 (Mock Repository) |
| 온보딩 필요 여부 판단 | 구현 완료 |
| 실제 SMS 연동 | 미구현 (mock) |
| 실제 이미지 업로드 | 미구현 (mock) |
| Remote API Repository | 미구현 |
| 학생 온보딩 (프로필 설정 + 튜토리얼) | 구현 완료 |

## 8. 관련 스펙

| 스펙 | 관계 |
|------|------|
| [선생님 등록 스펙](../../specs/user/teacher_registration.md) | 선생님 가입 전체 플로우 |
| [UX 가이드라인](../design/ux_guidelines.md) | UI/UX 규칙 |

---

## 9. 변경 이력

| 날짜 | 내용 |
|------|------|
| 2026-03-06 | 기존 구현 기반 스펙 문서 생성 (역공학) |
| 2026-03-07 | Dart enum 코드 블록 추가, 구현 파일 위치 섹션 추가, 관련 스펙 링크 보강 |
| 2026-03-11 | 학생 온보딩 섹션 추가 (프로필 설정, 튜토리얼 화면) |
| 2026-05-07 | 온보딩 로컬 storage provider와 홈 데모 대시보드 오버레이 반영 |
