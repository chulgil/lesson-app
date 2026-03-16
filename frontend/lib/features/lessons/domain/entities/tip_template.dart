// Tip template domain entities
// Moved from lib/models/tip_template.dart for Clean Architecture
import 'package:json_annotation/json_annotation.dart';
part 'tip_template.g.dart';

/// Category for tip templates
enum TipCategory {
  technique, // Bow, fingering, posture, etc.
  musicality, // Expression, dynamics, phrasing
  practice, // Practice methods
  mindset, // Mental preparation, performance anxiety
  general, // General tips
}

extension TipCategoryExtension on TipCategory {
  String get label {
    switch (this) {
      case TipCategory.technique:
        return '테크닉';
      case TipCategory.musicality:
        return '음악성';
      case TipCategory.practice:
        return '연습법';
      case TipCategory.mindset:
        return '마인드셋';
      case TipCategory.general:
        return '일반';
    }
  }

  String get icon {
    switch (this) {
      case TipCategory.technique:
        return 'build';
      case TipCategory.musicality:
        return 'music_note';
      case TipCategory.practice:
        return 'repeat';
      case TipCategory.mindset:
        return 'psychology';
      case TipCategory.general:
        return 'lightbulb';
    }
  }
}

/// Template for frequently used tips
@JsonSerializable()
class TipTemplate {
  final String id;
  final String teacherId;
  final String content;
  final TipCategory category;
  final String? instrument; // null means applicable to all instruments
  final int usageCount; // Track how often this tip is used
  final DateTime createdAt;
  final DateTime? lastUsedAt;

  const TipTemplate({
    required this.id,
    required this.teacherId,
    required this.content,
    this.category = TipCategory.general,
    this.instrument,
    this.usageCount = 0,
    required this.createdAt,
    this.lastUsedAt,
  });

  factory TipTemplate.fromJson(Map<String, dynamic> json) =>
      _$TipTemplateFromJson(json);

  Map<String, dynamic> toJson() => _$TipTemplateToJson(this);

  TipTemplate copyWith({
    String? id,
    String? teacherId,
    String? content,
    TipCategory? category,
    String? instrument,
    int? usageCount,
    DateTime? createdAt,
    DateTime? lastUsedAt,
  }) {
    return TipTemplate(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      content: content ?? this.content,
      category: category ?? this.category,
      instrument: instrument ?? this.instrument,
      usageCount: usageCount ?? this.usageCount,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  /// Increment usage count
  TipTemplate incrementUsage() {
    return copyWith(
      usageCount: usageCount + 1,
      lastUsedAt: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TipTemplate &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
