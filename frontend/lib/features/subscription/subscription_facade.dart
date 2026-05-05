/// Subscription Facade — single entry point for all subscription operations.
///
/// AI: Read this file to understand the full subscription API.
/// All subscription entity types, query providers, and mutation notifiers
/// are accessible through this single import.
///
/// Usage:
///   import 'package:lesson_app/features/subscription/subscription_facade.dart';
///
/// ## Entities
///
/// - [Subscription] — 수강권 (횟수, 기간, 상태 등)
/// - [SubscriptionProposal] — 수강권 제안 (선생님→학생)
/// - [SubscriptionTemplate] — 수강권 템플릿 (가격표)
/// - [SubscriptionUsage] — 수강권 사용 이력
/// - [ProposalSettings] — 자동 제안 설정
/// - [LessonPolicy] — 레슨 정책 (취소, 변경 규칙)
///
/// ## Query Providers (reactive — use ref.watch)
///
/// ### Subscriptions
/// - `studentSubscriptionsProvider(studentId)` — 학생의 전체 수강권
/// - `activeStudentSubscriptionsProvider(studentId)` — 활성 수강권만
/// - `membershipSubscriptionProvider(membershipId)` — 멤버십별 수강권
/// - `subscriptionProvider(id)` — 단건 조회
/// - `expiringSoonSubscriptionsProvider()` — 만료 임박
/// - `expiredSubscriptionsProvider()` — 만료된 수강권
/// - `teacherStudentSubscriptionsProvider(teacherId)` — 선생님 학생들의 수강권
/// - `unpaidSubscriptionsProvider(teacherId)` — 입금대기(후불) 수강권
/// - `unpaidSummaryProvider(teacherId)` — 입금대기(후불) 요약 (총액, 학생수)
/// - `activeSubscriptionBetweenProvider(studentId:, teacherId:)` — 관계별 활성 수강권
/// - `canBookLessonProvider(studentId:, teacherId:, isTrialLesson:)` — 레슨 예약 가능 여부
/// - `subscriptionUsageHistoryProvider(subscriptionId)` — 사용 이력
///
/// ### Proposals
/// - `teacherProposalsProvider(teacherId)` — 선생님의 전체 제안
/// - `activeTeacherProposalsProvider(teacherId)` — 진행 중 제안
/// - `awaitingConfirmationProposalsProvider(teacherId)` — 입금 확인 필요
/// - `studentProposalsProvider(studentId)` — 학생의 전체 제안
/// - `activeStudentProposalsProvider(studentId)` — 학생 진행 중 제안
/// - `pendingStudentProposalsProvider(studentId)` — 학생 대기 중 제안
/// - `pendingRenewalProposalProvider(studentId)` — 갱신 대기 제안
/// - `subscriptionProposalProvider(proposalId)` — 단건 조회
/// - `activeProposalBetweenProvider(teacherId, studentId)` — 관계별 진행 중 제안
///
/// ### Templates
/// - `teacherTemplatesProvider(teacherId)` — 선생님 템플릿 전체
/// - `activeTeacherTemplatesProvider(teacherId)` — 활성 템플릿
/// - `autoProposalTemplatesProvider(teacherId)` — 자동 제안 대상
/// - `academyTemplatesProvider(academyId)` — 학원 템플릿
/// - `activeAcademyTemplatesProvider(academyId)` — 학원 활성 템플릿
/// - `subscriptionTemplateProvider(templateId)` — 단건 조회
///
/// ### Settings & Policy
/// - `teacherProposalSettingsProvider(teacherId)` — 자동 제안 설정
/// - `teacherPolicyProvider(teacherId)` — 선생님 기본 정책
/// - `classPolicyProvider(lessonClassId)` — 수업별 정책
/// - `effectivePolicyProvider(teacherId:, lessonClassId:)` — 유효 정책
///
/// ## Mutation Notifiers (imperative — use ref.read)
///
/// ### SubscriptionNotifier (학생별)
///   ref.read(subscriptionNotifierProvider(studentId).notifier)
///   - `.create(subscription)` — 수강권 생성
///   - `.updateSubscription(subscription)` — 수정
///   - `.useLesson(id)` — 1회 사용
///   - `.useReschedule(id)` — 변경 1회 사용
///   - `.confirmPayment(id)` — 입금 확인
///   - `.pause(id)` / `.resume(id)` — 일시정지/재개
///
/// ### MembershipSubscriptionNotifier (멤버십별)
///   ref.read(membershipSubscriptionNotifierProvider(membershipId).notifier)
///   - `.create(subscription)` — 수강권 생성
///   - `.useLesson()` — 1회 사용
///   - `.useReschedule()` — 변경 1회 사용
///   - `.pause()` / `.resume()` — 일시정지/재개
///
/// ### SubscriptionProposalNotifier
///   ref.read(subscriptionProposalNotifierProvider.notifier)
///   - `.createProposal(...)` — 단일 제안
///   - `.createMultiChoiceProposal(...)` — 복수 선택 제안
///   - `.notifyPayment(proposalId)` — 입금 완료 알림
///   - `.confirmPayment(proposalId, subscriptionId)` — 입금 확인
///   - `.reject(proposalId, reason)` — 거절
///   - `.cancel(proposalId)` — 취소
///   - `.selectTemplate(proposalId, templateId)` — 템플릿 선택
///
/// ### SubscriptionTemplateNotifier
///   ref.read(subscriptionTemplateNotifierProvider.notifier)
///   - `.createTemplate(...)` — 생성
///   - `.updateTemplate(template)` — 수정
///   - `.deleteTemplate(template)` — 삭제
///   - `.toggleActive(template)` — 활성/비활성
///
/// ### ProposalSettingsNotifier
///   ref.read(proposalSettingsNotifierProvider.notifier)
///   - `.toggleAutoProposal(teacherId, enabled)` — 자동 제안 토글
///   - `.updateAutoProposalTemplates(teacherId, templateIds, ...)` — 대상 템플릿
///   - `.updateGoldenTimeDiscount(teacherId, ...)` — 골든타임 할인
///   - `.updateAutoReminder(teacherId, ...)` — 자동 리마인더
///   - `.updateSettings(settings)` — 전체 설정 업데이트
library;

// =============================================================================
// ENTITIES — import this facade to get all subscription types
// =============================================================================
export 'domain/entities/lesson_policy.dart';
export 'domain/entities/proposal_settings.dart';
export 'domain/entities/subscription.dart';
export 'domain/entities/subscription_proposal.dart';
export 'domain/entities/subscription_template.dart';
export 'domain/entities/subscription_usage.dart';

// =============================================================================
// DOMAIN SERVICES — used by lessons feature for auto-proposal & renewal
// =============================================================================
export 'domain/services/auto_proposal_service.dart';
export 'domain/services/subscription_renewal_service.dart';

// =============================================================================
// QUERY PROVIDERS + MUTATION NOTIFIERS
// =============================================================================
export 'presentation/providers/lesson_policy_providers.dart';
export 'presentation/providers/proposal_settings_providers.dart';
export 'presentation/providers/subscription_proposal_providers.dart';
export 'presentation/providers/subscription_providers.dart';
export 'presentation/providers/subscription_template_providers.dart';
