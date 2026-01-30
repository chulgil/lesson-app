import 'package:go_router/go_router.dart';

import '../app_routes.dart';
import '../../../features/subscription/presentation/screens/subscription_list_screen.dart';
import '../../../features/subscription/presentation/screens/subscription_detail_screen.dart';
import '../../../features/subscription/presentation/screens/issue_subscription_screen.dart';
import '../../../features/subscription/presentation/screens/subscription_template_list_screen.dart';
import '../../../features/subscription/presentation/screens/proposal_create_screen.dart';
import '../../../features/subscription/presentation/screens/proposal_detail_screen.dart';
import '../../../features/subscription/presentation/screens/proposal_confirm_screen.dart';
import '../../../features/subscription/presentation/screens/proposal_settings_screen.dart';

/// Subscription-related routes.
/// NOTE: More specific routes (like /issue, /templates) must come BEFORE parameterized routes (like /:id)
/// to prevent GoRouter from matching them as an ID parameter.
List<RouteBase> subscriptionRoutes = [
  GoRoute(
    path: AppRoutes.subscriptions,
    builder: (context, state) {
      final studentId = state.uri.queryParameters['studentId'];
      return SubscriptionListScreen(studentId: studentId);
    },
  ),
  // Issue route must come before detail route to avoid matching "issue" as :id
  GoRoute(
    path: AppRoutes.issueSubscription,
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>?;
      final studentId = extra?['studentId'] ??
          state.uri.queryParameters['studentId'] ??
          '';
      final membershipId = extra?['membershipId'] ??
          state.uri.queryParameters['membershipId'];
      final teacherId = extra?['teacherId'] ??
          state.uri.queryParameters['teacherId'];
      final isAppTransition = extra?['isAppTransition'] ?? false;
      final showScheduleRestoration = extra?['showScheduleRestoration'] ?? false;
      final lessonRequestId = extra?['lessonRequestId'] ??
          state.uri.queryParameters['lessonRequestId'];
      return IssueSubscriptionScreen(
        studentId: studentId,
        membershipId: membershipId,
        teacherId: teacherId,
        isAppTransition: isAppTransition,
        showScheduleRestoration: showScheduleRestoration,
        lessonRequestId: lessonRequestId,
      );
    },
  ),
  // Templates route for teacher to manage subscription products
  GoRoute(
    path: AppRoutes.subscriptionTemplates,
    builder: (context, state) {
      final teacherId = state.uri.queryParameters['teacherId'] ?? 'teacher_1';
      return SubscriptionTemplateListScreen(teacherId: teacherId);
    },
  ),
  GoRoute(
    path: AppRoutes.subscriptionDetail,
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return SubscriptionDetailScreen(subscriptionId: id);
    },
  ),
  // Proposal routes
  // NOTE: create and confirm routes must come BEFORE detail route (/:id)
  GoRoute(
    path: AppRoutes.proposalCreate,
    builder: (context, state) {
      final teacherId = state.uri.queryParameters['teacherId'] ?? 'teacher_1';
      final teacherName = state.uri.queryParameters['teacherName'] ?? '선생님'; // 🆕
      final studentId = state.uri.queryParameters['studentId'];
      return ProposalCreateScreen(
        teacherId: teacherId,
        teacherName: teacherName, // 🆕
        preselectedStudentId: studentId,
      );
    },
  ),
  GoRoute(
    path: AppRoutes.proposalConfirm,
    builder: (context, state) {
      final teacherId = state.uri.queryParameters['teacherId'] ?? 'teacher_1';
      final teacherName = state.uri.queryParameters['teacherName'] ?? '선생님'; // 🆕
      return ProposalConfirmScreen(
        teacherId: teacherId,
        teacherName: teacherName, // 🆕
      );
    },
  ),
  GoRoute(
    path: AppRoutes.proposalSettings,
    builder: (context, state) {
      final teacherId = state.uri.queryParameters['teacherId'] ?? 'teacher_1';
      return ProposalSettingsScreen(teacherId: teacherId);
    },
  ),
  GoRoute(
    path: AppRoutes.proposalDetail,
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return ProposalDetailScreen(proposalId: id);
    },
  ),
];
