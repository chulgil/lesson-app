import '../../../../core/l10n/app_strings.dart';
import '../../domain/entities/request_filter.dart';

extension RequestFilterPresetVisuals on RequestFilterPreset {
  String get label {
    return switch (this) {
      RequestFilterPreset.oneWeek => AppStrings.recentOneWeek,
      RequestFilterPreset.oneMonth => AppStrings.recentOneMonth,
      RequestFilterPreset.threeMonths => AppStrings.recentThreeMonths,
      RequestFilterPreset.custom => AppStrings.periodCustom,
    };
  }
}
