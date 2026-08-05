// #751 — 전 화면 렌더 스모크 하네스 (실 GoRouter + 2 뷰포트).
//
// 목적: 화면-흐름 런타임 크래시(RenderBox/RenderMetaData NEEDS-LAYOUT,
// RenderFlex overflow)를 자동 검출. flutter analyze(정적) + 고립 위젯
// pump(false-green)가 놓친 #746/#747 류 재발 방지.
//
// 설계: #731 Gate 3 e2e 하네스(`bootAsRole`)를 재사용해 실 라우터를 띄우고,
// 실제 GoRouter 네비게이션으로 각 라우트를 mobile(375)·desktop(1440) 두
// 뷰포트에서 렌더 → 매 단계 `expect(tester.takeException(), isNull)`.
// 고립 pump 금지(false-green 원인) — 실 라우터 흐름으로만 재현.
//
// 범위: 역할별(teacher/student/parent) **무파라미터** top-level 라우트.
// :param 이 필요한 상세 라우트는 시드 id 의존이라 별도 e2e 여정에서 다룬다.
//
// 실행: flutter test test/smoke/all_routes_render_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/features/students/presentation/screens/add_student_screen.dart';
import 'package:lessonaza/features/home/home_ui_facade.dart';

import '../e2e/helpers/e2e_harness.dart';

/// 두 표준 뷰포트 — mobile 375, desktop 1440 (이번 크래시는 desktop 특이성).
const _mobile = Size(375, 812);
const _desktop = Size(1440, 900);

/// 교사 셸에서 도달 가능한 무파라미터 top-level 라우트. (첫 항목 = 홈)
const _teacherRoutes = <String>[
  AppRoutes.home,
  AppRoutes.students,
  AppRoutes.addStudentMethod,
  AppRoutes.lessons,
  AppRoutes.addLesson,
  AppRoutes.bulkFeedback,
  AppRoutes.quickFeedbackList,
  AppRoutes.teacherAvailability,
  AppRoutes.teacherVacationMode,
  AppRoutes.scheduleChangeRequests,
  AppRoutes.pendingBookings,
  AppRoutes.subscriptions,
  AppRoutes.teacherSubscriptions,
  AppRoutes.expiringSubscriptions,
  AppRoutes.makeupCredits,
  AppRoutes.lessonPolicy,
  AppRoutes.subscriptionTemplates,
  AppRoutes.proposalSettings,
  AppRoutes.issueSubscription,
  AppRoutes.analytics,
  AppRoutes.teacherAttendance,
  AppRoutes.invite,
  AppRoutes.inviteHistory,
  AppRoutes.notifications,
  AppRoutes.priceTable,
  AppRoutes.extendedProfile,
  AppRoutes.tipTemplateManagement,
  AppRoutes.feedbackTemplateManagement,
  AppRoutes.cancellationDefaults,
  AppRoutes.profileVisibility,
  AppRoutes.profilePreview,
  AppRoutes.outstandingPayments,
  AppRoutes.paymentPending,
  AppRoutes.invitePending,
  AppRoutes.instrumentManagement,
  AppRoutes.repertoireManagement,
  AppRoutes.help,
  AppRoutes.appInfo,
  AppRoutes.newsRoadmap,
  AppRoutes.notificationSettings,
  AppRoutes.termsOfService,
  AppRoutes.privacyPolicy,
  AppRoutes.backupSettings,
  AppRoutes.allRecordings,
  AppRoutes.followList,
  AppRoutes.followFeed,
  AppRoutes.badgeCollection,
  AppRoutes.announcementHistory,
  AppRoutes.awaitingFeedback,
  AppRoutes.myProfileCategory,
  AppRoutes.policyNotificationsCategory,
];

/// 학생 셸에서 도달 가능한 무파라미터 top-level 라우트. (첫 항목 = 홈)
const _studentRoutes = <String>[
  AppRoutes.studentHome,
  AppRoutes.teacherSearch,
  AppRoutes.myTeachers,
  AppRoutes.addManualTeacher,
  AppRoutes.subscriptions,
  AppRoutes.myBookings,
  AppRoutes.pendingBookings,
  AppRoutes.practiceRepertoire,
  AppRoutes.practiceArchive,
  AppRoutes.practiceStats,
  AppRoutes.practiceLoopStats,
  AppRoutes.repertoireHistory,
  AppRoutes.practiceGoalSettings,
  AppRoutes.invite,
  AppRoutes.inviteHistory,
  AppRoutes.notifications,
  AppRoutes.studentGrowthDetail,
  AppRoutes.myLessonRequests,
  AppRoutes.followFeed,
  AppRoutes.followList,
  AppRoutes.help,
  AppRoutes.appInfo,
  AppRoutes.notificationSettings,
  AppRoutes.selectTeacher,
  AppRoutes.badgeCollection,
];

/// 학부모 셸에서 도달 가능한 무파라미터 top-level 라우트. (첫 항목 = 홈)
const _parentRoutes = <String>[
  AppRoutes.parentHome,
  AppRoutes.childProfiles,
  AppRoutes.addChildProfile,
  AppRoutes.notifications,
  AppRoutes.help,
  AppRoutes.appInfo,
  AppRoutes.notificationSettings,
];

/// 본 하네스가 발견한 화면별 레이아웃 이슈 추적. 현재 전부 수정됨 → 제외 목록 비움
/// (스윕이 전 라우트를 가드). 새 이슈를 잠시 보류하려면 여기에 라우트를 추가한다.
///
/// 수정 완료:
/// - #853 /home @375 — RenderFlex 6.5px overflow. 근본원인 = `SubscriptionBadge`
///   내부 Row(고정 폭·ellipsis 없음)가 좁은 info 칼럼(~145px)보다 6.5px 넓음.
///   수정 = 배지 라벨 Flexible+ellipsis + LessonCard 배지행 Row→Wrap(배지에 bounded
///   폭 부여). addStudent #750 의 6.5px 도 동일 출처(home 카드)였음 → 함께 해소.
/// - #853 /payments/pending 53px(학생명 Flexible), /proposals/settings(isExpanded).
/// - #852 chip_input_field Row→Wrap, teacher_search_card 요금 Flexible.
const _knownRenderIssues = <String>{};

void main() {
  setUpAll(initE2eEnvironment);
  tearDownAll(disposeE2eEnvironment);

  /// 로그인된 셸에서 [route]로 실 라우터 이동 후 [size] 뷰포트로 렌더 검증.
  Future<void> goAndAssert(
    WidgetTester tester,
    String route,
    Size size, {
    Finder? expectScreen,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    final ctx = tester.element(find.byType(Scaffold).first);
    GoRouter.of(ctx).go(route);
    await settle(tester);
    if (expectScreen != null) {
      expect(
        expectScreen,
        findsOneWidget,
        reason: '$route 도달(@${size.width.toInt()})',
      );
    }
    expect(
      tester.takeException(),
      isNull,
      reason: '$route 렌더 크래시 없음 (@${size.width.toInt()})',
    );
  }

  /// 전 라우트 루프 — 한 번의 boot 으로 모든 라우트를 두 뷰포트에서 렌더하고
  /// 실패를 누적해 한 실행에 전체 문제 라우트를 드러낸다. 라우터 참조를 boot
  /// 직후 한 번 잡아 두므로, 한 라우트가 크래시해도 다음 라우트로 계속 진행한다.
  /// 라우트 사이에는 홈([routes].first)으로 복귀해 깨끗한 셸에서 다음을 시작한다.
  Future<void> sweepRoutes(
    WidgetTester tester,
    DevAccount account,
    List<String> routes,
  ) async {
    await bootAsRole(tester, account);
    final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
    final home = routes.first;

    final failures = <String>[];
    for (final route in routes) {
      // 알려진 화면별 이슈는 건너뛴다(별도 후속 추적, _knownRenderIssues 주석 참조).
      if (_knownRenderIssues.contains(route)) continue;
      for (final size in const [_desktop, _mobile]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        try {
          router.go(route);
          await settle(tester);
        } catch (e) {
          failures.add('$route @${size.width.toInt()} (nav threw): $e');
          continue;
        }
        final ex = tester.takeException();
        if (ex != null) {
          failures.add('$route @${size.width.toInt()}: $ex');
        }
      }
      // 다음 라우트를 깨끗한 셸에서 시작하도록 홈으로 복귀.
      router.go(home);
      await settle(tester);
      tester.takeException();
    }

    // 마지막 라우트/홈 복귀가 남긴 mock 지연(예: getByStudentId 100ms) 타이머를
    // 충분히 배수해 teardown 의 "pending timer" 실패를 막는다.
    await settle(tester, frames: 20);
    tester.takeException();

    expect(
      failures,
      isEmpty,
      reason:
          '${account.name} (${routes.length} 라우트) 렌더 크래시 ${failures.length}건:\n'
          '${failures.join('\n')}',
    );
  }

  testWidgets('교사 무파라미터 라우트 — 2 뷰포트 렌더 크래시 없음', (tester) async {
    await sweepRoutes(tester, DevAccount.teacher, _teacherRoutes);
  });

  testWidgets('학생 무파라미터 라우트 — 2 뷰포트 렌더 크래시 없음', (tester) async {
    await sweepRoutes(tester, DevAccount.student, _studentRoutes);
  });

  testWidgets('학부모 무파라미터 라우트 — 2 뷰포트 렌더 크래시 없음', (tester) async {
    await sweepRoutes(tester, DevAccount.parent, _parentRoutes);
  });

  // ── 회귀 가드: 특정 버그 재현 (#746/#750) ───────────────────────────────

  testWidgets('#746 학생 직접 등록 폼 — desktop·mobile 렌더 크래시 없음', (tester) async {
    await bootAsRole(tester, DevAccount.teacher);
    await goAndAssert(
      tester,
      AppRoutes.addStudent,
      _desktop,
      expectScreen: find.byType(AddStudentScreen),
    );
    await goAndAssert(
      tester,
      AppRoutes.addStudent,
      _mobile,
      expectScreen: find.byType(AddStudentScreen),
    );
  });

  testWidgets('#750 학생 직접 등록 — mobile(375) 주소 행 오버플로우 없음 + 폼 full-width', (
    tester,
  ) async {
    await bootAsRole(tester, DevAccount.teacher);

    tester.view.physicalSize = _mobile;
    tester.view.devicePixelRatio = 1.0;
    GoRouter.of(
      tester.element(find.byType(Scaffold).first),
    ).go(AppRoutes.addStudent);
    await settle(tester);

    expect(find.byType(AddStudentScreen), findsOneWidget);
    // 본 가드의 핵심은 본문이 93px 로 붕괴하지 않는지(#746 cascade 회귀)다.
    // addStudent @375 의 6.5px overflow 는 home 카드 SubscriptionBadge 가 출처였고
    // #853 에서 해소됨 — 이제 오버플로우 없음을 단언해 회귀를 가드한다.
    expect(
      tester.takeException(),
      isNull,
      reason: 'addStudent @375 렌더 오버플로우 없음 (#853 해소 회귀 가드)',
    );
    final body = find.byType(SingleChildScrollView);
    expect(body, findsOneWidget);
    final bodyWidth = tester.getSize(body).width;
    expect(
      bodyWidth,
      greaterThan(300),
      reason:
          '폼 본문이 full-width 여야 함 (93px 압축 회귀 가드). 실제 ${bodyWidth.toInt()}px',
    );
  });

  // ── 회귀 가드: #853 /home LessonCard 배지 행 오버플로우 ───────────────────
  testWidgets('#853 교사 홈 — mobile(375) LessonCard 배지 행 오버플로우 없음', (
    tester,
  ) async {
    await bootAsRole(tester, DevAccount.teacher);

    // 홈은 boot 직후 랜딩. 375 로 좁혀 배지 행(contextBadge+SubscriptionBadge)이
    // info 칼럼 폭을 넘지 않는지 확인. 출처: lesson_card.dart `_buildBadgesRow`.
    tester.view.physicalSize = _mobile;
    tester.view.devicePixelRatio = 1.0;
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go(AppRoutes.home);
    await settle(tester);

    expect(find.byType(LessonCard), findsWidgets, reason: '홈 레슨 카드 렌더');
    expect(
      tester.takeException(),
      isNull,
      reason: '홈 LessonCard 배지 행 RenderFlex 오버플로우 없음 (@375)',
    );
  });
}
