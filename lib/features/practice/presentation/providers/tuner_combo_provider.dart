import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/tuner_types.dart';
import 'tuner_provider.dart';

part 'tuner_combo_provider.g.dart';

/// Combo state for gamification.
class ComboState {
  const ComboState({
    this.count = 0,
    this.maxCount = 0,
    this.lastJudgement,
    this.perfectStartTime,
  });

  /// Current combo count (Perfect streak).
  final int count;

  /// Maximum combo achieved in this session.
  final int maxCount;

  /// Last judgement result.
  final JudgementResult? lastJudgement;

  /// Time when perfect streak started (for curtain effect).
  final DateTime? perfectStartTime;

  /// Duration of current perfect streak in seconds.
  double get perfectDuration {
    if (perfectStartTime == null) return 0;
    return DateTime.now().difference(perfectStartTime!).inMilliseconds / 1000;
  }

  /// Whether the yellow curtain is fully covering (8+ seconds of perfect).
  bool get isCurtainFullyCovered => perfectDuration >= 8.0;

  /// Combo tier based on count.
  ComboTier get tier {
    if (count >= 50) return ComboTier.legendary;
    if (count >= 20) return ComboTier.amazing;
    if (count >= 10) return ComboTier.great;
    if (count >= 5) return ComboTier.good;
    return ComboTier.none;
  }

  ComboState copyWith({
    int? count,
    int? maxCount,
    JudgementResult? lastJudgement,
    DateTime? perfectStartTime,
    bool clearJudgement = false,
    bool clearPerfectStartTime = false,
  }) {
    return ComboState(
      count: count ?? this.count,
      maxCount: maxCount ?? this.maxCount,
      lastJudgement: clearJudgement ? null : (lastJudgement ?? this.lastJudgement),
      perfectStartTime: clearPerfectStartTime ? null : (perfectStartTime ?? this.perfectStartTime),
    );
  }
}

/// Combo tier for visual effects.
enum ComboTier {
  /// No combo (0-4)
  none(0, ''),

  /// Good combo (5-9): small jump, 1 star
  good(5, '콤보 시작!'),

  /// Great combo (10-19): big jump, 2 stars
  great(10, '대단해옹!'),

  /// Amazing combo (20-49): dancing, 3 stars
  amazing(20, '천재다옹!'),

  /// Legendary combo (50+): special dance, golden star
  legendary(50, '전설이다옹!');

  const ComboTier(this.minCount, this.message);

  final int minCount;
  final String message;

  /// Number of stars to display.
  int get stars {
    switch (this) {
      case ComboTier.none:
        return 0;
      case ComboTier.good:
        return 1;
      case ComboTier.great:
        return 2;
      case ComboTier.amazing:
        return 3;
      case ComboTier.legendary:
        return 3; // Golden star
    }
  }

  /// Whether this tier uses golden star.
  bool get isGolden => this == ComboTier.legendary;
}

/// Combo counter and judgement management.
@Riverpod(keepAlive: true)
class TunerCombo extends _$TunerCombo {
  @override
  ComboState build() {
    // Watch tuner state to react to note changes
    ref.listen(tunerProvider, (previous, next) {
      _onNoteChanged(previous, next);
    });

    return const ComboState();
  }

  void _onNoteChanged(TunerProviderState? previous, TunerProviderState next) {
    // Only process when we have a stable note
    if (next.currentNote == null) return;

    // Get difficulty from settings
    final difficulty = next.settings.difficulty;
    final centDeviation = next.currentNote!.centDeviation;

    // Judge the current tuning
    final judgement = difficulty.judge(centDeviation);
    _recordJudgement(judgement);
  }

  void _recordJudgement(JudgementResult judgement) {
    switch (judgement) {
      case JudgementResult.perfect:
        // Increment combo on Perfect
        final newCount = state.count + 1;
        // Start tracking perfect time if not already tracking
        final startTime = state.perfectStartTime ?? DateTime.now();
        state = state.copyWith(
          count: newCount,
          maxCount: newCount > state.maxCount ? newCount : state.maxCount,
          lastJudgement: judgement,
          perfectStartTime: startTime,
        );
        break;

      case JudgementResult.good:
        // Maintain combo on Good (don't increment or reset, keep perfect time tracking)
        state = state.copyWith(lastJudgement: judgement);
        break;

      case JudgementResult.miss:
        // Reset combo and perfect time on Miss
        state = state.copyWith(
          count: 0,
          lastJudgement: judgement,
          clearPerfectStartTime: true,
        );
        break;
    }
  }

  /// Reset combo counter (e.g., when stopping tuner).
  void reset() {
    state = state.copyWith(count: 0, clearJudgement: true, clearPerfectStartTime: true);
  }

  /// Reset session (including max count).
  void resetSession() {
    state = const ComboState();
  }
}

/// Provider for whether combo should be shown.
@riverpod
bool showCombo(ShowComboRef ref) {
  final tunerState = ref.watch(tunerProvider);
  final comboState = ref.watch(tunerComboProvider);

  return tunerState.settings.showCombo &&
      tunerState.isListening &&
      comboState.count > 0;
}

/// Provider for combo message (if any).
@riverpod
String? comboMessage(ComboMessageRef ref) {
  final comboState = ref.watch(tunerComboProvider);

  if (comboState.tier == ComboTier.none) return null;
  return comboState.tier.message;
}

/// Provider for whether the yellow curtain is fully covering the screen.
/// Returns true when perfect pitch has been maintained for 8+ seconds.
@riverpod
bool isCurtainFullyCovered(IsCurtainFullyCoveredRef ref) {
  final comboState = ref.watch(tunerComboProvider);
  return comboState.isCurtainFullyCovered;
}
