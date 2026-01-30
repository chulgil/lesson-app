import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'proposal_settings.g.dart';

/// Settings for subscription proposal behavior.
///
/// Teachers can configure:
/// - Auto-proposal after trial lesson completion
/// - Which templates to include in auto-proposals
/// - Golden time discount settings
/// - Auto-reminder settings
@HiveType(typeId: 98)
@JsonSerializable()
class ProposalSettings extends HiveObject {
  @HiveField(0)
  final String teacherId;

  /// Whether to automatically send proposals after trial lesson completion.
  /// Default: true
  @HiveField(1)
  final bool autoProposalEnabled;

  /// Template IDs to include in auto-proposals.
  /// If empty, all active templates are included.
  @HiveField(2)
  final List<String> autoProposalTemplateIds;

  /// Recommended template ID for auto-proposals.
  /// Shown with star (⭐) and pre-selected for students.
  @HiveField(3)
  final String? recommendedTemplateId;

  /// Golden time discount percentage (0-100).
  /// Applied to auto-proposals after trial completion.
  @HiveField(4)
  final int goldenTimeDiscountPercent;

  /// Golden time validity in hours.
  /// Discount expires after this many hours from trial completion.
  @HiveField(5)
  final int goldenTimeHours;

  /// Whether to send automatic reminders.
  @HiveField(6)
  final bool autoReminderEnabled;

  /// Reminder intervals in hours after proposal (e.g., [24, 48, 72]).
  @HiveField(7)
  final List<int> reminderHours;

  /// When these settings were last updated.
  @HiveField(8)
  final DateTime? updatedAt;

  ProposalSettings({
    required this.teacherId,
    this.autoProposalEnabled = true,
    this.autoProposalTemplateIds = const [],
    this.recommendedTemplateId,
    this.goldenTimeDiscountPercent = 10,
    this.goldenTimeHours = 24,
    this.autoReminderEnabled = true,
    this.reminderHours = const [24, 48, 72],
    this.updatedAt,
  });

  factory ProposalSettings.fromJson(Map<String, dynamic> json) =>
      _$ProposalSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$ProposalSettingsToJson(this);

  /// Default settings for a teacher.
  factory ProposalSettings.defaults(String teacherId) => ProposalSettings(
        teacherId: teacherId,
        autoProposalEnabled: true,
        autoProposalTemplateIds: const [],
        goldenTimeDiscountPercent: 10,
        goldenTimeHours: 24,
        autoReminderEnabled: true,
        reminderHours: const [24, 48, 72],
      );

  /// Whether golden time discount is enabled.
  bool get hasGoldenTimeDiscount => goldenTimeDiscountPercent > 0;

  /// Calculate golden time expiration from a given start time.
  DateTime goldenTimeExpiresAt(DateTime startTime) =>
      startTime.add(Duration(hours: goldenTimeHours));

  /// Whether golden time is still valid.
  bool isGoldenTimeValid(DateTime trialCompletedAt) =>
      DateTime.now().isBefore(goldenTimeExpiresAt(trialCompletedAt));

  /// Calculate discounted price.
  int applyGoldenTimeDiscount(int originalPrice) {
    if (goldenTimeDiscountPercent <= 0) return originalPrice;
    final discount = (originalPrice * goldenTimeDiscountPercent / 100).round();
    return originalPrice - discount;
  }

  ProposalSettings copyWith({
    String? teacherId,
    bool? autoProposalEnabled,
    List<String>? autoProposalTemplateIds,
    String? recommendedTemplateId,
    int? goldenTimeDiscountPercent,
    int? goldenTimeHours,
    bool? autoReminderEnabled,
    List<int>? reminderHours,
    DateTime? updatedAt,
  }) {
    return ProposalSettings(
      teacherId: teacherId ?? this.teacherId,
      autoProposalEnabled: autoProposalEnabled ?? this.autoProposalEnabled,
      autoProposalTemplateIds:
          autoProposalTemplateIds ?? this.autoProposalTemplateIds,
      recommendedTemplateId:
          recommendedTemplateId ?? this.recommendedTemplateId,
      goldenTimeDiscountPercent:
          goldenTimeDiscountPercent ?? this.goldenTimeDiscountPercent,
      goldenTimeHours: goldenTimeHours ?? this.goldenTimeHours,
      autoReminderEnabled: autoReminderEnabled ?? this.autoReminderEnabled,
      reminderHours: reminderHours ?? this.reminderHours,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'ProposalSettings(teacherId: $teacherId, autoProposalEnabled: $autoProposalEnabled)';
}
