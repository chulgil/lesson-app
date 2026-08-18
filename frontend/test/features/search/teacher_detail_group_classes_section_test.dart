import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_profile.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_search.dart';
import 'package:lessonaza/features/profile/profile_facade.dart';
import 'package:lessonaza/features/schedule/data/repositories/mock_group_class_repository.dart';
import 'package:lessonaza/features/schedule/presentation/providers/group_class_providers.dart';
import 'package:lessonaza/features/search/presentation/screens/teacher_detail_screen.dart';
import 'package:lessonaza/features/search/search_facade.dart';
import 'package:lessonaza/features/students/students_facade.dart';
import 'package:lessonaza/features/subscription/subscription_facade.dart';

/// J12 P1-2 — 교사 상세의 "개설 클래스" 섹션 (D3: 학생 탐색 표면).
///
/// 계약:
///   ① 개설 클래스가 있으면 섹션 제목 + 반/특강 배지 + 클래스명이 렌더된다
///   ② 개설 클래스가 없으면 섹션 자체가 숨는다 (공개 프로필 빈 상태 노이즈 금지)
void main() {
  const teacherId = 'teacher_1';
  const studentId = 'student_1';

  final profile = TeacherPublicProfile(
    id: teacherId,
    name: '김선생',
    instruments: const ['바이올린'],
    introduction: '소개',
    completionLevel: ProfileCompletionLevel.standard,
  );

  final student = Student(
    id: studentId,
    name: '박학생',
    instrument: '바이올린',
    createdAt: DateTime(2026, 1, 1),
  );

  Future<void> pumpDetail(
    WidgetTester tester, {
    required MockGroupClassRepository repository,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          teacherPublicProfileProvider(
            teacherId,
          ).overrideWith((ref) async => profile),
          myDisconnectedConnectionsProvider.overrideWith((ref) async => []),
          currentStudentProvider.overrideWith((ref) async => student),
          activeSubscriptionBetweenProvider(
            studentId: studentId,
            teacherId: teacherId,
          ).overrideWith((ref) async => null),
          groupClassRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          home: TeacherDetailScreen(teacherId: teacherId),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('① 개설 클래스가 있으면 섹션에 반·특강이 나열된다', (tester) async {
    // 시드 = 정규 반 1 + 특강 1, 둘 다 teacher_1 소유.
    await pumpDetail(tester, repository: MockGroupClassRepository());

    expect(
      find.text(AppStrings.groupClassesTeacherDetailTitle),
      findsOneWidget,
    );
    expect(find.text('목요일 앙상블반'), findsOneWidget);
    expect(find.text('원데이 보잉 특강'), findsOneWidget);
    // 반 / 특강 을 배지로 구분한다 (dropIn 라벨은 '특강').
    expect(find.text(AppStrings.groupClassRegular), findsOneWidget);
    expect(find.text(AppStrings.groupClassDropin), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('② 개설 클래스가 없으면 섹션이 숨는다', (tester) async {
    await pumpDetail(tester, repository: MockGroupClassRepository(seed: false));

    expect(find.text(AppStrings.groupClassesTeacherDetailTitle), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
