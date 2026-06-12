/// Gamification facade — public entry point for cross-feature gamification use.
library;

export 'domain/entities/gamification.dart' show PointHistory, PointType;
export 'presentation/providers/point_award_service.dart'
    show PointAwardNotifier, pointAwardNotifierProvider;
// 학생 P1 — practice 녹음 종료 시 heatmap/quest 기록 wiring 이 소비.
export 'presentation/providers/growth_heatmap_provider.dart'
    show growthHeatmapRepositoryProvider;
export 'presentation/providers/student_quest_provider.dart'
    show studentQuestRepositoryProvider;
