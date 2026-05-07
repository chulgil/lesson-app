/// Local state for the app rating prompt flow.
///
/// Stored in Hive as JSON (no generated adapter needed).
/// Spec: `docs/specs/settings/app_rating_prompt_spec.md` §4.1
class AppReviewState {
  /// Last date/time the prompt was shown to the user.
  /// Null = never shown.
  final DateTime? lastPromptDate;

  /// How many times the user chose "나중에" / dissatisfied path.
  final int dismissCount;

  /// Whether the user has tapped "requestReview" (네, 도움돼요!).
  final bool hasRated;

  const AppReviewState({
    this.lastPromptDate,
    this.dismissCount = 0,
    this.hasRated = false,
  });

  /// State for a freshly installed app.
  const AppReviewState.initial()
      : lastPromptDate = null,
        dismissCount = 0,
        hasRated = false;

  /// Returns true if the prompt should no longer be shown (permanent suppression).
  bool get isPermanentlySuppressed => hasRated || dismissCount >= 3;

  /// Returns true if enough time has passed since the last prompt (90-day window).
  bool get canShowAgain {
    if (lastPromptDate == null) return true;
    return DateTime.now().difference(lastPromptDate!).inDays > 90;
  }

  AppReviewState copyWith({
    Object? lastPromptDate = _absent,
    int? dismissCount,
    bool? hasRated,
  }) {
    return AppReviewState(
      lastPromptDate: identical(lastPromptDate, _absent)
          ? this.lastPromptDate
          : lastPromptDate as DateTime?,
      dismissCount: dismissCount ?? this.dismissCount,
      hasRated: hasRated ?? this.hasRated,
    );
  }

  Map<String, dynamic> toJson() => {
        'lastPromptDate': lastPromptDate?.toIso8601String(),
        'dismissCount': dismissCount,
        'hasRated': hasRated,
      };

  factory AppReviewState.fromJson(Map<String, dynamic> json) {
    return AppReviewState(
      lastPromptDate: json['lastPromptDate'] != null
          ? DateTime.parse(json['lastPromptDate'] as String)
          : null,
      dismissCount: (json['dismissCount'] as int?) ?? 0,
      hasRated: (json['hasRated'] as bool?) ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppReviewState &&
          lastPromptDate == other.lastPromptDate &&
          dismissCount == other.dismissCount &&
          hasRated == other.hasRated;

  @override
  int get hashCode =>
      Object.hash(lastPromptDate, dismissCount, hasRated);
}

// Sentinel for nullable copyWith fields.
const _absent = Object();
