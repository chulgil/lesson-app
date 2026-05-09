import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';

import '../app_routes.dart';
import '../../../features/auth/presentation/providers/user_role_provider.dart';
import '../../../features/subscription/presentation/screens/expiring_subscriptions_screen.dart';
import '../../../features/subscription/presentation/screens/subscription_list_screen.dart';
import '../../../features/subscription/presentation/screens/teacher_subscription_list_screen.dart';
import '../../../features/subscription/presentation/screens/subscription_detail_screen.dart';
import '../../../features/subscription/presentation/screens/issue_subscription_screen.dart';
import '../../../features/subscription/presentation/screens/lesson_policy_screen.dart';
import '../../../features/subscription/presentation/screens/proposal_detail_screen.dart';
import '../../../features/subscription/presentation/screens/proposal_confirm_screen.dart';
import '../../../features/subscription/presentation/screens/renewal_detail_screen.dart';
import '../../../features/subscription/presentation/screens/student_proposal_accept_screen.dart';
import '../../../features/subscription/presentation/screens/schedule_change_request_list_screen.dart';
import '../../../features/subscription/presentation/screens/subscription_template_list_screen.dart';
import '../../../features/subscription/presentation/screens/proposal_settings_screen.dart';

/// Subscription-related routes.
/// NOTE: More specific routes (like /issue, /policy) must come BEFORE parameterized routes (like /:id)
/// to prevent GoRouter from matching them as an ID parameter.
List<RouteBase> subscriptionRoutes = [
  GoRoute(
    path: AppRoutes.proposalSettings,
    builder: (context, state) {
      final teacherId = state.uri.queryParameters['teacherId'] ?? 'teacher_1';
      return _TeacherOnlySubscriptionRoute(
        child: ProposalSettingsScreen(teacherId: teacherId),
      );
    },
  ),
  GoRoute(
    path: AppRoutes.subscriptionTemplates,
    builder: (context, state) {
      final teacherId = state.uri.queryParameters['teacherId'] ?? 'teacher_1';
      return _TeacherOnlySubscriptionRoute(
        child: SubscriptionTemplateListScreen(teacherId: teacherId),
      );
    },
  ),
  GoRoute(
    path: AppRoutes.subscriptions,
    builder: (context, state) {
      final studentId = state.uri.queryParameters['studentId'];
      return SubscriptionListScreen(studentId: studentId);
    },
  ),
  // Teacher subscription list route must come before detail route
  GoRoute(
    path: AppRoutes.teacherSubscriptions,
    builder:
        (context, state) => const _TeacherOnlySubscriptionRoute(
          child: TeacherSubscriptionListScreen(),
        ),
  ),
  // Expiring subscriptions route must come before detail route
  GoRoute(
    path: AppRoutes.expiringSubscriptions,
    builder:
        (context, state) => const _TeacherOnlySubscriptionRoute(
          child: ExpiringSubscriptionsScreen(),
        ),
  ),
  // Schedule change requests route
  GoRoute(
    path: AppRoutes.scheduleChangeRequests,
    builder: (context, state) {
      final teacherId = state.uri.queryParameters['teacherId'] ?? 'teacher_1';
      return _TeacherOnlySubscriptionRoute(
        child: ScheduleChangeRequestListScreen(teacherId: teacherId),
      );
    },
  ),
  // Issue route must come before detail route
  GoRoute(
    path: AppRoutes.issueSubscription,
    builder: (context, state) {
      // Support both single studentId and multiple studentIds
      final studentIdsParam = state.uri.queryParameters['studentIds'];
      final studentIdParam = state.uri.queryParameters['studentId'];
      final membershipId = state.uri.queryParameters['membershipId'];
      final templateId = state.uri.queryParameters['templateId'];

      final lessonRequestId = state.uri.queryParameters['lessonRequestId'];
      final lessonRequestIdsParam =
          state.uri.queryParameters['lessonRequestIds'];

      // Parse studentIds from comma-separated string or single studentId
      final List<String> studentIds;
      if (studentIdsParam != null && studentIdsParam.isNotEmpty) {
        studentIds =
            studentIdsParam.split(',').where((s) => s.isNotEmpty).toList();
      } else if (studentIdParam != null && studentIdParam.isNotEmpty) {
        studentIds = [studentIdParam];
      } else {
        studentIds = [];
      }

      // Parse lessonRequestIds from comma-separated string
      final List<String> lessonRequestIds;
      if (lessonRequestIdsParam != null && lessonRequestIdsParam.isNotEmpty) {
        lessonRequestIds =
            lessonRequestIdsParam
                .split(',')
                .where((s) => s.isNotEmpty)
                .toList();
      } else {
        lessonRequestIds = [];
      }

      return _TeacherOnlySubscriptionRoute(
        child: IssueSubscriptionScreen(
          studentIds: studentIds,
          membershipId: membershipId,
          templateId: templateId,
          lessonRequestId: lessonRequestId,
          lessonRequestIds: lessonRequestIds,
        ),
      );
    },
  ),
  // Policy route must come before detail route
  GoRoute(
    path: AppRoutes.lessonPolicy,
    builder: (context, state) {
      final teacherId = state.uri.queryParameters['teacherId'] ?? 'teacher_1';
      final lessonClassId = state.uri.queryParameters['lessonClassId'];
      return LessonPolicyScreen(
        teacherId: teacherId,
        lessonClassId: lessonClassId,
      );
    },
  ),
  // Proposal confirm route must come before parameterized proposal detail route
  GoRoute(
    path: AppRoutes.proposalConfirm,
    builder: (context, state) {
      final teacherId = state.uri.queryParameters['teacherId'] ?? 'teacher_1';
      return ProposalConfirmScreen(teacherId: teacherId);
    },
  ),
  // Renewal detail route must come before parameterized proposal detail route
  GoRoute(
    path: AppRoutes.renewalDetail,
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return RenewalDetailScreen(proposalId: id);
    },
  ),
  GoRoute(
    path: AppRoutes.subscriptionDetail,
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      final extra = state.extra as Map<String, dynamic>?;
      final viewerRole = extra?['viewerRole'] as String? ?? 'student';
      final initialSession = int.tryParse(
        state.uri.queryParameters['session'] ?? '',
      );
      final focusLessonId = extra?['focusLessonId'] as String?;
      return SubscriptionDetailScreen(
        subscriptionId: id,
        viewerRole: viewerRole,
        initialSelectedSession: initialSession,
        focusLessonId: focusLessonId,
      );
    },
  ),
  // Student proposal accept (must come before proposalDetail)
  GoRoute(
    path: AppRoutes.proposalAccept,
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return StudentProposalAcceptScreen(proposalId: id);
    },
  ),
  // Proposal detail route
  GoRoute(
    path: AppRoutes.proposalDetail,
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return ProposalDetailScreen(proposalId: id);
    },
  ),
];

/// Prevents student/parent viewers from opening teacher-owned subscription
/// operations through stale links, direct URLs, or incorrectly wired CTAs.
class _TeacherOnlySubscriptionRoute extends ConsumerWidget {
  final Widget child;

  const _TeacherOnlySubscriptionRoute({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentUserRoleProvider);
    if (role != UserRole.teacher) {
      return SubscriptionListScreen(
        studentId: ref.watch(currentUserIdProvider),
      );
    }

    return child;
  }
}
