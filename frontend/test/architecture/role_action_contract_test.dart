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
    final lessonProgressMapper =
        File(
          'lib/features/student_home/presentation/mappers/student_lesson_progress_mapper.dart',
        ).readAsStringSync();
    final lessonProgressSection =
        File(
          'lib/features/student_home/presentation/widgets/student_lesson_progress_section.dart',
        ).readAsStringSync();

    expect(lessonCard, contains("extra: {'viewerRole': 'student'}"));
    expect(subscriptionSummary, contains("extra: {'viewerRole': 'student'}"));
    expect(lessonProgressMapper, contains("'viewerRole': 'student'"));
    expect(lessonProgressSection, contains('extra: sortedItems[i].routeExtra'));
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

  test('student home does not link to legacy booking detail route', () {
    final forbiddenUsages = <String>[];
    for (final file in Directory('lib/features/student_home')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))) {
      final content = file.readAsStringSync();
      if (content.contains('AppRoutes.bookingDetail')) {
        forbiddenUsages.add(file.path);
      }
    }

    expect(
      forbiddenUsages,
      isEmpty,
      reason:
          'Student trial/upcoming booking cards must open the current MyBookings flow, not the legacy unregistered booking detail route.',
    );
  });

  test('student home booking widgets use student-home application providers', () {
    final bookingWidgets = [
      File(
        'lib/features/student_home/presentation/widgets/dashboard/next_lesson_card.dart',
      ),
      File(
        'lib/features/student_home/presentation/widgets/trial_bookings_section.dart',
      ),
      File(
        'lib/features/student_home/presentation/widgets/trial_booking_card.dart',
      ),
    ];

    for (final file in bookingWidgets) {
      final content = file.readAsStringSync();
      expect(
        content,
        isNot(
          contains('/lessons/presentation/providers/booking_providers.dart'),
        ),
        reason:
            '${file.path} must not import the lessons presentation booking provider directly.',
      );
      expect(
        content,
        isNot(contains('studentBookingsProvider(')),
        reason:
            '${file.path} must use student_home application providers for booking reads.',
      );
      expect(
        content,
        isNot(contains('bookingsNotifierProvider')),
        reason:
            '${file.path} must use a student_home action provider for booking mutations.',
      );
    }
  });
}
