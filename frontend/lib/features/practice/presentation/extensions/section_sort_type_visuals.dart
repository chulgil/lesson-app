import '../../../../core/l10n/app_strings.dart';
import '../../domain/entities/section_sort_type.dart';

/// Presentation-layer display label for [SectionSortType].
///
/// Lives in `presentation/extensions/` per the flutter-architecture rule —
/// domain/data must not depend on `AppStrings`.
extension SectionSortTypeVisualsX on SectionSortType {
  /// Display name in Korean.
  String get displayName {
    switch (this) {
      case SectionSortType.createdDesc:
        return AppStrings.sortByCreatedDesc;
      case SectionSortType.createdAsc:
        return AppStrings.sortByCreatedAsc;
      case SectionSortType.nameAsc:
        return AppStrings.sortByName;
      case SectionSortType.measureAsc:
        return AppStrings.sortByMeasureAsc;
      case SectionSortType.lastPracticedDesc:
        return AppStrings.sortByLastPracticedDesc;
      case SectionSortType.custom:
        return AppStrings.sortByCustom;
    }
  }
}
