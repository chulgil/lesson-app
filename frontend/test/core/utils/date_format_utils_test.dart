import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/utils/date_format_utils.dart';

void main() {
  group('formatRelativeDay (#646 공유 헬퍼)', () {
    DateTime ago(int days) => DateTime.now().subtract(Duration(days: days));

    test('오늘 / 어제 경계', () {
      expect(formatRelativeDay(ago(0)), '오늘');
      expect(formatRelativeDay(ago(1)), '어제');
    });

    test('일 / 주 / 개월 / 년 단위', () {
      expect(formatRelativeDay(ago(3)), '3일 전');
      expect(formatRelativeDay(ago(7)), '1주 전');
      expect(formatRelativeDay(ago(20)), '2주 전');
      expect(formatRelativeDay(ago(30)), '1개월 전');
      expect(formatRelativeDay(ago(90)), '3개월 전');
      expect(formatRelativeDay(ago(365)), '1년 전');
      expect(formatRelativeDay(ago(800)), '2년 전');
    });
  });
}
