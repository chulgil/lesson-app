import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('remote note access does not show seeded mock active access', () {
    final source =
        File(
          'lib/features/practice/presentation/providers/note_access_provider.dart',
        ).readAsStringSync();

    expect(source, contains('createLocalFallbackRepository'));
    // EmptyNoteAccessRepository moved to data/repositories (layer boundary
    // contract); provider now imports it instead of an inline private class.
    expect(source, contains('EmptyNoteAccessRepository'));
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
      // #<int-invite-ui> — the onboarding invite-code screen now reuses the
      // shared InviteConfirmScreen (the "unify onboarding + post-onboarding
      // invite UI" rework), so the actual connection-request creation and its
      // "pending, not connected" wording moved there. student_invite_code_screen
      // only resolves the code and pushes the confirm step.
      final onboardingSource =
          File(
            'lib/features/auth/presentation/screens/student_invite_code_screen.dart',
          ).readAsStringSync();
      expect(onboardingSource, isNot(contains('authTeacherConnected')));

      final confirmSource =
          File(
            'lib/features/invite/presentation/screens/invite_confirm_screen.dart',
          ).readAsStringSync();
      expect(confirmSource, contains('AppStrings.inviteRequestSent'));
      expect(confirmSource, isNot(contains('authTeacherConnected')));

      final providerSource =
          File(
            'lib/features/profile/presentation/providers/invite_provider.dart',
          ).readAsStringSync();
      final requestConnectionBody = providerSource.substring(
        providerSource.indexOf('Future<ConnectionRequest?> requestConnection'),
      );
      expect(
        requestConnectionBody,
        contains('ref.invalidate(mySentRequestsProvider)'),
      );
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
