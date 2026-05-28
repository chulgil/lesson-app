import 'package:json_annotation/json_annotation.dart';

part 'cancellation_defaults.g.dart';

/// Teacher cancellation policy defaults
@JsonSerializable()
class CancellationDefaults {
  final String id;

  /// Hours before lesson start within which cancellation incurs no penalty
  /// (default: 12 hours)
  final int cancellationDeadlineHours;

  /// Whether to grant extra practice minutes as compensation for late student cancellation
  /// (default: true)
  final bool studentCompensationExtraMinutesEnabled;

  /// Whether to include compensation message in late cancellation notice to student
  /// (default: true)
  final bool includeExtraMinutesTextOnLateCancel;

  /// Custom compensation message shown to student on late cancellation
  /// (e.g., "10분 보너스 연습시간을 제공해드립니다")
  final String? studentCompensationExtraMinutesMessage;

  /// Whether to notify teacher when student cancels after deadline
  /// Only applicable for academy teachers (orgType == 'academy')
  /// (default: false)
  final bool notifyOwnerOnLateCancel;

  final DateTime createdAt;
  final DateTime? updatedAt;

  const CancellationDefaults({
    required this.id,
    this.cancellationDeadlineHours = 12,
    this.studentCompensationExtraMinutesEnabled = true,
    this.includeExtraMinutesTextOnLateCancel = true,
    this.studentCompensationExtraMinutesMessage,
    this.notifyOwnerOnLateCancel = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory CancellationDefaults.fromJson(Map<String, dynamic> json) =>
      _$CancellationDefaultsFromJson(json);

  Map<String, dynamic> toJson() => _$CancellationDefaultsToJson(this);

  /// Create a copy with modified fields
  CancellationDefaults copyWith({
    String? id,
    int? cancellationDeadlineHours,
    bool? studentCompensationExtraMinutesEnabled,
    bool? includeExtraMinutesTextOnLateCancel,
    String? studentCompensationExtraMinutesMessage,
    bool? notifyOwnerOnLateCancel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CancellationDefaults(
      id: id ?? this.id,
      cancellationDeadlineHours:
          cancellationDeadlineHours ?? this.cancellationDeadlineHours,
      studentCompensationExtraMinutesEnabled:
          studentCompensationExtraMinutesEnabled ??
          this.studentCompensationExtraMinutesEnabled,
      includeExtraMinutesTextOnLateCancel:
          includeExtraMinutesTextOnLateCancel ??
          this.includeExtraMinutesTextOnLateCancel,
      studentCompensationExtraMinutesMessage:
          studentCompensationExtraMinutesMessage ??
          this.studentCompensationExtraMinutesMessage,
      notifyOwnerOnLateCancel:
          notifyOwnerOnLateCancel ?? this.notifyOwnerOnLateCancel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
