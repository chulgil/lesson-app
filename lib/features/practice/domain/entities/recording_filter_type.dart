// Recording filter type enum for section detail screen

/// Filter type for recordings list
enum RecordingFilterType {
  /// Show all recordings
  all,

  /// Show recordings from the week containing the selected date (Mon-Sun)
  weekly,

  /// Show recordings from the selected date only
  daily,
}

/// Extension for RecordingFilterType display label
extension RecordingFilterTypeExtension on RecordingFilterType {
  String get displayLabel {
    switch (this) {
      case RecordingFilterType.all:
        return '전체';
      case RecordingFilterType.weekly:
        return '주간';
      case RecordingFilterType.daily:
        return '당일';
    }
  }
}
