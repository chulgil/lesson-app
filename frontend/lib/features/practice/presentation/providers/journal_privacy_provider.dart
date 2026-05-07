import 'dart:async';

import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../features/auth/auth_facade.dart';
import '../../domain/entities/journal_privacy.dart';

part 'journal_privacy_provider.g.dart';

const _journalPrivacyBoxName = 'practice_journal_privacy';

String _journalPrivacyKey({required String userId, required String studentId}) {
  return 'user:$userId:student:$studentId';
}

@Riverpod(keepAlive: true)
class JournalPrivacySetting extends _$JournalPrivacySetting {
  String? _studentId;

  @override
  Future<JournalPrivacy> build(String studentId) async {
    _studentId = studentId;
    final userId = ref.watch(currentUserIdProvider);
    return _load(userId: userId, studentId: studentId);
  }

  Future<JournalPrivacy> _load({
    required String userId,
    required String studentId,
  }) async {
    try {
      final box = await Hive.openBox<Map>(_journalPrivacyBoxName);
      final stored = box.get(
        _journalPrivacyKey(userId: userId, studentId: studentId),
      );
      if (stored == null) {
        return JournalPrivacy.private;
      }

      final map = Map<String, dynamic>.from(stored);
      return journalPrivacyFromStorageValue(map['privacy'] as String?);
    } catch (_) {
      return JournalPrivacy.private;
    }
  }

  Future<void> setPrivacy(JournalPrivacy privacy) async {
    final userId = ref.read(currentUserIdProvider);
    final studentId = _studentId;
    if (studentId == null) {
      throw StateError('JournalPrivacySetting has not been initialized.');
    }

    try {
      final box = await Hive.openBox<Map>(_journalPrivacyBoxName);
      await box.put(
        _journalPrivacyKey(userId: userId, studentId: studentId),
        <String, dynamic>{
          'privacy': privacy.storageValue,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
      state = AsyncData(privacy);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> setPrivate() => setPrivacy(JournalPrivacy.private);

  Future<void> setPartial() => setPrivacy(JournalPrivacy.partial);

  Future<void> setShared() => setPrivacy(JournalPrivacy.shared);
}
