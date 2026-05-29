// Public sharing route definitions (R2 #318).
//
// 인증 없이 접근 가능한 토큰 기반 공개 라우트. Auth-aware redirect 의
// _publicPaths 와 무관 — GoRouter 가 경로 매칭으로 처리하고 redirect 는
// 본 라우트를 막지 않는다 (path 자체에 token 이 포함되므로 사전 등록 불가).

import 'package:go_router/go_router.dart';

import '../../../features/share/presentation/screens/student_summary_screen.dart';
import '../app_routes.dart';

/// Public sharing routes (token-based read-only views).
List<GoRoute> shareRoutes = [
  GoRoute(
    path: AppRoutes.studentSummary,
    name: 'studentSummary',
    builder: (context, state) {
      final token = state.pathParameters['token'] ?? '';
      return StudentSummaryScreen(token: token);
    },
  ),
];
