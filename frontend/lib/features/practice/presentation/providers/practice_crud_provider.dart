import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/sync/presentation/providers/revalidation_events_provider.dart';
import '../../../../features/practice/domain/entities/practice_log.dart';
import '../../../gamification/gamification_facade.dart';
import '../../domain/repositories/practice_repository.dart';
import 'practice_repository_provider.dart';

part 'practice_crud_provider.g.dart';

/// Practice logs by student
@Riverpod(keepAlive: true)
Future<List<PracticeLog>> practiceLogs(
  PracticeLogsRef ref,
  String studentId,
) async {
  final repository = ref.watch(practiceRepositoryProvider);
  return repository.getPracticeLogs(studentId);
}

/// Single practice log
@Riverpod(keepAlive: true)
Future<PracticeLog?> practiceLog(PracticeLogRef ref, String id) async {
  final repository = ref.watch(practiceRepositoryProvider);
  return repository.getPracticeLog(id);
}

/// Practice log for specific date
@Riverpod(keepAlive: true)
Future<PracticeLog?> practiceLogByDate(
  PracticeLogByDateRef ref,
  ({String studentId, DateTime date}) params,
) async {
  final repository = ref.watch(practiceRepositoryProvider);
  return repository.getPracticeLogByDate(params.studentId, params.date);
}

/// Today's practice log for student
@Riverpod(keepAlive: true)
Future<PracticeLog?> todayPractice(
  TodayPracticeRef ref,
  String studentId,
) async {
  final repository = ref.watch(practiceRepositoryProvider);
  return repository.getPracticeLogByDate(studentId, DateTime.now());
}

/// Weekly practice for student (current week)
@Riverpod(keepAlive: true)
Future<List<bool>> weeklyPractice(
  WeeklyPracticeRef ref,
  String studentId,
) async {
  final repository = ref.watch(practiceRepositoryProvider);
  return repository.getWeeklyPractice(studentId);
}

/// Practice notifier for CRUD operations
@Riverpod(keepAlive: true)
class PracticeNotifier extends _$PracticeNotifier {
  PracticeRepository get _repository => ref.read(practiceRepositoryProvider);

  @override
  Future<List<PracticeLog>> build(String studentId) async {
    ref.autoRevalidate('/practice-logs');
    return _repository.getPracticeLogs(studentId);
  }

  Future<PracticeLog> addPracticeLog(PracticeLog log) async {
    state = const AsyncValue.loading();
    try {
      final newLog = await _repository.createPracticeLog(log);
      state = await AsyncValue.guard(
        () => _repository.getPracticeLogs(studentId),
      );
      // Award points for daily practice completion
      ref
          .read(pointAwardNotifierProvider.notifier)
          .awardPracticeComplete(studentId);
      return newLog;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<PracticeLog> updatePracticeLog(PracticeLog log) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _repository.updatePracticeLog(log);
      state = await AsyncValue.guard(
        () => _repository.getPracticeLogs(studentId),
      );
      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deletePracticeLog(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deletePracticeLog(id);
      state = await AsyncValue.guard(
        () => _repository.getPracticeLogs(studentId),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<PracticeTask> toggleTask(String logId, String taskId) async {
    try {
      final updated = await _repository.toggleTask(logId, taskId);
      state = await AsyncValue.guard(
        () => _repository.getPracticeLogs(studentId),
      );
      // Award points when task is toggled to completed
      if (updated.isCompleted) {
        ref
            .read(pointAwardNotifierProvider.notifier)
            .awardTaskComplete(studentId, updated.title);
      }
      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getPracticeLogs(studentId),
    );
  }
}
