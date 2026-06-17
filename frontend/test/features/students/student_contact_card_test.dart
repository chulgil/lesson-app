import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/students/domain/entities/student.dart';
import 'package:lessonaza/features/students/presentation/widgets/student_detail/student_contact_card.dart';

void main() {
  Student make({
    String? phone,
    String? parentName,
    String? parentPhone,
    String? address,
    String? notes,
  }) => Student(
    id: 's1',
    name: '김민준',
    instrument: 'violin',
    createdAt: DateTime(2026, 6, 11),
    phone: phone,
    parentName: parentName,
    parentPhone: parentPhone,
    address: address,
    notes: notes,
  );

  Future<void> pump(
    WidgetTester tester,
    Student student, {
    double width = 375,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: width,
            child: StudentContactCard(student: student),
          ),
        ),
      ),
    );
  }

  testWidgets('연락처/메모가 모두 있으면 라벨·값·메모를 렌더 (예외 없음)', (tester) async {
    await pump(
      tester,
      make(
        phone: '010-1111-2222',
        parentName: '김부모',
        parentPhone: '010-3333-4444',
        address: '서울시 강남구',
        notes: '체험 후 등록. 바이올린 2년차.',
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.studentContactSectionTitle), findsOneWidget);
    expect(find.text('010-1111-2222'), findsOneWidget);
    expect(find.text('010-3333-4444'), findsOneWidget);
    expect(find.text('서울시 강남구'), findsOneWidget);
    expect(find.text('체험 후 등록. 바이올린 2년차.'), findsOneWidget);
    expect(find.text(AppStrings.studentContactMemoLabel), findsOneWidget);
    // 전화/문자 액션 아이콘 (학생+학부모 = 전화 2 + 문자 2)
    expect(find.byIcon(Icons.call), findsNWidgets(2));
    expect(find.byIcon(Icons.sms_outlined), findsNWidgets(2));
  });

  testWidgets('연락처/메모가 전혀 없으면 빈 카드 대신 아무것도 렌더하지 않음', (tester) async {
    await pump(tester, make());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.studentContactSectionTitle), findsNothing);
    expect(find.byType(SizedBox), findsWidgets); // SizedBox.shrink
  });

  testWidgets('narrow(320) 좁은 폭에서 오버플로우 없이 렌더', (tester) async {
    await pump(
      tester,
      make(
        phone: '010-1111-2222',
        parentName: '김부모',
        parentPhone: '010-3333-4444',
        address: '서울특별시 강남구 테헤란로 123 4층 401호',
        notes: '메모',
      ),
      width: 320,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
