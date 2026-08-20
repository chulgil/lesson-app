import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/auth_facade.dart';
import '../../domain/entities/starter_sample_data.dart';

part 'starter_sample_storage_provider.g.dart';

const _boxName = 'starter_sample_data';

/// Remembers which rows the starter sample walkthrough created (UXB-1).
///
/// User-scoped, like [OnboardingProgressStorage]: two teachers on one device
/// must not clean up each other's sample. If the box is wiped the sample keeps
/// working as an ordinary manual student — the teacher just deletes it by hand
/// instead of by the one-tap CTA.
@Riverpod(keepAlive: true)
class StarterSampleStorage extends _$StarterSampleStorage {
  @override
  Future<StarterSampleData?> build() async {
    final teacherId = ref.watch(currentUserIdProvider);
    return _load(teacherId);
  }

  Future<StarterSampleData?> _load(String teacherId) async {
    final box = await Hive.openBox<String>(_boxName);
    final studentId = box.get(_studentKey(teacherId));
    if (studentId == null || studentId.isEmpty) return null;
    return StarterSampleData(
      studentId: studentId,
      lessonId: box.get(_lessonKey(teacherId)),
      practiceLogId: box.get(_practiceLogKey(teacherId)),
    );
  }

  String _teacherPrefix(String teacherId) => 'teacher:$teacherId';

  String _studentKey(String teacherId) =>
      '${_teacherPrefix(teacherId)}:studentId';

  String _lessonKey(String teacherId) =>
      '${_teacherPrefix(teacherId)}:lessonId';

  String _practiceLogKey(String teacherId) =>
      '${_teacherPrefix(teacherId)}:practiceLogId';

  /// Records a freshly created sample.
  Future<void> save(StarterSampleData sample) async {
    final teacherId = ref.read(currentUserIdProvider);
    final box = await Hive.openBox<String>(_boxName);
    await box.put(_studentKey(teacherId), sample.studentId);
    await _putOrDelete(box, _lessonKey(teacherId), sample.lessonId);
    await _putOrDelete(box, _practiceLogKey(teacherId), sample.practiceLogId);
    state = AsyncData(sample);
  }

  /// Forgets the sample after it was removed.
  Future<void> clear() async {
    final teacherId = ref.read(currentUserIdProvider);
    final box = await Hive.openBox<String>(_boxName);
    await box.delete(_studentKey(teacherId));
    await box.delete(_lessonKey(teacherId));
    await box.delete(_practiceLogKey(teacherId));
    state = const AsyncData(null);
  }

  Future<void> _putOrDelete(Box<String> box, String key, String? value) {
    return value == null ? box.delete(key) : box.put(key, value);
  }
}
