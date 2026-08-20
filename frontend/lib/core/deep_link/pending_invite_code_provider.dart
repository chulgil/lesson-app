// UXB-2 (#1289) — 초대 딥링크로 받은 코드를 라우팅이 끝날 때까지 보관한다.
//
// `lessonapp://invite/{6자}` 는 `/invite/code?code=NNNNNN` 으로 navigate 되지만,
// 역할이 아직 없는 사용자(AuthNeedsRole)는 auth 가드에 걸려 roleSelect 로 튕기고
// 그 순간 코드가 사라졌다. 6자리 코드는 항상 학생 연결을 뜻하므로(BE `Invite`
// 테이블은 학생 전용, 학부모는 전화 기반 `ParentInvitation` 별도 경로) 코드를
// 들고 있는 동안에는 역할 질문을 건너뛰고 학생 초대코드 화면으로 바로 보낸다.
//
// [resolveAuthRedirect] 는 순수 함수를 유지해야 하므로 이 값을 인자로 받는다.
// codegen 없는 단순 String? 상태 — flutter-architecture.md 의 "StateProvider 는
// 단순 UI state 에만" 조건에 해당한다.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../router/app_routes.dart';

/// 아직 사용되지 않은 초대 딥링크 코드. null = 딥링크로 들어오지 않은 세션.
///
/// 설정: [DeepLinkHandler] navigate 콜백(main.dart).
/// 해제: 학생 역할이 확정되거나(초대 확인 진입) 사용자가 다른 역할을 선택할 때.
final pendingInviteCodeProvider = StateProvider<String?>((ref) => null);

/// DeepLinkHandler 가 넘겨준 경로에서 초대 코드를 추출한다.
///
/// 초대 코드 경로가 아니거나 6자리 숫자가 아니면 null — 다른 딥링크(레슨 상세,
/// 공유 요약)는 이 상태를 건드리지 않는다.
String? pendingInviteCodeFromPath(String path) {
  final uri = Uri.tryParse(path);
  if (uri == null || uri.path != AppRoutes.inviteCode) return null;
  final code = uri.queryParameters['code'];
  if (code == null || !RegExp(r'^[0-9]{6}$').hasMatch(code)) return null;
  return code;
}
