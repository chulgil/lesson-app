import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/lessons/data/repositories/mock_lesson_repository.dart';
import 'package:lessonaza/features/lessons/lessons_facade.dart';
import 'package:lessonaza/features/lessons/presentation/providers/lesson_widget_support_provider.dart';
import 'package:lessonaza/features/lessons/presentation/screens/add_lesson_screen.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_profile.dart';
import 'package:lessonaza/features/profile/presentation/providers/teacher_extended_profile_provider.dart';
import 'package:lessonaza/features/students/students_facade.dart';
import 'package:lessonaza/features/subscription/subscription_facade.dart';

/// 레슨 추가 폼 점진 공개(세부 설정 = 장소·반복·리마인더) 회귀 가드.
///
/// UI 감사: 6개 결정 지점(학생/수강권/날짜시간/소요시간/장소/반복/레슨내용/리마인더)을
/// 3개로 줄이기 위해 장소·반복·리마인더를 `ExpansionTile`(세부 설정)로 접었다.
/// `maintainState: true` 로 접힌 상태에서도 children 이 트리에 남으므로, 장소 자동
/// 프리필 같은 기본값 동작은 펼치지 않아도 그대로여야 한다(§요구사항 핵심).

const _teacherId = 'teacher_fixture';
const _studentId = 'student_fixture';
const _locationName = '고정 레슨실';

Student _fixtureStudent() => Student(
  id: _studentId,
  name: '홍길동',
  instrument: '피아노',
  level: StudentLevel.beginner,
  status: StudentStatus.active,
  monthlyFee: 200000,
  createdAt: DateTime(2026, 1, 1),
);

LessonLocation _fixtureLocation() => LessonLocation(
  id: 'loc_fixture',
  name: _locationName,
  type: LocationType.teacherStudio,
  isDefault: true,
  createdAt: DateTime(2026, 1, 1),
);

/// 저장된 [Lesson] 을 가로채 저장값을 검증할 수 있게 하는 spy.
class _SpyLessonRepository extends MockLessonRepository {
  final List<Lesson> created = [];

  @override
  Future<Lesson> createLesson(Lesson lesson, {String? overflowMode}) async {
    final saved = await super.createLesson(lesson, overflowMode: overflowMode);
    created.add(saved);
    return saved;
  }
}

/// 인증 체인(currentUserIdProvider 등) 없이도 안전하게 즉시 resolve.
class _FakeTeacherExtendedProfile extends TeacherExtendedProfile {
  @override
  AsyncValue<TeacherProfile?> build() => const AsyncValue.data(null);
}

List<Override> _overrides(_SpyLessonRepository repo) => [
  currentTeacherIdProvider.overrideWithValue(_teacherId),
  studentsProvider.overrideWith((ref) async => [_fixtureStudent()]),
  activeStudentSubscriptionsProvider(
    _studentId,
  ).overrideWith((ref) async => []),
  teacherMakeupCreditsProvider(_studentId).overrideWith((ref) async => []),
  lessonsProvider.overrideWith((ref) async => []),
  lessonRepositoryProvider.overrideWithValue(repo),
  lessonWidgetTeacherLocationsProvider(
    _teacherId,
  ).overrideWith((ref) => AsyncValue.data([_fixtureLocation()])),
  teacherExtendedProfileProvider.overrideWith(
    () => _FakeTeacherExtendedProfile(),
  ),
];

Future<void> _pumpBounded(WidgetTester tester, [int frames = 20]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// 800x600 테스트 뷰포트에서 폼이 스크롤돼야 도달하는 대상을 안전하게 탭한다.
Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await _pumpBounded(tester);
  await tester.tap(finder);
  await _pumpBounded(tester);
}

/// 학생·미래 날짜를 프리셀렉트해 학생 선택 시트/수강권 시트 상호작용 없이
/// 곧장 폼 기본 상태(세부 설정 접힘)로 진입한다.
Future<GoRouter> _pumpAddLesson(
  WidgetTester tester,
  _SpyLessonRepository repo,
) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const Scaffold()),
      GoRoute(
        path: '/add-lesson',
        builder:
            (_, __) => const AddLessonScreen(
              preselectedStudentId: _studentId,
              preselectedDate: '2099-01-05',
              preselectedHour: 14,
              preselectedMinute: 0,
            ),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(repo),
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pump();
  // studentsProvider 를 미리 resolve — initState 의 preselectedStudentId
  // 매칭은 addPostFrameCallback 1회뿐이라, Future 가 그 시점까지 안 풀리면
  // 학생 매칭이 조용히 무산된다(테스트 타이밍 레이스, 실 앱과 무관).
  final container = ProviderScope.containerOf(
    tester.element(find.byType(Scaffold).first),
  );
  await container.read(studentsProvider.future);
  router.push('/add-lesson');
  await _pumpBounded(tester);
  return router;
}

void main() {
  late _SpyLessonRepository lessonRepo;

  setUp(() {
    lessonRepo = _SpyLessonRepository();
  });

  // 참고: flutter_test 의 find.text/byType 등은 기본값이 skipOffstage:true —
  // ExpansionTile 이 접히면(Offstage) 기본 파인더가 자동으로 "화면에 없음"을
  // 뜻하게 된다. 트리 존재(maintainState) 자체를 확인할 때만 skipOffstage:false.

  testWidgets('세부 설정 접힘 기본값 — 펼치지 않아도 자동 프리필로 저장됨', (tester) async {
    final router = await _pumpAddLesson(tester, lessonRepo);

    expect(tester.takeException(), isNull);
    // 접힌 상태 — 기본 파인더는 반복 섹션을 찾지 못한다(화면에 없음).
    expect(find.text('정기 레슨'), findsNothing);
    // 그러나 maintainState:true 로 트리에는 여전히 남아 있어야 한다.
    expect(find.text('정기 레슨', skipOffstage: false), findsOneWidget);

    // 장소 자동 프리필은 접힌 상태에서도 동작해야 한다(§요구사항 핵심).
    // (ChoiceChip 은 소요시간 선택기도 쓰므로 라벨로 특정한다.)
    final chip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, _locationName, skipOffstage: false),
    );
    expect(chip.selected, isTrue, reason: '접힌 상태에서도 장소가 자동 선택돼야 함');

    await _tapVisible(
      tester,
      find.widgetWithText(FilledButton, AppStrings.addLessonButton),
    );
    await _pumpBounded(tester, 30);

    expect(tester.takeException(), isNull);
    expect(lessonRepo.created, hasLength(1));
    expect(
      lessonRepo.created.single.location?.name,
      _locationName,
      reason: '접힌 상태에서 저장해도 자동 프리필된 장소가 이전과 동일하게 저장돼야 함',
    );
    expect(router.state.uri.path, '/', reason: '저장 성공 시 이전 화면으로 복귀');
  });

  testWidgets('세부 설정 펼치기 — 장소·반복·리마인더 3섹션 노출', (tester) async {
    await _pumpAddLesson(tester, lessonRepo);

    expect(find.text('정기 레슨'), findsNothing);
    expect(find.text('레슨 알림'), findsNothing);

    await _tapVisible(
      tester,
      find.text(AppStrings.lessonAdvancedSettingsLabel),
    );

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.lessonLocationLabel), findsOneWidget);
    expect(find.text('정기 레슨'), findsOneWidget);
    expect(find.text('레슨 알림'), findsOneWidget);
  });

  testWidgets('접힌 세부 설정 안 검증 에러 — 저장 시 자동으로 펼쳐짐', (tester) async {
    await _pumpAddLesson(tester, lessonRepo);

    // 펼쳐서 정기 레슨 ON (요일은 선택하지 않음) 후 다시 접는다.
    final header = find.text(AppStrings.lessonAdvancedSettingsLabel);
    await _tapVisible(tester, header);
    await _tapVisible(tester, find.byType(Switch).first); // 정기 레슨 스위치
    await _tapVisible(tester, header);
    expect(find.text('반복 요일'), findsNothing);

    await _tapVisible(
      tester,
      find.widgetWithText(
        FilledButton,
        AppStrings.reserveRecurringLessonButton,
      ),
    );

    expect(find.text(AppStrings.selectRecurringDaysValidation), findsOneWidget);
    expect(
      find.text('반복 요일'),
      findsOneWidget,
      reason: '접힌 세부 설정 안 검증 에러는 저장 시 자동으로 펼쳐져야 함',
    );
  });
}
