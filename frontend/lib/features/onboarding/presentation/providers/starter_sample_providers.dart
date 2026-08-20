import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../lessons/lessons_facade.dart';
import '../../../practice/practice_facade.dart';
import '../../../students/students_facade.dart';
import '../../domain/entities/starter_sample_data.dart';
import '../../domain/services/starter_sample_data_service.dart';
import 'starter_sample_storage_provider.dart';

part 'starter_sample_providers.g.dart';

/// Copy for the sample rows. Lives in presentation because the domain service
/// must stay free of `AppStrings` (layer contract).
const starterSampleContent = StarterSampleContent(
  studentName: AppStrings.starterSampleStudentName,
  studentNotes: AppStrings.starterSampleStudentNotes,
  instrument: AppStrings.instrumentViolin,
  lessonFeedback: AppStrings.starterSampleLessonFeedback,
  lessonKeyPoints: [
    AppStrings.starterSampleLessonKeyPointFirst,
    AppStrings.starterSampleLessonKeyPointSecond,
  ],
  lessonPracticeTips: AppStrings.starterSampleLessonPracticeTips,
  practiceNotes: AppStrings.starterSamplePracticeNotes,
);

@Riverpod(keepAlive: true)
StarterSampleDataService starterSampleDataService(
  StarterSampleDataServiceRef ref,
) {
  return StarterSampleDataService(
    studentRepository: ref.watch(studentRepositoryProvider),
    lessonRepository: ref.watch(lessonRepositoryProvider),
    practiceRepository: ref.watch(practiceRepositoryProvider),
  );
}

/// How the last starter-sample action ended, for the message the teacher reads.
enum StarterSampleOutcome {
  created,
  removed,

  /// Failed, and nothing was left behind.
  failed,

  /// Failed, and a partially created sample may still be in the roster.
  failedWithResidue,
}

/// Drives the opt-in walkthrough (UXB-1).
///
/// Nothing runs without an explicit tap. The [AsyncValue] state carries only
/// progress — loading while the rows are being written, error when the write
/// failed — while the returned [StarterSampleOutcome] tells the caller which
/// message to show.
@riverpod
class StarterSampleController extends _$StarterSampleController {
  @override
  FutureOr<void> build() {}

  Future<StarterSampleOutcome> createSample() async {
    state = const AsyncValue.loading();
    try {
      final sample = await ref
          .read(starterSampleDataServiceProvider)
          .create(content: starterSampleContent, now: DateTime.now());
      await ref.read(starterSampleStorageProvider.notifier).save(sample);
      _invalidateAffectedViews();
      state = const AsyncValue.data(null);
      return StarterSampleOutcome.created;
    } on StarterSampleCreationFailure catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      // A failed rollback leaves a sample student the teacher has to delete by
      // hand, so the roster still has to be refreshed to show it.
      if (!error.rolledBack) _invalidateAffectedViews();
      return error.rolledBack
          ? StarterSampleOutcome.failed
          : StarterSampleOutcome.failedWithResidue;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return StarterSampleOutcome.failed;
    }
  }

  Future<StarterSampleOutcome> removeSample() async {
    final sample = await ref.read(starterSampleStorageProvider.future);
    if (sample == null) return StarterSampleOutcome.removed;

    state = const AsyncValue.loading();
    try {
      await ref.read(starterSampleDataServiceProvider).remove(sample);
      await ref.read(starterSampleStorageProvider.notifier).clear();
      _invalidateAffectedViews();
      state = const AsyncValue.data(null);
      return StarterSampleOutcome.removed;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return StarterSampleOutcome.failed;
    }
  }

  /// The sample is written through repositories rather than the feature
  /// notifiers, so the invalidation those notifiers normally perform has to be
  /// repeated here. `studentsNotifierProvider` cascades to the grouped-roster
  /// and triage-summary providers that watch it.
  void _invalidateAffectedViews() {
    ref.invalidate(studentsNotifierProvider);
    ref.invalidate(studentsProvider);
    ref.invalidate(filteredStudentsProvider);
    ref.invalidate(lessonsProvider);
    ref.invalidate(lessonsByStudentProvider);
    ref.invalidate(recentLessonsProvider);
    ref.invalidate(practiceLogsProvider);
  }
}

/// True once the sample exists alongside at least one real student — the point
/// where the sample stops being scaffolding and starts being clutter.
@riverpod
Future<bool> starterSampleCleanupVisible(
  StarterSampleCleanupVisibleRef ref,
) async {
  final sample = await ref.watch(starterSampleStorageProvider.future);
  if (sample == null) return false;

  final students = await ref.watch(studentsNotifierProvider.future);
  return students.any((student) => student.id != sample.studentId);
}

/// True while the teacher has no students and has not run the walkthrough yet.
@riverpod
Future<bool> starterSampleOfferVisible(StarterSampleOfferVisibleRef ref) async {
  final sample = await ref.watch(starterSampleStorageProvider.future);
  return sample == null;
}
