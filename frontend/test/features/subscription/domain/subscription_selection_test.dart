import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription.dart';
import 'package:lessonaza/features/subscription/domain/subscription_selection.dart';

Subscription _sub({
  required String id,
  DateTime? endDate,
  int? totalLessons,
  int usedLessons = 0,
  String? instrument,
  SubscriptionType type = SubscriptionType.package,
}) {
  return Subscription(
    id: id,
    studentId: 'st1',
    membershipId: 'm_$id',
    type: type,
    totalLessons: totalLessons,
    usedLessons: usedLessons,
    endDate: endDate,
    amount: 100000,
    status: SubscriptionStatus.active,
    createdAt: DateTime(2026, 1, 1),
    instrument: instrument,
  );
}

void main() {
  group('resolveLessonInstrument', () {
    test('수강권이 있으면 수강권(멤버십) 악기를 상속한다', () {
      final result = resolveLessonInstrument(
        subscription: _sub(id: 's1', instrument: '피아노'),
        studentInstrument: '바이올린',
      );
      expect(result, '피아노');
    });

    test('수강권이 없으면(0개) 학생 악기를 사용한다', () {
      final result = resolveLessonInstrument(
        subscription: null,
        studentInstrument: '바이올린',
      );
      expect(result, '바이올린');
    });

    test('수강권 악기가 null이면 학생 악기로 폴백한다', () {
      final result = resolveLessonInstrument(
        subscription: _sub(id: 's1', instrument: null),
        studentInstrument: '바이올린',
      );
      expect(result, '바이올린');
    });

    test('수강권 악기가 공백이면 학생 악기로 폴백한다', () {
      final result = resolveLessonInstrument(
        subscription: _sub(id: 's1', instrument: '   '),
        studentInstrument: '바이올린',
      );
      expect(result, '바이올린');
    });
  });

  group('sortSubscriptionsForPicker', () {
    test('만료일이 빠른 수강권을 앞에 둔다 (만료 임박 우선)', () {
      final later = _sub(id: 'later', endDate: DateTime(2026, 12, 31));
      final sooner = _sub(id: 'sooner', endDate: DateTime(2026, 6, 30));
      final result = sortSubscriptionsForPicker([later, sooner]);
      expect(result.map((s) => s.id).toList(), ['sooner', 'later']);
    });

    test('만료일이 없는 수강권은 만료일 있는 수강권보다 뒤에 둔다', () {
      final noEnd = _sub(id: 'noEnd', totalLessons: 8, usedLessons: 0);
      final withEnd = _sub(id: 'withEnd', endDate: DateTime(2026, 6, 30));
      final result = sortSubscriptionsForPicker([noEnd, withEnd]);
      expect(result.first.id, 'withEnd');
    });

    test('만료일이 같으면 잔여 횟수가 적은 수강권을 앞에 둔다', () {
      final many = _sub(
        id: 'many',
        endDate: DateTime(2026, 6, 30),
        totalLessons: 10,
        usedLessons: 0,
      ); // remaining 10
      final few = _sub(
        id: 'few',
        endDate: DateTime(2026, 6, 30),
        totalLessons: 10,
        usedLessons: 8,
      ); // remaining 2
      final result = sortSubscriptionsForPicker([many, few]);
      expect(result.map((s) => s.id).toList(), ['few', 'many']);
    });

    test('원본 리스트를 변경하지 않는다 (immutability)', () {
      final a = _sub(id: 'a', endDate: DateTime(2026, 12, 31));
      final b = _sub(id: 'b', endDate: DateTime(2026, 6, 30));
      final input = [a, b];
      sortSubscriptionsForPicker(input);
      expect(input.map((s) => s.id).toList(), ['a', 'b']);
    });

    test('빈 리스트는 빈 리스트를 반환한다', () {
      expect(sortSubscriptionsForPicker([]), isEmpty);
    });
  });
}
