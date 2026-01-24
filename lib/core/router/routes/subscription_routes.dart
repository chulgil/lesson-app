import 'package:go_router/go_router.dart';

import '../app_routes.dart';
import '../../../features/subscription/presentation/screens/subscription_list_screen.dart';
import '../../../features/subscription/presentation/screens/subscription_detail_screen.dart';

/// Subscription-related routes.
List<RouteBase> subscriptionRoutes = [
  GoRoute(
    path: AppRoutes.subscriptions,
    builder: (context, state) {
      final studentId = state.uri.queryParameters['studentId'];
      return SubscriptionListScreen(studentId: studentId);
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
