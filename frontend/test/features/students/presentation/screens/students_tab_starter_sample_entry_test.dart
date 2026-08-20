import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/auth/auth_facade.dart';
import 'package:lessonaza/features/onboarding/onboarding_facade.dart';
import 'package:lessonaza/features/onboarding/presentation/providers/starter_sample_storage_provider.dart';
import 'package:lessonaza/features/students/domain/entities/roster_summary.dart';
import 'package:lessonaza/features/students/domain/entities/student.dart';
import 'package:lessonaza/features/students/domain/repositories/student_repository.dart';
import 'package:lessonaza/features/students/presentation/providers/grouped_students_provider.dart';
import 'package:lessonaza/features/students/presentation/providers/student_repository_provider.dart';
import 'package:lessonaza/features/students/presentation/providers/student_roster_summary_provider.dart';
import 'package:lessonaza/features/students/presentation/screens/students_tab.dart';

/// UXB-1 진입점 배선 가드 — 위젯만 만들고 화면에 붙이지 않는 "덩그러니" 방지.
/// students_tab 에서 제안/정리 CTA 를 떼어내면 RED.
void main() {
  Future<void> pumpTab(
    WidgetTester tester, {
    required StarterSampleData? sample,
    List<Student> students = const [],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWith((ref) => 'teacher_a'),
          studentRepositoryProvider.overrideWithValue(
            _StubStudentRepository(students),
          ),
          filteredGroupedStudentsProvider(
            'teacher_a',
          ).overrideWith((ref) async => const []),
          studentRosterSummaryProvider.overrideWith(
            (ref) async => RosterSummary.empty,
          ),
          starterSampleStorageProvider.overrideWith(
            () => _StubStarterSampleStorage(sample),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: StudentsTab())),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('empty roster offers the starter sample walkthrough', (
    tester,
  ) async {
    await pumpTab(tester, sample: null);

    expect(find.text(AppStrings.studentsEmptyTitle), findsOneWidget);
    expect(
      find.byType(StarterSampleOffer),
      findsOneWidget,
      reason: '빈 명단 아래 둘러보기 제안이 배선되어 있어야 한다',
    );
    expect(find.text(AppStrings.starterSampleOfferLabel), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cleanup CTA reaches the roster once a real student exists', (
    tester,
  ) async {
    await pumpTab(
      tester,
      sample: const StarterSampleData(studentId: 'student-1'),
      students: [
        Student(
          id: 'student-1',
          name: AppStrings.starterSampleStudentName,
          instrument: '바이올린',
          createdAt: DateTime(2026, 8, 20),
        ),
        Student(
          id: 'student-2',
          name: '김하늘',
          instrument: '피아노',
          createdAt: DateTime(2026, 8, 20),
        ),
      ],
    );

    expect(
      find.byType(StarterSampleCleanupBanner),
      findsOneWidget,
      reason: '정리 CTA 가 수강 관리 탭에 배선되어 있어야 한다',
    );
    expect(find.text(AppStrings.starterSampleCleanupLabel), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _StubStudentRepository implements StudentRepository {
  _StubStudentRepository(this._students);

  final List<Student> _students;

  @override
  Future<List<Student>> getStudents() async => _students;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubStarterSampleStorage extends StarterSampleStorage {
  _StubStarterSampleStorage(this._sample);

  final StarterSampleData? _sample;

  @override
  Future<StarterSampleData?> build() async => _sample;
}
