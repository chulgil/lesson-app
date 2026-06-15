// Regression test — instrument write→read SSOT sync (#732 follow-up bug).
//
// Bug: the instrument management screen WRITES via
// CurrentTeacherProfileNotifier.updateProfile (repo + Notifier state) but READS
// currentTeacherProfileProvider — a SEPARATE FutureProvider. The write never
// invalidated that FutureProvider, so every reader (the screen list AND the
// home quest hasInstruments) kept showing stale/empty instruments: the "추가
// 되었습니다" snackbar fired but nothing appeared.
//
// Why #732's tests missed it: instrument_ssot_provider_test overrides
// currentTeacherProfileProvider directly (injects the read value), so it never
// exercises the Notifier write → FutureProvider read path. This test uses the
// REAL providers backed by a shared mock repo, and — critically — keeps the
// FutureProvider alive with a listener (as the always-mounted home quest does),
// because an autoDispose read between writes would refetch and hide the bug.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/auth/auth_facade.dart'
    show currentUserIdProvider;
import 'package:lessonaza/features/onboarding/onboarding_facade.dart'
    show
        currentTeacherProfileNotifierProvider,
        currentTeacherProfileProvider,
        teacherProfileRepositoryProvider;
import 'package:lessonaza/features/profile/data/repositories/mock_teacher_profile_repository.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_profile.dart';

TeacherProfile _profile() => TeacherProfile(
  id: 'p1',
  userId: 'u1',
  name: '테스트 선생님',
  instruments: const [],
  introduction: '',
  verification: const TeacherVerification(),
  createdAt: DateTime(2026),
);

void main() {
  test(
    'updateProfile via Notifier is reflected in currentTeacherProfileProvider',
    () async {
      final repo = MockTeacherProfileRepository(empty: true);
      await repo.createProfile(_profile());

      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWith((ref) => 'u1'),
          teacherProfileRepositoryProvider.overrideWith((ref) => repo),
        ],
      );
      addTearDown(container.dispose);

      // Keep the read FutureProvider alive across the write — mirrors the
      // always-mounted home quest. Without this, autoDispose would refetch on
      // the second read and mask the stale-cache bug.
      final sub = container.listen(
        currentTeacherProfileProvider,
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);

      final before = await container.read(currentTeacherProfileProvider.future);
      expect(before?.instruments, isEmpty);

      // Write the way the management screen does: via the Notifier.
      await container
          .read(currentTeacherProfileNotifierProvider.notifier)
          .updateProfile(before!.copyWith(instruments: ['바이올린']));

      // The read provider must now reflect the write.
      final after = await container.read(currentTeacherProfileProvider.future);
      expect(
        after?.instruments,
        contains('바이올린'),
        reason:
            'write via Notifier must invalidate the read FutureProvider so the '
            'screen and quest see the new instrument',
      );
    },
  );
}
