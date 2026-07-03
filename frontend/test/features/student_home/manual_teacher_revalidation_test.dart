import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/sync/presentation/providers/revalidation_events_provider.dart';
import 'package:lessonaza/features/student_home/domain/entities/manual_teacher.dart';
import 'package:lessonaza/features/student_home/domain/repositories/manual_teacher_repository.dart';
import 'package:lessonaza/features/student_home/presentation/providers/manual_teacher_provider.dart';

/// Repository fake that counts `getAll` calls, so we can observe whether the
/// wired provider actually re-fetches on a revalidation event.
class _CountingManualTeacherRepo implements ManualTeacherRepository {
  _CountingManualTeacherRepo(this.onGetAll);

  final void Function() onGetAll;

  @override
  Future<List<ManualTeacher>> getAll() async {
    onGetAll();
    return const [];
  }

  @override
  Future<ManualTeacher?> getById(String id) async => null;

  @override
  Future<void> add(ManualTeacher teacher) async {}

  @override
  Future<void> update(ManualTeacher teacher) async {}

  @override
  Future<void> delete(String id) async {}
}

void main() {
  test(
    'a wired provider re-fetches on a matching revalidation event, not otherwise',
    () async {
      var fetches = 0;
      final container = ProviderContainer(
        overrides: [
          manualTeacherRepositoryProvider.overrideWithValue(
            _CountingManualTeacherRepo(() => fetches++),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.listen(
        manualTeacherNotifierProvider,
        (_, _) {},
        fireImmediately: true,
      );
      await container.read(manualTeacherNotifierProvider.future);
      expect(fetches, 1);

      // A matching prefix event refreshes the provider (autoRevalidate wiring).
      container
          .read(revalidationEventsProvider.notifier)
          .emit('/manual-teachers');
      await Future<void>.delayed(Duration.zero);
      await container.read(manualTeacherNotifierProvider.future);
      expect(fetches, 2, reason: 'bus emit refreshes the wired provider');

      // A non-matching prefix must NOT refresh it.
      container.read(revalidationEventsProvider.notifier).emit('/lessons');
      await Future<void>.delayed(Duration.zero);
      await container.read(manualTeacherNotifierProvider.future);
      expect(fetches, 2, reason: 'non-matching prefix does not refresh');
    },
  );
}
