import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/practice/domain/entities/practice_log.dart';
import '../../../../repositories/practice_repository.dart';
import 'practice_repository_provider.dart';

/// Practice logs by student
final practiceLogsProvider =
    FutureProvider.family<List<PracticeLog>, String>((ref, studentId) async {
  final repository = ref.watch(practiceRepositoryProvider);
  return repository.getPracticeLogs(studentId);
});

/// Single practice log
final practiceLogProvider =
    FutureProvider.family<PracticeLog?, String>((ref, id) async {
  final repository = ref.watch(practiceRepositoryProvider);
  return repository.getPracticeLog(id);
});

/// Practice log for specific date
final practiceLogByDateProvider = FutureProvider.family<PracticeLog?,
    ({String studentId, DateTime date})>((ref, params) async {
  final repository = ref.watch(practiceRepositoryProvider);
  return repository.getPracticeLogByDate(params.studentId, params.date);
});

/// Today's practice log for student
final todayPracticeProvider =
    FutureProvider.family<PracticeLog?, String>((ref, studentId) async {
  final repository = ref.watch(practiceRepositoryProvider);
  return repository.getPracticeLogByDate(studentId, DateTime.now());
});

/// Weekly practice for student (current week)
final weeklyPracticeProvider =
    FutureProvider.family<List<bool>, String>((ref, studentId) async {
  final repository = ref.watch(practiceRepositoryProvider);
  return repository.getWeeklyPractice(studentId);
});

/// Practice notifier for CRUD operations
class PracticeNotifier
    extends FamilyAsyncNotifier<List<PracticeLog>, String> {
  PracticeRepository get _repository => ref.read(practiceRepositoryProvider);

  @override
  Future<List<PracticeLog>> build(String studentId) async {
    return _repository.getPracticeLogs(studentId);
  }

  Future<PracticeLog> addPracticeLog(PracticeLog log) async {
    state = const AsyncValue.loading();
    try {
      final newLog = await _repository.createPracticeLog(log);
      state = await AsyncValue.guard(() => _repository.getPracticeLogs(arg));
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
      state = await AsyncValue.guard(() => _repository.getPracticeLogs(arg));
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
      state = await AsyncValue.guard(() => _repository.getPracticeLogs(arg));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<PracticeTask> toggleTask(String logId, String taskId) async {
    try {
      final updated = await _repository.toggleTask(logId, taskId);
      state = await AsyncValue.guard(() => _repository.getPracticeLogs(arg));
      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getPracticeLogs(arg));
  }
}

final practiceNotifierProvider = AsyncNotifierProvider.family<PracticeNotifier,
    List<PracticeLog>, String>(
  PracticeNotifier.new,
);
