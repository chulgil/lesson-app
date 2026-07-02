import '../../../../core/l10n/app_strings.dart';
import '../../domain/entities/repertoire_sort_type.dart';

/// Presentation-layer display label for [RepertoireSortType].
///
/// Lives in `presentation/extensions/` per the flutter-architecture rule —
/// domain/data must not depend on `AppStrings`.
extension RepertoireSortTypeVisualsX on RepertoireSortType {
  /// Display name in Korean.
  String get displayName {
    switch (this) {
      case RepertoireSortType.createdDesc:
        return AppStrings.sortByCreatedDesc;
      case RepertoireSortType.createdAsc:
        return AppStrings.sortByCreatedAsc;
      case RepertoireSortType.nameAsc:
        return AppStrings.sortByName;
      case RepertoireSortType.custom:
        return AppStrings.sortByCustom;
    }
  }
}
