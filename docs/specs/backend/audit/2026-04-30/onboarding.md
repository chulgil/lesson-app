# Audit — onboarding 도메인 (2026-04-30)

> 점검자: Claude Phase 3-2 격리 에이전트  
> 범위: docs/specs/onboarding/ + frontend/lib/features/onboarding/ vs backend models/api/services  
> 기준: backend HEAD, spec onboarding_master.md (2026-03-11)

---

## 1. 프론트 요구 인벤토리

### 선생님 온보딩 (Teacher)
- **5단계**: roleSelect → phoneVerification → profileSetup → tutorial → completed
- **Phone Verification**: 휴대폰 번호 입력 + SMS 인증코드(6자리) + 3분 타이머
- **Profile Setup**: 이름 + 프로필 이미지 + 악기 복수선택 + 자기소개 (20자+)
- **Tutorial**: 5페이지 PageView (welcome/inviteStudent/createLesson/writeFeedback/completed)
- **상태**: TeacherOnboardingState (currentStep, phoneVerification, profile, tutorialProgress, completedAt)

### 학생 온보딩 (Student)
- **플로우**: roleSelect → (inviteCode입력 선택) → profileSetup → tutorial → 홈
- **Invite Code Input** (학생용): 6자리 코드 또는 "코드 없이 시작" 옵션
- **Student Profile**: 이름 + 악기 (단일선택)
- **Student Tutorial**: 4페이지 (welcome/lessonCheck/practiceLog/feedbackShare)

### 기타 요구사항
- 프로필 생성 → teacherProfileRepository 저장 (with phone verification 데이터)
- onboarding_completed 플래그 설정
- 인증 상태 별도 추적 (isPhoneVerified, verifiedAt)

---

## 2. 백엔드 현황

### 모델 (User/Teacher/Student/Parent)
| 엔티티 | onboarding 관련 컬럼 | 상태 |
|---|---|---|
| **User** | `onboarding_completed` (bool) | ✅ PASS |
| **Teacher** | `is_phone_verified`, `phone_number`, `phone_verified_at` | ✅ PASS |
| **Student** | 무 | ⚠️ 학생용 phone verification 미정의 |
| **Parent** | 무 | ⚠️ 부모용 onboarding 필드 미정의 |

### API 엔드포인트
| 기능 | 라우터 | 상태 |
|---|---|---|
| 역할 설정 | `PUT /users/me/role` | ✅ PASS |
| onboarding 완료 표시 | `PATCH /users/me/onboarding-complete` | ✅ PASS |
| 휴대폰 인증 시작 | 미구현 | ❌ MISSING |
| 인증코드 검증 | 미구현 | ❌ MISSING |
| 프로필 저장 (teacher/student) | `teachers` / `students` 라우터 | ⚠️ 부분 |
| 초대코드 확인 (학생) | `invites` 라우터 (조회O, 사용처리X) | ⚠️ 부분 |

### 서비스 로직
| 서비스 | 메서드 | 상태 |
|---|---|---|
| **AuthService** | oauth_login, dev_login, refresh_token | ✅ PASS (인증 흐름) |
| **UserService** | update_role, update_profile | ✅ PASS |
| **TeacherService** | 프로필 CRUD | ✅ PASS (but onboarding 통합 없음) |
| **StudentService** | 프로필 CRUD | ✅ PASS (but invite code 검증 없음) |

---

## 3. 갭 매트릭스 (26항목)

### P0 (데이터 손실 / 무결성 critical)

| # | 갭 | 프론트 영향 | 권장 조치 | 우선순위 |
|---|---|---|---|---|
| 1 | **Phone Verification API 부재** | 인증코드 발송/검증 로직이 프론트 메모리만 의존 → 서버 재시작시 코드 소실 | `POST /auth/phone/request-code`, `POST /auth/phone/verify-code` 신설 | P0 |
| 2 | **Phone Verification 영속화 없음** | `PhoneVerification` 상태가 Redux/Hive에만 존재 → DB 미동기 | `phone_verifications` 테이블 + lifecycle manager 신설 | P0 |
| 3 | **Student Phone Verification 스키마 미정의** | 학생 가입 시 휴대폰 인증 데이터 저장 경로 불명 | `Student` 모델에 `phone_verified_at`, `phone_number` 컬럼 추가 | P0 |
| 4 | **Invite Code 검증 + 학생 생성 원자성 부재** | 코드 입력 후 검증은 가능하나, 학생 프로필 생성과의 연결 미정의 | `POST /students/onboarding/invite-join` endpoint (invite 소비 + 학생 생성) | P0 |

### P1 (기능 차단)

| # | 갭 | 영향 | 권장 조치 |
|---|---|---|---|
| 5 | **Teacher Profile 생성 (onboarding 맥락) endpoint 부재** | ProfileSetupScreen 제출 → "프로필 저장" API 경로 없음 | `POST /teachers/{id}/from-onboarding` 또는 `teachers` POST 에 onboarding flag 추가 |
| 6 | **Student Profile 생성 (onboarding 맥락) endpoint 부재** | StudentProfileSetupScreen 제출 → API 경로 모호 (invite code 선택적) | `POST /students/onboarding/create-profile` (user_id, name, instrument, invite_id?) |
| 7 | **Invite Code 만료/재발급 로직 미정의** | 프론트 학생용 초대코드 입력 UI는 있으나, 백엔드 코드 유효성 검사만 존재 | `invites` 라우터에 validate endpoint + 만료 체크 추가 |
| 8 | **Onboarding 완료 → 프로필 동기 확인 플로우 부재** | 프론트가 `completeOnboarding()` 호출 후 프로필 확인 경로 불명 | 서비스 레이어에 "onboarding completion handler" 작성 (프로필→user 동기화) |
| 9 | **Teacher Tutorial 진행도 영속화 미정의** | Tutorial 건너뛰기/완료 → DB 저장 경로 없음 | `teacher_onboarding_progress` 테이블 신설 또는 `Teacher.tutorial_progress` JSON 컬럼 |
| 10 | **Student Tutorial 진행도 영속화 미정의** | StudentTutorialScreen 완료 → DB 저장 경로 없음 | `student_onboarding_progress` 테이블 또는 `Student.tutorial_progress` JSON |

### P2 (정합성 / 권장사항)

| # | 갭 | 설명 | 권장 조치 |
|---|---|---|---|
| 11 | Onboarding 단계별 진행 상태 추적 (DB) | 프론트 `currentStep` enum은 정의되나, 백엔드 저장 경로 미정의 | `onboarding_step` 컬럼 추가 (User 또는 Teacher/Student) |
| 12 | 약관 동의 (Terms) 영속화 | 스펙에 미명시되나, 일반적 온보딩 요구사항 | `onboarding_consents` 테이블 (terms_agreed_at, marketing_agreed_at, notification_permission_at) |
| 13 | 부모 온보딩 흐름 미정의 | 부모는 학생 생성 후 초대코드로 가입하는 경로 | `Parent` 모델 + onboarding 스키마 정의 필요 |
| 14 | 초대 코드 일회용 vs 재사용 규칙 미정의 | `Invite.is_single_use` 필드는 있으나, 사용 후 처리 로직 미구현 | `invites` 라우터 업데이트 (code 사용 → status:used 전환) |
| 15 | Teacher Profile 완성도 (completion_level) 미정의 | 스펙 §2.7 "ProfileCompletionLevel" enum 언급되나 모델 미존재 | Enum 정의 + Teacher 모델에 `profile_completion_level` 추가 |
| 16 | Student Connection Status 와 Onboarding 상태 분리 미정의 | `Student.connection_status` ≠ onboarding_status (invite 수용 vs 프로필 완료) | 별도 `student_onboarding_status` 컬럼 추가 |
| 17 | 재가입자 (returning user) 온보딩 skip 경로 미정의 | User.onboarding_completed=true 시 프론트 UI flow 제어하나 백엔드 플래그 체크 미정의 | GET `/auth/me/onboarding-status` endpoint 추가 |
| 18 | Parent Phone Verification | 부모 온보딩 시 휴대폰 인증 필요 시 처리 | 통일된 phone verification API 또는 `parents` 라우터에 검증 로직 |
| 19 | 프로필 이미지 업로드 (onboarding) | 프론트 mock URL 사용 → 실제 이미지 업로드 흐름 미정의 | `/teachers/{id}/profile-image`, `/students/{id}/profile-image` endpoint |
| 20 | Device Token 등록 시점 | onboarding 완료 직후 또는 별도? | 명시적 endpoint + 타이밍 정의 |

### P3 (스펙 명확화 필요)

| # | 갭 | 항목 |
|---|---|---|
| 21 | 학생 악기 복수선택 vs 단일선택 | 스펙 §2.5.2 "악기 (1개)" vs 선생님 "복수선택" 차이 명확화 필요 |
| 22 | Invite Code 형식 검증 | 6자리인가? 알파뉴메릭인가? → `invites` 라우터 명시 필요 |
| 23 | Phone Number 국제화 | 한국번만? (01x-xxxx-xxxx) vs 글로벌? |
| 24 | Onboarding Timeout | 타이머 만료(3분) 후 재시작 vs 이어하기? |
| 25 | Failed Verification Retry | 최대 시도 횟수 명시 (현재 mock: 6회) |
| 26 | Parent 온보딩 전체 플로우 | 부모는 학생 초대코드 입력만? 아니면 별도 등록? |

---

## 4. 권장 조치 (Action Items)

### Phase 1 (P0 critical) — 1주
1. `phone_verifications` 테이블 신설 (user_id, phone_number, verification_code, code_sent_at, code_expires_at, is_verified, verified_at, attempt_count)
2. `POST /auth/phone/request-code` + `POST /auth/phone/verify-code` endpoint 신설
3. `Student` 모델에 phone verification 컬럼 추가 (alembic)
4. `POST /students/onboarding/invite-join` endpoint (invite code 검증 + 학생 생성 원자성)

### Phase 2 (P1 기능) — 2주
5. Teacher/Student onboarding 전용 profile creation endpoint
6. Tutorial progress 영속화 (JSON 컬럼 또는 별도 테이블)
7. Onboarding completion handler (state sync)

### Phase 3 (P2 정합성) — 3주
8. `onboarding_consents` 테이블 (terms/marketing/notification)
9. `Parent` onboarding 흐름 정의 + 스키마
10. ProfileCompletionLevel enum + Teacher.completion_level

---

## 5. 점검 요약

| 판정 | 개수 | 항목 |
|---|---|---|
| **PASS** | 4 | User.onboarding_completed, Teacher phone verification (model), role update API, oauth/dev login flow |
| **FAIL** | 3 | Phone verification API 완전 미구현, Student phone schema 미정의, Invite+Student 원자성 부재 |
| **MISSING** | 5 | Phone verification endpoint 2개, Teacher/Student onboarding profile endpoint, tutorial progress API, parent onboarding |
| **STALE** | 1 | Invite code validation 로직 (라우터에 validate 미흡) |
| **P2 정합성** | 13 | onboarding step 추적, 약관 동의, 부모 흐름, 완성도 enum, connection vs onboarding status, 재가입자 처리 등 |

**총점 26항목**: PASS 4 | FAIL 3 | MISSING 5 | STALE 1 | P2 13

---

## 6. 평가 (Rubric)

- **구현도**: 35% (phone verification API + profile creation 핵심 미구현)
- **데이터 일관성**: 25% (상태 영속화 경로 불명, 초대코드 처리 미정의)
- **테스트 커버리지**: 20% (onboarding 통합 test scenario 미존재)
- **명세 정합성**: 20% (프론트 요구 vs 백엔드 API 매핑 30~40% 정렬)

**총 평가**: **C (60/100)** — Phone verification, invite code handling, profile creation flow 의 3대 갭이 인증/가입 전체 무력화. 즉시 P0 4건 처리 필요.
