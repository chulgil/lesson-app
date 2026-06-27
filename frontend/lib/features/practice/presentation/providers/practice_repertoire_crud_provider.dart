import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../features/practice/domain/entities/practice_repertoire.dart';
import 'practice_repertoire_repository_provider.dart';

part 'practice_repertoire_crud_provider.g.dart';

/// Provider for student's repertoires list
@Riverpod(keepAlive: true)
Future<List<PracticeRepertoire>> studentRepertoires(
  StudentRepertoiresRef ref,
  String studentId,
) async {
  final repository = ref.watch(practiceRepertoireRepositoryProvider);
  return repository.getRepertoires(studentId);
}

/// Parameters for date-filtered repertoires
class RepertoiresForDateParams {
  final String studentId;
  final DateTime date;

  const RepertoiresForDateParams({required this.studentId, required this.date});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepertoiresForDateParams &&
          runtimeType == other.runtimeType &&
          studentId == other.studentId &&
          date.year == other.date.year &&
          date.month == other.date.month &&
          date.day == other.date.day;

  @override
  int get hashCode => studentId.hashCode ^ date.day ^ date.month ^ date.year;
}

/// Provider for student's repertoires filtered by date
@Riverpod(keepAlive: true)
Future<List<PracticeRepertoire>> repertoiresForDate(
  RepertoiresForDateRef ref,
  RepertoiresForDateParams params,
) async {
  final repository = ref.watch(practiceRepertoireRepositoryProvider);
  return repository.getRepertoiresForDate(params.studentId, params.date);
}

/// Provider for a single repertoire
@Riverpod(keepAlive: true)
Future<PracticeRepertoire?> repertoire(
  RepertoireRef ref,
  String repertoireId,
) async {
  final repository = ref.watch(practiceRepertoireRepositoryProvider);
  return repository.getRepertoire(repertoireId);
}

/// Provider for a single section
@Riverpod(keepAlive: true)
Future<PracticeSection?> section(SectionRef ref, String sectionId) async {
  final repository = ref.watch(practiceRepertoireRepositoryProvider);
  return repository.getSection(sectionId);
}

/// Notifier for repertoire CRUD operations
@Riverpod(keepAlive: true)
class RepertoireCrud extends _$RepertoireCrud {
  @override
  Future<void> build() async {}

  /// Create a new repertoire
  Future<PracticeRepertoire> createRepertoire({
    required String studentId,
    required String name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(practiceRepertoireRepositoryProvider);
      final now = DateTime.now();
      final repertoire = PracticeRepertoire(
        id: '',
        studentId: studentId,
        name: name,
        description: description,
        startDate: startDate ?? now,
        endDate: endDate,
        createdAt: now,
      );
      final result = await repository.createRepertoire(repertoire);

      // Invalidate the repertoires list
      ref.invalidate(studentRepertoiresProvider(studentId));

      // Also invalidate date-based provider for practice tab
      final today = DateTime.now();
      ref.invalidate(
        repertoiresForDateProvider(
          RepertoiresForDateParams(studentId: studentId, date: today),
        ),
      );

      state = const AsyncData(null);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Update an existing repertoire
  Future<PracticeRepertoire> updateRepertoire(
    PracticeRepertoire repertoire,
  ) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(practiceRepertoireRepositoryProvider);
      final result = await repository.updateRepertoire(repertoire);

      // Invalidate related providers
      ref.invalidate(studentRepertoiresProvider(repertoire.studentId));
      ref.invalidate(repertoireProvider(repertoire.id));

      // Also invalidate date-based provider for practice tab
      final today = DateTime.now();
      ref.invalidate(
        repertoiresForDateProvider(
          RepertoiresForDateParams(
            studentId: repertoire.studentId,
            date: today,
          ),
        ),
      );

      state = const AsyncData(null);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Delete a repertoire
  Future<void> deleteRepertoire(String id, String studentId) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(practiceRepertoireRepositoryProvider);
      await repository.deleteRepertoire(id);

      // Invalidate the repertoires list
      ref.invalidate(studentRepertoiresProvider(studentId));

      // Also invalidate date-based provider for practice tab
      final today = DateTime.now();
      ref.invalidate(
        repertoiresForDateProvider(
          RepertoiresForDateParams(studentId: studentId, date: today),
        ),
      );

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

typedef RepertoireCrudNotifier = RepertoireCrud;

/// Notifier for section CRUD operations
@Riverpod(keepAlive: true)
class SectionCrud extends _$SectionCrud {
  @override
  Future<void> build() async {}

  /// Create a new section
  Future<PracticeSection> createSection({
    required String repertoireId,
    required String pieceName,
    SectionRangeType rangeType = SectionRangeType.measure,
    int startMeasure = 1,
    int endMeasure = 1,
    int? startLine,
    int? endLine,
    String? sectionName,
    bool isRepeat = true,
    int? repeatCount,
    DateTime? startDate,
    DateTime? endDate,
    int? targetPracticeSeconds,
    String? studentId,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(practiceRepertoireRepositoryProvider);
      final section = PracticeSection(
        id: '',
        repertoireId: repertoireId,
        pieceName: pieceName,
        rangeType: rangeType,
        startMeasure: startMeasure,
        endMeasure: endMeasure,
        startLine: startLine,
        endLine: endLine,
        sectionName: sectionName,
        isRepeat: isRepeat,
        repeatCount: repeatCount,
        startDate: startDate,
        endDate: endDate,
        targetPracticeSeconds: targetPracticeSeconds,
        createdAt: DateTime.now(),
      );
      final result = await repository.createSection(section);

      // Invalidate related providers (mirror updateSection symmetry)
      ref.invalidate(repertoireProvider(repertoireId));
      ref.invalidate(sectionProvider(result.id));

      // Also invalidate list providers if studentId is provided
      if (studentId != null) {
        ref.invalidate(studentRepertoiresProvider(studentId));
        final today = DateTime.now();
        ref.invalidate(
          repertoiresForDateProvider(
            RepertoiresForDateParams(studentId: studentId, date: today),
          ),
        );
      }

      state = const AsyncData(null);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Update an existing section
  Future<PracticeSection> updateSection(
    PracticeSection section, {
    String? studentId,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(practiceRepertoireRepositoryProvider);
      final result = await repository.updateSection(section);

      // Invalidate related providers
      ref.invalidate(repertoireProvider(section.repertoireId));
      ref.invalidate(sectionProvider(section.id));

      // Also invalidate list providers if studentId is provided
      if (studentId != null) {
        ref.invalidate(studentRepertoiresProvider(studentId));
        final today = DateTime.now();
        ref.invalidate(
          repertoiresForDateProvider(
            RepertoiresForDateParams(studentId: studentId, date: today),
          ),
        );
      }

      state = const AsyncData(null);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Delete a section
  Future<void> deleteSection(String id, String repertoireId) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(practiceRepertoireRepositoryProvider);
      await repository.deleteSection(id);

      // Invalidate related providers
      ref.invalidate(repertoireProvider(repertoireId));

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Toggle section completion status for a specific date.
  /// Syncs dailyStatuses for the target date.
  /// Only updates the global isCompleted flag when toggling today.
  Future<PracticeSection> toggleComplete(
    String sectionId,
    String repertoireId, {
    String? studentId,
    DateTime? date,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(practiceRepertoireRepositoryProvider);
      final result = await repository.toggleSectionComplete(
        sectionId,
        date: date,
      );

      // Invalidate related providers
      ref.invalidate(repertoireProvider(repertoireId));
      ref.invalidate(sectionProvider(sectionId));

      // Also invalidate date-based providers if studentId is provided
      if (studentId != null) {
        ref.invalidate(studentRepertoiresProvider(studentId));
        // Invalidate the target date's provider for calendar sync
        final targetDate = date ?? DateTime.now();
        ref.invalidate(
          repertoiresForDateProvider(
            RepertoiresForDateParams(studentId: studentId, date: targetDate),
          ),
        );
      }

      state = const AsyncData(null);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Increment practice count
  Future<PracticeSection> incrementPractice(
    String sectionId,
    String repertoireId,
    int practiceSeconds,
  ) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(practiceRepertoireRepositoryProvider);
      final result = await repository.incrementPracticeCount(
        sectionId,
        practiceSeconds,
      );

      // Invalidate related providers
      ref.invalidate(repertoireProvider(repertoireId));
      ref.invalidate(sectionProvider(sectionId));

      state = const AsyncData(null);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Toggle daily completion status for a specific date
  Future<PracticeSection> toggleDailyCompletion(
    String sectionId,
    String repertoireId,
    String studentId,
    DateTime date,
  ) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(practiceRepertoireRepositoryProvider);
      final result = await repository.toggleDailyCompletion(sectionId, date);

      // Invalidate related providers
      ref.invalidate(repertoireProvider(repertoireId));
      ref.invalidate(sectionProvider(sectionId));
      ref.invalidate(studentRepertoiresProvider(studentId));
      ref.invalidate(
        repertoiresForDateProvider(
          RepertoiresForDateParams(studentId: studentId, date: date),
        ),
      );

      state = const AsyncData(null);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Toggle section repeat setting
  Future<PracticeSection> toggleRepeat(
    String sectionId,
    String repertoireId,
    String studentId,
  ) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(practiceRepertoireRepositoryProvider);
      final result = await repository.toggleSectionRepeat(sectionId);

      // Invalidate related providers
      ref.invalidate(repertoireProvider(repertoireId));
      ref.invalidate(sectionProvider(sectionId));
      ref.invalidate(studentRepertoiresProvider(studentId));

      state = const AsyncData(null);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

typedef SectionCrudNotifier = SectionCrud;

/// Notifier for recording CRUD operations
@Riverpod(keepAlive: true)
class RecordingCrud extends _$RecordingCrud {
  @override
  Future<void> build() async {}

  /// Create a new recording
  Future<PracticeRecording> createRecording({
    required String sectionId,
    required String filePath,
    required int durationSeconds,
    int? bpm,
    bool isRepresentative = false,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(practiceRepertoireRepositoryProvider);
      final recording = PracticeRecording(
        id: '',
        sectionId: sectionId,
        filePath: filePath,
        durationSeconds: durationSeconds,
        bpm: bpm,
        isRepresentative: isRepresentative,
        createdAt: DateTime.now(),
      );
      final result = await repository.createRecording(recording);

      // Invalidate related providers
      ref.invalidate(sectionProvider(sectionId));

      state = const AsyncData(null);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Delete a recording
  Future<void> deleteRecording(String id, String sectionId) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(practiceRepertoireRepositoryProvider);
      await repository.deleteRecording(id);

      // Invalidate related providers
      ref.invalidate(sectionProvider(sectionId));

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Set representative recording
  Future<PracticeSection> setRepresentative(
    String sectionId,
    String recordingId,
    String repertoireId,
  ) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(practiceRepertoireRepositoryProvider);
      final result = await repository.setRepresentativeRecording(
        sectionId,
        recordingId,
      );

      // Invalidate related providers
      ref.invalidate(sectionProvider(sectionId));
      ref.invalidate(repertoireProvider(repertoireId));

      state = const AsyncData(null);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

typedef RecordingCrudNotifier = RecordingCrud;
