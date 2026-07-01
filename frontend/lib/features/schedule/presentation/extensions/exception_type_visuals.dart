import '../../../../core/l10n/app_strings.dart';
import '../../domain/entities/teacher_availability.dart';

/// Presentation-layer display label for [ExceptionType].
///
/// Lives in `presentation/extensions/` per the flutter-architecture rule —
/// domain/data must not depend on `AppStrings`.
extension ExceptionTypeVisualsX on ExceptionType {
  /// Display name in Korean.
  String get displayName {
    switch (this) {
      case ExceptionType.holiday:
        return AppStrings.exceptionTypeHoliday;
      case ExceptionType.vacation:
        return AppStrings.exceptionTypeVacation;
      case ExceptionType.additionalSlot:
        return AppStrings.exceptionTypeAdditionalSlot;
    }
  }
}
