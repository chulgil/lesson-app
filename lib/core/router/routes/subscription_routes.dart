import 'package:go_router/go_router.dart';

import '../app_routes.dart';
import '../../../features/subscription/presentation/screens/subscription_list_screen.dart';
import '../../../features/subscription/presentation/screens/subscription_detail_screen.dart';
import '../../../features/subscription/presentation/screens/issue_subscription_screen.dart';

/// Subscription-related routes.
/// NOTE: More specific routes (like /issue) must come BEFORE parameterized routes (like /:id)
/// to prevent GoRouter from matching "issue" as an ID parameter.
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
      final studentId = state.uri.queryParameters['studentId']!;
      final membershipId = state.uri.queryParameters['membershipId'];
      return IssueSubscriptionScreen(
        studentId: studentId,
        membershipId: membershipId,
      );
    },
  ),
  GoRoute(
    path: AppRoutes.subscriptionDetail,
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return SubscriptionDetailScreen(subscriptionId: id);
    },
  ),
];
