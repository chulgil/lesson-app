import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'lesson detail route derives teacher actions from current user role',
    () {
      final content =
          File('lib/core/router/routes/lesson_routes.dart').readAsStringSync();

      expect(content, contains('currentUserRoleProvider'));
      expect(content, contains('UserRole.teacher'));
      expect(content, contains('isTeacher:'));
    },
  );

  test('subscription issue route is guarded as teacher-only', () {
    final content =
        File(
          'lib/core/router/routes/subscription_routes.dart',
        ).readAsStringSync();

    expect(content, contains('AppRoutes.issueSubscription'));
    expect(content, contains('currentUserRoleProvider'));
    expect(content, contains('role != UserRole.teacher'));
    expect(content, contains('SubscriptionListScreen'));
  });

  test('teacher-only subscription routes share the same role guard', () {
    final content =
        File(
          'lib/core/router/routes/subscription_routes.dart',
        ).readAsStringSync();

    expect(content, contains('class _TeacherOnlySubscriptionRoute'));
    expect(content, contains('path: AppRoutes.subscriptionTemplates'));
    expect(content, contains('path: AppRoutes.teacherSubscriptions'));
    expect(content, contains('path: AppRoutes.expiringSubscriptions'));
    expect(content, contains('path: AppRoutes.scheduleChangeRequests'));
  });

  test('student entry points pass student viewer role explicitly', () {
    final lessonCard =
        File(
          'lib/features/student_home/presentation/widgets/student_lesson_card.dart',
        ).readAsStringSync();
    final subscriptionSummary =
        File(
          'lib/features/student_home/presentation/widgets/student_subscription_summary.dart',
        ).readAsStringSync();

    expect(lessonCard, contains("extra: {'viewerRole': 'student'}"));
    expect(subscriptionSummary, contains("extra: {'viewerRole': 'student'}"));
  });

  test(
    'student and parent home do not link to teacher subscription issue route',
    () {
      final forbiddenUsages = <String>[];
      for (final root in [
        Directory('lib/features/student_home'),
        Directory('lib/features/parent_home'),
      ]) {
        for (final file in root
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))) {
          final content = file.readAsStringSync();
          if (content.contains('AppRoutes.issueSubscription')) {
            forbiddenUsages.add(file.path);
          }
        }
      }

      expect(
        forbiddenUsages,
        isEmpty,
        reason:
            'Student/parent surfaces may ask the teacher for issuance, but must not open the teacher issue route.',
      );
    },
  );
}
