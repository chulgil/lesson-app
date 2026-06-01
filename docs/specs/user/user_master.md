# User System Master Spec

> 구현 상태: ⚠️ 부분 구현 — 멀티 소속 전환, 학부모 서브롤 미구현
> Last updated: 2026-03-07
> 통합 대상: parent_system, parent_dashboard_spec, parent_login_flow, teacher_registration, student_class_system, invite_system_v2, subscription_based_relationship, review_system, trial_lesson_system, google_sso_setup_guide

---

## 1. 개요

### 1.1 시스템 목적

Lessonaza는 음악 레슨 관리 앱으로, 선생님-학생-학부모 3자 간의 레슨/연습/과제/수강권 입금 상태를 통합 관리한다.

### 1.2 경쟁사 대비 차별점

| 특성 | Lessonaza | Tonara | Lessonpal | Simply Music |
|------|:---------:|:------:|:---------:|:------------:|
| 선생님-학생-학부모 3역할 통합 | O (단일 앱) | 분리 (Teacher/Student 앱) | 선생님만 | X |
| 학부모 대시보드 | O | 분리 앱 | X | X |
| 수강권 기반 관계 자동 전환 | O | X | X | X |
| 다중 선생님/학원 동시 소속 | O | X | X | X |
| 체험 레슨 예약 시스템 | O | X | O | X |
| 자녀 프로필 (14세 미만 법적 대응) | O | X | X | X |
| 프로필 전환 (학부모/학생/자녀) | O | X | X | X |
| QR 제로탭 초대 | O | X | X | X |

**핵심 차별점**: 선생님, 학생, 학부모 3자가 **하나의 앱**에서 각자의 역할로 활동. 경쟁사 Tonara는 Teacher 앱/Student 앱 분리, Lessonpal은 선생님 전용. 만 14세 미만 자녀의 개인정보보호법 대응(자녀 프로필 방식)과 학부모-학생 프로필 전환은 업계 유일.

### 1.3 역할 (3 Roles)

| 역할 | 설명 | 계정 유형 |
|------|------|----------|
| **선생님 (Teacher)** | 레슨 제공, 학생 관리, 과제 배정, 수강권 입금 상태 관리 | 소셜 로그인 계정 |
| **학생 (Student)** | 레슨 수강, 연습 기록, 과제 수행 | 소셜 로그인 계정 (만 14세 이상) 또는 자녀 프로필 (만 14세 미만) |
| **학부모 (Parent)** | 자녀 레슨 모니터링, 수강권 입금 상태 확인, 과제 확인 | 소셜 로그인 계정 |

#### UserRole Enum (정식 정의)

> 소스: `features/auth/domain/entities/user_role.dart`

```dart
enum UserRole {
  teacher,   // 선생님
  student,   // 학생
  parent;    // 학부모

  String get label;      // 선생님/학생/학부모
  String get emoji;      // 역할별 이모지
  String get homeRoute;  // /home, /student-home, /parent-home
}
```

### 1.4 다중 소속 모델 (Multi-Affiliation)

- 선생님: 여러 학원 + 개인레슨 동시 관리 가능
- 학생: 여러 선생님에게 동시 레슨 가능 (악기별)
- 학부모: N명의 자녀 관리, 이중 역할(학부모+학생) 가능

### 1.5 활동 컨텍스트

| 컨텍스트 | 설명 | organizationId |
|----------|------|----------------|
| **개인 레슨** | 선생님-학생 직접 연결 | `null` |
| **학원 레슨** | 학원 소속 선생님이 관리 | 학원 ID |
| **겸업** | 개인 + 학원 소속 동시 | Context에 따라 다름 |

---

## 2. 인증 & 가입

### 2.1 소셜 로그인 (Google / Kakao / Apple SSO)

#### 인증 플로우

```
Flutter 앱 (google_sign_in SDK)
  -> Google 로그인 팝업 -> 사용자 인증
    -> serverAuthCode 획득
      -> 백엔드 POST /auth/oauth/google 에 code 전달
        -> 백엔드가 Google 토큰 엔드포인트에서 code -> access_token 교환
          -> Google userinfo API로 사용자 정보 조회
            -> JWT 토큰 발급 -> 앱에 반환
```

#### OAuth 클라이언트 ID 구조

| # | 유형 | 용도 |
|---|------|------|
| 1 | 웹 애플리케이션 | 백엔드 code 교환 + Flutter serverClientId |
| 2 | iOS | iOS 앱 Google 로그인 |
| 3 | Android (debug/release) | Android 앱 Google 로그인 |

- 베타/운영은 동일한 Google Cloud Console 프로젝트, 동일 클라이언트 ID 사용
- 서버 URL만 `--dart-define=API_BASE_URL=...`로 변경
- OAuth 기능은 완전 무료 (결제 계정 불필요)

#### 구현 상태

| 항목 | 상태 |
|------|:----:|
| Google SSO | ✅ 구현 완료 |
| Kakao SSO | ⚠️ Flutter SDK 미연결 — 준비 중 안내 |
| Apple SSO | ⚠️ Flutter SDK 미연결 — 준비 중 안내 |
| 소셜 로그인 미설정 시 크래시 방지 | ✅ 구현 완료 |

#### 관련 파일

```
features/auth/
├── domain/entities/auth_user.dart       -- AuthUser 엔티티
├── domain/entities/user_role.dart       -- UserRole enum
├── domain/repositories/auth_repository.dart
├── data/repositories/remote_auth_repository.dart
├── presentation/providers/auth_provider.dart
├── presentation/providers/user_role_provider.dart
└── presentation/screens/login_screen.dart
```

### 2.2 선생님 가입 & 온보딩

> **흐름 변경 (2026-06-01 — E2E 감사 #10 A-C2)**: 휴대폰 인증을 SSO 직후에서 분리. 첫 수강권 발급 직전(E3) 게이트로 이동. 상세: [phone_verification_policy.md](phone_verification_policy.md)
> **첫 가용시간 설정 추가 (#1 AB-C1)**: 온보딩 Phase B 필수 퀘스트 1번. 상세: [teacher_first_availability_setup.md](../onboarding/teacher_first_availability_setup.md)

#### 가입 플로우 (신규 — 2026-06-01)

```
소셜 로그인 + 약관 1탭 동의 -> 역할 선택("선생님") -> 이름·악기 1개 -> 홈
                                                                          ↓
                                                          첫 가용시간 설정 (블로커 퀘스트)
                                                                          ↓
                                                          학생 초대 → 수강권 제안
                                                                          ↓
                                                          첫 수강권 발급 직전: 휴대폰 인증 게이트
```

#### Step 1: SSO + 약관 동의 (1탭)

- 소셜 로그인 (Google/Kakao/Apple)
- 약관 동의 1탭 (별도 화면 X)

#### Step 2: 역할 선택

- "선생님으로 시작하기" / "학생으로 시작하기"
- 최초 로그인 시에만 표시

#### Step 3: 이름·악기 (30초)

- 이름 + 가르치는 악기 1개 선택
- 소개글·전화인증·프로필 사진은 Phase C 보상 퀘스트로 이동

#### Step 4 (~수강권 발급 전): 휴대폰 인증 게이트

| 시점 | 설명 |
|:----:|------|
| 첫 수강권 발급 시도 | 인증 미완료면 인증 화면 강제 진입 |
| 인증 방법 | 휴대폰 번호 + 6자리 인증번호 (3분 유효) |
| 인증 완료 | 인증 선생님 배지 부여 + 수강권 발급 진행 |

> 가입~D 단계는 인증 없이 자유 진행. 학부모 신뢰가 필요한 결제 단계에서만 인증 필수.

#### Step 3: 필수 프로필 입력

| 항목 | 필수 | 설명 |
|------|:----:|------|
| name | O | 이름 |
| profileImage | ✗ | 프로필 사진 (선택, 나중에 추가) |
| instruments | O | 가르치는 악기 (최소 1개) |
| introduction | O | 소개글 (최소 20자) |

#### Step 4: 튜토리얼 (스킵 가능)

| 단계 | 내용 |
|------|------|
| welcome | "환영합니다! 레슨앱에서 학생을 관리해보세요" |
| inviteStudent | "학생을 초대하는 방법" |
| createLesson | "레슨 일정 등록하기" |
| writeFeedback | "레슨 노트 작성하기" |
| completed | "준비 완료!" |

#### 프로필 완성도 시스템

| 레벨 | 완성도 | 기능 제한 |
|------|:------:|----------|
| minimum | 30% | 학생 초대 불가, 검색 노출 불가, 레슨 생성 불가 |
| basic | 60% | 검색 노출 불가, 학생 수 5명 제한 |
| standard | 80% | 정상 활동 가능 |
| complete | 100% | 검색 상위 노출, 프리미엄 뱃지 |

#### 프로필 항목별 완성도

| 구분 | 항목 |
|------|------|
| Minimum (30%) | 이름, 악기, 소개글 |
| Basic (60%) | + 경력, 레슨 가능 지역, 레슨 유형(대면/비대면), 레슨료 범위 |
| Standard (80%) | + 학력, 자격증, 경력 상세 |
| Complete (100%) | + 연주 영상, 레슨 스타일, 전문 분야 |

#### 완성도별 기능 제한

| 기능 | minimum | basic | standard | complete |
|------|:-------:|:-----:|:--------:|:--------:|
| 학생 초대 | X | O | O | O |
| 검색 노출 | X | X | O | O (상위) |
| 레슨 생성 | X | O | O | O |
| 대시보드 | O | O | O | O |
| 최대 학생 수 | - | 5명 | 무제한 | 무제한 |
| 프리미엄 뱃지 | - | - | - | O |

#### 자격증 인증 시스템

```
자격증 업로드 -> 운영팀 검토 (1-3일) -> 승인/반려 -> 뱃지 부여
```

| 상태 | 설명 |
|------|------|
| pending | 검토 중 |
| approved | 승인됨 |
| rejected | 반려됨 |

자격증 유형: musicTeacher, cultureArtsEducator, schoolTeacher, conservatory, degree, performance, other

#### 뱃지 시스템

| 뱃지 | 아이콘 | 조건 |
|------|:------:|------|
| phoneVerified | (phone) | 휴대폰 인증 완료 |
| certified | (check) | 자격증 1개 이상 승인 |
| premium | (star) | 프로필 100% 완성 |

#### 학원 소속 등록

| 방법 | 설명 |
|------|------|
| 학원 초대 수락 | 학원 관리자가 초대 -> 선생님이 수락 |
| 가입 요청 | 선생님이 학원 검색 -> 가입 요청 -> 학원 승인 |

소속 후 변화: Context Switcher로 개인/학원 전환, 학원 학생 데이터는 학원 소유

#### 구현 상태

| 항목 | 상태 |
|------|:----:|
| 소셜 로그인 + 역할 선택 | ✅ 구현 완료 |
| 휴대폰 인증 | ❌ 미구현 |
| 필수 프로필 입력 | ✅ 부분 구현 |
| 튜토리얼 | ❌ 미구현 |
| 프로필 완성도 표시 | ❌ 미구현 |
| 자격증 인증 | ❌ 미구현 |
| 학원 소속 등록 | ❌ 미구현 |

#### 관련 파일

```
features/auth/presentation/screens/role_select_screen.dart
features/profile/domain/entities/teacher.dart
features/profile/domain/entities/teacher_profile.dart
features/profile/domain/entities/teacher_onboarding.dart
features/profile/presentation/screens/extended_profile_screen.dart
features/profile/presentation/screens/certificate_edit_screen.dart
features/profile/presentation/screens/education_edit_screen.dart
features/profile/presentation/screens/career_edit_screen.dart
```

### 2.3 학생 가입

#### 가입 플로우

```
소셜 로그인 -> 역할 선택("학생") -> 학생 홈
```

#### 연령별 계정 구조

| 연령 구분 | 계정 구조 | 학부모 연결 |
|----------|----------|------------|
| **만 14세 미만** | 회원가입 X (자녀 프로필) | 필수 (부모 계정에 포함) |
| **만 14세 이상** | 학생 계정 가입 가능 | 선택적 연동 |
| **성인 (18+)** | 학생 계정 단독 | 선택적 |

**법적 근거**: 개인정보보호법 제22조의2 - 만 14세 미만 아동의 개인정보 수집 시 법정대리인 동의 필수. 자녀 프로필 방식은 회원가입 없이 최소 정보만 저장하여 이 요건을 우회.

#### 구현 상태

| 항목 | 상태 |
|------|:----:|
| 학생 역할 선택 | ✅ 구현 완료 |
| 학생 초대 코드 입력 | ✅ 구현 완료 |

#### 관련 파일

```
features/auth/presentation/screens/student_invite_code_screen.dart
```

### 2.4 학부모 가입 & 로그인 플로우

#### 결정사항

| 항목 | 결정 |
|------|------|
| 역할 선택 위치 | 로그인 화면에 "학부모이신가요?" 텍스트 링크 |
| 신규 학부모 온보딩 | 즉시 초대 코드 입력 화면 |
| 초대 코드 없는 경우 | 로그인 허용, 빈 홈 화면 표시 |
| 다중 역할 지원 | 인앱 역할 전환기 제공 |

#### 플로우

```
[로그인 화면]
     |
     |--- [소셜 로그인 버튼들]
     |         |
     |         +--- 로그인 성공 ---> [역할 선택 다이얼로그]
     |                                    |
     |                                    |--- 선생님 선택 -> /home
     |                                    +--- 학생 선택 -> /student-home
     |
     +--- "학부모이신가요?" 텍스트 링크
               |
               +--- 탭 ---> [소셜 로그인] ---> [초대 코드 입력 화면]
                                                      |
                                                      |--- 코드 입력 -> 자녀 연결 -> /parent-home
                                                      +--- "코드가 없어도 괜찮아요" -> /parent-home (빈 화면)
```

#### 초대 코드 입력 화면 (ParentInviteCodeScreen)

- 초대 코드 입력 필드
- [코드 확인하기] Primary 버튼
- "코드가 없어도 괜찮아요" 텍스트 링크 (나중에 프로필에서 자녀 등록 가능)

#### 빈 학부모 홈 화면

초대 코드 없이 진입 시: "자녀를 등록해주세요" 안내 + [초대 코드 입력하기] 버튼

#### 이중 역할 처리 (학부모이자 학생)

하나의 계정에서 역할 전환:
- 학부모 프로필: 자녀 관리 대시보드, 수강권 입금 상태, 모니터링
- 본인 학생 프로필: 내 레슨 일정, 과제, 연습
- 자녀 프로필 N개: 프로필별 학생 UI로 전환

#### 구현 상태

| 항목 | 상태 |
|------|:----:|
| "학부모이신가요?" 링크 | ✅ 구현 완료 |
| ParentInviteCodeScreen | ✅ 구현 완료 |
| 프로필 전환기 (ProfileSwitcher) | ✅ 구현 완료 |
| 빈 학부모 홈 | ✅ 구현 완료 |

#### 관련 파일

```
features/auth/presentation/screens/parent_invite_code_screen.dart
features/auth/presentation/screens/login_screen.dart
features/parent_home/presentation/widgets/profile_switcher.dart
```

---

## 3. 관계 시스템 (Relationship System)

### 3.1 수강권 중심 관계 모델 (Subscription-Based Relationship)

#### 설계 배경

기존 "연결(Connection)" 중심 모델의 문제점:
- 연결 != 레슨 관계 (개념 불일치)
- 수강권과 연결의 분리로 인한 혼란
- "연결 끊김"이 레슨 관계 종료로 오해됨

#### 핵심 변경 (v1 -> v2)

| 항목 | 기존 (Connection 중심) | 변경 (Subscription 중심) |
|------|----------------------|------------------------|
| 관계 정의 | 맞팔 | **수강권 상태** |
| 연결 의미 | 레슨 관계 | **알림/공유 설정** |
| 상태 기준 | 팔로우 상태 | **수강권 유효 기간** |
| 자동 전환 | 없음 | **30일 후 "이전 레슨"으로 전환** |
| 팔로우 용도 | 레슨 관계 | **소식 구독** (공연/이벤트) |

#### RelationshipStatus Enum (정식 정의)

> 소스: `features/relationship/domain/entities/relationship_status.dart`

```dart
@HiveType(typeId: 91)
enum RelationshipStatus {
  @HiveField(0) trialBooked,  // 체험대기 - 체험 레슨 예약됨
  @HiveField(1) active,       // 활성 - 수강권 유효 (정규 레슨 진행 중)
  @HiveField(2) expired,      // 수강권 만료 - 만료 후 30일 이내
  @HiveField(3) past,         // 이전 레슨 - 만료 후 30일 초과
}

extension RelationshipStatusExtension on RelationshipStatus {
  String get displayName;        // 체험 예정/수강 중/수강권 만료/이전 레슨
  bool get canBookLesson;        // active만 true
  bool get canRequestLesson;     // expired, past만 true
  bool get canSharePractice;     // active만 true
  bool get isActiveRelationship; // past가 아니면 true
}
```

> **용어 주의 -- ConnectionStatus vs RelationshipStatus**
>
> | 용어 | 정의 | 소스 파일 | 용도 |
> |------|------|----------|------|
> | `RelationshipStatus` | 수강권 기반 선생님-학생 관계 (trialBooked/active/expired/past) | `features/relationship/domain/entities/relationship_status.dart` | 레슨/과제/공유 권한 결정 |
> | `ConnectionStatus` | 앱 연결 상태 (offline/inviteSent/inviteReceived/connected/disconnected) | `core/models/shared_enums.dart` | 학생 목록 인디케이터 표시 |
> | `ChildConnectionStatus` | 자녀 프로필 연결 상태 (connected/pending/unconnected) | `features/parent_home/domain/entities/child_profile.dart` | 학부모 대시보드 자녀 상태 |
>
> `RelationshipStatus`는 비즈니스 관계(수강권), `ConnectionStatus`는 기술적 연결(앱 팔로우) 상태. 이 두 개념은 독립적이며, 한 학생이 `ConnectionStatus.connected` + `RelationshipStatus.expired`일 수 있다.

#### 상태 전이

```
[신규 학생 유입]
     |
     v
trialBooked (체험대기) <-- 체험 예약
     |
     | 수강권 발급 (체험 후 등록)
     | (체험 취소/노쇼 -> 관계 종료)
     v
active (활성) <----------+----------+
     |                    |          |
     | 수강권 만료        |          |
     v                    |          |
expired (수강권만료) -----+          |
     |         수강권 재발급         |
     | 30일 경과 (자동 전환)        |
     v                              |
past (이전 레슨) -------------------+
               수강권 재발급
```

#### 설계 결정사항

| 항목 | 결정 | 이유 |
|------|------|------|
| 만료 후 대기 기간 | 30일 | 일반적인 레슨 간격 커버 |
| 연습 공유 | 수강권 유효 시만 | 명확한 권한 구분 |
| 이전 레슨 접근권 | 전체 유지 | 장기 레슨 이전 레슨 보존 |
| 수기 등록 학생 | 항상 active | 선생님이 직접 관리 |
| 자동 리마인더 | 보내지 않음 | 스팸 방지, 선생님이 직접 제안 |
| 선생님 선제안 | 가능 (월 1회 제한) | 학생 부담 고려 |

#### 수기 등록 학생 (특수 케이스)

- 앱 미사용, 선생님이 직접 등록/관리
- 항상 active (수강권 만료되어도)
- 연습 공유/수강권 만료 전환 없음
- 학생 목록에 (grey) 오프라인 아이콘 표시
- 앱 연결 시 수강권 유무에 따라 정상 상태로 전환

#### 재등록 경로

| 경로 | 주체 | 플로우 |
|------|------|--------|
| 학생 레슨 요청 | 학생 | 레슨 요청 -> 선생님 수강권 제안 -> 발급 |
| 선생님 선제안 | 선생님 | 직접 수강권 제안 -> 학생 수락 -> 발급 |
| 기존 정기레슨 앱 전환 | 선생님 | QR 스캔 -> 수강권 등록 -> 스케줄 등록 |

#### 상태별 기능 매트릭스 (선생님)

| 기능 | trialBooked | active | expired | past |
|------|:-----------:|:------:|:-------:|:----:|
| 학생 목록 표시 | O | O | O | O |
| 연습 현황 확인 | X | O | X | X |
| 레슨 노트 작성 | X | O | X | X |
| 과제 배정 | X | O | X | X |
| 레슨 기록 조회 | X | O | O | O |
| 수강권 제안 | O | O | O | O |
| 레슨 예약 | X | O | X | X |

#### 상태별 기능 매트릭스 (학생)

| 기능 | trialBooked | active | expired | past |
|------|:-----------:|:------:|:-------:|:----:|
| 선생님 목록 표시 | O | O | O | O |
| 레슨 노트 확인 | X | O | O | O |
| 연습 과제 확인 | X | O | O | O |
| 레슨 예약 | X | O | X | X |
| 레슨 요청 | X | X | O | O |
| 연습 기록 | O (개인) | O (공유) | O (개인) | O (개인) |

#### 구현 상태

| 항목 | 상태 |
|------|:----:|
| RelationshipStatus enum | ✅ 엔티티 정의 완료 |
| TeacherStudentRelation | ✅ 엔티티 정의 완료 |
| 자동 상태 전환 로직 | ❌ 미구현 (백엔드 필요) |

#### 관련 파일

```
features/profile/domain/entities/teacher_student_relation.dart
```

### 3.2 초대 시스템 (Invitation System v2)

> **초대 코드 라이프사이클 (재발송·만료·회수) 상세**: [invite_lifecycle_spec.md](invite_lifecycle_spec.md) 참조
> (E2E 감사 #5 D-G3 대응 — 2026-06-01 신규)

#### 핵심 변경 (v1 -> v2)

| 항목 | v1 | v2 |
|------|----|----|
| 연결 방식 | 요청 -> 수락 2단계 | QR 스캔 = 자동 연결 (제로 탭) |
| 학생 등록 | 앱 연결 필수 | 수기 등록 지원 |
| 검색 방식 | 코드 입력 | 연락처 동기화 + 코드 |
| 학원 지원 | 없음 | 학원-선생님 소속 관계 |
| 초대 라이프사이클 | 단순 만료 | 재발송·회수·만료 임박 알림 (2026-06-01) |

#### 초대 방식

| 방식 | 설명 |
|------|------|
| qrCode | QR 코드 (대면 레슨 시) |
| urlLink | URL 링크 (메시지/카카오톡) |
| inAppSearch | 앱 내 검색 |

#### 연결 승인 규칙

1. **선생님 -> 학생 초대**: 학생이 팔로우하면 자동 맞팔
2. **학생 -> 선생님 팔로우**: 선생님 설정에 따라 처리
   - 자동 수락 (기본): 즉시 맞팔
   - 수동 수락: 선생님이 알림에서 수락/거절
3. **수기 학생 매칭**: 전화번호 일치 시 자동 연결
4. **기존 정기레슨 앱 전환**: QR 스캔 후 선생님이 수강권 직접 등록

#### 학생 상태 인디케이터

**앱 연결됨 -> 연습 성과 표시:**

| 상태 | 색상 | 설명 |
|------|------|------|
| 우수 | green | 연습 잘함 (5/7일 이상) |
| 보통 | orange | 적당히 연습 (3-4/7일) |
| 부족 | red | 연습 부족 (1-2/7일) |
| 휴강 | grey | 휴강 중 |
| 신규 연결 | primary(#6B5B95) | 연습 데이터 없음 |

**앱 미연결 -> 연결 상태 표시:**

| 상태 | 색상 | 설명 |
|------|------|------|
| 초대 보냄 | amber | 내가 팔로우함 (대기 중) |
| 초대 받음 | blue | 상대가 팔로우함 (수락 대기) |
| 오프라인 | grey | 수기 등록 (앱 미사용) |
| 연결 끊김 | grey | 학생이 팔로우 해제함 |

#### 연결 혜택 (액터별)

**선생님 혜택:**
- 실시간 연습 현황 파악, 연습 과제 전달
- 연습 알림 발송, 녹음 피드백
- 레슨/입금 상태 알림 자동 발송

**학생 혜택 (연결 없이 사용 가능):**
- 연습 기록 (선생님 템플릿 활용), 연습 스트릭, 메트로놈, 녹음

**학생 혜택 (연결 후 추가):**
- 레슨 노트 확인, 연습 과제, 연습 현황 공유, 선생님 피드백

**학부모 혜택:**
- 자녀 연습 현황 실시간 확인, 레슨 스케줄, 레슨 노트
- 입금 완료 알림 후 선생님 확인 상태 확인

#### 학부모 연결 시스템

**학부모 주도 연결 플로우:**

```
학부모 앱 가입 -> 자녀 등록 -> 선생님 찾기(코드/전화번호) -> 연결할 자녀 선택 -> 연결 완료
```

- 미성년자 자녀만 대리 등록 가능 (만 19세 미만)
- 자녀가 선생님 학생 목록에 자동 등록
- 학부모가 자녀 연습 기록 대신 입력 가능

**선생님 주도 학부모 초대 (권장):**

```
선생님 앱 -> 학부모 초대 (연락처 입력) -> 초대 링크 전송 -> 학부모 가입 -> 자녀 선택 -> 연결 완료
```

#### 자녀 본인 계정 전환 (만 14세 도달 시)

```
자녀가 본인 계정으로 앱 가입
  -> 선생님 코드로 연결 시도
  -> 기존 학부모 등록 자녀와 매칭 감지
  -> 학부모에게 확인 요청
  -> [승인] -> 기존 데이터 자녀 계정으로 이전, 학부모는 조회 권한만 유지
  -> [거절] -> 전환 거절 (기존 유지)
```

#### 학원-선생님 초대 시스템

**멤버십 역할:**

| 역할 | 권한 |
|------|------|
| owner | 학원 전체 관리, 멤버 관리, 정산 |
| manager | 스케줄 관리, 학생 배정 |
| instructor | 본인 학생만 관리 |

**학원 -> 선생님 초대:**
```
학원 관리자 -> 강사 초대 (검색/코드) -> 초대 링크 전송 -> 선생님 수락 -> Membership 생성
```

**선생님 -> 학원 가입 요청:**
```
선생님 -> 학원 검색 -> 가입 요청 -> 학원 관리자 승인 -> Membership 생성
```

#### 구현 상태

| 항목 | 상태 |
|------|:----:|
| 초대 코드 생성/검증 | ✅ 구현 완료 |
| QR 코드 스캔 화면 | ✅ 구현 완료 |
| 초대 확인 화면 | ✅ 구현 완료 |
| 초대 이력 화면 | ✅ 구현 완료 |
| 대기 요청 화면 | ✅ 구현 완료 |
| 내 연결 목록 화면 | ✅ 구현 완료 |
| 학부모 연결 | ✅ 부분 구현 |
| 학원-선생님 초대 | ❌ 미구현 |
| 자녀 계정 전환 | ❌ 미구현 |

#### 관련 파일

```
features/invite/
├── domain/entities/invite_code.dart
├── presentation/screens/invite_screen.dart
├── presentation/screens/scan_invite_screen.dart
├── presentation/screens/invite_confirm_screen.dart
├── presentation/screens/invite_history_screen.dart
├── presentation/screens/pending_requests_screen.dart
├── presentation/screens/my_connections_screen.dart
└── presentation/screens/code_input_screen.dart
features/profile/domain/entities/invite.dart
features/profile/presentation/providers/invite_provider.dart
```

### 3.3 팔로우 시스템 (소식 구독)

#### 개념

팔로우 = 소식 구독 (수강권/레슨 관계와 무관)
- 누구나 선생님이나 학원을 팔로우하여 공연, 행사, 소식을 받아볼 수 있음

#### 관계 vs 팔로우 비교

| 항목 | 관계 (RelationshipStatus) | 팔로우 (Follow) |
|------|--------------------------|----------------|
| 기반 | 수강권 기반 | 누구나 가능 |
| 용도 | 레슨/연습/과제 관련 | 소식/공연/행사 알림 |
| 대상 | 학생만 가능 | 학생/학부모/일반인 가능 |
| 수락 | 선생님의 수락 필요 | 수락 불필요 (일방향) |
| 전환 | 자동 (수강권 상태) | 사용자가 직접 팔로우/언팔 |

#### 팔로우 대상

| 대상 | 가능 여부 | 설명 |
|------|:---------:|------|
| 선생님 | O | 개인 선생님 소식 |
| 학원 | O | 학원 행사/공연 소식 |
| 학생 | X | 팔로우 대상 아님 |

#### 팔로우와 레슨 관계 조합

- 팔로우만 함 (레슨 관계 없음): 소식/공연 알림만 수신
- 레슨 학생 + 팔로우: 레슨 알림 + 소식 알림 모두 수신
- 레슨 학생 + 언팔로우: 레슨 알림은 정상, 소식만 차단
- 수강권 만료 후: 팔로우는 사용자 설정 그대로 유지

#### Follow 엔티티

```dart
class Follow extends HiveObject {
  final String id;
  final String followerId;      // 팔로우 하는 사람
  final String followingId;     // 팔로우 대상 (선생님/학원)
  final FollowTargetType targetType;  // teacher | academy
  final bool notificationEnabled;     // 알림 수신 여부 (기본 ON)
  final DateTime createdAt;
}
```

#### 학부모 팔로우 규칙

- 자녀 연결 시 -> 해당 선생님 자동 팔로우
- 자녀 언팔로우 -> 선생님 팔로우 유지 (선택)
- 팔로워 수에 포함됨

#### 알림/공유 설정 (NotificationSetting)

| 설정 | 기본값 | 변경 가능 |
|------|:------:|:--------:|
| 푸시 알림 | On | O |
| 연습 공유 | On | O |
| 레슨 리마인더 | On | O |
| 입금 상태 알림 | On | O |

- 알림 끄기/연습 공유 끄기는 관계에 영향 없음
- 명시적 "관계 종료 요청" 시에만 past로 전환

#### 구현 상태

| 항목 | 상태 |
|------|:----:|
| Follow 엔티티 | ✅ 엔티티 정의 완료 |
| 팔로우 UI | ❌ 미구현 |
| NotificationSetting | ❌ 미구현 (백엔드 필요) |

### 3.4 3자 관계 (학원-선생님-학생)

#### 관계 구조

```
학원 (Organization)
  |
  |-- 1:N (소속)
  v
선생님 (Teacher) --- Membership (역할: owner/manager/instructor)
  |
  |-- 1:N (LessonClass)
  v
클래스 (LessonClass: academy/private)
  |
  |-- N:M (ClassMembership)
  v
학생 (Student)
```

#### 입금 안내 대상 구분

| 클래스 유형 | 입금 안내 유형 | 입금 대상 |
|------------|----------|----------|
| academy | organization | 학원 계좌로 입금 -> 선생님은 급여 정산 대상 |
| private | parent | 학부모가 선생님 계좌로 직접 입금 |

#### 데이터 소유권

- 학원 컨텍스트에서 생성된 데이터는 학원 소유
- 선생님이 학원 탈퇴 시 학원 학생 데이터 접근 불가

#### 구현 상태

| 항목 | 상태 |
|------|:----:|
| LessonClass 엔티티 | ✅ 구현 완료 |
| ClassMembership 엔티티 | ✅ 구현 완료 |
| 3자 관계 UI | ❌ 미구현 |

---

## 4. 학생 & 클래스 시스템

### 4.1 클래스/멤버십 모델

#### 핵심 목표

1. 한 선생님이 여러 학원 + 개인레슨 동시 관리
2. 입금 안내 대상 (학원 vs 학부모) 명확 구분
3. 한 학생이 여러 선생님에게 레슨 받을 수 있는 구조
4. 기존 데이터와의 하위 호환성 유지

#### LessonClass (클래스/소속 그룹)

| 필드 | 설명 |
|------|------|
| teacherId | 소유 선생님 ID |
| name | 클래스명 ("OO음악학원", "개인레슨" 등) |
| type | LessonClassType (academy / private) |
| paymentType | PaymentType (organization / parent) |
| contactPerson/Phone/address | 학원 정보 (academy 타입만) |

#### ClassMembership (클래스 소속 관계)

**소속 상태 (MembershipStatus):**

| 값 | 설명 |
|----|------|
| trial | 체험 중 |
| active | 정규 수강 중 |
| paused | 휴강 |
| terminated | 종료 |

**주요 필드:**
- lessonClassId, studentId: 클래스-학생 연결
- instrument: 악기
- status: MembershipStatus
- level: 레벨 (입문/초급/중급/고급)
- monthlyFee, lessonsPerWeek: 수강료 정보
- lessonDay, lessonTime, lessonDuration: 스케줄

**계산 필드:**
- monthlyLessonCount: 주당 횟수 x 4
- lessonFee: 월 수강료 / 월 레슨 횟수

#### Subscription (수강권)

| 유형 | 설명 |
|------|------|
| trial | 체험 레슨 (무료/할인) |
| monthly | 월정액 (기간제) |
| package | 회차제 (8회, 16회 등) |

| 상태 | 설명 |
|------|------|
| active | 활성 (사용 가능) |
| expiringSoon | 만료 임박 (기간제: 7일 이내, 회차제: 잔여 2회 이하) |
| expired | 만료됨 |
| paused | 일시정지 |

### 4.2 다중 선생님 지원

한 학생이 여러 선생님에게 레슨 받는 경우:

```
김민수 (Student)
|
|-- 박선생님 / OO음악학원 -> 피아노 레슨
|   +-- ClassMembership: instrument=피아노, level=중급
|
+-- 이선생님 / 개인레슨 -> 바이올린 레슨
    +-- ClassMembership: instrument=바이올린, level=초급
```

학생 홈 화면에서 악기별 탭으로 전환, 수강권 현황 통합 표시

### 4.3 수강관리 (선생님 측)

> **용어 변경 (2026-04-16)**: "학생관리" → "수강관리". 목록 단위가 학생이 아닌 **수강(멤버십)**이므로 변경.
> 같은 학생이 바이올린+피아노를 배우면 2행으로 표시됨.

#### 수강 목록 화면 (클래스별 그룹화)

```
수강관리
|
|-- OO음악학원 (3명)          [설정]
|   |-- 김민수  바이올린 중급  화 15:00  [활성]  5/8회
|   |-- 이서연  피아노  초급  화 16:00  [활성]  3/4회
|   +-- 박지훈  피아노  입문  수 14:00  [체험]
|
|-- 개인레슨 (2명)             [설정]
|   +-- 김민수  피아노  중급  금 17:00  [활성]  2/4회  ← 같은 학생, 다른 과목
|
+-- 이전 수강 (1명)            ← 만료 멤버십
    +-- 정다은  바이올린 초급  [만료]  4/4회 완료
```

#### 수강 상세 진입 규칙

- 목록에서 행 탭 → `studentId` + `membershipId` 전달
- 상세 화면의 모든 데이터는 **해당 멤버십 범위로 필터링**
  - 수강권: 해당 멤버십의 **마지막(최신) 수강권 1개**만 카드 표시
  - 레슨 노트: 해당 멤버십의 악기 레슨 노트만
  - 수강 이력: 해당 멤버십의 과거+현재 수강권 전체
- `membershipId` 없이 진입 시 (폴백): 학생 전체 데이터 표시

#### 만료 멤버십 접근

수강권 종료 후에도 레슨 이력은 조회 가능:
- "이전 수강" 그룹에 만료 멤버십 표시
- 탭하면 과거 수강권 + 레슨 노트 이력 열람

#### 목록 필터 구조 (2026-04-16)

**정보 아키텍처**: 클래스 중심 (학원/개인 그룹) — 학생 중심(Q1=A 결정)

**필터 UI**:

| 영역 | 구성 | 기능 |
|------|------|------|
| 1차 필터 | 세그먼트 (1줄) | 학원 / 개인 / 전체 |
| 2차 필터 | 필터 아이콘 → 바텀시트 | 연습상태 (우수/보통/부족/휴강), 상태 (활성/만료예정/만료) |
| 검색 | 상단 검색바 | 학생 이름, 악기 |
| 정렬 | 정렬 드롭다운 | 이름순 / 악기순 / 최근 레슨순 |

**변경 전**: 칩 2줄 (수업유형 3개 + 연습상태 5개)
**변경 후**: 세그먼트 1줄 + 필터 바텀시트 (다중 필터 지원)

> 참고: 네이버 예약 — 세그먼트 + 필터 버튼 패턴

#### 연습 추이 시각화 (스파크라인)

**목적**: 학생의 7일 연습 추이를 한눈에 파악

**표시**: 최근 7일 연습 시간을 미니 막대 그래프(sparkline)로 표시

```
이서연  🎹 피아노  수 16:00  ▅▅▃▅▃▅▅   ← 꾸준히 연습
박지훈  🎹 피아노  수 14:00  ▅▃▁▁▁▁▁   ← 최근 감소 (주의)
김민준  🎻 바이올린 화 15:00  ▁▁▁▅▅▅▅  ← 최근 시작
```

**색상**: 최근 3일 기준
- 🟢 평균 우수 (5일 이상 연습)
- 🟡 평균 보통 (3~4일)
- 🔴 평균 부족 (0~2일)

**데이터 소스**: PracticeCheckin 엔티티의 최근 7일 (Mock 기반, 백엔드 연동 후 실데이터)

#### 복수 과목 학생 표시

같은 학생이 여러 클래스(학원+개인)에 수강 중일 때:
- 각 클래스 그룹에서 별도 행으로 표시 (현재 구조 유지)
- 학생 이름 옆 **`[2]` 배지**로 복수 과목 힌트 (선택 사항)

```
학원 (3)
  김민준 [2]  🎻 바이올린  ▅▅▃▅▃▅▅   ← [2] = 2과목 수강
  이서연       🎹 피아노    ▅▃▁▁▁▁▁
개인레슨 (2)
  김민준 [2]  🎹 피아노    ▂▂▅▃▁▂▅   ← 같은 학생
  강서윤       🎻 바이올린  ▅▃▅▅▃▅▃
```

**이유 (Q1=A 결정)**:
- 클래스 중심 정보 아키텍처 유지 → "이 학생을 어떤 클래스에서 가르치는지" 명확
- 같은 학생이라도 과목마다 완전히 다른 수업 → 분리 표시가 자연스러움
- 네이버 예약 패턴 (동일 고객 여러 예약 = 여러 행)

#### 학생 추가 플로우

1단계: 클래스 선택 (어느 클래스에 추가?)
2단계: 학생 정보 (기존 학생 검색 또는 신규 등록)
3단계: 레슨 정보 (악기, 레벨, 수강료, 요일/시간)

#### Student 엔티티 (단순화)

학생의 기본 정보만 포함. 레슨/수강료 정보는 ClassMembership으로 이동.

| 필드 | 설명 |
|------|------|
| name, profileColor | 기본 정보 |
| phone, parentPhone, parentName | 연락처 |
| birthDate, manualAgeGroup | 연령 정보 |
| connectionStatus | offline / inviteSent / connected |

**연령 그룹 (AgeGroup):**
- child: 만 12세 이하 (미취학/초등)
- student: 만 13-18세 (중고등)
- adult: 만 19세 이상 (성인)

#### 레슨 장소 시스템

| 유형 | 설명 |
|------|------|
| academyRoom | 학원 레슨실 |
| teacherStudio | 선생님 스튜디오 |
| studentHome | 학생 집 방문 |
| externalPlace | 외부 장소 |
| online | 온라인 (Zoom, 구글 미트 등) |

#### 데이터 마이그레이션 전략

기존 Student 데이터를 새 구조로 변환:
1. 기본 "개인레슨" LessonClass 생성
2. 기존 Student에서 레슨 정보 -> ClassMembership으로 이동
3. StudentWithMembership 결합 클래스로 하위 호환성 유지

#### Provider 설계

| Provider | 파라미터 | 반환 타입 |
|----------|---------|----------|
| teacherClassesProvider | teacherId | `List<LessonClass>` |
| classMembershipsProvider | classId | `List<StudentWithMembership>` |
| groupedStudentsProvider | teacherId | `Map<LessonClass, List<...>>` |

#### 구현 상태

| 항목 | 상태 |
|------|:----:|
| LessonClass 엔티티 | ✅ 구현 완료 |
| ClassMembership 엔티티 | ✅ 구현 완료 |
| Student 엔티티 (단순화) | ✅ 구현 완료 |
| LessonLocation 엔티티 | ✅ 구현 완료 |
| StudentWithMembership | ✅ 구현 완료 |
| Mock Repository (Class, Membership, Location, Student) | ✅ 구현 완료 |
| Remote Repository (Student) | ✅ 구현 완료 |
| groupedStudentsProvider | ✅ 구현 완료 |
| 학생 목록 그룹화 UI | ✅ 구현 완료 |
| 클래스 관리 화면 | ✅ 부분 구현 |
| Subscription 엔티티 | ✅ 엔티티 정의 완료 |
| 데이터 마이그레이션 | ❌ 미구현 |
| 수강권 입금 상태 클래스별 분리 | ❌ 미구현 (결제/정산 기능은 현행 스펙 범위 밖) |

#### 관련 파일

```
features/students/
├── domain/entities/
│   ├── lesson_class.dart
│   ├── class_membership.dart
│   ├── student.dart
│   ├── student_with_membership.dart
│   ├── grouped_students.dart
│   └── lesson_location.dart
├── domain/repositories/
│   ├── lesson_class_repository.dart
│   ├── membership_repository.dart
│   ├── student_repository.dart
│   └── location_repository.dart
├── data/repositories/
│   ├── mock_lesson_class_repository.dart
│   ├── mock_membership_repository.dart
│   ├── mock_student_repository.dart
│   ├── mock_location_repository.dart
│   └── remote_student_repository.dart
└── presentation/providers/
    ├── grouped_students_provider.dart
    ├── student_crud_provider.dart
    ├── lesson_class_providers.dart
    ├── membership_providers.dart
    └── location_providers.dart
```

---

## 5. 학부모 시스템

### 5.1 학부모-자녀 연결

#### 현재 구조 (1:N)

1명의 학부모가 여러 자녀를 관리. 추후 N:N (여러 학부모-여러 자녀)으로 확장 가능.

#### 자녀 프로필 구조

만 14세 미만 자녀는 "회원"이 아닌 부모 계정에 종속된 데이터.

**저장 정보:**

| 정보 | 저장 | 용도 |
|------|:----:|------|
| 이름/닉네임 | O | 선생님이 구분 |
| 생년 (년도만) | O | 연령 확인 |
| 악기 | O | 레슨 유형 |
| 레벨 | O | 실력 수준 |
| 연습 기록 | O | 핵심 기능 |
| 레슨 노트 | O | 핵심 기능 |
| 상세 생년월일, 주민번호, 주소, 학교 | X | 수집 안함 |

#### ChildProfile 엔티티

```dart
class ChildProfile {
  final String id;
  final String parentId;
  final String name;
  final int birthYear;
  final String instrument;
  final String level;
  final String? teacherId;
  final String? teacherName;
  final Color profileColor;
  final ChildProfileStatus status;              // active | inactive
  final ChildConnectionStatus connectionStatus; // connected | pending | unconnected
  final DateTime createdAt;

  int get age => DateTime.now().year - birthYear;
  bool get isConnected => connectionStatus == ChildConnectionStatus.connected;
}
```

#### 미연결 자녀 기능

| 기능 | 미연결 자녀 | 연결된 자녀 |
|------|:-----------:|:-----------:|
| 연습 기록, 메트로놈, 스트릭, 레퍼토리 | O | O |
| 레슨 노트, 과제, 피드백, 입금 상태 | X | O |

사용 시나리오: 레슨 계획 없는 자녀, 선생님 탐색 중, 독학 중

#### 휴대폰 없는 학생 처리

| 방식 | 설명 |
|------|------|
| 부모 기기 공유 | 부모 휴대폰에서 프로필 전환하여 사용 |
| 태블릿/iPad 사용 | 가정 내 태블릿에서 앱 사용 |
| 복합 사용 (권장) | 집에서는 태블릿, 외출 시 부모 폰 |

#### 학부모 권한

| 권한 | 설명 |
|------|------|
| 연습 기록 입력 | O (자녀 대신) |
| 연습 스트릭 확인 | O |
| 메트로놈 사용 | O (자녀와 함께) |
| 녹음 | O (자녀 연습) |
| 레슨 노트 확인 | O |
| 입금 상태 확인 | O (수강료 입금 확인 상태) |
| 레슨 알림 | O (리마인더 수신) |

### 5.2 학부모 대시보드

#### 탭 구성

| 탭 | 화면 | 상태 |
|----|------|:----:|
| 홈 | ParentDashboardTab | ✅ Mock |
| 레슨 | ParentLessonsTab | ✅ Mock |
| 과제 | ParentAssignmentsTab | ✅ Mock |
| 프로필 | ParentProfileTab | ✅ 부분 실데이터 |

#### 홈 탭 (ParentDashboardTab)

구성 요소:
- 자녀 그래디언트 헤더 (이름, 나이, 악기, 레벨, 선생님)
- 퀵 스탯 3열 (이번주 레슨 횟수, 과제 완료율, 연습 스트릭)
- 다음 레슨 카드 (D-day, 날짜/시간, 선생님)
- 이번 주 연습 캘린더 (요일별 완료 상태)
- 최근 과제 목록 (우선순위별)
- 수강권 입금 상태 카드

#### 레슨 탭 (ParentLessonsTab)

- 캘린더 그리드 (월간)
- 예정된 레슨 목록
- 지난 레슨 목록 (레슨 노트 바텀시트로 상세 보기)

#### 과제 탭 (ParentAssignmentsTab)

- 이번 주 과제 진행률 (프로그레스 바)
- 미완료 과제 목록
- 완료된 과제 목록

#### 프로필 탭 (ParentProfileTab)

- 프로필 정보 (아바타, 이름, 이메일)
- 연결된 자녀 관리
- 알림 설정 (과제/레슨/연습/입금 상태)
- 설정 (다크 모드, 언어, 녹음 백업)
- 지원 (도움말, 피드백, 앱 정보)
- 계정 (이용약관, 개인정보처리방침, 로그아웃)

#### 자녀 전환

바텀시트로 자녀 전환 + 자동 첫 번째 선택
- selectedChildProfileProvider 업데이트 시 대시보드 UI 즉시 갱신

#### 프로필 전환 (ProfileSwitcher)

```
프로필 드롭다운
|-- 학부모 (박부모)
|-- 학생 (본인 학생 프로필)
|-- --------
|-- 자녀 프로필
|   |-- 김서연 (연결됨 / 김선생님)
|   +-- 김지훈 (미연결)
+-- 선택 시 역할 전환 -> 해당 앱 화면으로 이동
```

#### UserProfile 엔티티

```dart
class UserProfile {
  final String userId;
  final String userName;
  final ProfileType activeProfile;   // parent | student | child
  final String? activeChildId;
  final bool hasStudentProfile;
  final List<ChildProfile> children;
}
```

### 5.3 데이터 접근 & 가시성

#### Mock -> 실데이터 GAP 분석

| 데이터 | 현재 | 실데이터 전환 | 의존 |
|--------|:----:|:------------:|------|
| 자녀 프로필 목록 | ✅ 실데이터 | - | parent_system |
| 선택된 자녀 상태 | ✅ 실데이터 | - | child_profile_provider |
| 알림 설정 | ✅ 실데이터 | - | notification_system |
| 이번주 레슨 수 | ❌ 하드코딩 | lessonProvider 연동 | lesson_schedule |
| 과제 완료율 | ❌ 하드코딩 | assignmentProvider 연동 | - |
| 연습 스트릭 | ❌ 하드코딩 | practiceStreakProvider 연동 | practice_streak_spec |
| 다음 레슨 정보 | ❌ 하드코딩 | lessonProvider 연동 | lesson_schedule |
| 연습 캘린더 | ❌ 하드코딩 | practiceCompletionProvider 연동 | practice_screen_spec |
| 최근 과제 | ❌ 하드코딩 | assignmentProvider 연동 | - |
| 수강권 입금 상태 | ❌ 하드코딩 | subscriptionProvider 연동 | subscription_master §4 |
| 레슨 목록/노트 | ❌ 하드코딩 | lessonProvider 연동 | lesson_note_spec |

#### 구현 상태

| 항목 | 상태 |
|------|:----:|
| ParentHomeScreen 4탭 네비게이션 | ✅ 구현 완료 |
| ParentDashboardTab (Mock) | ✅ 구현 완료 |
| ParentLessonsTab (Mock) | ✅ 구현 완료 |
| ParentAssignmentsTab (Mock) | ✅ 구현 완료 |
| ParentProfileTab (부분 실데이터) | ✅ 구현 완료 |
| ProfileSwitcher | ✅ 구현 완료 |
| UnconnectedChildDashboard | ✅ 구현 완료 |
| ChildProfile / UserProfile 엔티티 | ✅ 구현 완료 |
| childProfilesProvider / SelectedChildProfile | ✅ 구현 완료 |
| ChildProfileManager (CRUD) | ✅ 구현 완료 |
| ChildProfileFormScreen (자녀 등록/수정) | ✅ 구현 완료 |
| RemoteParentRepository | ✅ 구현 완료 |
| RemoteChildProfileRepository | ✅ Remote 구현 완료 (2026-05-31) |
| 실데이터 연동 (퀵스탯, 과제, 입금 상태 등) | ❌ 미구현 |

#### 관련 파일

```
features/parent_home/
├── domain/entities/
│   ├── child_profile.dart
│   ├── user_profile.dart
│   ├── parent.dart
│   ├── parent_child_relation.dart
│   ├── parent_notification_settings.dart
│   └── parent_visibility_settings.dart
├── data/repositories/
│   └── remote_parent_repository.dart
├── presentation/providers/
│   ├── child_profile_provider.dart
│   ├── user_profile_provider.dart
│   ├── parent_crud_provider.dart
│   └── parent_repository_provider.dart
├── presentation/screens/
│   ├── parent_home_screen.dart
│   ├── parent_dashboard_tab.dart
│   ├── parent_lessons_tab.dart
│   ├── parent_assignments_tab.dart
│   ├── parent_profile_tab.dart
│   ├── child_profiles_screen.dart
│   ├── child_profile_form_screen.dart
│   └── unconnected_child_dashboard.dart
└── presentation/widgets/
    ├── profile_switcher.dart
    ├── stat_card.dart
    ├── section_card.dart
    ├── child_card.dart
    ├── assignment_item.dart
    ├── notification_settings_sheet.dart
    └── parent_notification_badge.dart
```

#### 에러/엣지 케이스

| 상황 | 현재 동작 |
|------|----------|
| 자녀 0명 | "자녀를 등록하세요" 안내 |
| 미연결 자녀 선택 | UnconnectedChildDashboard 표시 |
| 자녀 삭제 후 선택 | 첫 번째 자녀로 자동 전환 |
| 레슨/과제 데이터 없음 | 하드코딩 Mock 표시 (Phase 2에서 빈 상태 위젯) |
| 선생님 미연결 상태 | 제한된 기능 표시 (Phase 2에서 연결 유도 배너) |

---

## 6. 선생님 프로필 & 검색

### 6.1 확장 프로필 (Extended Profile)

#### 공개 프로필 설정

| 공개 범위 | 설명 |
|----------|------|
| public | 모든 사용자에게 공개 |
| students | 연결된 학생에게만 공개 |
| private | 비공개 |

#### 기본 공개 범위

| 항목 | 기본값 |
|------|:------:|
| name | public |
| photo | public |
| contact | students |
| fee | public |
| career | public |
| certificate | public |

#### 구현 상태

| 항목 | 상태 |
|------|:----:|
| 확장 프로필 화면 | ✅ 구현 완료 |
| 자격증 편집 | ✅ 구현 완료 |
| 학력 편집 | ✅ 구현 완료 |
| 경력 편집 | ✅ 구현 완료 |
| 악기 관리 | ✅ 구현 완료 |
| 레슨 시간 설정 | ✅ 구현 완료 |
| 공개 범위 설정 | ✅ 구현 완료 |
| 입금 상태 관리 | ✅ 구현 완료 |
| 레퍼토리 관리 | ✅ 구현 완료 |
| 공개 프로필 API | ✅ 구현 완료 (2026-05-31) — `GET /teachers/public/{id}` 인증 불필요, 민감정보 제외 |

#### 관련 파일

```
features/profile/
├── domain/entities/
│   ├── teacher.dart
│   ├── teacher_profile.dart
│   ├── teacher_settings.dart
│   └── teacher_onboarding.dart
├── presentation/providers/
│   └── teacher_extended_profile_provider.dart
└── presentation/screens/
    ├── extended_profile_screen.dart
    ├── profile_visibility_screen.dart
    ├── certificate_edit_screen.dart
    ├── education_edit_screen.dart
    ├── career_edit_screen.dart
    ├── instrument_management_screen.dart
    ├── lesson_time_settings_screen.dart
    └── outstanding_payments_screen.dart
```

### 6.2 선생님 검색/발견

#### 검색 탭 구분

| 탭 | 설명 | 필터 조건 |
|----|------|----------|
| 학원 | 학원 소속 선생님 검색 | organizationId != null |
| 개인 선생님 | 개인 선생님 검색 | organizationId == null |

#### 검색 필터

| 필터 | 설명 |
|------|------|
| teacherType | 학원/개인 (탭으로 제어) |
| instruments | 악기 |
| area | 지역 |
| lessonType | 대면/비대면 |
| feeRange | 레슨료 범위 |
| hasVerifiedCertificate | 자격인증 여부 |
| minExperience | 최소 경력 |

#### 검색 랭킹 요소

| 순위 | 요소 |
|:----:|------|
| 1 | 프로필 완성도 (complete > standard) |
| 2 | 자격인증 여부 |
| 3 | 학생 수 / 리뷰 수 |
| 4 | 최근 활동일 |

#### 구현 상태

| 항목 | 상태 |
|------|:----:|
| 선생님 검색 화면 (학원/개인 탭) | ✅ 구현 완료 |
| 선생님 상세 화면 | ✅ 구현 완료 |
| 학원 상세 화면 | ✅ 구현 완료 |
| 검색 필터 엔티티 | ✅ 구현 완료 |
| 검색 Provider | ✅ 구현 완료 |
| 백엔드 검색 API | ❌ 미구현 |
| 검색 랭킹 알고리즘 | ❌ 미구현 |

#### 관련 파일

```
features/search/
├── domain/entities/search_filter.dart
├── presentation/providers/
│   ├── teacher_search_provider.dart
│   └── teacher_providers.dart
└── presentation/screens/
    ├── teacher_search_screen.dart
    ├── teacher_detail_screen.dart
    └── academy_detail_screen.dart
```

### 6.3 리뷰 시스템

#### 개요

레슨 피드백을 기반으로 선생님 리뷰를 생성하는 통합 시스템.

#### 피드백 -> 리뷰 통합 플로우

```
레슨 완료 -> 피드백 작성 (선택, 비공개) -> 피드백 누적 -> 리뷰 요청 트리거 -> 리뷰 작성 (공개 가능)
```

#### 피드백 시스템 (비공개)

| 만족도 | 이모지 | 설명 |
|--------|:------:|------|
| veryGood | (smile) | 매우 좋았어요 |
| good | (slightly_smile) | 좋았어요 |
| okay | (neutral) | 보통이에요 |
| notGood | (confused) | 아쉬웠어요 |

#### 리뷰 요청 트리거

| 트리거 | 시점 |
|--------|------|
| trialLessonComplete | 체험레슨 완료 직후 |
| connectionEnded | 연결 해제 시 |
| voluntary | 언제든지 자발적 작성 |

#### 리뷰 카테고리

| 카테고리 | 한글명 |
|----------|--------|
| preparation | 수업 준비 |
| explanation | 설명력 |
| friendliness | 친절도 |
| progressMgmt | 진도 관리 |

#### 리뷰 작성 규칙

| 항목 | 값 |
|------|-----|
| 최소 레슨 횟수 | 1회 |
| 텍스트 최소 길이 | 20자 (공개 시 필수) |
| 텍스트 최대 길이 | 500자 |
| 수정 가능 기간 | 7일 |
| 학생 삭제 | 가능 |
| 선생님 삭제 | 불가 |

#### 작성자 유형 (자녀 프로필 리뷰 처리)

| 작성자 유형 | 설명 |
|------------|------|
| student | 학생 본인 (만 14세 이상) |
| parent | 부모 대리 작성 (만 14세 미만) |

- 만 14세 미만 자녀 프로필: 부모만 작성 가능, "학부모"로 표시
- 만 14세 이상 학생: 학생 본인 작성, "학생"으로 표시

#### 리뷰 공개 설정 (선생님)

| 공개 범위 | 설명 |
|----------|------|
| public | 모든 리뷰 자동 공개 |
| selective | 선생님이 개별 선택 |
| summaryOnly | 평균 점수만 표시 |
| private | 완전 비공개 |

#### 선생님 답변 기능

| 규칙 | 값 |
|------|-----|
| 최대 길이 | 300자 |
| 수정/삭제 | 가능 |
| 답변 기한 | 30일 이내 |

#### 검색 랭킹 반영

| 요소 | 가중치 |
|------|:------:|
| 평균 평점 | 30% |
| 리뷰 수 | 20% |
| 프로필 완성도 | 20% |
| 최근 활동 | 20% |
| 자격 인증 | 10% |

#### 리뷰 관련 뱃지

| 뱃지 | 조건 |
|------|------|
| topRated | 평점 4.8+ & 리뷰 10개+ |
| studentChoice | 평점 4.5+ & 리뷰 20개+ |
| verified | 자격증 인증 완료 |
| premium | 프로필 완성도 100% |
| phoneVerified | 휴대폰 인증 완료 |

#### 구현 상태

| 항목 | 상태 |
|------|:----:|
| TeacherReview 엔티티 | ✅ 엔티티 정의 완료 |
| 레슨 피드백 UI | ❌ 미구현 |
| 리뷰 작성 UI | ❌ 미구현 |
| 리뷰 공개 설정 | ❌ 미구현 |
| 선생님 답변 기능 | ❌ 미구현 |
| 검색 랭킹 반영 | ❌ 미구현 |
| 뱃지 시스템 | ❌ 미구현 |

#### 관련 파일

```
features/profile/domain/entities/review.dart
```

---

## 7. 체험 레슨 시스템

### 7.1 개요

| 항목 | 내용 |
|------|------|
| 정의 | 1회성 레슨으로 선생님과 학생이 서로를 알아가는 시간 |
| 목적 | 정규 레슨 전 레슨 스타일 맞춤 확인 |
| 비용 | 30,000원 (기본, 선생님 커스텀 가능) |

지원 컨텍스트: 개인 선생님, 학원 소속 선생님 모두 지원

### 7.2 선생님 관점

#### 가용 시간 관리 (3계층)

```
Layer 1: 주간 템플릿 (기본 스케줄) -> 요일별 ON/OFF, 시간 범위, 제외 시간
Layer 2: 예외 (오버라이드) -> 특정 날짜 휴무, 시간 블로킹, 반복 예외
Layer 3: 구글 캘린더 연동 -> 외부 일정 확인 후 수동 블로킹
```

#### 체험 레슨 신청 처리

| 액션 | 설명 |
|------|------|
| 승인 | 확인 -> 학생 알림 -> 캘린더에 표시 |
| 일정 조율 | 사유 선택 + 대안 시간 제안 (최대 3개) |

일정 조율 사유: "해당 시간 마감", "일정 조율 필요", "잠시 레슨 쉬는 중"

#### 정규 레슨 전환

레슨 완료 후 "정규 레슨 등록하기" 버튼 활성화

### 7.3 학생 관점

#### 체험 레슨 신청

| 필드 | 필수 | 설명 |
|------|:----:|------|
| 날짜/시간 | O | 선생님 가용시간 중 선택 |
| 레슨 목표 | O | 취미/입시/전공 |
| 악기 경험 | O | 처음/1년미만/1-3년/3년이상 |
| 메시지 | X | 선생님께 전달할 메시지 |

#### 동시 신청 정책

| 정책 | 허용 |
|------|:----:|
| 여러 선생님 동시 신청 | O |
| 같은 선생님 다른 악기 | O |
| 같은 선생님 같은 악기 중복 | X |

#### 예약 상태

| 상태 | 학생 액션 |
|------|----------|
| pending (신청완료) | 수정, 취소 |
| confirmed (확정) | 변경요청, 취소 |
| changeRequested (변경요청) | 취소 |
| unavailable (일정조율) | 대안 선택, 취소 |
| expired (만료) | 다시 신청 |
| completed (완료) | - |
| cancelled (취소) | - |

### 7.4 노쇼/취소 정책

| 항목 | 정책 |
|------|------|
| 취소 마감 | 레슨 24시간 전 |
| 취소 페널티 | 선생님별 설정 (기본: 100% 과금) |
| 체험레슨 | 취소 대신 일정변경 허용 (관대) |
| 노쇼 | 선생님별 설정 (100% 과금) |
| 긴급상황 | 선생님 재량 |

### 7.5 입금 상태 플로우

```
1. 학생: 계좌 이체 (선생님 계좌)
2. 학생: 앱에서 "입금 완료 알림" 전송
3. 선생님: 계좌 확인 후 "입금 확인" 처리
```

### 7.6 구현 상태

| 항목 | 상태 |
|------|:----:|
| 체험 레슨 신청 화면 | ✅ 구현 완료 |
| 승인 대기 목록 | ✅ 구현 완료 |
| 일정 조율 (사유 선택 + 대안 제안) | ✅ 구현 완료 |
| 예약 상태 관리 | ✅ 구현 완료 |
| 시간 슬롯 선택 위젯 | ✅ 구현 완료 |
| 예약 카드 위젯 | ✅ 구현 완료 |
| 라우터 연결 | 🟡 화면 완료, 라우터 미연결 |
| 푸시 알림 | ❌ 미구현 |
| 선생님 찾기/검색 (백엔드) | ❌ 미구현 |
| 앱 내 결제/PG/카드 연동 | ❌ 현행 범위 아님 |
| 리뷰/평점 연동 | ❌ 미구현 |
| 정규 레슨 전환 유도 | ❌ 미구현 |

#### 관련 파일

```
lib/models/lesson_booking.dart
lib/models/time_slot.dart
lib/repositories/booking_repository.dart
lib/providers/booking/booking_providers.dart
features/schedule/presentation/screens/trial_lesson_request_screen.dart
features/schedule/presentation/screens/pending_bookings_screen.dart
features/schedule/presentation/screens/booking_detail_screen.dart
features/schedule/presentation/widgets/time_slot_picker.dart
features/schedule/presentation/widgets/booking_card.dart
```

---

## 8. 구현 상태 요약

### Phase 1: 완료 (MVP)

| 기능 | 상태 |
|------|:----:|
| 소셜 로그인 (Google/Kakao/Apple) | ⚠️ Google 구현, Kakao/Apple 준비 중 |
| 역할 선택 (선생님/학생/학부모) | ✅ |
| 학부모 로그인 플로우 | ✅ |
| 학생/학부모 초대 코드 화면 | ✅ |
| 초대 시스템 (QR/URL/코드) | ✅ |
| 선생님 프로필 (확장 프로필 편집) | ✅ |
| 선생님 검색 화면 (학원/개인 탭) | ✅ |
| 학생 관리 (클래스별 그룹화) | ✅ |
| LessonClass / ClassMembership 엔티티 | ✅ |
| 학부모 대시보드 4탭 (Mock) | ✅ UI 완료, 실데이터 부분 연동 |
| ProfileSwitcher (역할 전환) | ✅ |
| 자녀 프로필 CRUD | ✅ |
| 체험 레슨 신청/승인 화면 | ✅ |
| 리뷰/팔로우 엔티티 정의 | ✅ |

### Phase 2: 진행 예정

| 기능 | 상태 |
|------|:----:|
| 학부모 대시보드 실데이터 연동 | ❌ |
| 수강권 중심 관계 자동 전환 (백엔드) | ❌ |
| 푸시 알림 (FCM) | ❌ |
| 선생님 검색 백엔드 API | ❌ |
| 수강권 입금 상태 연동 | ❌ |

### Phase 3: 향후 예정

| 기능 | 상태 |
|------|:----:|
| 휴대폰 인증 | ❌ |
| 자격증 인증 시스템 | ❌ |
| 리뷰/피드백 UI 구현 | ❌ |
| 검색 랭킹 알고리즘 | ❌ |
| 뱃지 시스템 | ❌ |
| 학원-선생님 초대 | ❌ |
| 자녀 본인 계정 전환 | ❌ |
| 데이터 마이그레이션 (Student -> ClassMembership) | ❌ |
| 팔로우 시스템 UI | ❌ |

---

## 9. Claude 구현 가이드

### 9.1 핵심 Provider 설계

> Claude가 새 기능을 구현할 때 참조할 Provider 상세. `@riverpod` 어노테이션 사용 필수.

| Provider | 파라미터 | 반환 타입 | 설명 | 파일 |
|----------|---------|----------|------|------|
| authProvider | - | `AsyncValue<AuthUser?>` | 현재 로그인 사용자 | `features/auth/presentation/providers/auth_provider.dart` |
| userRoleProvider | - | `UserRole` | 현재 선택된 역할 | `features/auth/presentation/providers/user_role_provider.dart` |
| teacherClassesProvider | teacherId: String | `AsyncValue<List<LessonClass>>` | 선생님 클래스 목록 | `features/students/presentation/providers/lesson_class_providers.dart` |
| classMembershipsProvider | classId: String | `AsyncValue<List<StudentWithMembership>>` | 클래스별 학생 목록 | `features/students/presentation/providers/membership_providers.dart` |
| groupedStudentsProvider | teacherId: String | `AsyncValue<Map<LessonClass, List<StudentWithMembership>>>` | 클래스별 그룹화된 학생 | `features/students/presentation/providers/grouped_students_provider.dart` |
| childProfilesProvider | parentId: String | `AsyncValue<List<ChildProfile>>` | 학부모의 자녀 목록 | `features/parent_home/presentation/providers/child_profile_provider.dart` |
| selectedChildProfileProvider | - | `ChildProfile?` | 현재 선택된 자녀 | `features/parent_home/presentation/providers/child_profile_provider.dart` |
| teacherExtendedProfileProvider | teacherId: String | `AsyncValue<TeacherProfile>` | 선생님 확장 프로필 | `features/profile/presentation/providers/teacher_extended_profile_provider.dart` |
| inviteProvider | - | `InviteState` | 초대 코드 생성/검증 | `features/profile/presentation/providers/invite_provider.dart` |
| teacherSearchProvider | filter: SearchFilter | `AsyncValue<List<Teacher>>` | 선생님 검색 결과 | `features/search/presentation/providers/teacher_search_provider.dart` |

### 9.2 구현 파일-코드 매핑 (미구현 기능)

Claude가 미구현 기능을 구현할 때 생성해야 할 파일 목록.

#### 팔로우 시스템 (Follow)

| 계층 | 파일 | 상태 |
|------|------|:----:|
| Entity | `features/relationship/domain/entities/follow.dart` | 생성 필요 |
| Repository | `features/relationship/domain/repositories/follow_repository.dart` | 생성 필요 |
| Repository (Mock) | `features/relationship/data/repositories/mock_follow_repository.dart` | 생성 필요 |
| Provider | `features/relationship/presentation/providers/follow_provider.dart` | 생성 필요 |
| Screen | `features/relationship/presentation/screens/followers_screen.dart` | 생성 필요 |

#### 리뷰 시스템 (Review)

| 계층 | 파일 | 상태 |
|------|------|:----:|
| Entity | `features/profile/domain/entities/review.dart` | 정의 완료 |
| Repository | `features/profile/domain/repositories/review_repository.dart` | 생성 필요 |
| Repository (Mock) | `features/profile/data/repositories/mock_review_repository.dart` | 생성 필요 |
| Provider | `features/profile/presentation/providers/review_provider.dart` | 생성 필요 |
| Screen (작성) | `features/profile/presentation/screens/review_write_screen.dart` | 생성 필요 |
| Screen (목록) | `features/profile/presentation/screens/review_list_screen.dart` | 생성 필요 |

#### 자격증 인증 시스템

| 계층 | 파일 | 상태 |
|------|------|:----:|
| Entity | `features/profile/domain/entities/certificate.dart` | 정의 완료 (teacher_profile.dart 내) |
| Provider | `features/profile/presentation/providers/certificate_provider.dart` | 생성 필요 |
| Screen | `features/profile/presentation/screens/certificate_edit_screen.dart` | 구현 완료 (업로드/검토 로직 미구현) |

#### 수강권 자동 전환 (백엔드 의존)

| 계층 | 파일 | 상태 |
|------|------|:----:|
| Entity | `features/relationship/domain/entities/teacher_student_relation.dart` | 정의 완료 |
| Repository | `features/relationship/domain/repositories/teacher_student_relation_repository.dart` | 정의 완료 |
| Repository (Remote) | `features/relationship/data/repositories/remote_teacher_student_relation_repository.dart` | 정의 완료 |
| Provider | `features/relationship/presentation/providers/relationship_providers.dart` | 정의 완료 |
| 자동 전환 로직 | 백엔드 cron/trigger 필요 | 미구현 |

---

## 10. 관련 스펙

| 문서 | 경로 | 설명 |
|------|------|------|
| 연습 시스템 마스터 | `specs/practice/practice_master.md` | 연습/녹음/레퍼토리 통합 마스터 |
| 학부모 시스템 | `specs/user/parent_system.md` | 학부모 상세 (본 문서에 통합) |
| 학부모 대시보드 | `specs/user/parent_dashboard_spec.md` | 대시보드 상세 (본 문서에 통합) |
| 학부모 로그인 | `specs/user/parent_login_flow.md` | 로그인 플로우 (본 문서에 통합) |
| 선생님 등록 | `specs/user/teacher_registration.md` | 선생님 온보딩 (본 문서에 통합) |
| 학생 클래스 | `specs/student/student_class_system.md` | 클래스 시스템 (본 문서에 통합) |
| 초대 시스템 v2 | `specs/lesson/invite/invite_system_v2.md` | 초대 시스템 (본 문서에 통합) |
| 수강권 관계 | `specs/lesson/invite/subscription_based_relationship.md` | 관계 모델 (본 문서에 통합) |
| 리뷰 시스템 | `specs/review/review_system.md` | 리뷰 시스템 (본 문서에 통합) |
| 체험 레슨 | `specs/trial/trial_lesson_system.md` | 체험 레슨 (본 문서에 통합) |
| Google SSO | `specs/auth/google_sso_setup_guide.md` | SSO 설정 가이드 (본 문서에 통합) |
| 3자 관계 | `specs/lesson/three_party_relationship_spec.md` | 학원-선생님-학생 관계 상세 |
| 수강권 시스템 | `specs/subscription/subscription_system_spec.md` | 수강권 비즈니스 로직 상세 |
| 수강료 입금 정책 | `specs/subscription/payment_architecture.md` | 무통장입금 정책, 앱 사용료 결제는 향후 별도 스펙 |
| 알림 시스템 | `specs/notification/notification_system.md` | 알림 상세 |
| 앱 사용 플로우 | `specs/_archive/old/flow_with_app.md` | 신규/재등록/앱 전환 플로우 (아카이브됨, lesson_master.md 참조) |

---

## 11. 용어 사전 (Glossary)

> 본 문서에서 사용하는 핵심 용어의 정의. 혼동하기 쉬운 용어를 명확히 구분.

| 용어 | 정의 | 관련 Enum/Entity |
|------|------|------------------|
| **역할 (Role)** | 사용자의 앱 내 역할: 선생님/학생/학부모 | `UserRole` |
| **관계 (Relationship)** | 수강권 기반 선생님-학생 레슨 관계 | `RelationshipStatus` |
| **연결 (Connection)** | 앱 내 팔로우/초대 기술적 연결 상태 | `ConnectionStatus` |
| **팔로우 (Follow)** | 소식 구독 (레슨 관계와 무관, 일방향) | `Follow` entity |
| **수강권 (Subscription)** | 레슨 이용권 (기간제/회차제) | `Subscription` entity |
| **클래스 (LessonClass)** | 선생님의 레슨 소속 그룹 (학원/개인) | `LessonClass` entity |
| **멤버십 (ClassMembership)** | 학생의 클래스 소속 관계 | `ClassMembership` entity |
| **자녀 프로필 (ChildProfile)** | 만 14세 미만 학부모 종속 프로필 | `ChildProfile` entity |
| **자녀 연결 (ChildConnection)** | 자녀 프로필의 선생님 연결 상태 | `ChildConnectionStatus` |
| **수기 학생** | 앱 미사용, 선생님이 직접 등록한 학생 | `ConnectionStatus.offline` |
| **프로필 전환** | 학부모/학생/자녀 간 역할 전환 | `ProfileSwitcher` widget |

---

## 12. 변경 이력

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| 1.1 | 2026-03-07 | Enum 정식 정의 추가 (UserRole, RelationshipStatus dart 코드 블록) |
| | | 경쟁사 대비 차별점 섹션 추가 (1.2) |
| | | ConnectionStatus vs RelationshipStatus 용어 명확화 추가 |
| | | Claude 구현 가이드 섹션 추가 (9장) - Provider 설계 상세, 미구현 파일 매핑 |
| | | 용어 사전 (Glossary) 섹션 추가 (11장) |
| | | 관련 스펙에 practice_master.md 참조 추가 |
| 1.0 | 2026-03-06 | 초안 -- 10개 스펙 파일 통합 마스터 스펙 작성 |
