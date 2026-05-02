import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/core/router/routes/profile_routes.dart';

void main() {
  test('profile routes expose tuition deposit status, not independent payments',
      () {
    final routeNames =
        profileRoutes.map((route) => route.name).whereType<String>().toSet();
    final routePaths = profileRoutes.map((route) => route.path).toSet();

    expect(routeNames, isNot(contains('paymentManagement')));
    expect(routePaths, isNot(contains('/profile/payments')));
    expect(routePaths, contains(AppRoutes.outstandingPayments));
  });
}
