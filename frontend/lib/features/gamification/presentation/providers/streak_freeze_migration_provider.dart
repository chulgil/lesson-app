// Student gamification P2 — D-day 마이그레이션 + 안내 토스트 (Job 5 Task 5.2).
//
// 스펙 §18.3: P2 배포 시점 1회 — 기존 학생 → StreakFreeze.balance = 2 부여
// + "스트릭 동결 시스템 시작" 안내 토스트 1회.
//
// Hive flag 기반 idempotent (학생별 격리). teacher_settings_boot_migration_provider
// 패턴 차용.

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'streak_freeze_provider.dart';

part 'streak_freeze_migration_provider.g.dart';

/// Hive flag 키 정책 — 외부 wiring 단일 지점.
class StreakFreezeMigrationKeys {
  StreakFreezeMigrationKeys._();

  static const String boxName = 'streak_freeze_migration_state';

  static String doneKey(String studentId) =>
      'migration_v2_streak_freeze_done_$studentId';

  static String toastShownKey(String studentId) =>
      'streak_freeze_migration_toast_shown_$studentId';
}

/// 토스트 표시 dismiss 헬퍼 — 화면에서 호출.
class StreakFreezeMigrationToast {
  StreakFreezeMigrationToast._();

  /// 토스트 노출 후 dismiss flag 영속.
  static Future<void> markShown(String studentId) async {
    final box = await Hive.openBox(StreakFreezeMigrationKeys.boxName);
    await box.put(StreakFreezeMigrationKeys.toastShownKey(studentId), true);
  }
}

/// 학생별 D-day 마이그레이션 — `weeklyGrantIfDue` 강제 호출 (lastGrantedAt=null
/// 이므로 자동 +2) + flag 영속. 재호출 시 flag 검사 후 no-op.
///
/// Hive 미초기화 (테스트 환경 일부) 시 `false` 반환 — boot 차단 회피.
@Riverpod(keepAlive: true)
Future<bool> streakFreezeBootMigration(
  StreakFreezeBootMigrationRef ref,
  String studentId,
) async {
  final Box<dynamic> box;
  try {
    box = await Hive.openBox(StreakFreezeMigrationKeys.boxName);
  } catch (_) {
    return false;
  }
  try {
    final done =
        box.get(StreakFreezeMigrationKeys.doneKey(studentId)) as bool? ?? false;
    if (done) return true;

    final service = ref.read(streakFreezeServiceProvider);
    await service.weeklyGrantIfDue(studentId: studentId, now: DateTime.now());

    await box.put(StreakFreezeMigrationKeys.doneKey(studentId), true);
    return true;
  } catch (e, st) {
    debugPrint('streakFreezeBootMigration failed: $e\n$st');
    return false;
  }
}

/// 학생별 마이그레이션 안내 토스트 노출 상태.
///
/// `false` → 미노출 (토스트 표시 필요). `true` → 이미 노출 (skip).
@riverpod
Future<bool> streakFreezeMigrationToastShown(
  StreakFreezeMigrationToastShownRef ref,
  String studentId,
) async {
  try {
    final box = await Hive.openBox(StreakFreezeMigrationKeys.boxName);
    return box.get(StreakFreezeMigrationKeys.toastShownKey(studentId))
            as bool? ??
        false;
  } catch (_) {
    return false;
  }
}
