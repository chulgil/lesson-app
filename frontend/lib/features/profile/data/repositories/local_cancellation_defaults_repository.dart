import 'dart:convert';

import 'package:hive/hive.dart';

import '../../domain/entities/cancellation_defaults.dart';
import '../../domain/repositories/cancellation_defaults_repository.dart';

/// Local, user-scoped persistent implementation of
/// [CancellationDefaultsRepository].
///
/// Used in remote mode while there is no backend endpoint for cancellation
/// policy defaults yet (#5 D-G3). Unlike the mock repository, this persists the
/// teacher's edits across app restarts and does NOT seed dummy data, so a real
/// user's policy is never silently reset.
class LocalCancellationDefaultsRepository
    implements CancellationDefaultsRepository {
  LocalCancellationDefaultsRepository({required this.teacherId});

  /// User id used to scope the stored value (`teacher:<id>:cancellation`).
  final String teacherId;

  static const _boxName = 'cancellation_defaults';

  String get _key => 'teacher:$teacherId:cancellation';

  Future<Box<String>> _openBox() => Hive.openBox<String>(_boxName);

  @override
  Future<CancellationDefaults> getCancellationDefaults() async {
    final box = await _openBox();
    final raw = box.get(_key);
    if (raw == null) {
      // No stored value yet — return neutral defaults (no dummy message).
      return CancellationDefaults(
        id: teacherId.isEmpty ? 'teacher' : teacherId,
        createdAt: DateTime.now(),
      );
    }
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return CancellationDefaults.fromJson(json);
  }

  @override
  Future<CancellationDefaults> updateCancellationDefaults(
    CancellationDefaults defaults,
  ) async {
    final box = await _openBox();
    final updated = defaults.copyWith(updatedAt: DateTime.now());
    await box.put(_key, jsonEncode(updated.toJson()));
    return updated;
  }
}
