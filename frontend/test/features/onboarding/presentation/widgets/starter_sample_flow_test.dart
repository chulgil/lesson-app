import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/auth/auth_facade.dart';
import 'package:lessonaza/features/lessons/domain/repositories/lesson_repository.dart';
import 'package:lessonaza/features/lessons/lessons_facade.dart';
import 'package:lessonaza/features/onboarding/onboarding_facade.dart';
import 'package:lessonaza/features/onboarding/presentation/providers/starter_sample_storage_provider.dart';
import 'package:lessonaza/features/practice/domain/repositories/practice_repository.dart';
import 'package:lessonaza/features/practice/practice_facade.dart';
import 'package:lessonaza/features/students/domain/repositories/student_repository.dart';
import 'package:lessonaza/features/students/students_facade.dart';

/// UXB-1 스타터 샘플의 두 진입점(빈 상태 제안 · 정리 배너)을 실제 리포지토리
/// 계약 위에서 끝에서 끝까지 확인한다 — 진입점 배선이 끊기면 RED.
void main() {
  late _FakeStudentRepository students;
  late _FakeLessonRepository lessons;
  late _FakePracticeRepository practice;

  setUp(() {
    students = _FakeStudentRepository();
    lessons = _FakeLessonRepository();
    practice = _FakePracticeRepository();
  });

  Future<void> pumpHost(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWith((ref) => 'teacher_a'),
          studentRepositoryProvider.overrideWithValue(students),
          lessonRepositoryProvider.overrideWithValue(lessons),
          practiceRepositoryProvider.overrideWithValue(practice),
          // Hive 는 실제 파일 I/O 라 testWidgets 의 fake async 안에서 완료되지
          // 않는다. 영속 자체는 starter_sample_storage_provider_test 가 검증하고,
          // 여기서는 배선만 본다.
          starterSampleStorageProvider.overrideWith(
            _InMemoryStarterSampleStorage.new,
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [StarterSampleCleanupBanner(), StarterSampleOffer()],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('offers the walkthrough and writes nothing until tapped', (
    tester,
  ) async {
    await pumpHost(tester);

    expect(find.text(AppStrings.starterSampleOfferLabel), findsOneWidget);
    expect(find.text(AppStrings.starterSampleCleanupLabel), findsNothing);
    expect(students.created, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('one tap creates the student, lesson note and practice log', (
    tester,
  ) async {
    await pumpHost(tester);

    await tester.tap(find.text(AppStrings.starterSampleOfferLabel));
    await tester.pumpAndSettle();

    expect(students.created, hasLength(1));
    expect(students.created.single.name, AppStrings.starterSampleStudentName);
    expect(lessons.statusWrites.single.$2, LessonStatus.completed);
    expect(lessons.feedbackWrites, hasLength(1));
    expect(practice.created, hasLength(1));
    // 제안은 한 번 실행되면 사라진다.
    expect(find.text(AppStrings.starterSampleOfferLabel), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cleanup surfaces only after a real student exists', (
    tester,
  ) async {
    await pumpHost(tester);

    await tester.tap(find.text(AppStrings.starterSampleOfferLabel));
    await tester.pumpAndSettle();
    expect(
      find.text(AppStrings.starterSampleCleanupLabel),
      findsNothing,
      reason: '예시만 있는 동안에는 정리 CTA 가 명단을 어지럽히지 않는다',
    );

    await students.createStudent(
      Student(
        id: 'seed',
        name: '김하늘',
        instrument: '피아노',
        createdAt: DateTime(2026, 8, 20),
      ),
    );
    final context = tester.element(find.byType(StarterSampleOffer));
    ProviderScope.containerOf(
      context,
      listen: false,
    ).invalidate(studentsNotifierProvider);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.starterSampleCleanupLabel), findsOneWidget);
  });

  testWidgets('cleanup deletes exactly the sample rows after confirmation', (
    tester,
  ) async {
    await pumpHost(tester);

    await tester.tap(find.text(AppStrings.starterSampleOfferLabel));
    await tester.pumpAndSettle();

    final sampleStudentId = students.created.single.id;
    await students.createStudent(
      Student(
        id: 'seed',
        name: '김하늘',
        instrument: '피아노',
        createdAt: DateTime(2026, 8, 20),
      ),
    );
    final context = tester.element(find.byType(StarterSampleOffer));
    ProviderScope.containerOf(
      context,
      listen: false,
    ).invalidate(studentsNotifierProvider);
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.starterSampleCleanupLabel));
    await tester.pumpAndSettle();
    // destructive 확인 다이얼로그를 통과해야 실제 삭제가 일어난다.
    expect(
      find.text(AppStrings.starterSampleCleanupConfirmTitle),
      findsOneWidget,
    );
    await tester.tap(find.text(AppStrings.starterSampleCleanupLabel).last);
    await tester.pumpAndSettle();

    expect(students.deleted, [sampleStudentId]);
    expect(lessons.deleted, [lessons.created.single.id]);
    expect(practice.deleted, [practice.created.single.id]);
    expect(
      students.remaining.map((student) => student.name),
      ['김하늘'],
      reason: '직접 등록한 학생은 정리에서 살아남아야 한다',
    );
    expect(find.text(AppStrings.starterSampleCleanupLabel), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('surfaces an error and leaves nothing behind when create fails', (
    tester,
  ) async {
    practice.failOnCreate = true;
    await pumpHost(tester);

    await tester.tap(find.text(AppStrings.starterSampleOfferLabel));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.starterSampleCreateFailed), findsWidgets);
    expect(students.remaining, isEmpty, reason: '실패 시 생성 역순으로 롤백된다');
    expect(
      find.text(AppStrings.starterSampleOfferLabel),
      findsOneWidget,
      reason: '실패했으면 다시 시도할 수 있어야 한다',
    );
    expect(tester.takeException(), isNull);
  });
}

class _InMemoryStarterSampleStorage extends StarterSampleStorage {
  StarterSampleData? _sample;

  @override
  Future<StarterSampleData?> build() async => _sample;

  @override
  Future<void> save(StarterSampleData sample) async {
    _sample = sample;
    state = AsyncData(sample);
  }

  @override
  Future<void> clear() async {
    _sample = null;
    state = const AsyncData(null);
  }
}

class _FakeStudentRepository implements StudentRepository {
  final List<Student> created = [];
  final List<Student> remaining = [];
  final List<String> deleted = [];
  int _sequence = 0;

  @override
  Future<List<Student>> getStudents() async => List.unmodifiable(remaining);

  @override
  Future<Student> createStudent(Student student) async {
    final stored = student.copyWith(id: 'student-${++_sequence}');
    if (student.name == AppStrings.starterSampleStudentName) {
      created.add(stored);
    }
    remaining.add(stored);
    return stored;
  }

  @override
  Future<void> deleteStudent(String id) async {
    deleted.add(id);
    remaining.removeWhere((student) => student.id == id);
  }

  @override
  Future<List<Student>> searchStudents(String query) async => getStudents();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLessonRepository implements LessonRepository {
  final List<Lesson> created = [];
  final List<(String, String?)> feedbackWrites = [];
  final List<(String, LessonStatus)> statusWrites = [];
  final List<String> deleted = [];
  int _sequence = 0;

  @override
  Future<List<Lesson>> getLessons() async => List.unmodifiable(created);

  @override
  Future<Lesson> createLesson(Lesson lesson, {String? overflowMode}) async {
    final stored = lesson.copyWith(id: 'lesson-${++_sequence}');
    created.add(stored);
    return stored;
  }

  @override
  Future<Lesson> updateLessonFeedback(
    Lesson lesson, {
    String? feedback,
    List<String>? keyPoints,
    String? practiceTips,
  }) async {
    feedbackWrites.add((lesson.id, feedback));
    return lesson.copyWith(
      feedback: feedback,
      keyPoints: keyPoints,
      practiceTips: practiceTips,
    );
  }

  @override
  Future<Lesson> updateLessonStatus(Lesson lesson, LessonStatus status) async {
    statusWrites.add((lesson.id, status));
    return lesson.copyWith(status: status);
  }

  @override
  Future<void> deleteLesson(String id) async => deleted.add(id);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePracticeRepository implements PracticeRepository {
  final List<PracticeLog> created = [];
  final List<String> deleted = [];
  bool failOnCreate = false;
  int _sequence = 0;

  @override
  Future<PracticeLog> createPracticeLog(PracticeLog log) async {
    if (failOnCreate) throw StateError('create failed');
    final stored = log.copyWith(id: 'log-${++_sequence}');
    created.add(stored);
    return stored;
  }

  @override
  Future<void> deletePracticeLog(String id) async => deleted.add(id);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
