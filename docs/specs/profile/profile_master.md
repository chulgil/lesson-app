# 프로필 마스터 스펙

> 마지막 업데이트: 2026-06-12
> 구현 상태: ✅ 구현 완료 (10x Vision 진행 중)
> 관련 코드: `features/profile/`

---

## 1. 개요

선생님 프로필 관리, 확장 프로필(경력/자격/학력), 초대 시스템, 리뷰, 수강권 입금 상태 화면 제공.

**핵심 설계 원칙 (2026-04-16 10x Vision)**:
- 24개 메뉴 탐색 압박 해소 → **자주 쓰는 3개 바로가기 카드** 상단 배치
- 팔로워 수 → **입금대기(후불) 통계**로 교체 (선생님 실용성)
- 프로필 미리보기를 **상단 CTA**로 승격
- **프로필 완성도 게이지** 추가 (0~100%) — 신규 선생님 온보딩 독려
- 섹션 순서: 자주 쓰는 것 먼저 (수강권·입금 → 레슨 운영 → 내 소개)

---

## 2. 화면 구조

### 2.1 선생님 프로필 탭 (TO-BE — 5묶음 IA, 2026-06-12 채택)

teacher-settings-redesign 머지 결과 — 11개 메뉴를 5묶음 카테고리 IA 로 통합.
근거: `.harness/spec/2026-06-11-teacher-settings-redesign.md` §3 + §7.2.

**순서**:

| 순서 | 섹션 | 설명 |
|:---:|------|------|
| 1 | 프로필 헤더 | 이름, 악기, 소개 |
| 2 | **⭐ 프로필 미리보기 CTA** | [🎭 내 프로필 미리보기 →] 버튼 (최상단) |
| 3 | **⭐ 통계 (학생·레슨·입금대기(후불))** | 팔로워 → 입금대기(후불)로 교체 |
| 4 | **⭐ 프로필 완성도 게이지** | 0~100% (퀘스트 100% = 게이지 100% — `teacher_quest_audit_2026-06-08.md` §9.3) |
| 5 | **⭐ 자주 쓰는 설정 (3개 카드)** | 가용시간 · 입금대기(후불) · 수강권 템플릿 |
| 6 | **🕐 운영시간** | `TeacherAvailabilitySplitPage` 직접 라우트 (`features/schedule/`) |
| 7 | **🎓 수업방식** | `LessonStyleSettingsScreen` 직접 라우트 (W3) |
| 8 | **💰 수강권·정산** | 행 탭 → BottomSheet (수강권 템플릿 · 입금대기 · 입금 계좌) |
| 9 | **👤 내 프로필** | `BasicInfoEditScreen` 직접 라우트 |
| 10 | **⚙️ 정책·알림·지원** | 행 탭 → BottomSheet (정책 · 템플릿 · 알림 · 녹음 · 공개 · 지원 · 계정) |

**카드 상태 라벨** (§11.1):
- 운영시간: 슬롯+쉬는시간 → "설정완료" / 부분 → "미설정" 노란 점
- 수업방식: 3 항목 (`lessonDurationMinutes` · `minBookingHours` · `bookingGuidanceMessage`) → "N/3 항목"
- 수강권·정산: 가격표+계좌 → "설정완료" / 부분 → 노란 점
- 내 프로필: 이름·사진·악기 → "N/M 항목"
- 정책·알림·지원: 항상 "기본값" (선택적 설정)

**마이그레이션 (기존 가입자)** — `teacher-settings-redesign.md` §10:
- ProfileTab 첫 진입 시 `OnboardingCategoryPreviewScreen` 1회 overlay 재활용
- 새 5묶음 카드에 NEW 점 7일 표시 (`category_new_badge_provider`, `kCategoryNewBadgeWindow = 7d`)
- 한 번 카드 진입 시 즉시 dismiss

### 2.2 프로필 완성도 게이지 (신규)

**목적**: 신규 선생님이 학생을 초대하기 전에 필수 프로필을 완성하도록 유도.

**완성도 계산 (100%)**:

| 항목 | 가중치 | 기준 |
|------|:------:|------|
| 프로필 사진 | 20% | 업로드됨 |
| 자기소개 | 20% | 20자 이상 |
| 악기 | 15% | 1개 이상 |
| 가용시간 설정 | 15% | 주간 스케줄 1개 이상 |
| 수강권 템플릿 | 10% | 1개 이상 |
| 입금 계좌 | 10% | 등록됨 |
| 경력·학력 | 10% | 1개 이상 |

**UI**:
```
프로필 완성도   60%
▓▓▓▓▓▓░░░░░░░░░░
다음: 가용시간을 설정해보세요 →
```

**표시 조건**:
- 100% 미만일 때만 표시
- 100% 달성 시 축하 메시지 후 다음 세션부터 숨김

### 2.3 자주 쓰는 설정 카드 (3개)

**고정 3개**:
1. **가용시간** → TeacherAvailabilityScreen
2. **수강권 입금 상태** → Subscription status views
3. **수강권 템플릿** → ProposalSettingsScreen or SubscriptionTemplateListScreen

**카드 스타일**: 정사각형 3분할, 아이콘 + 라벨 + 현재 값 (있으면)

### 2.4 통계 (재정의)

**AS-IS**: 학생 수 · 이번달 레슨 · 팔로워
**TO-BE**: 학생 수 · 이번달 레슨 · **입금대기(후불)** (N건)

입금대기(후불) 0건일 때: "0건 ✓"

---

## 3. 기존 화면 (유지)

- **ProfilePreviewScreen**: 공개 프로필 미리보기 (학생 뷰)
- **BasicInfoEditScreen**: 기본 정보 편집 (5묶음 §9 진입점)
- **ExtendedProfileScreen**: 확장 프로필 (경력·자격·학력)
- **BankAccountEditScreen**: 계좌 관리 (5묶음 §8 BottomSheet 진입점)
- **Subscription status views**: 수강권 입금 상태 확인 (독립 결제 기능 아님)
- **TipTemplateManagementScreen**: 피드백 템플릿
- **TeacherAvailabilitySplitPage**: 운영시간 (5묶음 §6 진입점, `features/schedule/`)
- **LessonStyleSettingsScreen** (신규, W3): 수업방식 — `lessonDurationMinutes` + `minBookingHours` + `bookingGuidanceMessage` (5묶음 §7)
- **PriceTableScreen** (신규, W3): 가격표 — `LessonTimeSettingsScreen §6` 에서 분리 (5묶음 §8 BottomSheet 진입)
- **OnboardingCategoryPreviewScreen** (신규, W4): Step 2.5 5묶음 미리보기 (가입 직후 1회) + W6 마이그레이션 overlay 재활용

**Deprecated**:
- ~~LessonTimeSettingsScreen~~ — 2026-06 5묶음 IA 채택으로 라우트 deprecated. 가격표는 PriceTableScreen, 수업방식은 LessonStyleSettingsScreen 으로 분리.

---

## 4. 코드 위치

| 레이어 | 파일 | 비고 |
|--------|------|------|
| 엔티티 | `features/profile/domain/entities/` (12개: invite, review, teacher, teacher_profile 등) | |
| Repository 인터페이스 | `features/profile/domain/repositories/` (3개: teacher_profile, teacher, invite) | Mock 구현 포함 |
| Remote 구현체 | `features/onboarding/data/repositories/remote_teacher_profile_repository.dart` | cross-domain 재사용 |
| Remote 구현체 | `features/invite/data/repositories/remote_invite_repository.dart` | cross-domain 재사용 |
| Provider | `features/profile/presentation/providers/` (invite, profile, extended_profile 등 9개) | |
| 화면 | `features/profile/presentation/screens/` (15개) | |
| 위젯 | `features/profile/presentation/widgets/` | |

> **구조 참고**: Remote Repository가 `onboarding/`, `invite/` 도메인에 위치하는 것은 cross-domain 재사용 패턴. profile 도메인 내에 별도 data/ 계층을 두지 않는 것은 의도적 설계.

---

## 5. 구현 현황

| 기능 | 상태 | 비고 |
|------|:----:|------|
| 기본 섹션 구조 | 완료 | 2026-03 |
| BasicInfoEdit / ExtendedProfile | 완료 | |
| BankAccountEdit / OutstandingPayments | 완료 | 2026-03 |
| ProfilePreviewScreen | 완료 | 2026-03 |
| TipTemplate / LessonTime | 완료 | |
| **⭐ 프로필 완성도 게이지** | **진행 중** | 2026-04-16 |
| **⭐ 자주 쓰는 설정 카드** | **진행 중** | 2026-04-16 |
| **⭐ 통계 입금대기(후불) 교체** | **진행 중** | 2026-04-16 |
| **⭐ 미리보기 상단 CTA** | **진행 중** | 2026-04-16 |
| **⭐ 섹션 순서 재정렬** | **진행 중** | 2026-04-16 |

---

## 코드 반영 추가 (2026-06-03)

> 코드에는 존재하나 §3 기존 화면 목록에 누락되었던 항목 (코드→스펙 단방향 반영). 출처: `features/profile/`.

### A. 누락 화면 (코드 반영 2026-06-03)

| 화면 | 파일 | 설명 |
|------|------|------|
| `CancellationDefaultsScreen` | `presentation/screens/cancellation_defaults_screen.dart` | 취소/노쇼 기본 정책 설정 |
| `InstrumentManagementScreen` | `presentation/screens/instrument_management_screen.dart` | 가르치는 악기 추가/제거/순서 |
| `RepertoireManagementScreen` | `presentation/screens/repertoire_management_screen.dart` | 레퍼토리 관리 |
| `ProfileVisibilityScreen` | `presentation/screens/profile_visibility_screen.dart` | 공개 프로필 항목별 노출 설정 |
| `FeedbackTemplateManagementScreen` | `presentation/screens/feedback_template_management_screen.dart` | 피드백 템플릿 관리 — [feedback_template_management.md](feedback_template_management.md) |
| `InvitePendingListScreen` | `presentation/screens/invite_pending_list_screen.dart` | 대기 중 초대 목록 |

### B. 누락 엔티티 (코드 반영 2026-06-03)

| 엔티티/enum | 파일 | 핵심 필드 |
|------|------|------|
| `CancellationDefaults` | `domain/entities/cancellation_defaults.dart` | cancellationDeadlineHours, studentCompensationExtraMinutesEnabled, includeExtraMinutesTextOnLateCancel, studentCompensationExtraMinutesMessage?, notifyOwnerOnLateCancel |
| `PendingInvite` | `domain/entities/pending_invite.dart` | 대기 초대 표시용 |
| `VerificationBadge` (enum) | `domain/entities/teacher_profile.dart` | phoneVerified / certified / premium — user_master §2.2 배지 시스템의 enum 정의 |

### C. 누락 위젯 (코드 반영 2026-06-03)

| 위젯 | 파일 | 설명 |
|------|------|------|
| `VerificationBadgeChip` | `presentation/widgets/verification_badge_chip.dart` | `VerificationBadge` 3종(phoneVerified/certified/premium) 칩 렌더링. 학생/학부모 노출 — [phone_verification_policy.md §5.4](../user/phone_verification_policy.md) |

### D. 누락 Provider (코드 반영 2026-06-03)

> 소스: `presentation/providers/`

| Provider | 용도 |
|----------|------|
| `cancellationDefaultsProvider` | 취소 기본 정책 조회/CRUD |
| `backgroundImageProvider` | 프로필 배경 이미지 |
| `profileImageProvider` | 프로필 이미지 — [profile_image_spec.md](profile_image_spec.md) |
| `invitePendingProvider` | 대기 초대 목록 |
| `teacherExtendedProfileProvider` | 확장 프로필(경력/자격/학력) |

### E. CancellationDefaults 로컬 영속성 정책 (2026-06-04 명시)

`CancellationDefaults` 는 BE 엔드포인트가 없는 동안 **Hive 로컬 저장** 으로 동작한다 — `LocalCancellationDefaultsRepository` (`data/repositories/local_cancellation_defaults_repository.dart`).

| 항목 | 정책 |
|------|------|
| 저장 위치 | Hive box `cancellation_defaults` — 사용자별 key scoping (`teacher:<userId>:cancellation_defaults`) |
| 수명 | 앱 재시작 후에도 유지 (MockRepository 와 달리 영속) |
| BE 마이그레이션 시점 | #5 D-G3 에서 `RemoteCancellationDefaultsRepository` 추가 + Mock/Local 토글. 마이그레이션 직후 한 번만 local → remote sync (사용자 첫 BE 호출 시) |
| Conflict 처리 | BE 응답이 우선. local 만 가지고 있던 값은 sync 후 BE 응답으로 덮어쓰기 |

> 정책 사유: 취소 기본값은 사용자가 한 번 설정하면 자주 바뀌지 않으므로 로컬 캐시가 합리적. BE 미도입 기간에도 사용자 경험을 유지하기 위해 Mock 대신 Local 사용.

### F. ProfileVisibilitySettings 저장 메커니즘 (2026-06-04 명시)

`ProfileVisibilityScreen` 의 토글 상태는 `TeacherProfile.visibilitySettings` 필드(`ProfileVisibilitySettings` 값 객체)로 저장. `updateVisibilitySettings()` provider 액션이 BE PUT 호출 → 성공 시 캐시 invalidate.

| 필드 | 정책 |
|------|------|
| `showEducation` / `showCareer` / `showCertificates` / `showRepertoire` / `showReviews` | 토글 — 기본값 모두 true |
| `showPhoneNumber` | 학생/학부모에게 노출 — 기본값 false (개인정보 보호) |
| 저장 위치 | BE — `PUT /teachers/me/visibility` (mock 동일 인터페이스) |
| Optimistic update | 미적용 — BE 응답 대기 후 state 반영 (실패 시 토글 원복) |

### G. LessonTimeSettingsScreen — 해체 완료 (W2 Task 2.5, 2026-06-12 갱신)

> **진입점 현황**: `LessonTimeSettingsScreen` 클래스 및 파일은 W2 Task 2.5에서 해체됨. 화면 파일 없음.

| 항목 | 현황 |
|------|------|
| 클래스 파일 | 삭제됨 (`lesson_time_settings_screen.dart` 미존재) |
| 라우트 `/profile/lesson-time` | `redirect → AppRoutes.profile` (ProfileTab으로 무음 redirect) |
| 편집 진입점 | 5묶음 ProfileTab (각 항목별 SSOT) + `LessonStyleSettingsScreen`(§6.2) |
| 기존 push 호출처 | `quest_board_card.dart`, `lesson_policy_screen.dart` — 모두 redirect 경유 ProfileTab 도달 |

**SSOT 결정 (P1 #5)**: 레슨 시간 관련 설정의 편집 UI 는 단일 화면에 집중되지 않는다.
각 설정 항목은 5묶음 ProfileTab 내 해당 섹션이 **항목별 SSOT** 이며, 동일 편집 UI 를 별도 화면에 중복 배치하는 것은 금지 패턴 #19 (SSOT 위반) 에 해당한다.
`/profile/lesson-time` 경로로 진입하는 모든 호출은 redirect 를 통해 ProfileTab 으로 이동하며, 독립적인 레슨 시간 편집 전용 화면은 존재하지 않는다.

**구 화면 필드 분산 위치** (참고):

| 구 필드 | 현재 편집 위치 |
|---------|--------------|
| `defaultDurationMinutes` | `LessonStyleSettingsScreen` (§6.2, `/profile/lesson-style`) |
| `breakMinutes` | `LessonStyleSettingsScreen` (§6.2) |
| `minBookingHours` | `LessonStyleSettingsScreen` (§6.2) |
| `timezone` | `LessonStyleSettingsScreen` (§6.2) |
| `guideMessage` | `LessonStyleSettingsScreen` (§6.2) |
| `trialPolicy` | `LessonStyleSettingsScreen` (§6.2) |
| `pricingNote` | `PriceTableScreen` (§6.3, `/profile/price-table`) |

**저장 흐름 (불변):** `teacherSettingsNotifierProvider.update*()` 호출 → `RemoteSettingsRepository` 가 BE 호출 + availability mirror best-effort. 성공 시 `teacherSettingsProvider` invalidate.

---

## 6. 관련 마스터 스펙

- 초대: [user_master.md §3](../user/user_master.md)
- 리뷰: [user_master.md §6](../user/user_master.md)
- UX 원칙: [ux_guidelines.md](../design/ux_guidelines.md)

---

## 7. 변경 이력

| 날짜 | 변경 |
|------|------|
| 2026-06-12 | §G LessonTimeSettingsScreen 해체 확정 (P1 #5 SSOT 감사) — 진입점 현황 갱신, 5묶음 항목별 SSOT 결정 명시, 구 필드 분산 위치 표 추가 |
| 2026-06-04 | §E CancellationDefaults Hive 영속성 정책 명시 (LocalCancellationDefaultsRepository, BE 마이그레이션 시점 sync 규칙). §F ProfileVisibilitySettings 저장 메커니즘 (필드별 기본값, optimistic update 미적용). §G LessonTimeSettingsScreen 화면 구조 (7개 필드, cross-domain teacherSettings 소비) |
| 2026-06-03 | 코드 반영 — 누락 화면 6종, 엔티티 3종(CancellationDefaults/PendingInvite/VerificationBadge), VerificationBadgeChip 위젯, Provider 5종 추가 |
| 2026-04-16 | 10x Vision UX 개선 — 완성도 게이지, 바로가기 카드, 통계 재정의, 섹션 순서 변경 |
| 2026-04-15 | 계좌 관리, 입금대기(후불), 미리보기 화면 추가 |
| 2026-03-12 | 초기 스펙 작성 |
