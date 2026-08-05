// 2026-06-12 — 라우트 파라미터 공통 헬퍼.
//
// 배경 (베타 회귀): 라우트 빌더들이 `queryParameters['teacherId'] ?? 'teacher_1'`
// 하드코딩 폴백을 사용해, remote(베타) 에서 쿼리 없이 push 하면 화면 조회는
// 가짜 'teacher_1' 로 / 저장(PUT)은 토큰 기준 본인 계정으로 — **쓰기-읽기
// 대상 불일치**로 "저장해도 화면 무반응" 버그가 났다. mock 모드는
// currentUserId 도 'teacher_1' 이라 우연히 일치해 재현 불가였다.
//
// 원칙: teacherId 류 식별자 폴백은 하드코딩이 아니라 **현재 로그인 사용자**.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_facade.dart'
    show currentUserIdProvider, currentUserRoleProvider;

/// 쿼리 `teacherId` 가 있으면 그 값, 없으면 현재 로그인 사용자 ID.
///
/// 라우트 빌더 (GoRoute.builder) 전용 — ProviderScope 루트 아래의 context 가
/// 필요하다 (선례: academy_routes 의 containerOf 패턴).
String teacherIdParamOrCurrent(BuildContext context, GoRouterState state) {
  final fromQuery = state.uri.queryParameters['teacherId'];
  if (fromQuery != null && fromQuery.isNotEmpty) return fromQuery;
  return ProviderScope.containerOf(context).read(currentUserIdProvider);
}

/// `extra` map 의 `teacherId` 가 있으면 그 값, 없으면 현재 로그인 사용자 ID.
String teacherIdExtraOrCurrent(
  BuildContext context,
  Map<String, dynamic>? extra,
) {
  final fromExtra = extra?['teacherId'] as String?;
  if (fromExtra != null && fromExtra.isNotEmpty) return fromExtra;
  return ProviderScope.containerOf(context).read(currentUserIdProvider);
}


/// `extra` map 의 `viewerRole` 이 있으면 그 값, 없으면 현재 로그인 사용자 역할.
///
/// 하드코딩 'teacher'/'student' 폴백은 extra 유실(딥링크·상태복원) 시 반대
/// 역할의 액션을 노출한다 — 식별자와 같은 원칙으로 현재 사용자에서 유도한다.
String viewerRoleExtraOrCurrent(
  BuildContext context,
  Map<String, dynamic>? extra,
) {
  final fromExtra = extra?['viewerRole'] as String?;
  if (fromExtra != null && fromExtra.isNotEmpty) return fromExtra;
  return ProviderScope.containerOf(context).read(currentUserRoleProvider).name;
}
