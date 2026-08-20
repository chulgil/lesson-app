import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/network/api_exceptions.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_settings.dart';
import 'package:lessonaza/features/schedule/data/repositories/mock_group_class_repository.dart';
import 'package:lessonaza/features/schedule/domain/entities/availability_slot.dart';
import 'package:lessonaza/features/schedule/domain/entities/teacher_availability.dart';
import 'package:lessonaza/features/schedule/domain/repositories/teacher_availability_repository.dart';
import 'package:lessonaza/features/schedule/domain/repositories/unified_lesson_request_repository.dart';
import 'package:lessonaza/features/schedule/presentation/providers/teacher_availability_providers.dart';
import 'package:lessonaza/features/schedule/presentation/providers/unified_lesson_request_providers.dart';
import 'package:lessonaza/features/schedule/data/repositories/mock_unified_lesson_request_repository.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';
import 'package:lessonaza/features/schedule/presentation/providers/group_class_providers.dart';
import 'package:lessonaza/features/schedule/presentation/screens/unified_lesson_request_screen.dart';
import 'package:lessonaza/features/schedule/presentation/widgets/proposal_bottom_sheet.dart';
import 'package:lessonaza/features/settings/domain/repositories/settings_repository.dart';
import 'package:lessonaza/features/settings/presentation/providers/settings_repository_provider.dart';
import 'package:lessonaza/features/students/domain/repositories/teacher_announcement_repository.dart';
import 'package:lessonaza/features/students/presentation/providers/teacher_announcement_providers.dart';
import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/features/subscription/subscription_facade.dart';

/// J15b — 학생이 교사 상세에서 반을 지정해 신청하고, 교사가 챗형 승인에서 그
/// 반의 그룹 템플릿을 제안하기까지의 FE 계약.
///
/// 계약:
///   ① 신청은 반 id 를 BE wire 이름(`group_class_id`)으로 실어 보낸다
///   ② 같은 학생 x 같은 반의 활성 신청은 중복 차단(409), 종결된 신청은 막지 않는다
///   ③ 신청 화면은 어떤 반에 신청하는지 읽기 전용으로 알려준다
///   ④ 교사 승인 화면은 그 반의 그룹 템플릿을 맨 위에 배지와 함께 노출하되,
///      다른 템플릿도 그대로 고를 수 있다 (교사 재량 보존)
void main() {
  const teacherId = 'teacher_1';
  const classId = 'group_class_1';

  UnifiedLessonRequest buildRequest({
    required String id,
    required String studentId,
    String? groupClassId,
    UnifiedRequestStatus status = UnifiedRequestStatus.pending,
  }) {
    return UnifiedLessonRequest(
      id: id,
      studentId: studentId,
      teacherId: teacherId,
      type: LessonRequestType.regular,
      instrument: '바이올린',
      goal: UnifiedLessonGoal.hobby,
      experience: UnifiedExperienceLevel.beginner,
      groupClassId: groupClassId,
      status: status,
      createdAt: DateTime(2026, 8, 20),
    );
  }

  group('① 신청 wire', () {
    test('반 id 는 BE 필드명 group_class_id 로 직렬화된다', () {
      final json =
          buildRequest(
            id: 'req-wire',
            studentId: 'student_1',
            groupClassId: classId,
          ).toJson();

      expect(json['group_class_id'], classId);
    });

    test('BE 응답의 group_class_id 를 다시 읽어들인다', () {
      final json =
          buildRequest(
            id: 'req-roundtrip',
            studentId: 'student_1',
            groupClassId: classId,
          ).toJson();

      expect(UnifiedLessonRequest.fromJson(json).groupClassId, classId);
    });

    test('반 지정이 없는 1:1 신청은 null 을 유지한다', () {
      final request = buildRequest(id: 'req-1to1', studentId: 'student_1');

      expect(request.groupClassId, isNull);
      expect(request.toJson()['group_class_id'], isNull);
    });
  });

  group('② 같은 반 중복 신청', () {
    test('활성 신청이 있으면 409 로 막는다', () async {
      final repository = MockUnifiedLessonRequestRepository();
      await repository.create(
        buildRequest(
          id: 'req-dup-1',
          studentId: 'student_1',
          groupClassId: classId,
        ),
      );

      await expectLater(
        repository.create(
          buildRequest(
            id: 'req-dup-2',
            studentId: 'student_1',
            groupClassId: classId,
          ),
        ),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 409),
        ),
      );
    });

    test('다른 반이면 막지 않는다', () async {
      final repository = MockUnifiedLessonRequestRepository();
      await repository.create(
        buildRequest(
          id: 'req-other-1',
          studentId: 'student_1',
          groupClassId: classId,
        ),
      );

      final second = await repository.create(
        buildRequest(
          id: 'req-other-2',
          studentId: 'student_1',
          groupClassId: 'group_class_2',
        ),
      );

      expect(second.id, 'req-other-2');
    });

    test('종결된 신청은 재신청을 막지 않는다', () async {
      final repository = MockUnifiedLessonRequestRepository();
      await repository.create(
        buildRequest(
          id: 'req-terminal',
          studentId: 'student_1',
          groupClassId: classId,
          status: UnifiedRequestStatus.cancelled,
        ),
      );

      final retry = await repository.create(
        buildRequest(
          id: 'req-retry',
          studentId: 'student_1',
          groupClassId: classId,
        ),
      );

      expect(retry.id, 'req-retry');
    });

    test('다른 학생의 같은 반 신청은 서로 막지 않는다', () async {
      final repository = MockUnifiedLessonRequestRepository();
      await repository.create(
        buildRequest(
          id: 'req-student-a',
          studentId: 'student_1',
          groupClassId: classId,
        ),
      );

      final other = await repository.create(
        buildRequest(
          id: 'req-student-b',
          studentId: 'student_2',
          groupClassId: classId,
        ),
      );

      expect(other.id, 'req-student-b');
    });
  });

  group('③ 신청 화면의 반 맥락', () {
    Future<void> pumpRequestScreen(
      WidgetTester tester, {
      String? groupClassId,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupClassRepositoryProvider.overrideWithValue(
              MockGroupClassRepository(),
            ),
            settingsRepositoryProvider.overrideWithValue(
              _StubSettingsRepository(),
            ),
            teacherAvailabilityRepositoryProvider.overrideWithValue(
              _StubAvailabilityRepository(),
            ),
          ],
          child: MaterialApp(
            home: UnifiedLessonRequestScreen(
              params: UnifiedLessonRequestParams(
                teacherId: teacherId,
                teacherName: '김선생',
                teacherInstruments: const ['바이올린'],
                groupClassId: groupClassId,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('반을 지정해 들어오면 클래스명을 읽기 전용으로 보여준다', (tester) async {
      await pumpRequestScreen(tester, groupClassId: classId);

      expect(
        find.text(AppStrings.groupClassRequestContextLabel),
        findsOneWidget,
      );
      // 시드의 group_class_1 이름 — 학생이 무엇에 신청하는지 화면에서 확인된다.
      expect(find.text('목요일 앙상블반'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('1:1 신청에는 반 맥락 줄이 없다', (tester) async {
      await pumpRequestScreen(tester);

      expect(find.text(AppStrings.groupClassRequestContextLabel), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('③-b 중복 신청 안내', () {
    testWidgets('BE 가 409 를 주면 재시도 대신 중복 안내를 띄운다', (tester) async {
      final repository = _RejectingRequestRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupClassRepositoryProvider.overrideWithValue(
              MockGroupClassRepository(),
            ),
            settingsRepositoryProvider.overrideWithValue(
              _StubSettingsRepository(),
            ),
            teacherAvailabilityRepositoryProvider.overrideWithValue(
              _StubAvailabilityRepository(openAllWeek: true),
            ),
            teacherAnnouncementRepositoryProvider.overrideWithValue(
              _StubAnnouncementRepository(),
            ),
            unifiedLessonRequestRepositoryProvider.overrideWithValue(
              repository,
            ),
          ],
          child: MaterialApp(
            home: UnifiedLessonRequestScreen(
              params: const UnifiedLessonRequestParams(
                teacherId: teacherId,
                teacherName: '김선생',
                teacherInstruments: ['바이올린'],
                groupClassId: classId,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 희망 시간 1개를 골라야 제출이 통과한다. 선택 가능한 칸은 그리드에서
      // paperAccentSoft + 테두리로 그려진다.
      final availableCell = find.byWidgetPredicate((w) {
        if (w is! GestureDetector) return false;
        final child = w.child;
        if (child is! Container) return false;
        final decoration = child.decoration;
        return decoration is BoxDecoration &&
            decoration.color == AppColors.paperAccentSoft &&
            decoration.border != null;
      });
      expect(availableCell, findsWidgets);
      await tester.ensureVisible(availableCell.first);
      await tester.pumpAndSettle();
      await tester.tap(availableCell.first);
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.priorityCellLabel(1)), findsOneWidget);

      final submit = find.text(AppStrings.submitRequest);
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.pumpAndSettle();

      // 신청 자체는 반 id 를 실어 나갔고, 409 는 중복 안내로 번역된다.
      expect(repository.attempted?.groupClassId, classId);
      expect(find.text(AppStrings.groupClassRequestDuplicate), findsOneWidget);
      expect(find.text(AppStrings.requestSubmitFailedRetry), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('④ 교사 승인 — 그룹 템플릿 우선노출', () {
    final groupTemplate = SubscriptionTemplate(
      id: 'template_group',
      ownerId: teacherId,
      ownerType: SubscriptionTemplateOwnerType.teacher,
      name: '앙상블반 8회권',
      totalLessons: 8,
      lessonDurationMinutes: 60,
      validityDays: 90,
      price: 280000,
      displayOrder: 9,
      appliesTo: SubscriptionAppliesTo.group,
      groupClassId: classId,
      createdAt: DateTime(2026, 8, 1),
    );
    final oneToOneTemplate = SubscriptionTemplate(
      id: 'template_1to1',
      ownerId: teacherId,
      ownerType: SubscriptionTemplateOwnerType.teacher,
      name: '개인레슨 8회권',
      totalLessons: 8,
      lessonDurationMinutes: 60,
      validityDays: 90,
      price: 480000,
      displayOrder: 0,
      createdAt: DateTime(2026, 8, 1),
    );

    Future<void> pumpSheet(WidgetTester tester, {String? groupClassId}) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeTeacherTemplatesProvider(
              teacherId,
            ).overrideWith((ref) async => [oneToOneTemplate, groupTemplate]),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder:
                    (context) => TextButton(
                      onPressed:
                          () => showProposalBottomSheet(
                            context,
                            teacherId: teacherId,
                            groupClassId: groupClassId,
                          ),
                      child: const Text('open'),
                    ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('반 지정 신청이면 그룹 템플릿이 배지와 함께 맨 위로 온다', (tester) async {
      await pumpSheet(tester, groupClassId: classId);

      expect(find.text(AppStrings.templateGroupClassBadge), findsOneWidget);
      expect(
        tester.getTopLeft(find.text(groupTemplate.name)).dy,
        lessThan(tester.getTopLeft(find.text(oneToOneTemplate.name)).dy),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('다른 템플릿도 그대로 고를 수 있다 (하드차단 금지)', (tester) async {
      await pumpSheet(tester, groupClassId: classId);

      await tester.tap(find.text(oneToOneTemplate.name));
      await tester.pumpAndSettle();

      // 선택 가능해야 제출 버튼이 살아난다.
      final submit = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, AppStrings.actionSendPaymentGuide),
      );
      expect(submit.onPressed, isNotNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('반 지정이 없으면 배지도 재정렬도 없다', (tester) async {
      await pumpSheet(tester);

      expect(find.text(AppStrings.templateGroupClassBadge), findsNothing);
      expect(
        tester.getTopLeft(find.text(oneToOneTemplate.name)).dy,
        lessThan(tester.getTopLeft(find.text(groupTemplate.name)).dy),
      );
      expect(tester.takeException(), isNull);
    });
  });
}

/// Stub repositories keep the form's own async work out of this test — the mock
/// repositories' delayed futures outlive the pump and trip the timer guard.
class _StubSettingsRepository implements SettingsRepository {
  @override
  Future<TeacherSettings> getTeacherSettings() async => _settings('teacher_1');

  @override
  Future<TeacherSettings> getTeacherSettingsById(String teacherId) async =>
      _settings(teacherId);

  TeacherSettings _settings(String id) => TeacherSettings(
    id: id,
    instruments: const ['바이올린'],
    createdAt: DateTime.utc(2026, 8, 1),
    lessonPriceTable: const {
      '바이올린': {'beginner': 60000},
    },
  );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

class _StubAvailabilityRepository implements TeacherAvailabilityRepository {
  _StubAvailabilityRepository({this.openAllWeek = false});

  /// When true the grid renders selectable cells so a test can pick a slot.
  final bool openAllWeek;

  @override
  Future<TeacherAvailability?> getAvailability(String teacherId) async {
    if (!openAllWeek) return null;
    return TeacherAvailability(
      id: 'availability-$teacherId',
      teacherId: teacherId,
      createdAt: DateTime.utc(2026, 8, 1),
      weeklySchedules: [
        for (var day = 0; day < 7; day++)
          WeeklySchedule(
            id: 'schedule-$day',
            dayOfWeek: day,
            startTime: '09:00',
            endTime: '21:00',
            createdAt: DateTime.utc(2026, 8, 1),
          ),
      ],
    );
  }

  @override
  Future<List<AvailabilitySlot>> getAvailableSlotsForDate(
    String teacherId,
    DateTime date, {
    String? currentStudentId,
  }) async => const [];

  @override
  Future<List<AvailabilitySlot>> getAvailableSlotsForDateRange(
    String teacherId,
    DateTime startDate,
    DateTime endDate, {
    String? currentStudentId,
  }) async => const [];

  @override
  Future<List<DateTime>> getNextAvailableDates(
    String teacherId, {
    required DateTime fromDate,
    int limit = 3,
  }) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

class _StubAnnouncementRepository implements TeacherAnnouncementRepository {
  @override
  Future<List<DateTime>> getDayOffs({
    required String teacherId,
    required DateTime from,
    required DateTime to,
  }) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Stands in for the backend rejecting a second active request for the same
/// class. Records what the screen tried to send.
class _RejectingRequestRepository implements UnifiedLessonRequestRepository {
  UnifiedLessonRequest? attempted;

  @override
  Future<UnifiedLessonRequest> create(UnifiedLessonRequest request) async {
    attempted = request;
    throw const ApiException(
      message: 'duplicate active request for group class',
      statusCode: 409,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
