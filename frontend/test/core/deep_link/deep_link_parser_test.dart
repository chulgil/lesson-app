// R2 #318 — lessonapp:// URI 파서 단위 테스트.
//
// 딥링크 라우팅 계약:
//   lessonapp://invite/{code}              → /invite/code (code 6자리)
//   lessonapp://student/summary/{token}    → /student/summary/{token}
// 그 외 URI 는 null 반환 (지원 안 함).

import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/deep_link/deep_link_parser.dart';
import 'package:lessonaza/core/router/app_routes.dart';

void main() {
  group('DeepLinkParser.toRoute', () {
    test('invite code URI returns /invite/code path with code arg', () {
      final result = DeepLinkParser.toRoute(
        Uri.parse('lessonapp://invite/123456'),
      );

      expect(result, isNotNull);
      expect(result!.path, AppRoutes.inviteCode);
      expect(result.code, '123456');
      expect(result.token, isNull);
    });

    test('student summary URI returns concrete path with token arg', () {
      final result = DeepLinkParser.toRoute(
        Uri.parse('lessonapp://student/summary/abc-def-token'),
      );

      expect(result, isNotNull);
      expect(result!.path, '/student/summary/abc-def-token');
      expect(result.token, 'abc-def-token');
      expect(result.code, isNull);
    });

    test('unknown scheme returns null', () {
      final result = DeepLinkParser.toRoute(
        Uri.parse('https://example.com/invite/123456'),
      );

      expect(result, isNull);
    });

    test('unknown host returns null', () {
      final result = DeepLinkParser.toRoute(
        Uri.parse('lessonapp://unknown/foo'),
      );

      expect(result, isNull);
    });

    test('invite without code returns null', () {
      final result = DeepLinkParser.toRoute(Uri.parse('lessonapp://invite/'));

      expect(result, isNull);
    });

    test('student summary without token returns null', () {
      final result = DeepLinkParser.toRoute(
        Uri.parse('lessonapp://student/summary/'),
      );

      expect(result, isNull);
    });

    test('student missing summary segment returns null', () {
      final result = DeepLinkParser.toRoute(
        Uri.parse('lessonapp://student/abc'),
      );

      expect(result, isNull);
    });

    test('invite code with non-digit chars returns null', () {
      final result = DeepLinkParser.toRoute(
        Uri.parse('lessonapp://invite/abcdef'),
      );

      expect(result, isNull);
    });

    test('invite code with wrong length returns null', () {
      final result = DeepLinkParser.toRoute(
        Uri.parse('lessonapp://invite/12345'),
      );

      expect(result, isNull);
    });
  });
}
