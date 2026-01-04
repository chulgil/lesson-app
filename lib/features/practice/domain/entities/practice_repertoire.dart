// Practice repertoire domain entities
// Moved from lib/models/practice_repertoire.dart for Clean Architecture

import 'package:hive/hive.dart';

import 'practice_note.dart';

part 'practice_repertoire.g.dart';

/// Range type for practice section (full, line, or measure)
enum SectionRangeType {
  full, // 전체 (범위 지정 없음)
  line, // 줄 단위 (1~3줄)
  measure, // 마디 단위 (1~10마디)
}

/// Daily practice status for a section on a specific date
class DailyPracticeStatus {
  final String id;
  final String sectionId;
  final DateTime date;
  final bool isCompleted;
  final DateTime? completedAt;

  const DailyPracticeStatus({
    required this.id,
    required this.sectionId,
    required this.date,
    this.isCompleted = false,
    this.completedAt,
  });

  /// Get date only (without time) for comparison
  DateTime get dateOnly => DateTime(date.year, date.month, date.day);

  DailyPracticeStatus copyWith({
    String? id,
    String? sectionId,
    DateTime? date,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return DailyPracticeStatus(
      id: id ?? this.id,
      sectionId: sectionId ?? this.sectionId,
      date: date ?? this.date,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyPracticeStatus &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Practice recording model
@HiveType(typeId: 30)
class PracticeRecording extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String sectionId;

  @HiveField(2)
  final String filePath;

  @HiveField(3)
  final int durationSeconds;

  @HiveField(4)
  final int? bpm; // Metronome BPM used during recording

  @HiveField(5)
  final bool isRepresentative;

  @HiveField(6)
  final DateTime createdAt;

  PracticeRecording({
    required this.id,
    required this.sectionId,
    required this.filePath,
    required this.durationSeconds,
    this.bpm,
    this.isRepresentative = false,
    required this.createdAt,
  });

  /// Get formatted duration string (e.g., "1:23")
  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get BPM display string
  String? get bpmText => bpm != null ? '$bpm BPM' : null;

  PracticeRecording copyWith({
    String? id,
    String? sectionId,
    String? filePath,
    int? durationSeconds,
    int? bpm,
    bool? isRepresentative,
    DateTime? createdAt,
  }) {
    return PracticeRecording(
      id: id ?? this.id,
      sectionId: sectionId ?? this.sectionId,
      filePath: filePath ?? this.filePath,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      bpm: bpm ?? this.bpm,
      isRepresentative: isRepresentative ?? this.isRepresentative,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PracticeRecording &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Practice section model (piece + measure range)
class PracticeSection {
  final String id;
  final String repertoireId;
  final String pieceName;

  // Range type (line or measure)
  final SectionRangeType rangeType;

  // Measure range (when rangeType == measure)
  final int startMeasure;
  final int endMeasure;

  // Line range (when rangeType == line)
  final int? startLine;
  final int? endLine;

  final String? sectionName;
  final bool isCompleted;
  final bool isRepeat; // If true, shows every day with daily reset

  // N회 반복 설정 (null = 사용 안 함, 2~10 = 해당 횟수)
  final int? repeatCount;
  // 날짜별 반복 완료 횟수 (key: 'YYYY-MM-DD', value: 완료한 횟수)
  final Map<String, int> dailyRepeatCounts;

  // Section-level active period (optional, within repertoire dates)
  final DateTime? startDate;
  final DateTime? endDate;

  final int practiceCount;
  final int totalPracticeSeconds;
  final List<PracticeRecording> recordings;
  final List<DailyPracticeStatus> dailyStatuses; // Daily completion tracking
  final List<PracticeNote> notes; // Practice notes for this section
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final int? sortOrder; // Custom sort order for drag and drop
  final DateTime? lastPracticedAt; // Last practice time for sorting

  const PracticeSection({
    required this.id,
    required this.repertoireId,
    required this.pieceName,
    this.rangeType = SectionRangeType.measure, // Default to measure
    required this.startMeasure,
    required this.endMeasure,
    this.startLine,
    this.endLine,
    this.sectionName,
    this.isCompleted = false,
    this.isRepeat = true, // Default to repeat
    this.repeatCount,
    this.dailyRepeatCounts = const {},
    this.startDate,
    this.endDate,
    this.practiceCount = 0,
    this.totalPracticeSeconds = 0,
    this.recordings = const [],
    this.dailyStatuses = const [],
    this.notes = const [],
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.sortOrder,
    this.lastPracticedAt,
  });

  /// Get measure range display string (e.g., "1~4 마디")
  String get measureRangeText => '$startMeasure~$endMeasure 마디';

  /// Get line range display string (e.g., "1~3줄")
  String get lineRangeText =>
      startLine != null && endLine != null ? '$startLine~$endLine줄' : '';

  /// Get range display string based on rangeType
  String get rangeText {
    switch (rangeType) {
      case SectionRangeType.full:
        return '전체';
      case SectionRangeType.line:
        return lineRangeText;
      case SectionRangeType.measure:
        return measureRangeText;
    }
  }

  /// Get display name (section name or auto-generated)
  String get displayName => sectionName ?? rangeText;

  /// Check if N회 반복 is enabled
  bool get hasRepeatCount => repeatCount != null && repeatCount! >= 2;

  /// Get completed repeat count for a specific date
  int getRepeatCompletedCount(DateTime date) {
    final dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return dailyRepeatCounts[dateKey] ?? 0;
  }

  /// Check if all repeats are completed for a date
  bool isAllRepeatsCompletedForDate(DateTime date) {
    if (!hasRepeatCount) return isCompletedForDate(date);
    return getRepeatCompletedCount(date) >= repeatCount!;
  }

  /// Get date key string for dailyRepeatCounts
  static String dateToKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get representative recording if exists
  PracticeRecording? get representativeRecording {
    try {
      return recordings.firstWhere((r) => r.isRepresentative);
    } catch (_) {
      return recordings.isNotEmpty ? recordings.first : null;
    }
  }

  /// Get formatted total practice time
  String get formattedTotalTime {
    if (totalPracticeSeconds == 0) return '0분';
    final hours = totalPracticeSeconds ~/ 3600;
    final minutes = (totalPracticeSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '$hours시간 $minutes분';
    }
    return '$minutes분';
  }

  /// Get the latest note
  PracticeNote? get latestNote {
    if (notes.isEmpty) return null;
    return notes.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b);
  }

  /// Get notes grouped by date
  Map<String, List<PracticeNote>> get notesByDate {
    final grouped = <String, List<PracticeNote>>{};
    for (final note in notes) {
      final dateKey = note.dateText;
      grouped.putIfAbsent(dateKey, () => []).add(note);
    }
    // Sort each group by time (newest first)
    for (final list in grouped.values) {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return grouped;
  }

  /// Check if this section is completed for a specific date
  bool isCompletedForDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return dailyStatuses.any((s) => s.dateOnly == dateOnly && s.isCompleted);
  }

  /// Get daily status for a specific date
  DailyPracticeStatus? getStatusForDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    try {
      return dailyStatuses.firstWhere((s) => s.dateOnly == dateOnly);
    } catch (_) {
      return null;
    }
  }

  /// Check if this section should be visible for a date
  /// - If repeat is ON: always visible
  /// - If repeat is OFF: visible only if not completed on any previous day
  bool isVisibleForDate(DateTime date) {
    if (isRepeat) return true;
    // If repeat is off and completed on a previous day, don't show
    final dateOnly = DateTime(date.year, date.month, date.day);
    return !dailyStatuses
        .any((s) => s.isCompleted && s.dateOnly.isBefore(dateOnly));
  }

  PracticeSection copyWith({
    String? id,
    String? repertoireId,
    String? pieceName,
    SectionRangeType? rangeType,
    int? startMeasure,
    int? endMeasure,
    int? startLine,
    int? endLine,
    String? sectionName,
    bool? isCompleted,
    bool? isRepeat,
    int? repeatCount,
    bool clearRepeatCount = false,
    Map<String, int>? dailyRepeatCounts,
    DateTime? startDate,
    DateTime? endDate,
    bool clearStartDate = false,
    bool clearEndDate = false,
    int? practiceCount,
    int? totalPracticeSeconds,
    List<PracticeRecording>? recordings,
    List<DailyPracticeStatus>? dailyStatuses,
    List<PracticeNote>? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    int? sortOrder,
    DateTime? lastPracticedAt,
  }) {
    return PracticeSection(
      id: id ?? this.id,
      repertoireId: repertoireId ?? this.repertoireId,
      pieceName: pieceName ?? this.pieceName,
      rangeType: rangeType ?? this.rangeType,
      startMeasure: startMeasure ?? this.startMeasure,
      endMeasure: endMeasure ?? this.endMeasure,
      startLine: startLine ?? this.startLine,
      endLine: endLine ?? this.endLine,
      sectionName: sectionName ?? this.sectionName,
      isCompleted: isCompleted ?? this.isCompleted,
      isRepeat: isRepeat ?? this.isRepeat,
      repeatCount: clearRepeatCount ? null : (repeatCount ?? this.repeatCount),
      dailyRepeatCounts: dailyRepeatCounts ?? this.dailyRepeatCounts,
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      practiceCount: practiceCount ?? this.practiceCount,
      totalPracticeSeconds: totalPracticeSeconds ?? this.totalPracticeSeconds,
      recordings: recordings ?? this.recordings,
      dailyStatuses: dailyStatuses ?? this.dailyStatuses,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      sortOrder: sortOrder ?? this.sortOrder,
      lastPracticedAt: lastPracticedAt ?? this.lastPracticedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PracticeSection &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Practice repertoire model (book or piece collection)
class PracticeRepertoire {
  final String id;
  final String studentId;
  final String name;
  final String? description;
  final DateTime startDate; // When this repertoire becomes active
  final DateTime? endDate; // When this repertoire ends (null = ongoing)
  final List<PracticeSection> sections;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isArchived; // Archive status
  final DateTime? archivedAt; // When this repertoire was archived

  const PracticeRepertoire({
    required this.id,
    required this.studentId,
    required this.name,
    this.description,
    required this.startDate,
    this.endDate,
    this.sections = const [],
    required this.createdAt,
    this.updatedAt,
    this.isArchived = false,
    this.archivedAt,
  });

  /// Check if this repertoire is active (not archived)
  bool get isActive => !isArchived;

  /// Get completion rate (0.0 to 1.0)
  double get completionRate {
    if (sections.isEmpty) return 0.0;
    final completed = sections.where((s) => s.isCompleted).length;
    return completed / sections.length;
  }

  /// Get completion percentage string
  String get completionPercentage => '${(completionRate * 100).round()}%';

  /// Get completed section count
  int get completedSectionCount =>
      sections.where((s) => s.isCompleted).length;

  /// Get total practice count across all sections
  int get totalPracticeCount =>
      sections.fold(0, (sum, s) => sum + s.practiceCount);

  /// Get total practice time in seconds across all sections
  int get totalPracticeSeconds =>
      sections.fold(0, (sum, s) => sum + s.totalPracticeSeconds);

  /// Get formatted total practice time
  String get formattedTotalTime {
    if (totalPracticeSeconds == 0) return '0분';
    final hours = totalPracticeSeconds ~/ 3600;
    final minutes = (totalPracticeSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '$hours시간 $minutes분';
    }
    return '$minutes분';
  }

  /// Check if this repertoire is active for a specific date
  bool isActiveForDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);

    // Check if date is on or after start date
    if (dateOnly.isBefore(start)) return false;

    // If no end date, it's ongoing
    if (endDate == null) return true;

    // Check if date is on or before end date
    final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
    return !dateOnly.isAfter(end);
  }

  /// Get date range display string
  String get dateRangeText {
    final startStr = '${startDate.month}/${startDate.day}';
    if (endDate == null) {
      return '$startStr~계속';
    }
    final endStr = '${endDate!.month}/${endDate!.day}';
    return '$startStr~$endStr';
  }

  /// Get visible sections for a specific date
  List<PracticeSection> getSectionsForDate(DateTime date) {
    return sections.where((s) => s.isVisibleForDate(date)).toList();
  }

  PracticeRepertoire copyWith({
    String? id,
    String? studentId,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
    List<PracticeSection>? sections,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isArchived,
    DateTime? archivedAt,
  }) {
    return PracticeRepertoire(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      name: name ?? this.name,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      sections: sections ?? this.sections,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PracticeRepertoire &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
