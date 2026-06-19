/// Pure domain representation of a wall-clock time.
class ClockTime {
  final int hour;
  final int minute;

  const ClockTime({required this.hour, required this.minute})
    : assert(hour >= 0 && hour < 24),
      assert(minute >= 0 && minute < 60);

  factory ClockTime.fromJson(Map<String, dynamic> json) {
    return ClockTime(
      hour: _coerceInt(json['hour']).clamp(0, 23),
      minute: _coerceInt(json['minute']).clamp(0, 59),
    );
  }

  /// Coerce a dynamic JSON value (int / num / numeric String / null) to int.
  /// Defensive against remote serialization variants; never throws.
  static int _coerceInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  factory ClockTime.fromMinutes(int minutes) {
    final normalized = minutes % Duration.minutesPerDay;
    return ClockTime(
      hour: normalized ~/ Duration.minutesPerHour,
      minute: normalized % Duration.minutesPerHour,
    );
  }

  /// Parses a wall-clock string. Total function — never throws on malformed
  /// input. Missing / extra / non-numeric / out-of-range parts fall back to 0
  /// and are clamped, so a single bad remote `startTime` cannot crash a build
  /// (#64 — release-mode gray ErrorWidget).
  factory ClockTime.parse(String time) {
    final parts = time.split(':');
    final hour = parts.isNotEmpty ? (int.tryParse(parts[0].trim()) ?? 0) : 0;
    final minute = parts.length > 1 ? (int.tryParse(parts[1].trim()) ?? 0) : 0;
    return ClockTime(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
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
