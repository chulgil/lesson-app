import '../../../../core/l10n/app_strings.dart';
import '../../domain/entities/relationship_status.dart';

/// Presentation-layer display label for [RelationshipStatus].
///
/// Lives in `presentation/extensions/` per the flutter-architecture rule —
/// domain/data must not depend on `AppStrings`. Business getters
/// (canBookLesson, canRequestLesson, ...) stay in the domain extension.
extension RelationshipStatusVisualsX on RelationshipStatus {
  /// Display name in Korean.
  String get displayName {
    switch (this) {
      case RelationshipStatus.trialBooked:
        return AppStrings.relationshipStatusTrialBooked;
      case RelationshipStatus.active:
        return AppStrings.relationshipStatusActive;
      case RelationshipStatus.expired:
        return AppStrings.relationshipStatusExpired;
      case RelationshipStatus.past:
        return AppStrings.relationshipStatusPast;
    }
  }
}
