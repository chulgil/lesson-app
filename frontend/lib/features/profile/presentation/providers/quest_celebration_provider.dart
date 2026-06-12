import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/durations.dart';
import '../../../auth/auth_facade.dart' show authRepositoryProvider;

part 'quest_celebration_provider.g.dart';

const _kBoxName = 'quest_state';

/// BE `User.quest_celebrated_at` 의 로컬 캐시 (졸업 시각).
const _kCelebratedAtKey = 'celebrated_at';

/// 사용자 명시 dismiss (X 버튼) 시각 (Hive local fallback).
const _kDismissedAtKey = 'celebrated_dismissed_at';

/// 퀘스트 졸업 상태 — `QuestCelebrationProvider` 가 노출하는 값.
///
/// W5 의미 재정의 (spec §9.4) — `celebratedAt` 은 "Q1~Q10 (필수) 100% 완료
/// = 졸업" 시점. Q11 (보너스) 은 별도 `quest_bonus_shown_provider`.
///
/// 표시 규칙:
/// - `celebratedAt == null`: 아직 졸업 안 됨 → 졸업 카드 미표시, 보드 표시
/// - `celebratedAt != null && visible`: 졸업 카드 표시
/// - `graduated`: 메인에서 완전 hide (보드/카드 모두) — "가이드 다시 보기" 로만 접근
class QuestCelebrationState {
  /// BE SSOT — Q1~Q10 100% 완료 시점.
  final DateTime? celebratedAt;

  /// 사용자 명시 dismiss (X 버튼) 시각 — Hive local.
  final DateTime? dismissedAt;

  /// 시간 비교용 — 테스트에서 override 가능 (production = `DateTime.now()`).
  @visibleForTesting
  final DateTime now;

  QuestCelebrationState({
    required this.celebratedAt,
    required this.dismissedAt,
    DateTime? now,
  }) : now = now ?? DateTime.now();

  /// 졸업 카드 노출 여부 — 졸업 후 7일 grace 내 + 명시 dismiss 안 됨.
  bool get visible {
    if (celebratedAt == null) return false;
    if (dismissedAt != null) return false;
    return now.difference(celebratedAt!) < kQuestGraduationGrace;
  }

  /// 메인 보드/카드 모두 hide — 졸업 + (7일 경과 OR 사용자 dismiss).
  ///
  /// "가이드 다시 보기" 진입 시 dismissedAt 리셋으로 복원 가능.
  bool get graduated {
    if (celebratedAt == null) return false;
    if (dismissedAt != null) return true;
    return now.difference(celebratedAt!) >= kQuestGraduationGrace;
  }
}

/// 퀘스트 졸업 상태 + 1회성 보장 (§8.2 — W5 의미 재정의).
///
/// SSOT 우선순위:
/// 1. BE `User.quest_celebrated_at` (졸업 시점) — `markCelebrated()` /
///    `onRequiredCompleted()` PATCH 응답에서 캐시
/// 2. Hive `celebrated_at` (local cache, offline / 다음 진입 시 즉시 반영)
/// 3. Hive `celebrated_dismissed_at` (사용자 명시 dismiss)
///
/// 자동 트리거 흐름 (W5):
/// 1. `QuestBoardCard` 가 `allMandatoryQuestsCompletedProvider` listen
/// 2. true 전환 시 `onRequiredCompleted()` 호출
/// 3. BE PATCH → 응답의 questCelebratedAt 을 Hive 캐시 + state 반영
/// 4. 졸업 카드 7일간 노출, 이후 자동 hide
///
/// SSOT: `.harness/spec/2026-06-11-teacher-settings-redesign.md` §8.2 / §9.4
@riverpod
class QuestCelebration extends _$QuestCelebration {
  Box<dynamic>? _box;

  Future<Box<dynamic>> _openBox() async {
    return _box ??= await Hive.openBox(_kBoxName);
  }

  @override
  Future<QuestCelebrationState> build() async {
    final box = await _openBox();
    final celebratedIso = box.get(_kCelebratedAtKey) as String?;
    final dismissedIso = box.get(_kDismissedAtKey) as String?;
    return QuestCelebrationState(
      celebratedAt:
          celebratedIso == null ? null : DateTime.tryParse(celebratedIso),
      dismissedAt:
          dismissedIso == null ? null : DateTime.tryParse(dismissedIso),
    );
  }

  /// Q1~Q10 (mandatory 11개) 100% 완료 시 자동 호출 — 졸업 시점 영속.
  ///
  /// 이미 celebratedAt 이 있으면 no-op (idempotent).
  /// BE PATCH 실패해도 Hive 에는 즉시 기록 (오프라인 졸업 처리).
  Future<void> onRequiredCompleted() async {
    final current = await future;
    if (current.celebratedAt != null) return;

    final now = DateTime.now();
    DateTime celebratedAt = now;

    try {
      final user = await ref.read(authRepositoryProvider).markQuestCelebrated();
      // BE 가 idempotent — 이미 set 됐으면 기존 값 반환.
      celebratedAt = user.questCelebratedAt ?? now;
    } catch (e) {
      // BE 실패해도 Hive 캐시로 즉시 졸업 처리.
      debugPrint('[QuestCelebration] onRequiredCompleted PATCH failed: $e');
    }

    final box = await _openBox();
    await box.put(_kCelebratedAtKey, celebratedAt.toIso8601String());

    ref.invalidateSelf();
    await future;
  }

  /// 사용자 명시 dismiss (X 버튼) — Hive 에 dismiss 시각 기록.
  ///
  /// 졸업 카드는 즉시 사라지고, 보드도 함께 hide (graduated == true).
  Future<void> markCelebrated() async {
    final box = await _openBox();
    final now = DateTime.now();
    await box.put(_kDismissedAtKey, now.toIso8601String());

    // 기존 동작 호환: BE PATCH 도 호출 (1회성 보장 SSOT).
    // celebratedAt 이 아직 set 안 됐으면 PATCH 가 set, set 됐으면 idempotent.
    try {
      final user = await ref.read(authRepositoryProvider).markQuestCelebrated();
      if (user.questCelebratedAt != null) {
        await box.put(
          _kCelebratedAtKey,
          user.questCelebratedAt!.toIso8601String(),
        );
      }
    } catch (e) {
      debugPrint('[QuestCelebration] markCelebrated PATCH failed: $e');
    }

    ref.invalidateSelf();
    await future;
  }

  /// "가이드 다시 보기" — 명시 dismiss 만 리셋 (BE celebratedAt 은 유지).
  ///
  /// graduated 상태에서 사용자가 보드를 다시 보고 싶을 때 호출. 단,
  /// celebratedAt 후 7일 경과한 경우는 다시 hide.
  Future<void> resetDismissal() async {
    final box = await _openBox();
    await box.delete(_kDismissedAtKey);
    ref.invalidateSelf();
    await future;
  }
}
