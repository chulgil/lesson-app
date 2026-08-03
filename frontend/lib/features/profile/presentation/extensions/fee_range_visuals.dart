import '../../../../core/l10n/app_strings.dart';
import '../../domain/entities/teacher_profile.dart';
import '../../domain/entities/teacher_settings.dart';

/// Presentation formatting for [FeeRange] (C3 SSOT).
///
/// Moved off the domain entity (flutter-architecture: no display getters on
/// entities) and fixed the manwon truncation — 45,000 renders "4만 5000원"
/// instead of "4만원" (R2, D3-class remainder bug).
extension FeeRangeVisuals on FeeRange {
  String get label {
    final min = _formatWon(minFee);
    final max = _formatWon(maxFee);
    final durationStr = LessonDurations.format(duration);
    if (minFee == maxFee) {
      return '$min / $durationStr';
    }
    return '$min ~ $max / $durationStr';
  }

  String _formatWon(int amount) {
    if (amount >= 10000) {
      final man = amount ~/ 10000;
      final remainder = amount % 10000;
      return remainder == 0
          ? AppStrings.amountManwon('$man')
          : AppStrings.amountManwonWithRemainder(man, remainder);
    }
    return AppStrings.amountWon(amount);
  }
}
