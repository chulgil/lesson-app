// #846 수강권 발급 무인자 진입(준비 체크리스트 Q7 등) dead-end 방지.
//
// studentId 없이 IssueSubscriptionScreen 진입 시 NoMembershipState 막다른 화면
// 대신 연결 학생 선택 UI 가 떠야 한다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/auth/auth_facade.dart'
    show currentUserIdProvider;
import 'package:lessonaza/features/students/domain/entities/grouped_students.dart';
import 'package:lessonaza/features/students/domain/entities/student.dart';
import 'package:lessonaza/features/students/domain/entities/student_with_membership.dart';
import 'package:lessonaza/features/students/students_facade.dart'
    show groupedStudentsProvider;
import 'package:lessonaza/features/subscription/presentation/screens/issue_subscription_screen.dart';

const _teacherId = 't1';

void main() {
  testWidgets('#846 빈 studentId 진입 -> 학생 선택 UI + 연결 학생 렌더', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue(_teacherId),
          groupedStudentsProvider(_teacherId).overrideWith(
            (ref) async => [
              StudentGroup(
                students: [
                  StudentWithMembership(
                    student: Student(
                      id: 's1',
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
        child: const MaterialApp(home: IssueSubscriptionScreen(studentIds: [])),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.issueSelectStudentTitle), findsOneWidget);
    expect(find.text('홍길동'), findsOneWidget);
  });
}
