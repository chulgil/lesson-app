import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/presentation/providers/auth_provider.dart';

part 'quest_celebration_provider.g.dart';

const _kBoxName = 'quest_state';
const _kDismissedAtKey = 'celebrated_dismissed_at';

/// 전체 완료 축하 카드의 1회성 보장 (§8.3) — BE SSOT + Hive offline fallback.
///
/// 우선순위:
/// 1. BE `User.quest_celebrated_at` (SSOT) — `markCelebrated()` 가 PATCH 호출
/// 2. Hive `celebrated_dismissed_at` (local fallback, offline / 네트워크 실패 시)
///
/// `build()` 가 반환하는 `DateTime?`:
/// - null = 아직 dismiss 안 됨 → 축하 카드 표시
/// - DateTime = 이미 dismiss 됨 → 축하 카드 숨김
///
/// SSOT: `.harness/spec/2026-06-08-teacher-quest-system.md` §8.3
@riverpod
class QuestCelebration extends _$QuestCelebration {
  Box<dynamic>? _box;

  Future<Box<dynamic>> _openBox() async {
    return _box ??= await Hive.openBox(_kBoxName);
  }

  /// 축하 카드 dismiss 시각. null = 아직 dismiss 안 됨.
  @override
  Future<DateTime?> build() async {
    final box = await _openBox();
    final iso = box.get(_kDismissedAtKey) as String?;
    return iso == null ? null : DateTime.tryParse(iso);
  }

  /// 사용자가 축하 카드를 dismiss / 액션 시 호출.
  ///
  /// 1. BE PATCH `/users/me/quest-celebrated` — 1회성 보장 SSOT
  /// 2. Hive local set — BE 실패 시에도 같은 세션 내 재표시 방지
  /// 3. 자신의 provider invalidate → 카드 사라짐
  ///
  /// BE 호출 실패 시 Hive 만 set 하고 silently 진행 (UX 차단 X).
  Future<void> markCelebrated() async {
    final now = DateTime.now();
    final box = await _openBox();
    await box.put(_kDismissedAtKey, now.toIso8601String());

    try {
      await ref.read(authRepositoryProvider).markQuestCelebrated();
    } catch (e) {
      // BE 실패해도 Hive local 이 있으므로 같은 기기에서 재표시 안 됨.
      // 다음 로그인/getMe 시 BE 의 null 이 보일 수 있으나, Hive 가 우선이라 안전.
      debugPrint('[QuestCelebration] BE PATCH failed: $e');
    }

    ref.invalidateSelf();
    await future;
  }
}
