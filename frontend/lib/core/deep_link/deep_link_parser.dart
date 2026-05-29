// R2 #318 — lessonapp:// 딥링크 URI → GoRouter 경로 매핑 (순수 함수).
//
// 외부 의존성 없이 Uri 만 받아 라우팅 결정을 반환하므로 단위 테스트가 쉽다.
// app_links 패키지에서 받은 URI 를 DeepLinkHandler 가 이 파서에 위임한다.

import '../router/app_routes.dart';

/// 딥링크 라우팅 결과.
///
/// path 는 GoRouter `context.go(path)` 에 그대로 전달 가능한 절대 경로.
/// code/token 은 화면이 추가 처리에 사용할 수 있는 원본 값.
class DeepLinkRoute {
  const DeepLinkRoute({required this.path, this.code, this.token});

  final String path;
  final String? code;
  final String? token;
}

/// lessonapp:// URI 를 앱 내부 경로로 매핑한다.
///
/// 지원 형식:
///   - `lessonapp://invite/{code}` (code 는 숫자 6자리)
///   - `lessonapp://student/summary/{token}`
///
/// 그 외 형식은 모두 null (silent ignore — 잘못된 링크로 앱이 깨지지 않게).
class DeepLinkParser {
  DeepLinkParser._();

  static const _scheme = 'lessonapp';

  static DeepLinkRoute? toRoute(Uri uri) {
    if (uri.scheme != _scheme) return null;

    final host = uri.host;
    final segments = uri.pathSegments;

    if (host == 'invite') {
      if (segments.length != 1) return null;
      final code = segments[0];
      if (code.length != 6) return null;
      if (!RegExp(r'^[0-9]{6}$').hasMatch(code)) return null;
      return DeepLinkRoute(path: AppRoutes.inviteCode, code: code);
    }

    if (host == 'student') {
      if (segments.length != 2) return null;
      if (segments[0] != 'summary') return null;
      final token = segments[1];
      if (token.isEmpty) return null;
      return DeepLinkRoute(path: '/student/summary/$token', token: token);
    }

    return null;
  }
}
