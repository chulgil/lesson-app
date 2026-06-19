import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

/// 학생 게이미피케이션 onboarding 1회 해제 영속 저장소 (#81).
///
/// 배경: [StudentGamificationOnboardingTrigger] 는 `activeQuests` 가 0 개일 때만
/// onboarding 을 노출했다. "내가 정할래"(decline) 는 quest 를 만들지 않으므로
/// 0 개 상태가 유지 → 매 mount 마다 재노출되는 무한 루프가 발생했다.
///
/// 이 저장소는 user-scoped 해제 플래그를 영속화한다. 키 규약은
/// `OnboardingProgressStorage` 의 `teacher:<id>:...` 패턴을 미러링한다.
///
/// 수동 provider (no `@riverpod` codegen) — build_runner 재생성 불필요.
abstract class GamificationOnboardingDismissStore {
  /// `studentId` 의 onboarding 해제 여부 조회.
  Future<bool> isDismissed(String studentId);

  /// `studentId` 의 onboarding 을 해제로 기록 (영구).
  Future<void> markDismissed(String studentId);
}

/// Hive 기반 기본 구현 (`onboarding_state` box 재사용).
class HiveGamificationOnboardingDismissStore
    implements GamificationOnboardingDismissStore {
  static const _boxName = 'onboarding_state';

  String _key(String studentId) =>
      'student:$studentId:gamificationOnboardingDismissed';

  Future<Box<dynamic>> _openBox() async => Hive.openBox<dynamic>(_boxName);

  @override
  Future<bool> isDismissed(String studentId) async {
    // Hive 미초기화/박스 오류(테스트 등)는 "미해제"로 간주 — 읽기 실패가
    // onboarding 렌더를 깨뜨리지 않도록 graceful degradation.
    try {
      final box = await _openBox();
      return box.get(_key(studentId), defaultValue: false) as bool;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> markDismissed(String studentId) async {
    final box = await _openBox();
    await box.put(_key(studentId), true);
  }
}

/// 저장소 주입 지점 — 테스트에서 fake 로 override.
final gamificationOnboardingDismissStoreProvider =
    Provider<GamificationOnboardingDismissStore>(
      (ref) => HiveGamificationOnboardingDismissStore(),
    );

/// `studentId` 의 onboarding 해제 여부 (read).
///
/// 트리거는 `quests.isEmpty && !dismissed` 일 때만 onboarding 을 노출한다.
final gamificationOnboardingDismissedProvider =
    FutureProvider.family<bool, String>((ref, studentId) {
      final store = ref.watch(gamificationOnboardingDismissStoreProvider);
      return store.isDismissed(studentId);
    });
