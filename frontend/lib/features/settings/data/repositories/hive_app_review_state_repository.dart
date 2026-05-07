import 'dart:convert';

import 'package:hive/hive.dart';

import '../../domain/entities/app_review_state.dart';
import '../../domain/repositories/app_review_state_repository.dart';

const String kAppReviewStateBoxKey = 'app_review_state';
const String _kStateKey = 'state';

/// Hive-backed implementation of [AppReviewStateRepository].
///
/// Stores [AppReviewState] as a JSON string in a dedicated Hive box.
/// No custom adapter needed — uses `jsonEncode`/`jsonDecode`.
class HiveAppReviewStateRepository implements AppReviewStateRepository {
  HiveAppReviewStateRepository({required Box<String> box}) : _box = box;

  final Box<String> _box;

  @override
  Future<AppReviewState> getState() async {
    final raw = _box.get(_kStateKey);
    if (raw == null) return const AppReviewState.initial();
    try {
      return AppReviewState.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return const AppReviewState.initial();
    }
  }

  @override
  Future<void> saveState(AppReviewState state) async {
    await _box.put(_kStateKey, jsonEncode(state.toJson()));
  }

  @override
  Future<void> reset() async {
    await _box.delete(_kStateKey);
  }
}
