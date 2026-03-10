// Provider for practice reminder settings state management.

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'practice_reminder_provider.g.dart';

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
}

@Riverpod(keepAlive: true)
class PracticeReminder extends _$PracticeReminder {
  @override
  PracticeReminderState build() {
    return const PracticeReminderState();
  }

  void toggleEnabled(bool value) {
    state = state.copyWith(isEnabled: value);
  }

  void setTime(int hour, int minute) {
    state = state.copyWith(hour: hour, minute: minute);
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
    state = state.copyWith(selectedDays: days);
  }
}
