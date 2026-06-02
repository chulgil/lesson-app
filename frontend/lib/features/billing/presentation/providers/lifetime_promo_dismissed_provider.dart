// #415 R4 Phase B2 — Lifetime promo banner 세션 dismiss 상태.
//
// 사용자가 banner X 버튼을 누르면 true → 같은 세션 동안 노출 차단.
// 앱 재시작 시 false 로 초기화되어 (해당 윈도우 동안) 다시 노출.
//
// 영속 dismiss (24h+ persistence with Hive) 는 별도 phase. 현재는 banner blindness
// 완화만 목표 — 세션 내 한 번 닫으면 충분, 다음 부팅 시 lifetime 윈도우가 아직
// 활성이면 다시 안내 (promo 노출-기회를 사용자가 영구히 끄지 못하도록).

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 현재 세션에서 LifetimePromoBanner 가 사용자에 의해 닫혔는지.
///
/// `true` → profile_tab 의 `_buildLifetimePromoBanner` 가 SizedBox.shrink 반환.
final lifetimePromoDismissedProvider = StateProvider<bool>((ref) => false);
