import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/auth_facade.dart';
import '../../data/repositories/hive_practice_loop_override_repository.dart';
import '../../data/repositories/hive_practice_repeat_total_repository.dart';
import '../../data/services/audio_session_audio_routing_service.dart';
import '../../data/services/audio_session_practice_audio_mix_service.dart';
import '../../domain/entities/loop_memo.dart';
import '../../domain/entities/practice_loop_override.dart';
import '../../domain/repositories/practice_loop_override_repository.dart';
import '../../domain/repositories/practice_repeat_total_repository.dart';
import '../../domain/services/audio_routing_service.dart';
import '../../domain/services/badge_checker.dart';
import '../../domain/services/practice_audio_mix_service.dart';
import '../../domain/value_objects/audio_mix_mode.dart';
import '../../domain/value_objects/practice_loop_speeds.dart';
import 'badge_provider.dart';

part 'practice_loop_provider.g.dart';

/// Singleton repository for student-side loop overrides.
@Riverpod(keepAlive: true)
PracticeLoopOverrideRepository practiceLoopOverrideRepository(
  PracticeLoopOverrideRepositoryRef ref,
) => HivePracticeLoopOverrideRepository();

/// Singleton repository for cumulative repeat counts (#508).
@Riverpod(keepAlive: true)
PracticeRepeatTotalRepository practiceRepeatTotalRepository(
  PracticeRepeatTotalRepositoryRef ref,
) => HivePracticeRepeatTotalRepository();

/// Singleton audio routing service (headphone detection).
@Riverpod(keepAlive: true)
AudioRoutingService audioRoutingService(AudioRoutingServiceRef ref) {
  final svc = AudioSessionAudioRoutingService();
  ref.onDispose(svc.dispose);
  return svc;
}

/// Singleton audio mix service (audio session translator).
@Riverpod(keepAlive: true)
PracticeAudioMixService practiceAudioMixService(
  PracticeAudioMixServiceRef ref,
) {
  final svc = AudioSessionPracticeAudioMixService();
  ref.onDispose(svc.reset);
  return svc;
}

/// Loop override state for a specific [sectionId].
///
/// Loads the override from Hive on init, exposes mutation methods that persist
/// every change. Returns a non-null default when no override exists yet.
@riverpod
class PracticeLoopOverrideNotifier extends _$PracticeLoopOverrideNotifier {
  @override
  Future<PracticeLoopOverride> build(String sectionId) async {
    final studentUserId = ref.watch(currentUserIdProvider);
    final repo = ref.watch(practiceLoopOverrideRepositoryProvider);
    final existing = await repo.findFor(
      studentUserId: studentUserId,
      sectionId: sectionId,
    );
    if (existing != null) return existing;
    return PracticeLoopOverride(
      sectionId: sectionId,
      studentUserId: studentUserId,
      lastPlayedAt: DateTime.now(),
    );
  }

  Future<void> _persist(PracticeLoopOverride next) async {
    state = AsyncData(next);
    final repo = ref.read(practiceLoopOverrideRepositoryProvider);
    await repo.save(next);
  }

  Future<void> setSegment({int? startSeconds, int? endSeconds}) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _persist(
      current.copyWith(
        overrideStartSeconds: startSeconds,
        overrideEndSeconds: endSeconds,
        lastPlayedAt: DateTime.now(),
      ),
    );
  }

  Future<void> resetSegment() async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _persist(
      current.copyWith(
        clearOverrideStart: true,
        clearOverrideEnd: true,
        lastPlayedAt: DateTime.now(),
      ),
    );
  }

  Future<void> setSpeed(double speed) async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (!PracticeLoopSpeeds.isAllowed(speed)) {
      speed = PracticeLoopSpeeds.clamp(speed);
    }
    await _persist(current.copyWith(playbackSpeed: speed));
  }

  Future<void> setTargetRepeatCount(int count) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final clamped = count.clamp(1, 20);
    await _persist(current.copyWith(targetRepeatCount: clamped));
  }

  Future<void> incrementCompletedCount() async {
    final current = state.valueOrNull;
    if (current == null) return;
    final nextCount = current.completedRepeatCount + 1;
    await _persist(
      current.copyWith(
        completedRepeatCount: nextCount,
        lastPlayedAt: DateTime.now(),
      ),
    );

    // Badge trigger (#508) — fire only when the per-section target is reached
    // so we do not hammer the checker on every loop. Cumulative total is
    // stored per student so badges survive section changes.
    if (nextCount < current.targetRepeatCount) return;
    final studentUserId = ref.read(currentUserIdProvider);
    final totalRepo = ref.read(practiceRepeatTotalRepositoryProvider);
    final newTotal = await totalRepo.increment(
      studentUserId: studentUserId,
      by: nextCount,
    );
    ref
        .read(practiceBadgeStateNotifierProvider(studentUserId).notifier)
        .evaluate(
          stats: PracticeStatsSnapshot(cumulativeRepeatCount: newTotal),
          trigger: BadgeTrigger.onPracticeRepeat,
        );
  }

  Future<void> resetCompletedCount() async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _persist(current.copyWith(completedRepeatCount: 0));
  }

  Future<void> setCountInEnabled(bool enabled) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _persist(current.copyWith(countInEnabled: enabled));
  }

  Future<void> setCountInSoundEnabled(bool enabled) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _persist(current.copyWith(countInSoundEnabled: enabled));
  }

  Future<void> setAudioMixMode(AudioMixMode mode) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _persist(current.copyWith(audioMixMode: mode));
    await ref.read(practiceAudioMixServiceProvider).apply(mode);
  }

  // -- #510: 영상 구간별 손글씨 메모 --

  /// Append a memo at [atSeconds] with [text] (UI is expected to enforce the
  /// 100-char limit). Returns the new memo's id.
  Future<String> addMemo({required int atSeconds, required String text}) async {
    final current = state.valueOrNull;
    if (current == null) return '';
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '';
    final id = 'memo-${DateTime.now().microsecondsSinceEpoch}';
    final memo = LoopMemo(
      id: id,
      atSeconds: atSeconds,
      text: trimmed,
      createdAt: DateTime.now(),
    );
    final next = [...current.studentMemos, memo]
      ..sort((a, b) => a.atSeconds.compareTo(b.atSeconds));
    await _persist(current.copyWith(studentMemos: next));
    return id;
  }

  /// Update an existing memo's text.
  Future<void> updateMemo({required String id, required String text}) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final next = current.studentMemos
        .map((m) => m.id == id ? m.copyWith(text: trimmed) : m)
        .toList();
    await _persist(current.copyWith(studentMemos: next));
  }

  /// Delete a memo by id.
  Future<void> deleteMemo(String id) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final next = current.studentMemos
        .where((m) => m.id != id)
        .toList(growable: false);
    await _persist(current.copyWith(studentMemos: next));
  }
}
