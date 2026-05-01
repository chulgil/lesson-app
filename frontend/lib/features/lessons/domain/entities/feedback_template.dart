// Feedback template domain entity.
// Teacher writes a long feedback body once and reuses it during lesson feedback.
// Distinct from TipTemplate (practice tips for students).
import 'package:json_annotation/json_annotation.dart';

part 'feedback_template.g.dart';

/// Category for feedback templates. Aligned with TipCategory naming for UX consistency.
enum FeedbackCategory { technique, musicality, practice, attitude, general }

extension FeedbackCategoryExtension on FeedbackCategory {
  String get label {
    switch (this) {
      case FeedbackCategory.technique:
        return '테크닉';
      case FeedbackCategory.musicality:
        return '음악성';
      case FeedbackCategory.practice:
        return '연습';
      case FeedbackCategory.attitude:
        return '태도';
      case FeedbackCategory.general:
        return '일반';
    }
  }
}

/// Feedback template — a reusable lesson feedback body with metadata tags.
///
/// Tags are metadata only (used for search/filter), not auto-prepended to body.
@JsonSerializable()
class FeedbackTemplate {
  final String id;
  final String teacherId;

  /// Short display name (shown in list/picker).
  final String title;

  /// Full feedback body (replaces feedback text on apply).
  final String body;

  /// Metadata tags for filtering/search (e.g. '음정 주의', '리듬 좋음').
  final List<String> tags;

  final FeedbackCategory category;
  final int usageCount;
  final DateTime createdAt;
  final DateTime? lastUsedAt;

  const FeedbackTemplate({
    required this.id,
    required this.teacherId,
    required this.title,
    required this.body,
    this.tags = const [],
    this.category = FeedbackCategory.general,
    this.usageCount = 0,
    required this.createdAt,
    this.lastUsedAt,
  });

  factory FeedbackTemplate.fromJson(Map<String, dynamic> json) =>
      _$FeedbackTemplateFromJson(json);

  Map<String, dynamic> toJson() => _$FeedbackTemplateToJson(this);

  FeedbackTemplate copyWith({
    String? id,
    String? teacherId,
    String? title,
    String? body,
    List<String>? tags,
    FeedbackCategory? category,
    int? usageCount,
    DateTime? createdAt,
    DateTime? lastUsedAt,
  }) {
    return FeedbackTemplate(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      title: title ?? this.title,
      body: body ?? this.body,
      tags: tags ?? this.tags,
      category: category ?? this.category,
      usageCount: usageCount ?? this.usageCount,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  FeedbackTemplate incrementUsage() {
    return copyWith(usageCount: usageCount + 1, lastUsedAt: DateTime.now());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeedbackTemplate &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
