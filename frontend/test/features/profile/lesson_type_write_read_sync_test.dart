// #1146 — lesson type (레슨 방식) write→read sync.
//
// The profile "레슨 방식" section (LessonStyleSettingsScreen) writes the
// teacher's lessonTypes via TeacherExtendedProfile.updateLessonTypes, which was
// dead code (0 callers) until this feature. The section reads back the same
// provider, and the public teacher detail / subscription gating read
// currentTeacherProfileProvider — so the write must invalidate that read
// provider too (SSOT sync), mirroring the #732 instrument bug.
//
// Uses REAL providers backed by a shared mock repo (not a read override) so the
// Notifier write → FutureProvider read path is actually exercised.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/auth/auth_facade.dart'
    show currentUserIdProvider;
import 'package:lessonaza/features/onboarding/onboarding_facade.dart'
    show currentTeacherProfileProvider, teacherProfileRepositoryProvider;
import 'package:lessonaza/features/profile/data/repositories/mock_teacher_profile_repository.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_profile.dart';
import 'package:lessonaza/features/profile/presentation/providers/teacher_extended_profile_provider.dart';

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
    'updateLessonTypes persists and is reflected in both the extended profile '
    'and currentTeacherProfileProvider',
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

      // Keep the public read provider alive across the write, like the
      // always-mounted teacher detail / gating readers.
      final sub = container.listen(
        currentTeacherProfileProvider,
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);

      // TeacherExtendedProfile is a Notifier whose build() kicks off an async
      // load; refresh() awaits that load so we can read a settled state.
      final notifier = container.read(teacherExtendedProfileProvider.notifier);
      await notifier.refresh();
      final before = container.read(teacherExtendedProfileProvider).valueOrNull;
      expect(before?.lessonTypes ?? const [], isEmpty);

      await notifier.updateLessonTypes(const [
        LessonTypeOption.inPerson,
        LessonTypeOption.online,
      ]);

      final after = container.read(teacherExtendedProfileProvider).valueOrNull;
      expect(after?.lessonTypes, [
        LessonTypeOption.inPerson,
        LessonTypeOption.online,
      ]);

      // The public read provider must reflect the write (SSOT sync).
      final publicAfter = await container.read(
        currentTeacherProfileProvider.future,
      );
      expect(
        publicAfter?.lessonTypes,
        [LessonTypeOption.inPerson, LessonTypeOption.online],
        reason:
            'updateLessonTypes must invalidate currentTeacherProfileProvider so '
            'the teacher detail and subscription gating see the new modes',
      );
    },
  );
}
