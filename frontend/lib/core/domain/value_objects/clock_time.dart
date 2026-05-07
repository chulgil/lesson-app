/// Pure domain representation of a wall-clock time.
class ClockTime {
  final int hour;
  final int minute;

  const ClockTime({required this.hour, required this.minute})
    : assert(hour >= 0 && hour < 24),
      assert(minute >= 0 && minute < 60);

  factory ClockTime.fromJson(Map<String, dynamic> json) {
    return ClockTime(hour: json['hour'] as int, minute: json['minute'] as int);
  }

  factory ClockTime.fromMinutes(int minutes) {
    final normalized = minutes % Duration.minutesPerDay;
    return ClockTime(
      hour: normalized ~/ Duration.minutesPerHour,
      minute: normalized % Duration.minutesPerHour,
    );
  }

  factory ClockTime.parse(String time) {
    final parts = time.split(':');
    return ClockTime(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  int get inMinutes => hour * Duration.minutesPerHour + minute;

  Map<String, dynamic> toJson() => {'hour': hour, 'minute': minute};

  String format24Hour() {
    final hourStr = hour.toString().padLeft(2, '0');
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$hourStr:$minuteStr';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClockTime && other.hour == hour && other.minute == minute;
  }

  @override
  int get hashCode => Object.hash(hour, minute);
}
