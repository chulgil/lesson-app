import 'dart:convert';

import 'package:hive/hive.dart';

import '../../domain/entities/spotlight_prompt.dart';
import '../../domain/repositories/spotlight_prompt_repository.dart';

/// Hive 기반 [SpotlightPromptRepository] 구현 — 런타임 영속.
///
/// 플랜 Job 2 Task 2.3 / O2 결정: 단일 `Box<String>` `spotlight_prompt_v1`,
/// key = `{studentId}::{promptId}`, value = `jsonEncode(SpotlightPrompt.toJson())`.
/// 학생별 box 분리 부담 회피 — prefix scan 으로 격리.
class HiveSpotlightPromptRepository implements SpotlightPromptRepository {
  HiveSpotlightPromptRepository({required Box<String> box}) : _box = box;

  /// Box name = `spotlight_prompt_v1` (글로서리 §15 P3 / O2).
  static const String boxName = 'spotlight_prompt_v1';

  static const String _keySeparator = '::';

  final Box<String> _box;

  static String composeKey(String studentId, String id) =>
      '$studentId$_keySeparator$id';

  SpotlightPrompt? _decode(String? raw) {
    if (raw == null) return null;
    try {
      return SpotlightPrompt.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<SpotlightPrompt> _save(SpotlightPrompt prompt) async {
    final key = composeKey(prompt.studentId, prompt.id);
    await _box.put(key, jsonEncode(prompt.toJson()));
    return prompt;
  }

  @override
  Future<void> enqueue(SpotlightPrompt prompt) async {
    await _save(prompt);
  }

  @override
  Future<List<SpotlightPrompt>> listForStudent(String studentId) async {
    final prefix = '$studentId$_keySeparator';
    final results = <SpotlightPrompt>[];
    for (final key in _box.keys) {
      if (key is! String) continue;
      if (!key.startsWith(prefix)) continue;
      final decoded = _decode(_box.get(key));
      if (decoded != null) results.add(decoded);
    }
    return results;
  }

  @override
  Future<SpotlightPrompt?> getById(String id) async {
    final suffix = '$_keySeparator$id';
    for (final key in _box.keys) {
      if (key is! String) continue;
      if (!key.endsWith(suffix)) continue;
      final decoded = _decode(_box.get(key));
      if (decoded != null) return decoded;
    }
    return null;
  }

  Future<SpotlightPrompt> _requireById(String id) async {
    final p = await getById(id);
    if (p == null) {
      throw StateError('SpotlightPrompt not found: $id');
    }
    return p;
  }

  @override
  Future<SpotlightPrompt> markShown(String id, DateTime now) async {
    final updated = (await _requireById(id)).copyWith(lastShownAt: now);
    return _save(updated);
  }

  @override
  Future<SpotlightPrompt> incrementDecline(String id, DateTime now) async {
    final current = await _requireById(id);
    final updated = current.copyWith(
      declineCount: current.declineCount + 1,
      lastShownAt: now,
    );
    return _save(updated);
  }

  @override
  Future<SpotlightPrompt> setHideUntil(String id, DateTime until) async {
    final updated = (await _requireById(id)).copyWith(hideUntil: until);
    return _save(updated);
  }

  @override
  Future<SpotlightPrompt> markPermanentlyHidden(String id) async {
    final updated = (await _requireById(id)).copyWith(permanentlyHidden: true);
    return _save(updated);
  }
}
