import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'quest_celebration_provider.g.dart';

const _kBoxName = 'quest_state';
const _kDismissedAtKey = 'celebrated_dismissed_at';

/// 전체 완료 축하 카드의 1회성 보장 (§8.3) — Hive local fallback.
///
/// 우선순위:
/// 1. `AuthUser.questCelebratedAt` (BE 필드, SSOT) — null 이 아니면 표시 X
/// 2. Hive `celebrated_dismissed_at` (local, BE 엔드포인트 미완성 임시) — 값 있으면 표시 X
///
/// **TODO (Issue #608 BE 완료 후)**:
/// - `markCelebrated()` 가 BE `PATCH /users/me/quest-celebrated` 호출 + AuthUser invalidate
/// - Hive local fallback 은 BE 의존 제거 시 삭제 또는 유지 (offline 안전망)
///
/// SSOT: `.harness/spec/2026-06-08-teacher-quest-system.md` §8.3
@riverpod
class QuestCelebration extends _$QuestCelebration {
  Box<dynamic>? _box;

  Future<Box<dynamic>> _openBox() async {
    return _box ??= await Hive.openBox(_kBoxName);
  }

  /// 축하 카드 dismiss 시각 (Hive local). null = 아직 dismiss 안 됨.
  @override
  Future<DateTime?> build() async {
    final box = await _openBox();
    final iso = box.get(_kDismissedAtKey) as String?;
    return iso == null ? null : DateTime.tryParse(iso);
  }

  /// 사용자가 축하 카드를 dismiss 했을 때 호출.
  /// 현재: Hive local set + (TODO) BE PATCH `/users/me/quest-celebrated`.
  Future<void> markCelebrated() async {
    final now = DateTime.now();
    final box = await _openBox();
    await box.put(_kDismissedAtKey, now.toIso8601String());
    ref.invalidateSelf();
    await future;
    // TODO(Issue #608 BE 작업 후):
    //   await ref.read(userApiProvider).patchQuestCelebrated();
    //   ref.invalidate(authUserProvider);
  }
}
