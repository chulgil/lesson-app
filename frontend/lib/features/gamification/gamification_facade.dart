/// Gamification facade — public entry point for cross-feature gamification use.
library;

export 'domain/entities/gamification.dart' show PointHistory, PointType;
export 'presentation/providers/point_award_service.dart'
    show PointAwardNotifier, pointAwardNotifierProvider;
