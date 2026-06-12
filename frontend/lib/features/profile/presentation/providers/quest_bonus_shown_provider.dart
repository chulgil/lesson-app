import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'quest_bonus_shown_provider.g.dart';

const _kBoxName = 'quest_state';
const _kBonusShownKey = 'bonus_shown';

/// Q11 (전화인증, 보너스) 보너스 배지 1회 노출 영속 provider (W5 Task 5.2).
///
/// SSOT: `.harness/spec/2026-06-11-teacher-settings-redesign.md` §9.4
///
/// `quest_celebrated_at` 의 의미가 "Q1~Q10 (필수) 100% 완료 = 졸업" 으로
/// 재정의되었기 때문에, Q11 보너스 표시는 별도 영속 신호가 필요하다.
/// (glossary §1 — 졸업/보너스는 별개 개념).
///
/// `markShown()` 호출 시 true 로 영속. 이후 같은 사용자가 다시 진입해도
/// 보너스 배지 노출 1회 제어를 위해 호출 측이 값 확인.
@riverpod
class QuestBonusShown extends _$QuestBonusShown {
  Box<dynamic>? _box;

  Future<Box<dynamic>> _openBox() async {
    return _box ??= await Hive.openBox(_kBoxName);
  }

  @override
  Future<bool> build() async {
    final box = await _openBox();
    return box.get(_kBonusShownKey, defaultValue: false) as bool;
  }

  /// Q11 보너스 배지 1회 노출 완료 — 호출 측이 첫 표시 직후 호출.
  Future<void> markShown() async {
    final box = await _openBox();
    await box.put(_kBonusShownKey, true);
    ref.invalidateSelf();
    await future;
  }
}
