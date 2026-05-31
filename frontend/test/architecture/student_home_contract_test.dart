import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('remote note access does not show seeded mock active access', () {
    final source =
        File(
          'lib/features/practice/presentation/providers/note_access_provider.dart',
        ).readAsStringSync();

    expect(source, contains('createLocalFallbackRepository'));
    expect(source, contains('_EmptyNoteAccessRepository'));
    expect(source, isNot(contains('remote:')));
  });

  test('student getting started distinguishes pending teacher connection', () {
    final source =
        File(
          'lib/features/student_home/presentation/widgets/student_getting_started_card.dart',
        ).readAsStringSync();

    expect(source, contains('mySentRequestsProvider'));
    expect(source, contains('hasPendingConnectionRequest'));
    expect(source, contains('studentHomeTeacherConnectionPending'));
  });

  test(
    'student invite code submits a pending request, not a completed connection',
    () {
      final source =
          File(
            'lib/features/auth/presentation/screens/student_invite_code_screen.dart',
          ).readAsStringSync();

      expect(source, contains('authTeacherConnectionRequested'));
      expect(source, contains('ref.invalidate(mySentRequestsProvider)'));
      expect(source, contains('ref.invalidate(myConnectionsProvider)'));
      expect(source, isNot(contains('authTeacherConnected')));
    },
  );

  test('teacher dashboard surfaces pending connection requests', () {
    final source =
        File(
          'lib/features/home/presentation/widgets/dashboard_tab.dart',
        ).readAsStringSync();

    expect(source, contains('pendingRequestCountProvider'));
    expect(source, contains('AppRoutes.pendingRequests'));
    expect(source, contains('teacherHomeConnectionRequestsTitle'));
    expect(
      source.indexOf('_buildPendingConnectionRequests(context, ref)'),
      lessThan(source.indexOf('_buildTodayLessonsHeader')),
    );
  });

  test('accepting a connection request refreshes teacher roster state', () {
    final source =
        File(
          'lib/features/profile/presentation/providers/invite_provider.dart',
        ).readAsStringSync();
    final acceptBody = source.substring(
      source.indexOf('Future<Connection?> acceptRequest'),
    );

    expect(acceptBody, contains('ref.invalidate(studentsProvider)'));
    expect(acceptBody, contains('ref.invalidate(studentsNotifierProvider)'));
  });
}
