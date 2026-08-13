// Regression / entry-point wiring for #1264 — AcademyActivityTimelineScreen
// was fully built + smoke-tested (#395) with a registered route, but no
// screen ever pushed it (orphan). This test proves a real entry point exists
// and threads the correct per-academy actorMemberId — not just any string —
// through to the destination route.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/router/routes/academy_routes.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/academy/academy_facade.dart';
import 'package:lessonaza/features/academy/domain/entities/academy_activity_log.dart';
import 'package:lessonaza/features/academy/presentation/providers/academy_activity_provider.dart';
import 'package:lessonaza/features/auth/auth_facade.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_profile.dart';
import 'package:lessonaza/features/profile/presentation/providers/teacher_extended_profile_provider.dart';
import 'package:lessonaza/features/profile/presentation/screens/profile_visibility_screen.dart';

void main() {
  testWidgets("'내 활동 보기' 진입 → 해당 학원의 actorMemberId 로 활동 타임라인 라우트 도달 (#1264)", (
    tester,
  ) async {
    final profile = TeacherProfile(
      id: 'p1',
      userId: 'u1',
      name: '김선생',
      instruments: const ['피아노'],
      introduction: '소개글 텍스트입니다 20자 이상으로 충분히 길게 작성합니다.',
      createdAt: DateTime.utc(2026, 5, 1),
    );

    // 학원별 진입 버튼이 실제로 그 학원의 actorMemberId 를 넘기는지 증명하기
    // 위해, 정확한 (academyId, actorMemberId) 키에만 로그를 붙인다. 잘못된
    // 값이 배선되면(예: 빈 문자열) 이 override 는 매칭되지 않고 실제
    // repository 경로(빈 결과)로 빠져 아래 단언이 실패한다.
    final canned = AcademyActivityLog(
      id: 'log_test',
      academyId: 'acad_1',
      actorMemberId: 'member_1',
      actorName: '김선생',
      actionType: 'lesson_completed',
      description: '#1264 진입점 검증용 로그',
      createdAt: DateTime(2026, 8, 1, 10),
    );

    final router = GoRouter(
      initialLocation: '/profile/visibility',
      routes: [
        GoRoute(
          path: '/profile/visibility',
          builder: (context, state) => const ProfileVisibilityScreen(),
        ),
        ...academyRoutes,
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          teacherExtendedProfileProvider.overrideWith(
            () => _ImmediateProfileNotifier(profile),
          ),
          currentUserIdProvider.overrideWithValue('u1'),
          teacherAcademiesProvider('u1').overrideWith(
            (ref) async => const [
              TeacherAcademyMembership(
                academyId: 'acad_1',
                academyName: 'OO음악학원',
                publicPageConsent: true,
                actorMemberId: 'member_1',
              ),
            ],
          ),
          academyActivityLogsProvider(
            'acad_1',
            'member_1',
          ).overrideWith((ref) async => [canned]),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final entryButtonFinder = find.byIcon(Icons.history);
    await tester.scrollUntilVisible(entryButtonFinder, 200);
    await tester.tap(entryButtonFinder);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // 목적지 화면 도달.
    expect(find.text(AppStrings.academyActivityTimeline), findsOneWidget);
    // 정확한 actorMemberId 로 조회된 로그만 렌더된다 — 잘못된 파라미터가
    // 배선됐다면 이 텍스트는 나타나지 않는다.
    expect(find.text('#1264 진입점 검증용 로그'), findsOneWidget);
  });
}

class _ImmediateProfileNotifier extends TeacherExtendedProfile {
  _ImmediateProfileNotifier(this._profile);

  final TeacherProfile _profile;

  @override
  AsyncValue<TeacherProfile?> build() => AsyncValue.data(_profile);
}
