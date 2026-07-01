// #747 overflow 재현 프로브 — 사용자 헤드리스 프로브가 놓친 3차원 전수 검증:
//   (1) 상태 분기: 학생선택 entry / NoMembershipState / ErrorState / 배치 폼
//   (2) 짧은 뷰포트 높이 (macOS 창 축소)
//   (3) textScaleFactor 1.0 / 1.3 / 1.6 / 2.0 (프로브가 1.0만 썼을 가능성)
//
// 각 조합에서 (a) 해당 상태가 실제 렌더됐는지 확인(false-green 방지) →
// (b) RenderFlex overflow 예외 부재를 단언(takeException isNull).
//
// RED = 특정 조합에서 실제 overflow (사용자 프로브 사각지대). GREEN = 해소 근거.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/auth/auth_facade.dart'
    show currentUserIdProvider;
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';
import 'package:lessonaza/features/schedule/domain/repositories/unified_lesson_request_repository.dart';
import 'package:lessonaza/features/schedule/presentation/providers/unified_lesson_request_providers.dart';
import 'package:lessonaza/features/students/domain/entities/grouped_students.dart';
import 'package:lessonaza/features/students/domain/entities/student.dart';
import 'package:lessonaza/features/students/domain/entities/student_with_membership.dart';
import 'package:lessonaza/features/students/students_facade.dart'
    show groupedStudentsProvider;
import 'package:lessonaza/features/subscription/data/repositories/mock_subscription_repository.dart';
import 'package:lessonaza/features/subscription/presentation/providers/subscription_issue_flow_provider.dart';
import 'package:lessonaza/features/subscription/presentation/providers/subscription_providers.dart';
import 'package:lessonaza/features/subscription/presentation/screens/issue_subscription_screen.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/issue_form_membership_widgets.dart';

const _teacherId = 't1';
const _studentId = 's1';

/// 경량 lesson-request repo — 무거운 mock 시드(pumpAndSettle hang) 회피.
class _FakeLessonRequestRepository implements UnifiedLessonRequestRepository {
  final Map<String, UnifiedLessonRequest> store = {};
  @override
  Future<UnifiedLessonRequest?> getById(String id) async => store[id];
  @override
  Future<UnifiedLessonRequest> update(UnifiedLessonRequest request) async {
    store[request.id] = request;
    return request;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');
}

Future<void> _pump(
  WidgetTester tester, {
  required Size size,
  required double textScale,
  required List<Override> overrides,
  required Widget screen,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: Builder(
          builder:
              (context) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(textScale)),
                child: screen,
              ),
        ),
      ),
    ),
  );
  // pumpAndSettle 대신 유한 pump — mock 비동기 timer hang 회피.
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

String _label(Size s, double t) =>
    '${s.width.toInt()}x${s.height.toInt()} @${t}x';

void main() {
  // ── Group A: 학생선택 entry (studentId 없이 진입) — 스크롤 구조, overflow 없어야 ──
  group('A. 학생선택 entry', () {
    final sizes = [
      const Size(1280, 720),
      const Size(800, 600),
      const Size(375, 667),
      const Size(800, 360),
    ];
    for (final size in sizes) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('entry ${_label(size, scale)} → no overflow', (
          tester,
        ) async {
          await _pump(
            tester,
            size: size,
            textScale: scale,
            overrides: [
              currentUserIdProvider.overrideWithValue(_teacherId),
              groupedStudentsProvider(_teacherId).overrideWith(
                (ref) async => [
                  StudentGroup(
                    students: [
                      StudentWithMembership(
                        student: Student(
                          id: _studentId,
                          name: '홍길동',
                          instrument: '바이올린',
                          createdAt: DateTime(2026, 6, 19),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
            screen: const IssueSubscriptionScreen(studentIds: []),
          );
          expect(
            find.text(AppStrings.issueSelectStudentTitle),
            findsOneWidget,
            reason: '학생선택 상태가 렌더돼야 (false-green 방지)',
          );
          expect(tester.takeException(), isNull, reason: 'overflow 없어야');
        });
      }
    }
  });

  // ── Group B: NoMembershipState (Center>Column) — 짧은 높이/큰 textScale bottom overflow 후보 ──
  group('B. NoMembershipState', () {
    final sizes = [
      const Size(1280, 720),
      const Size(800, 600),
      const Size(800, 400),
      const Size(375, 667),
      const Size(375, 360),
    ];
    for (final size in sizes) {
      for (final scale in [1.0, 1.5, 2.0]) {
        testWidgets('no-membership ${_label(size, scale)} → no overflow', (
          tester,
        ) async {
          await _pump(
            tester,
            size: size,
            textScale: scale,
            overrides: [
              currentUserIdProvider.overrideWithValue(_teacherId),
              subscriptionIssueMembershipsProvider(
                _studentId,
              ).overrideWith((ref) async => []),
              subscriptionIssueStudentProvider(
                _studentId,
              ).overrideWith((ref) async => null),
            ],
            screen: const IssueSubscriptionScreen(studentIds: [_studentId]),
          );
          expect(
            find.byType(NoMembershipState),
            findsOneWidget,
            reason: 'NoMembershipState 가 렌더돼야 (false-green 방지)',
          );
          expect(tester.takeException(), isNull, reason: 'overflow 없어야');
        });
      }
    }
  });

  // ── Group C: SubscriptionErrorState (Center>Column) — 동일 후보 ──
  group('C. SubscriptionErrorState', () {
    final sizes = [
      const Size(800, 600),
      const Size(800, 400),
      const Size(375, 360),
    ];
    for (final size in sizes) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('error ${_label(size, scale)} → no overflow', (
          tester,
        ) async {
          await _pump(
            tester,
            size: size,
            textScale: scale,
            overrides: [
              currentUserIdProvider.overrideWithValue(_teacherId),
              subscriptionIssueMembershipsProvider(
                _studentId,
              ).overrideWith((ref) async => throw Exception('load fail')),
              subscriptionIssueStudentProvider(
                _studentId,
              ).overrideWith((ref) async => null),
            ],
            screen: const IssueSubscriptionScreen(studentIds: [_studentId]),
          );
          expect(
            find.byType(SubscriptionErrorState),
            findsOneWidget,
            reason: 'ErrorState 가 렌더돼야 (false-green 방지)',
          );
          expect(tester.takeException(), isNull, reason: 'overflow 없어야');
        });
      }
    }
  });

  // ── Group D: 배치 폼 전체 빌드 (모든 sub-widget 포함) — 좁은 폭 가로 overflow ──
  // 배치 모드는 per-student membership 조회를 우회. tall 뷰포트(6000)로 lazy ListView 의
  // 전 섹션을 일괄 빌드해 아래-fold sub-widget 까지 overflow 를 검출한다.
  //
  // 현실 바(assert): 전 폭 @1.0x(기본 글씨) + 375·800 @1.3x(중간 Dynamic Type) → overflow 0.
  //   #747 데스크톱/실기기 기본글씨 overflow 를 가드한다.
  // 잔여(미assert, 별도 추적 #1067): 320 @1.3x, 전 폭 @≥1.6x 는 폼 전역 sub-widget
  //   (TypeSelector·PaymentSection·Summary 등)이 큰 Dynamic Type 에서 overflow —
  //   폼 전역 접근성 하드닝은 #1067 에서 이 프로브를 확장해 RED→GREEN 으로 처리.
  group('D. 배치 폼 (전 섹션, 현실 바)', () {
    const height = 6000.0;
    final combos = <(double, double)>[
      (375.0, 1.0),
      (320.0, 1.0),
      (800.0, 1.0),
      (375.0, 1.3),
      (800.0, 1.3),
    ];
    for (final (width, scale) in combos) {
      final size = Size(width, height);
      testWidgets('batch ${_label(size, scale)} → no overflow', (tester) async {
        await _pump(
          tester,
          size: size,
          textScale: scale,
          overrides: [
            subscriptionRepositoryProvider.overrideWithValue(
              MockSubscriptionRepository(),
            ),
            unifiedLessonRequestRepositoryProvider.overrideWithValue(
              _FakeLessonRequestRepository(),
            ),
          ],
          screen: const IssueSubscriptionScreen(
            studentIds: ['student-1', 'student-2'],
          ),
        );
        // 재변경 허용 섹션이 실제 빌드됐는지 확인(false-green 방지).
        expect(
          find.text(AppStrings.rescheduleAllowanceTitle),
          findsOneWidget,
          reason: '재변경 허용 섹션이 빌드돼야 (false-green 방지)',
        );
        expect(tester.takeException(), isNull, reason: 'overflow 없어야');
      });
    }
  });
}
