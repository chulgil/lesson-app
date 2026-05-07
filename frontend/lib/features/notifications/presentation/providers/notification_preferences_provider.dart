import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/notification_preferences.dart';

part 'notification_preferences_provider.g.dart';

const _boxName = 'notification_settings';
const _preferencesKey = 'notification_preferences';

/// Hive-backed provider for per-category notification preferences.
///
/// keepAlive: app-wide setting, should not be disposed during session.
@Riverpod(keepAlive: true)
class NotificationPreferencesNotifier
    extends _$NotificationPreferencesNotifier {
  @override
  NotificationPreferences build() {
    return _loadFromHive() ?? NotificationPreferences.defaults;
  }

  NotificationPreferences? _loadFromHive() {
    try {
      final box = Hive.box(_boxName);
      final jsonStr = box.get(_preferencesKey) as String?;
      if (jsonStr == null) return null;
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return NotificationPreferences.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveToHive(NotificationPreferences prefs) async {
    try {
      final box = Hive.box(_boxName);
      await box.put(_preferencesKey, jsonEncode(prefs.toJson()));
    } catch (_) {
      // Storage failure is non-blocking
    }
  }

  /// Toggle the global master switch.
  void toggleMaster(bool enabled) {
    state = state.copyWith(masterEnabled: enabled);
    _saveToHive(state);
  }

  /// Toggle a specific category.
  void toggleCategory(NotificationCategory category, bool enabled) {
    state = switch (category) {
      NotificationCategory.lesson =>
        state.copyWith(lessonEnabled: enabled),
      NotificationCategory.schedule =>
        state.copyWith(scheduleEnabled: enabled),
      NotificationCategory.subscription =>
        state.copyWith(subscriptionEnabled: enabled),
      NotificationCategory.announcement =>
        state.copyWith(announcementEnabled: enabled),
      NotificationCategory.practice =>
        state.copyWith(practiceEnabled: enabled),
      NotificationCategory.marketing =>
        state.copyWith(marketingEnabled: enabled),
    };
    _saveToHive(state);
  }

  /// Set DND hours. Pass null for both to disable DND.
  void setQuietHours({required int? startHour, required int? endHour}) {
    state = state.copyWith(
      quietStartHour: startHour,
      quietEndHour: endHour,
    );
    _saveToHive(state);
  }

  /// Disable DND entirely.
  void clearQuietHours() {
    setQuietHours(startHour: null, endHour: null);
  }
}
