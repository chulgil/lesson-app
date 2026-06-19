import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/students/domain/entities/student.dart';
import 'package:lessonaza/features/student_home/presentation/providers/student_home_profile_edit_provider.dart';
import 'package:lessonaza/features/student_home/presentation/screens/student_profile_edit_screen.dart';

/// #77 — 저장 버튼 없이 이탈 시 자동 저장. PopScope 뒤로가기 인터셉트가
/// 변경분을 updateStudent 로 저장하는지 Red-Green 으로 확인한다.
class _SpyActions extends StudentHomeProfileEditActions {
  _SpyActions(super.ref);
  static Student? captured;
  @override
  Future<Student> updateStudent(Student student) async {
    captured = student;
    return student;
  }
}

void main() {
  testWidgets('변경 후 뒤로가기 → updateStudent 자동 호출(자동 저장)', (tester) async {
    _SpyActions.captured = null;
    final student = Student(
      id: 'student_1',
      name: '김서연',
      instrument: '바이올린',
      createdAt: DateTime.utc(2026, 1, 1),
    );

    late BuildContext homeCtx;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studentHomeProfileEditStudentProvider.overrideWith(
            (ref) async => student,
          ),
          studentHomeProfileEditImagePathProvider(
            'student_1',
          ).overrideWith((ref) async => null),
          studentHomeProfileEditActionsProvider.overrideWith(
            (ref) => _SpyActions(ref),
          ),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (c) {
              homeCtx = c;
              return const Scaffold(body: SizedBox());
            },
          ),
        ),
      ),
    );

    // 상세를 push 해 pop 대상(home)이 있도록 한다.
    Navigator.of(homeCtx).push(
      MaterialPageRoute<void>(builder: (_) => const StudentProfileEditScreen()),
    );
    await tester.pumpAndSettle();

    // 이름 변경 → _hasChanges = true
    await tester.enterText(find.byType(TextField).first, '새이름');
    await tester.pump();

    // 실제 뒤로가기(maybePop) → PopScope(canPop:false) 인터셉트 → 자동 저장
    final navState = tester.state<NavigatorState>(find.byType(Navigator).first);
    await navState.maybePop();
    await tester.pumpAndSettle();

    expect(_SpyActions.captured, isNotNull);
    expect(_SpyActions.captured!.name, '새이름');
  });
}
