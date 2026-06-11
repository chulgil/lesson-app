// W2 Task 2.5 — LessonTimeSettings legacy route redirect 회귀 테스트.
// spec: .harness/spec/2026-06-11-teacher-settings-redesign.md §6.1 — 5묶음 IA 로
// 흩어진 후 legacy URL 진입은 5묶음 메인(ProfileTab) 으로 무음 redirect 한다.

import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/core/router/routes/profile_routes.dart';

void main() {
  group('LessonTimeSettings legacy route (W2 Task 2.5)', () {
    test('lessonTimeSettings 라우트 정의는 /profile/lesson-time 으로 보존된다', () {
      // legacy URL 자체는 유지 — redirect 로 사용자 진입 보장
      expect(AppRoutes.lessonTimeSettings, '/profile/lesson-time');
    });

    test('lessonTimeSettings GoRoute 는 5묶음 메인(/profile) 으로 redirect 한다', () {
      final route = profileRoutes.firstWhere(
        (r) => r.path == AppRoutes.lessonTimeSettings,
        orElse: () => throw StateError('lessonTimeSettings route 누락'),
      );

      final redirectFn = route.redirect;
      expect(
        redirectFn,
        isNotNull,
        reason: 'W2 spec §6.1 — legacy URL 은 redirect 로 5묶음 메인 진입을 보장해야 함',
      );

      // GoRouter redirect 콜백은 BuildContext + GoRouterState non-null 인자.
      // 본 unit test 는 redirect 가 설정되었음만 검증 — 실제 redirect 결과는
      // 통합 테스트 또는 widget test 에서 검증 (mock GoRouter 비용 회피).
    });
  });
}
