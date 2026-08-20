import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/auth_facade.dart';

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

/// NextMissionSpotlight 소거 여부를 영속화하는 provider (UXC-2).
///
/// [QuestFirstShown] 의 타임스탬프와 분리된 별개의 플래그다. 첫 도착 기록은
/// home 진입 즉시(post-frame) 남고 QuestBoardCard 의 5분 윈도우가 그 값을
/// 쓰기 때문에, spotlight 노출 조건까지 같은 값에 묶어 두면 기록되는 순간
/// spotlight 가 사라진다 (플래시 또는 미노출). 이 플래그는 사용자가
/// [시작]/[나중에] 를 실제로 탭했을 때만 true 가 된다.
@riverpod
class NextMissionSpotlightDismissed extends _$NextMissionSpotlightDismissed {
  Box<dynamic>? _box;

  Future<Box<dynamic>> _openBox() async {
    return _box ??= await Hive.openBox(_kBoxName);
  }

  /// 사용자별 키 — 같은 기기에서 계정을 바꾸면 spotlight 가 다시 노출된다.
  String _key(String userId) => 'teacher:$userId:nextMissionSpotlightDismissed';

  @override
  Future<bool> build() async {
    final userId = ref.watch(currentUserIdProvider);
    final box = await _openBox();
    return box.get(_key(userId), defaultValue: false) as bool? ?? false;
  }

  /// spotlight 소거 — [시작]/[나중에] 탭 시 1회 호출.
  Future<void> markDismissed() async {
    final userId = ref.read(currentUserIdProvider);
    final box = await _openBox();
    await box.put(_key(userId), true);
    ref.invalidateSelf();
    await future;
  }
}
