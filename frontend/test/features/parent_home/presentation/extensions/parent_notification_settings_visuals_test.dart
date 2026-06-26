import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/parent_home/domain/entities/parent_notification_settings.dart';
import 'package:lessonaza/features/parent_home/presentation/extensions/parent_home_domain_visuals.dart';

void main() {
  group('NotificationCategoryVisuals', () {
    test('maps category labels and icons for presentation', () {
      expect(NotificationCategory.payment.label, '입금 상태');
      expect(NotificationCategory.lesson.label, '레슨');
      expect(NotificationCategory.assignment.label, '과제/숙제');
      expect(NotificationCategory.practice.label, '연습');
      expect(NotificationCategory.communication.label, '소통');
      expect(NotificationCategory.report.label, '리포트');

      expect(NotificationCategory.payment.icon, Icons.payments);
      expect(NotificationCategory.lesson.icon, Icons.calendar_today);
    });
  });

  group('NotificationItemVisuals', () {
    test('maps item labels and suffixes for presentation', () {
      const requiredItem = NotificationItem(
        NotificationSettingType.paymentRequest,
        true,
        isRequired: true,
      );
      const recommendedItem = NotificationItem(
        NotificationSettingType.lessonChange,
        true,
        isRecommended: true,
      );

      expect(requiredItem.label, '입금 안내');
      expect(requiredItem.suffix, '(필수)');
      expect(recommendedItem.label, '레슨 일정 변경');
      expect(recommendedItem.suffix, '(권장)');
    });
  });
}
