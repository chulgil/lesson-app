import '../../../../core/l10n/app_strings.dart';
import '../../domain/entities/follow_target_type.dart';

/// Presentation-layer display label for [FollowTargetType].
///
/// Lives in `presentation/extensions/` per the flutter-architecture rule —
/// domain/data must not depend on `AppStrings`.
extension FollowTargetTypeVisualsX on FollowTargetType {
  /// Display name in Korean.
  String get displayName {
    switch (this) {
      case FollowTargetType.teacher:
        return AppStrings.teacher;
      case FollowTargetType.academy:
        return AppStrings.academy;
    }
  }
}
