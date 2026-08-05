import '../../domain/entities/journey_sticker.dart';
import '../../domain/repositories/journey_sticker_repository.dart';

/// Mock journey sticker catalog — mirrors the backend's computed ladders
/// (see `backend/app/services/journey_sticker_service.py`) with a
/// semi-progressed student so both achieved and in-progress states render.
class MockJourneyStickerRepository implements JourneyStickerRepository {
  @override
  Future<JourneyStickerCatalog> getCatalog(String studentId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    return JourneyStickerCatalog(
      studentId: studentId,
      stickers: [
        _minutes('practice_minutes_10h', 1, 10 * 60, 12 * 60),
        _minutes('practice_minutes_50h', 2, 50 * 60, 12 * 60),
        _minutes('practice_minutes_200h', 3, 200 * 60, 12 * 60),
        _minutes('practice_minutes_1000h', 4, 1000 * 60, 12 * 60),
        _days('practice_days_30', 'practice_days', 1, 30, 18),
        _days('practice_days_100', 'practice_days', 2, 100, 18),
        _days('practice_days_365', 'practice_days', 3, 365, 18),
        _count(
          'journey_first_piece',
          'journey',
          'journey_first_piece',
          1,
          1,
          1,
        ),
        _count('journey_bound_1', 'journey', 'journey_bound_volumes', 1, 1, 2),
        _count('journey_bound_5', 'journey', 'journey_bound_volumes', 2, 5, 2),
        _count(
          'journey_bound_20',
          'journey',
          'journey_bound_volumes',
          3,
          20,
          2,
        ),
        _count(
          'journey_bound_50',
          'journey',
          'journey_bound_volumes',
          4,
          50,
          2,
        ),
        _days('streak_7', 'streak', 1, 7, 9, family: StickerFamily.streak),
        _days('streak_30', 'streak', 2, 30, 9, family: StickerFamily.streak),
        _days('streak_100', 'streak', 3, 100, 9, family: StickerFamily.streak),
        _days('streak_365', 'streak', 4, 365, 9, family: StickerFamily.streak),
        _count('growth_recordings_10', 'growth', 'growth_recordings', 1, 10, 4),
        _count('growth_recordings_50', 'growth', 'growth_recordings', 2, 50, 4),
        _count(
          'growth_recordings_200',
          'growth',
          'growth_recordings',
          3,
          200,
          4,
        ),
      ],
    );
  }

  JourneySticker _minutes(String key, int tier, int target, int current) {
    return JourneySticker(
      key: key,
      family: StickerFamily.practice,
      metric: 'practice_minutes',
      tier: tier,
      target: target,
      current: current,
      achieved: current >= target,
      unit: StickerUnit.minutes,
    );
  }

  JourneySticker _days(
    String key,
    String metric,
    int tier,
    int target,
    int current, {
    StickerFamily family = StickerFamily.practice,
  }) {
    return JourneySticker(
      key: key,
      family: family,
      metric: metric,
      tier: tier,
      target: target,
      current: current,
      achieved: current >= target,
      unit: StickerUnit.days,
    );
  }

  JourneySticker _count(
    String key,
    String family,
    String metric,
    int tier,
    int target,
    int current,
  ) {
    return JourneySticker(
      key: key,
      family: StickerFamily.values.firstWhere((f) => f.name == family),
      metric: metric,
      tier: tier,
      target: target,
      current: current,
      achieved: current >= target,
      unit: StickerUnit.count,
    );
  }
}
