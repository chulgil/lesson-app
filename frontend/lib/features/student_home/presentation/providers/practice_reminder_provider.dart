// Provider for practice reminder settings state management.

import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../auth/auth_facade.dart';
import '../../../notifications/notifications_facade.dart';

part 'practice_reminder_provider.g.dart';

// Opened at bootstrap (app_bootstrap.dart) — same box as the general
// notification preferences.
const _boxName = 'notification_settings';

/// Practice reminder settings state.
class PracticeReminderState {
  final bool isEnabled;
  final int hour;
  final int minute;
  final Set<int> selectedDays; // 0=Mon, 1=Tue, ..., 6=Sun

  const PracticeReminderState({
    this.isEnabled = true,
    this.hour = 17,
    this.minute = 0,
    this.selectedDays = const {0, 1, 2, 3, 4, 5, 6},
  });

  String get formattedTime {
    final period = hour < 12 ? '오전' : '오후';
    final displayHour = hour == 0
        ? 12
        : hour > 12
            ? hour - 12
            : hour;
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$period $displayHour:$displayMinute';
  }

  PracticeReminderState copyWith({
    bool? isEnabled,
    int? hour,
    int? minute,
    Set<int>? selectedDays,
  }) {
    return PracticeReminderState(
      isEnabled: isEnabled ?? this.isEnabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      selectedDays: selectedDays ?? this.selectedDays,
    );
  }

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'hour': hour,
        'minute': minute,
        'selectedDays': selectedDays.toList()..sort(),
      };

  factory PracticeReminderState.fromJson(Map<String, dynamic> json) {
    return PracticeReminderState(
      isEnabled: (json['isEnabled'] as bool?) ?? true,
      hour: (json['hour'] as int?) ?? 17,
      minute: (json['minute'] as int?) ?? 0,
      selectedDays:
          (json['selectedDays'] as List<dynamic>?)?.cast<int>().toSet() ??
              const {0, 1, 2, 3, 4, 5, 6},
    );
  }
}

@Riverpod(keepAlive: true)
class PracticeReminder extends _$PracticeReminder {
  @override
  PracticeReminderState build() {
    final userId = ref.watch(currentUserIdProvider);
    return _loadFromHive(userId) ?? const PracticeReminderState();
  }

  void toggleEnabled(bool value) {
    _update(state.copyWith(isEnabled: value));
  }

  void setTime(int hour, int minute) {
    _update(state.copyWith(hour: hour, minute: minute));
  }

  void toggleDay(int day) {
    final days = Set<int>.from(state.selectedDays);
    if (days.contains(day)) {
      if (days.length > 1) {
        days.remove(day);
      }
    } else {
      days.add(day);
    }
    _update(state.copyWith(selectedDays: days));
  }

  void _update(PracticeReminderState newState) {
    state = newState;
    _saveToHive(newState);
    _resyncSchedule(newState);
  }

  String _key(String userId) => 'student:$userId:practiceReminder';

  PracticeReminderState? _loadFromHive(String userId) {
    try {
      final box = Hive.box(_boxName);
      final jsonStr = box.get(_key(userId)) as String?;
      if (jsonStr == null) return null;
      return PracticeReminderState.fromJson(
        jsonDecode(jsonStr) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveToHive(PracticeReminderState newState) async {
    try {
      final box = Hive.box(_boxName);
      await box.put(
        _key(ref.read(currentUserIdProvider)),
        jsonEncode(newState.toJson()),
      );
    } catch (_) {
      // Storage failure is non-blocking.
    }
  }

  /// Full resync of the OS-level weekly schedule (#503). Delivery still
  /// passes the preference gate at schedule time; notifications already
  /// handed to the OS are not revoked by later preference changes.
  Future<void> _resyncSchedule(PracticeReminderState newState) async {
    final userId = ref.read(currentUserIdProvider);
    final scheduler = ref.read(practiceReminderSchedulerProvider);
    try {
      if (!newState.isEnabled) {
        await scheduler.cancelWeeklyReminders(userId);
        return;
      }
      await scheduler.scheduleWeeklyReminders(
        userId: userId,
        hour: newState.hour,
        minute: newState.minute,
        weekdays: newState.selectedDays,
        title: AppStrings.notifPracticeReminderTitle,
        body: AppStrings.notifPracticeReminderBody,
      );
    } catch (_) {
      // Platform plugin unavailable (e.g. tests) — settings stay persisted.
    }
  }
}
