import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../features/auth/auth_facade.dart';

part 'onboarding_progress_storage_provider.g.dart';

const _boxName = 'onboarding_progress';

class OnboardingProgressStorageState {
  final bool teacherOnboardingCompleted;
  final bool demoOverlayDismissed;
  final bool coachMarkCompleted;

  /// Q7~Q10 잠금 해제 축하 시트 1회 노출 여부 (감사 §4.5 B3).
  /// Q6 (첫 학생 초대) 완료 직후 1회 표시, 이후 영구 true.
  final bool questUnlockShown;

  const OnboardingProgressStorageState({
    required this.teacherOnboardingCompleted,
    required this.demoOverlayDismissed,
    required this.coachMarkCompleted,
    required this.questUnlockShown,
  });

  const OnboardingProgressStorageState.defaults()
    : teacherOnboardingCompleted = false,
      demoOverlayDismissed = false,
      coachMarkCompleted = false,
      questUnlockShown = false;

  OnboardingProgressStorageState copyWith({
    bool? teacherOnboardingCompleted,
    bool? demoOverlayDismissed,
    bool? coachMarkCompleted,
    bool? questUnlockShown,
  }) {
    return OnboardingProgressStorageState(
      teacherOnboardingCompleted:
          teacherOnboardingCompleted ?? this.teacherOnboardingCompleted,
      demoOverlayDismissed: demoOverlayDismissed ?? this.demoOverlayDismissed,
      coachMarkCompleted: coachMarkCompleted ?? this.coachMarkCompleted,
      questUnlockShown: questUnlockShown ?? this.questUnlockShown,
    );
  }
}

@Riverpod(keepAlive: true)
class OnboardingProgressStorage extends _$OnboardingProgressStorage {
  @override
  Future<OnboardingProgressStorageState> build() async {
    final teacherId = ref.watch(currentUserIdProvider);
    return _loadState(teacherId);
  }

  Future<OnboardingProgressStorageState> _loadState(String teacherId) async {
    final box = await Hive.openBox<bool>(_boxName);
    return OnboardingProgressStorageState(
      teacherOnboardingCompleted:
          box.get(_teacherCompletedKey(teacherId), defaultValue: false) ??
          false,
      demoOverlayDismissed:
          box.get(_demoOverlayDismissedKey(teacherId), defaultValue: false) ??
          false,
      coachMarkCompleted:
          box.get(_coachMarkCompletedKey(teacherId), defaultValue: false) ??
          false,
      questUnlockShown:
          box.get(_questUnlockShownKey(teacherId), defaultValue: false) ??
          false,
    );
  }

  Future<void> _persist(
    String teacherId,
    OnboardingProgressStorageState newState,
  ) async {
    final box = await Hive.openBox<bool>(_boxName);
    await box.put(
      _teacherCompletedKey(teacherId),
      newState.teacherOnboardingCompleted,
    );
    await box.put(
      _demoOverlayDismissedKey(teacherId),
      newState.demoOverlayDismissed,
    );
    await box.put(
      _coachMarkCompletedKey(teacherId),
      newState.coachMarkCompleted,
    );
    await box.put(_questUnlockShownKey(teacherId), newState.questUnlockShown);
  }

  String _teacherPrefix(String teacherId) => 'teacher:$teacherId';

  String _teacherCompletedKey(String teacherId) =>
      '${_teacherPrefix(teacherId)}:completed';

  String _demoOverlayDismissedKey(String teacherId) =>
      '${_teacherPrefix(teacherId)}:demoOverlayDismissed';

  String _coachMarkCompletedKey(String teacherId) =>
      '${_teacherPrefix(teacherId)}:coachMarkCompleted';

  String _questUnlockShownKey(String teacherId) =>
      '${_teacherPrefix(teacherId)}:questUnlockShown';

  Future<void> setTeacherOnboardingCompleted(bool value) async {
    final teacherId = ref.read(currentUserIdProvider);
    final current = state.valueOrNull ?? await _loadState(teacherId);
    final updated = current.copyWith(teacherOnboardingCompleted: value);
    await _persist(teacherId, updated);
    state = AsyncData(updated);
  }

  Future<void> markTeacherOnboardingCompleted() =>
      setTeacherOnboardingCompleted(true);

  Future<void> setDemoOverlayDismissed(bool value) async {
    final teacherId = ref.read(currentUserIdProvider);
    final current = state.valueOrNull ?? await _loadState(teacherId);
    final updated = current.copyWith(demoOverlayDismissed: value);
    await _persist(teacherId, updated);
    state = AsyncData(updated);
  }

  Future<void> dismissDemoOverlay() => setDemoOverlayDismissed(true);

  Future<void> setCoachMarkCompleted(bool value) async {
    final teacherId = ref.read(currentUserIdProvider);
    final current = state.valueOrNull ?? await _loadState(teacherId);
    final updated = current.copyWith(coachMarkCompleted: value);
    await _persist(teacherId, updated);
    state = AsyncData(updated);
  }

  Future<void> markCoachMarkCompleted() => setCoachMarkCompleted(true);

  /// Q7~Q10 잠금 해제 축하 시트를 표시한 사실을 기록 (감사 §4.5 B3).
  Future<void> setQuestUnlockShown(bool value) async {
    final teacherId = ref.read(currentUserIdProvider);
    final current = state.valueOrNull ?? await _loadState(teacherId);
    final updated = current.copyWith(questUnlockShown: value);
    await _persist(teacherId, updated);
    state = AsyncData(updated);
  }

  Future<void> markQuestUnlockShown() => setQuestUnlockShown(true);
}
