import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';

void main() {
  group('AppStrings - Lesson Request Terminology', () {
    test('lesson request uses "레슨 요청" (not "레슨 신청")', () {
      expect(AppStrings.lessonRequest, '레슨 요청');
      expect(AppStrings.lessonRequest, isNot(contains('신청')));
    });

    test('accept action uses "수락" (not "승인" or "확인")', () {
      expect(AppStrings.accept, '수락');
    });

    test('unavailable uses "레슨 불가" (not "거절")', () {
      expect(AppStrings.unavailable, '레슨 불가');
      expect(AppStrings.unavailable, isNot(contains('거절')));
    });

    test('counter propose uses "다른 시간 제안"', () {
      expect(AppStrings.counterPropose, '다른 시간 제안');
    });
  });

  group('AppStrings - Payment & Subscription', () {
    test('payment confirm uses "입금 확인"', () {
      expect(AppStrings.paymentConfirm, '입금 확인');
    });

    test('subscription uses "수강권"', () {
      expect(AppStrings.subscription, '수강권');
    });
  });

  group('AppStrings - Snackbar Messages', () {
    test('accept success message uses "수락"', () {
      expect(AppStrings.requestAccepted, contains('수락'));
      expect(AppStrings.requestAccepted, isNot(contains('승인')));
    });

    test('unavailable message uses "레슨 불가"', () {
      expect(AppStrings.requestUnavailable, contains('레슨 불가'));
      expect(AppStrings.requestUnavailable, isNot(contains('거절')));
    });

    test('trial complete message exists', () {
      expect(AppStrings.trialComplete, isNotEmpty);
    });

    test('accept error message uses "수락"', () {
      expect(AppStrings.acceptError, contains('수락'));
      expect(AppStrings.acceptError, isNot(contains('승인')));
    });
  });

  group('AppStrings - Screen Titles', () {
    test('lesson request title uses "레슨 요청"', () {
      expect(AppStrings.lessonRequestTitle, contains('레슨 요청'));
    });

    test('lesson request form title uses "레슨 요청"', () {
      expect(AppStrings.lessonRequestFormTitle, '레슨 요청');
    });

    test('request completion title uses "레슨 요청"', () {
      expect(AppStrings.requestCompleteTitle, contains('레슨 요청'));
    });
  });
}
