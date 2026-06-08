import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'quest_first_shown_provider.g.dart';

const _kBoxName = 'quest_state';
const _kFirstShownAtKey = 'first_shown_at';

/// 가입 직후 첫 도착 윈도우 — 5분 이내 진입 시 카드 2초 표시 예외.
const kQuestFirstArrivalWindow = Duration(minutes: 5);

/// 가입 직후 첫 도착 시점을 Hive 에 영속화하는 provider.
///
/// `markShown()` 호출 시 현재 시각을 ISO8601 으로 저장. 이후 5분 윈도우
/// 내 재진입 시 `isWithinFirstArrivalWindow == true` 가 되어 퀘스트 카드
/// 2초 표시 예외 적용.
///
/// SSOT: §13 퀘스트 시스템 — 가입 직후 첫 도착 (Signup First Arrival).
@riverpod
class QuestFirstShown extends _$QuestFirstShown {
  Box<dynamic>? _box;

  Future<Box<dynamic>> _openBox() async {
    return _box ??= await Hive.openBox(_kBoxName);
  }

  @override
  Future<DateTime?> build() async {
    final box = await _openBox();
    final iso = box.get(_kFirstShownAtKey) as String?;
    return iso == null ? null : DateTime.tryParse(iso);
  }

  /// 첫 도착 시각 기록 — 가입 흐름 직후 home_screen 진입 시 1회 호출.
  /// `invalidateSelf()` + `await future` 로 build() 재실행을 통해 state 갱신.
  /// (직접 `state = AsyncData(now)` 는 build() future 완료와 race 발생)
  Future<void> markShown() async {
    final now = DateTime.now();
    final box = await _openBox();
    await box.put(_kFirstShownAtKey, now.toIso8601String());
    ref.invalidateSelf();
    await future;
  }

  /// 5분 윈도우 내에 있는지 — caller 가 build()/markShown() 결과를 명시 전달.
  ///
  /// state.value 대신 명시 인자를 받아 테스트 가능성 + AsyncLoading race 회피.
  /// home_screen 진입 시 `ref.watch(questFirstShownProvider).whenData((v) => isWithin(v))` 패턴.
  static bool isWithin(DateTime? value, {DateTime? now}) {
    if (value == null) return false;
    return (now ?? DateTime.now()).difference(value) <=
        kQuestFirstArrivalWindow;
  }
}
