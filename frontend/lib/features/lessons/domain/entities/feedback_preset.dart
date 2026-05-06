import 'package:json_annotation/json_annotation.dart';

part 'feedback_preset.g.dart';

/// Custom feedback preset phrase for quick lesson feedback.
///
/// Teachers can add their own presets in addition to the default ones.
/// Default presets can be hidden but not permanently deleted.
@JsonSerializable()
class FeedbackPreset {
  final String id;

  /// The preset phrase text
  final String text;

  /// Teacher who created this preset (null = default/system preset)
  final String? teacherId;

  /// Display order (lower = first)
  final int sortOrder;

  /// Whether this is a default (system) preset
  final bool isDefault;

  /// Whether this preset is hidden (for default presets that user wants to hide)
  final bool isHidden;

  final DateTime createdAt;

  FeedbackPreset({
    required this.id,
    required this.text,
    this.teacherId,
    this.sortOrder = 0,
    this.isDefault = false,
    this.isHidden = false,
    required this.createdAt,
  });

  factory FeedbackPreset.fromJson(Map<String, dynamic> json) =>
      _$FeedbackPresetFromJson(json);

  Map<String, dynamic> toJson() => _$FeedbackPresetToJson(this);

  FeedbackPreset copyWith({
    String? id,
    String? text,
    String? teacherId,
    int? sortOrder,
    bool? isDefault,
    bool? isHidden,
    DateTime? createdAt,
  }) {
    return FeedbackPreset(
      id: id ?? this.id,
      text: text ?? this.text,
      teacherId: teacherId ?? this.teacherId,
      sortOrder: sortOrder ?? this.sortOrder,
      isDefault: isDefault ?? this.isDefault,
      isHidden: isHidden ?? this.isHidden,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
