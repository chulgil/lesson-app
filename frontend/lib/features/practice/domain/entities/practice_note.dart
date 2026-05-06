import 'package:json_annotation/json_annotation.dart';

part 'practice_note.g.dart';

/// Practice note model for tracking practice observations
@JsonSerializable()
class PracticeNote {
  final String id;

  final String sectionId;

  final String content;

  final DateTime createdAt;

  final DateTime? updatedAt;

  PracticeNote({
    required this.id,
    required this.sectionId,
    required this.content,
    required this.createdAt,
    this.updatedAt,
  });

  factory PracticeNote.fromJson(Map<String, dynamic> json) =>
      _$PracticeNoteFromJson(json);

  Map<String, dynamic> toJson() => _$PracticeNoteToJson(this);

  /// Time format (e.g. "10:30")
  String get timeText {
    return '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  /// Date format (e.g. "2026-01-03")
  String get dateText {
    return '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
  }

  /// Whether the note has been edited
  bool get isEdited => updatedAt != null;

  /// Whether created today
  bool get isToday {
    final now = DateTime.now();
    return createdAt.year == now.year &&
        createdAt.month == now.month &&
        createdAt.day == now.day;
  }

  /// Whether created yesterday
  bool get isYesterday {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    return createdAt.year == yesterday.year &&
        createdAt.month == yesterday.month &&
        createdAt.day == yesterday.day;
  }

  /// Formatted relative date text
  String get relativeDateText {
    if (isToday) return '오늘';
    if (isYesterday) return '어제';
    return dateText;
  }

  PracticeNote copyWith({
    String? id,
    String? sectionId,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PracticeNote(
      id: id ?? this.id,
      sectionId: sectionId ?? this.sectionId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
