import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/lessons/domain/entities/lesson.dart';
import 'package:lessonaza/features/student_home/presentation/widgets/student_lesson_card.dart';

/// 회색 화면(#64) 회귀 게이트.
///
/// 학생 홈은 IndexedStack 으로 4탭을 즉시 build 하므로, 레슨 탭의 카드 하나가
/// 비정상 startTime 으로 throw 하면 화면 전체가 릴리스 회색 ErrorWidget 으로 덮인다.
/// mock 은 항상 "HH:mm" 라 기존 테스트가 false-green 이었다. 이 게이트는 원격형
/// 비정상 startTime 을 직접 주입해 build 가 throw 하지 않음을 단언한다.
Lesson _lesson({required String startTime}) => Lesson(
  id: 'l1',
  studentId: 's1',
  studentName: '학생',
  instrument: '바이올린',
  date: DateTime(2026, 6, 19),
  startTime: startTime,
  createdAt: DateTime.utc(2026, 6, 1),
);

void main() {
  group('Lesson build-time getters — 비정상 startTime 에도 throw 금지', () {
    for (final bad in const ['', '17', '17:30:00', 'ab:cd', '25:99']) {
      test('startTime="$bad" → endDateTime/displayStatus 안전', () {
        final lesson = _lesson(startTime: bad);
        expect(() => lesson.endDateTime, returnsNormally);
        expect(() => lesson.displayStatus, returnsNormally);
        expect(() => lesson.isUnconfirmed, returnsNormally);
      });
    }
  });

  group('StudentLessonCard — 비정상 startTime 에도 렌더 크래시 금지', () {
    // 회색 화면의 원인은 build 중 파싱 예외(FormatException/RangeError)다. 테스트
    // 폰트 메트릭으로 생기는 사소한 RenderFlex overflow(프로덕션 폰트에선 없음)는
    // 본 게이트의 대상이 아니므로 파싱 예외 클래스만 단언한다.
    for (final bad in const ['', '17', '17:30:00']) {
      testWidgets('startTime="$bad" 카드가 파싱 크래시 없이 build 된다', (tester) async {
        await tester.binding.setSurfaceSize(const Size(375, 667));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: StudentLessonCard(lesson: _lesson(startTime: bad)),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));

        // 카드가 실제로 build 됨 = startTime 파싱이 throw 하지 않았다는 증거.
        expect(find.byType(StudentLessonCard), findsOneWidget);
        final ex = tester.takeException();
        expect(ex, isNot(isA<FormatException>()));
        expect(ex, isNot(isA<RangeError>()));
        expect(ex, isNot(isA<ArgumentError>()));
      });
    }
  });
}
