import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';
import 'package:lessonaza/features/subscription/presentation/screens/issue_subscription_actions.dart';

void main() {
  test('actual issue updates linked lesson request as subscription issued', () {
    expect(
      lessonRequestStatusForIssuedSubscription(),
      UnifiedRequestStatus.subscriptionIssued,
    );
  });
}
