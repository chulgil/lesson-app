# 학원(Academy) 앱 마스터 스펙

> 구현 상태: 🟡 앱 FE 골격 구현 (모든 Repository는 Mock — BE 미연동)
> Last updated: 2026-06-03 신설(코드 역공학)
> 관련 코드: `frontend/lib/features/academy/`

---

## 1. 개요

학원(Academy) 도메인의 **Flutter 앱(FE) 측** 마스터 스펙. 학원 기본 정보, 강사/학원장 소속(member), 학원 학생, 학원 귀속 수강권, 강사 공개 페이지 노출 동의, 학원 공지/문의, 강사 시점 활동 타임라인, 학원장 일괄 휴강을 다룬다.

본 문서는 **앱 feature 코드를 역공학**하여 작성됐다. 학원의 데이터 SoR(Source of Record)은 백엔드이며, 웹 콘솔/공개 페이지 관점의 기획·정책은 [web/academy](../web/academy/README.md) 스펙군이 SSOT다. 본 문서는 앱 코드에 실제로 존재하는 엔티티/enum/Repository 계약/Provider/라우트를 정확히 기술하고, 정책 배경은 web/academy로 링크한다.

> **현재 모든 학원 Repository는 Mock 구현이다.** 본문에서 "BE 대기"로 표기한 항목은 Remote(backend) 연동이 추가되어야 실데이터로 동작한다. web/academy 기준 mock→remote 전환 작업(AC-M1~M3)이 선행되어야 한다.

★ **과금 정책**: 앱은 선생님/학원(사용자)에게만 과금한다. 학원-학생 간 수강료는 PG를 사용하지 않으며 무통장입금 기준이다. `AcademySubscription`은 결제 수단이 아니라 **수강권 귀속/취소 정책 보유 단위**다.

---

## 2. 주요 기능

### 2.1 학원 기본 정보 / 소속 / 학생
- `Academy` 기본 정보 조회, 소속 멤버(강사/학원장) 목록, 학원 학생 목록 (`AcademyRepository`)
- 멤버 역할: `owner`(학원장) / `teacher`(강사) (`AcademyMemberRole`)
- 학생 상태 라이프사이클: 대기 → 매칭 → 활동 → 일시정지 → 졸업 (`AcademyStudentStatus`)

### 2.2 강사 초대 흐름
- 토큰 기반 초대 미리보기 → 수락(공개 페이지 노출 동의 포함)/거절 (`AcademyInviteRepository`, `AcademyMemberRepository`)
- 라우트: `/academy/accept`, `/academy/expired`

### 2.3 학원 귀속 수강권
- 수강권 귀속 주체: `academy`(학원 귀속) / `teacher`(강사 귀속) (`SubscriptionOwnership`)
- 강사 사유 취소 정책 보유: 취소 기준 시간, 학생 보상 추가 시간, 학원장 알림 등 (`AcademySubscription`)
- 정책 배경: web/academy [academy_schedule_authority_spec.md](../web/academy/academy_schedule_authority_spec.md), [teacher_cancellation_policy_spec.md](../web/academy/teacher_cancellation_policy_spec.md)

### 2.4 강사 공개 페이지 노출 동의
- 강사가 소속 학원별로 공개 페이지 노출 동의를 토글 (`AcademyVisibilityRepository`)
- 정책 배경: web/academy [public_page_spec.md](../web/academy/public_page_spec.md), [context_toggle_spec.md](../web/academy/context_toggle_spec.md)

### 2.5 학원 공지 / 학부모 문의
- 학원 공지사항 수신·읽음 처리 (`AcademyAnnouncementRepository`)
- 학부모/학생 문의 등록·답변 스레드 (`AcademyInquiryRepository`)
- 정책 배경: web/academy [announcements_spec.md](../web/academy/announcements_spec.md), [inbox_spec.md](../web/academy/inbox_spec.md)

### 2.6 강사 시점 활동 타임라인
- 강사 본인이 행위 주체(actor)인 학원 활동 로그 타임라인 (`AcademyActivityRepository`, `AcademyActivityTimelineScreen`)

### 2.7 학원장 일괄 휴강 (G15)
- 학원장이 휴원일 지정 → 영향 레슨 자동 산출 → 1시간 의견 윈도우(강사 의견) → 적용 → 강사가 레슨별 보강 일정 입력 (`BulkClosure`)
- 정책 배경: web/academy [owner_bulk_closure_spec.md](../web/academy/owner_bulk_closure_spec.md)

---

## 3. 데이터 모델

### 3.1 엔티티

코드: `features/academy/domain/entities/`

| 엔티티 | 파일 | 주요 필드 |
|--------|------|----------|
| `Academy` | `academy.dart` | `id, slug, name, address?, ownerUserId, createdAt` |
| `AcademyMember` | `academy_member.dart` | `id, academyId, userId, role, publicPageConsent(기본 false), onboardingUntil?, createdAt` · getter `isOnboarding` (onboardingUntil이 미래면 true) |
| `AcademyStudent` | `academy_student.dart` | `id, academyId, studentUserId?, parentUserId?, teacherMemberId?, name, instrument?, status, registeredAt, matchedAt?` |
| `AcademySubscription` | `academy_subscription.dart` | `id, academyId, studentId, teacherMemberId, ownership, cancellationDeadlineHours(기본 12), studentCompensationExtraMinutesEnabled(기본 true), includeExtraMinutesTextOnLateCancel(기본 true), studentCompensationExtraMinutesMessage?, notifyOwnerOnLateCancel(기본 true), createdAt` |
| `AcademyAnnouncement` | `academy_announcement.dart` | `id, academyId, title, body, sentAt, isRead(기본 false)` |
| `AcademyInquiry` | `academy_inquiry.dart` | `id, academyId, senderRole, senderName, body, createdAt, replies: List<AcademyInquiryReply>` |
| `AcademyInquiryReply` | `academy_inquiry.dart` | `id, body, createdAt, isFromAcademy` |
| `AcademyActivityLog` | `academy_activity_log.dart` | `id, academyId, actorMemberId, actorName, actionType(String), description, createdAt` |
| `BulkClosure` | `bulk_closure.dart` | `id, academyId, closureDate, reason, status, opinionWindowEndsAt?, appliedAt?, affectedLessons: List<AffectedLesson>, teacherComment?` · getter `isOpinionWindowOpen`, `makeupCompletedCount` |
| `AffectedLesson` | `bulk_closure.dart` | `lessonId, studentId, studentName, originalStartAt, originalEndAt, makeupAt?` |
| `AcademyInvitePreview` (DTO) | `repositories/academy_invite_repository.dart` | `token, academy: Academy, ownerName, roles: List<String>` |
| `TeacherAcademyMembership` (DTO) | `repositories/academy_visibility_repository.dart` | `academyId, academyName, publicPageConsent` |

> 배럴: `domain/entities/entities.dart`, feature 공개 API: `academy.dart`

### 3.2 enum

| enum | 파일 | 값 |
|------|------|-----|
| `AcademyMemberRole` | `academy_enums.dart` | `owner`, `teacher` |
| `AcademyStudentStatus` | `academy_enums.dart` | `waiting`, `matched`, `active`, `paused`, `alumni` |
| `SubscriptionOwnership` | `academy_enums.dart` | `academy`, `teacher` |
| `LessonVisibility` | `academy_enums.dart` | `academyFull`, `academyBusyOnly` (glossary 등록 용어) |
| `InquirySenderRole` | `academy_inquiry.dart` | `student`, `parent` |
| `ClosureStatus` | `bulk_closure.dart` | `proposed`(의견 윈도우 진행), `applied`(보강 입력 대기), `makeupCompleted`(보강 완료), `cancelled` |

> `actionType`은 enum이 아니라 `AcademyActivityLog`의 String 필드다. UI(`AcademyActivityTimelineScreen`)가 처리하는 값: `lesson_created`, `subscription_issued`, `student_enrolled`, `lesson_completed`, `payment_confirmed`, `schedule_changed`, `note_added`, `lesson_request_accepted`, `makeup_recorded` (그 외는 unknown 처리).

---

## 4. Repository 계약

코드: `features/academy/domain/repositories/` (인터페이스), `features/academy/data/repositories/` (구현 — **모두 Mock, BE 대기**).
배럴: `domain/repositories/repositories.dart`. 구현은 8종 모두 `Mock*` 접두 클래스.

| Repository | 메서드 |
|-----------|--------|
| `AcademyRepository` | `getById(id) → Academy?`<br>`listMembers(academyId) → List<AcademyMember>`<br>`listStudents(academyId) → List<AcademyStudent>` |
| `AcademyMemberRepository` | `acceptInvite(token, {publicPageConsent}) → AcademyMember`<br>`rejectInvite(token) → void`<br>`updateVisibility(memberId, {publicPageConsent}) → void` |
| `AcademyInviteRepository` | `getInvitePreview(token) → AcademyInvitePreview`<br>`acceptInvite(token, {publicPageConsent}) → void`<br>`rejectInvite(token, {reason?}) → void`<br>(주석 기준 BE 엔드포인트: `GET /academy/invites/:token/preview`, `POST .../accept`, `POST .../reject`) |
| `AcademySubscriptionRepository` | `listByStudent(studentId) → List<AcademySubscription>`<br>`getById(id) → AcademySubscription?` |
| `AcademyVisibilityRepository` | `getTeacherAcademyConsent(academyId, teacherId) → bool`<br>`updateTeacherAcademyConsent(academyId, teacherId, consent) → bool`<br>`listTeacherAcademies(teacherId) → List<TeacherAcademyMembership>` |
| `AcademyAnnouncementRepository` | `listByAcademy(academyId) → List<AcademyAnnouncement>`<br>`markAsRead(announcementId) → void` |
| `AcademyInquiryRepository` | `listByAcademy(academyId) → List<AcademyInquiry>`<br>`getById(inquiryId) → AcademyInquiry`<br>`reply(inquiryId, body) → void`<br>`create({academyId, senderRole, senderName, body}) → String` |
| `AcademyActivityRepository` | `listByAcademyAndActor(academyId, actorMemberId) → List<AcademyActivityLog>` (createdAt 내림차순) |

> 합계: 8 Repository, 메서드 21개.

### 4.1 G15 일괄 휴강 — 강사 시점 FE 구현 (2026-06-04)

§2.7 의 강사 시점 흐름(휴강 안내 수신 → 1시간 의견 윈도우 → 적용 후 보강 입력) 이 FE 측에 구현됨. **학원장 작성/적용/취소 UI 는 web 콘솔에서 처리하며 lesson-app FE 책임이 아니다**. 정책 SSOT: [web/academy/owner_bulk_closure_spec.md §5](../web/academy/owner_bulk_closure_spec.md).

| 항목 | 코드 위치 | 비고 |
|------|----------|------|
| `BulkClosureRepository` 인터페이스 | `features/academy/domain/repositories/bulk_closure_repository.dart` | `listByTeacherMember`/`getById`/`submitTeacherOpinion`/`submitMakeupSchedule` |
| `MockBulkClosureRepository` 구현 | `features/academy/data/repositories/mock_bulk_closure_repository.dart` | BE 대기. seed: `addClosure(teacherMemberId, closure)` |
| Provider | `features/academy/presentation/providers/bulk_closure_provider.dart` | `bulkClosureRepositoryProvider`(keepAlive), `teacherBulkClosuresProvider(teacherMemberId)`, `bulkClosureDetailProvider(closureId)`, `bulkClosureNotifierProvider` |
| 휴강 상세 화면 (강사 의견 + 보강 진입) | `features/academy/presentation/screens/bulk_closure_detail_screen.dart` | status 분기 — proposed: 의견 입력 + 1h 카운트다운 / applied: 보강 입력 CTA / makeupCompleted·cancelled: 결과 요약 |
| 보강 입력 화면 | `features/schedule/presentation/screens/makeup_lesson_input_screen.dart` | 이미 존재. router 가 `BulkClosure` extra 로 받아서 보강 시각 일괄 입력 |
| 라우트 | `core/router/routes/academy_routes.dart` (신규) | `academyBulkClosureDetail` (`/academy/:academyId/closures/:closureId`), `academyMakeupInput` (`.../makeup`), `academyActivityTimeline` (`/academy/:academyId/teachers/:actorMemberId/activity`) |
| l10n 키 | `core/l10n/app_strings.dart` | `bulkClosure*` 16개 (제목/상태/카운트다운/의견/CTA/안내문) |
| 테스트 | `test/features/academy/bulk_closure_repository_test.dart` | 7개 — listByTeacherMember / 의견 윈도우 / 보강 일괄 저장 + 상태 전이 |

**enum 상태 매핑 (web ↔ FE):**

| web (`AcademyClosure.status`) | FE (`ClosureStatus`) | 강사 시점 의미 |
|---|---|---|
| `draft` / `preview` | (미노출) | 학원장이 작성 중 — 강사에게 미공개 |
| `teacher_grace` | `proposed` | 1시간 의견 윈도우 진행 |
| `applied` (강사 보강 미입력) | `applied` | 강사가 보강 일정 입력해야 함 |
| `applied` + 모든 영향 레슨 makeupAt | `makeupCompleted` | FE 측 파생 상태 |
| `cancelled` | `cancelled` | 학원장이 취소 |

**FE 책임 경계:**

- ❌ 학원장 휴강 작성/적용/취소: web 콘솔
- ❌ 학생 카톡/인앱 알림 발송: BE 잡 + notification 도메인
- ❌ 영향 레슨 enumerate: BE (`AcademyClosureAffectedLesson` 캐시) — FE 는 BE 가 제공한 `affectedLessons` 리스트만 표시
- ✅ 강사 의견 제출 (윈도우 내)
- ✅ 강사 보강 시각 일괄 입력 (status=applied 일 때)
- ✅ 영향 레슨 본인 시점 표시

---

## 5. Provider

코드: `features/academy/presentation/providers/`. Riverpod codegen(`@riverpod`/`@Riverpod(keepAlive:true)`) 기반. **repository provider는 모두 Mock 인스턴스를 반환** (BE 대기).

| Provider | 파일 | 종류 | 비고 |
|----------|------|------|------|
| `academyActivityRepositoryProvider` | `academy_activity_provider.dart` | `@Riverpod(keepAlive)` | `MockAcademyActivityRepository` 반환 |
| `academyActivityLogsProvider(academyId, actorMemberId)` | `academy_activity_provider.dart` | `@riverpod` family Future | 강사 시점 활동 로그 |
| `academyVisibilityRepositoryProvider` | `academy_visibility_provider.dart` | `@Riverpod(keepAlive)` | `MockAcademyVisibilityRepository` 반환 |
| `teacherAcademiesProvider(teacherId)` | `academy_visibility_provider.dart` | `@riverpod` family Future | 강사 소속 학원 목록 |
| `academyVisibilityNotifierProvider` | `academy_visibility_provider.dart` | `AsyncNotifier<void>` | `updateConsent(...)` 후 `teacherAcademiesProvider` invalidate |
| `academyDetailProvider` | `academy_detail_provider.dart` | (예약 파일) | 현재 내용 없음. `AcademyDetailScreen`은 search feature의 `academyInfoProvider`/`academyTeachersProvider` 사용 |

### 5.1 강사 초대 토큰 Provider (auth feature 안)

`AcademyInviteRepository` 의 진입 Provider 들은 도메인은 academy 이지만 코드 위치는 `features/auth/presentation/providers/academy_invite_provider.dart` 다. `AcademyInviteAcceptScreen`/`AcademyInviteExpiredScreen` 이 직접 사용한다.

| Provider | 종류 | 책임 |
|----------|------|------|
| `academyInviteRepositoryProvider` | `@riverpod` | `MockAcademyInviteRepository` 반환 (BE 대기) |
| `academyInvitePreviewProvider(token)` | `@riverpod` family Future | `getInvitePreview(token)` — 토큰 미리보기 (학원명/역할 등) |
| `academyInviteAcceptProvider(token)` | `@riverpod` family Future | `acceptInvite(token, publicPageConsent:false)` (현재 동의값 false 기본) |
| `academyInviteRejectProvider(token)` | `@riverpod` family Future | `rejectInvite(token)` — 거절 처리 |

**에러 분류 정책 (2026-06-04 확정):** `AcademyInviteAcceptScreen` 은 `getInvitePreview` 호출 시 발생한 예외 메시지를 다음 코드로 매핑한 뒤 화면 분기를 결정한다.

| 분류 | 트리거 메시지 패턴 | 처리 |
|------|-----------------|------|
| `expired` | "expired", "만료" 등 | `AcademyInviteExpiredScreen` 으로 redirect (`/academy/expired`) |
| `already_used` | "already used", "이미 사용" | accept 화면 안에서 안내 + 메인 복귀 버튼 |
| `not_found` | "not found", "찾을 수 없" | accept 화면 안에서 안내 + 메인 복귀 버튼 |

> 향후 BE 연동 시 Repository 메서드 시그니처를 `throws AcademyInviteError(code, message)` 같은 sealed exception 으로 좁히면 위 문자열 매칭을 제거할 수 있다.

### Facade
`academy_facade.dart`는 cross-feature 공개 경계로 다음만 export:
`AcademyVisibilityRepository`, `TeacherAcademyMembership`, `academyVisibilityNotifierProvider`, `academyVisibilityRepositoryProvider`, `teacherAcademiesProvider`.

> 나머지 학원 관련 Repository/Provider는 아직 facade로 노출되지 않았다. 공지/문의/초대 화면들은 자기 feature(inbox/notifications/auth) 내부에서 직접 학원 mock repository를 참조한다(아래 §7 참조).

---

## 6. 화면 · 라우트

### 6.1 academy feature 내부 화면
- `AcademyActivityTimelineScreen` (`presentation/screens/academy_activity_timeline_screen.dart`)
  - 파라미터: `academyId`, `actorMemberId`, `actorName`
  - 활동 로그를 점-라인 타임라인으로 표시. 12시간 이내 항목은 "최근 변경" 강조. `actionType`별 색상/라벨 매핑(§3.2 참조). `NotebookScreenScaffold` + `AppStrings`/`AppColors`/`AppTypography` 사용.
  - 라우트 등록됨 (`academyActivityTimeline`, `/academy/:academyId/teachers/:actorMemberId/activity`, `academy_routes.dart`). 진입점: `ProfileVisibilityScreen`(profile feature)의 학원별 공개 페이지 노출 섹션에서 학원 행마다 "내 활동 보기" 버튼(#1264).

### 6.2 학원 관련 라우트 (다른 feature가 화면 보유)
코드: `core/router/app_routes.dart`, `core/router/routes/`

| 라우트 상수 | path | 화면 (소속 feature) |
|------------|------|---------------------|
| `academyDetail` | `/academies/:id` | `AcademyDetailScreen` (search) |
| `academyInviteAccept` | `/academy/accept` | `AcademyInviteAcceptScreen` (auth) |
| `academyInviteExpired` | `/academy/expired` | `AcademyInviteExpiredScreen` (auth) |
| `academyAnnouncements` | `/academy/:academyId/announcements` | `AcademyAnnouncementsScreen` (notifications) |
| `academyAnnouncementDetail` | `/academy/:academyId/announcements/:announcementId` | `AcademyAnnouncementDetailScreen` (notifications) |
| `academyInquiries` | `/academy/:academyId/inquiries` | `AcademyInquiryScreen` (inbox) |
| `academyInquiryDetail` | `/academy/:academyId/inquiries/:inquiryId` | `AcademyInquiryDetailScreen` (inbox) |

> **구조 메모**: 학원 도메인은 `features/academy/`에 엔티티·Repository·일부 Provider가 모여 있으나, UI 화면 대부분은 다른 feature(auth/inbox/notifications/search)에 분산되어 있다. 활동 타임라인만 academy feature에 자체 화면을 둔다.

---

## 7. 구현 파일 위치

| 레이어 | 위치 |
|--------|------|
| 엔티티 | `features/academy/domain/entities/` (8 파일 + `entities.dart` 배럴) |
| Repository 인터페이스 | `features/academy/domain/repositories/` (8 + `repositories.dart` 배럴) |
| Repository 구현(Mock) | `features/academy/data/repositories/` (`mock_academy_*.dart` 8종) |
| Provider | `features/academy/presentation/providers/` |
| 화면 | `features/academy/presentation/screens/academy_activity_timeline_screen.dart` |
| Facade / 배럴 | `features/academy/academy_facade.dart`, `features/academy/academy.dart` |
| 학원 라우트 정의 | `core/router/app_routes.dart`, `core/router/routes/{auth,notification,search}_routes.dart` |
| 분산 화면 | `features/{search,auth,inbox,notifications}/presentation/screens/academy_*.dart` |

---

## 8. 관련 스펙

- 학원 도메인 전체(웹 콘솔·공개페이지·기획 SSOT): [web/academy/README.md](../web/academy/README.md)
- 수강권 귀속 / 강사 변경 권한 / 활동 로그 가시성: [web/academy/academy_schedule_authority_spec.md](../web/academy/academy_schedule_authority_spec.md)
- 강사 취소 정책: [web/academy/teacher_cancellation_policy_spec.md](../web/academy/teacher_cancellation_policy_spec.md)
- 학원장 일괄 휴강: [web/academy/owner_bulk_closure_spec.md](../web/academy/owner_bulk_closure_spec.md)
- 공지 / 문의: [web/academy/announcements_spec.md](../web/academy/announcements_spec.md), [web/academy/inbox_spec.md](../web/academy/inbox_spec.md)
- 공개 페이지 / 컨텍스트 토글: [web/academy/public_page_spec.md](../web/academy/public_page_spec.md), [web/academy/context_toggle_spec.md](../web/academy/context_toggle_spec.md)
- 수강권 일반 모델: [subscription/subscription_master.md](../subscription/subscription_master.md)
- 선생님-학생 관계: [relationship/relationship_master.md](../relationship/relationship_master.md)

---

## 9. 변경 이력

| 날짜 | 변경 |
|------|------|
| 2026-06-04 | 갭 검증 결과 반영: §4.1 G15 강사 시점 FE 구현(BulkClosureRepository/Provider/BulkClosureDetailScreen + 라우트 3개 + l10n 16키 + 7테스트), §5.1 강사 초대 토큰 Provider 4종 + 에러 분류 정책(`expired`/`already_used`/`not_found`) 문서화. AcademyActivityTimeline 라우트 등록(`/academy/:academyId/teachers/:actorMemberId/activity`) |
| 2026-06-03 | 코드 역공학으로 앱 academy 마스터 스펙 신설 |
