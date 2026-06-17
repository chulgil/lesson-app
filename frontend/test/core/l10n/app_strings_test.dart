import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';

/// AppStrings 테스트 — 상수 존재성 + 금지 용어 미포함 검증.
///
/// 다국어 전환 시에도 깨지지 않도록 하드코딩 문자열 비교 대신
/// 구조적 검증(비어있지 않음, 금지 용어 미포함)을 사용한다.
void main() {
  group('AppStrings - Core Actions (존재성)', () {
    test('lessonRequest is not empty', () {
      expect(AppStrings.lessonRequest, isNotEmpty);
    });

    test('accept is not empty', () {
      expect(AppStrings.accept, isNotEmpty);
    });

    test('unavailable is not empty', () {
      expect(AppStrings.unavailable, isNotEmpty);
    });

    test('counterPropose is not empty', () {
      expect(AppStrings.counterPropose, isNotEmpty);
    });

    test('paymentConfirm is not empty', () {
      expect(AppStrings.paymentConfirm, isNotEmpty);
    });

    test('subscription is not empty', () {
      expect(AppStrings.subscription, isNotEmpty);
    });
  });

  group('AppStrings - Deprecated Terms (금지 용어 미포함)', () {
    // 이전에 사용했지만 폐기된 용어가 상수에 남아있지 않은지 검증.
    // 다국어 전환과 무관하게 항상 유효한 테스트.

    final deprecatedTerms = ['신청', '승인', '거절'];

    test('lessonRequest does not contain deprecated terms', () {
      for (final term in deprecatedTerms) {
        expect(
          AppStrings.lessonRequest,
          isNot(contains(term)),
          reason: 'lessonRequest should not contain "$term"',
        );
      }
    });

    test('accept does not contain deprecated terms', () {
      for (final term in ['승인', '확인', '거절']) {
        expect(
          AppStrings.accept,
          isNot(contains(term)),
          reason: 'accept should not contain "$term"',
        );
      }
    });

    test('unavailable does not contain deprecated terms', () {
      for (final term in ['거절', '거부', '불가']) {
        expect(
          AppStrings.unavailable,
          isNot(contains(term)),
          reason: 'unavailable should not contain "$term"',
        );
      }
    });

    test('requestAccepted does not contain deprecated terms', () {
      expect(AppStrings.requestAccepted, isNot(contains('승인')));
      expect(AppStrings.requestAccepted, isNot(contains('거절')));
    });

    test('requestUnavailable does not contain deprecated terms', () {
      expect(AppStrings.requestUnavailable, isNot(contains('거절')));
      expect(AppStrings.requestUnavailable, isNot(contains('거부')));
    });

    test('acceptError does not contain deprecated terms', () {
      expect(AppStrings.acceptError, isNot(contains('승인')));
    });
  });

  group('AppStrings - Snackbar Messages (존재성)', () {
    test('requestAccepted is not empty', () {
      expect(AppStrings.requestAccepted, isNotEmpty);
    });

    test('requestUnavailable is not empty', () {
      expect(AppStrings.requestUnavailable, isNotEmpty);
    });

    test('trialComplete is not empty', () {
      expect(AppStrings.trialComplete, isNotEmpty);
    });

    test('trialPaymentRequested is not empty', () {
      expect(AppStrings.trialPaymentRequested, isNotEmpty);
    });

    test('acceptError is not empty', () {
      expect(AppStrings.acceptError, isNotEmpty);
    });

    test('counterProposeError is not empty', () {
      expect(AppStrings.counterProposeError, isNotEmpty);
    });

    test('requestLoadError is not empty', () {
      expect(AppStrings.requestLoadError, isNotEmpty);
    });
  });

  group('AppStrings - Screen Titles (존재성)', () {
    test('lessonRequestTitle is not empty', () {
      expect(AppStrings.lessonRequestTitle, isNotEmpty);
    });

    test('lessonRequestFormTitle is not empty', () {
      expect(AppStrings.lessonRequestFormTitle, isNotEmpty);
    });

    test('requestCompleteTitle is not empty', () {
      expect(AppStrings.requestCompleteTitle, isNotEmpty);
    });

    test('requestCompleteHeader is not empty', () {
      expect(AppStrings.requestCompleteHeader, isNotEmpty);
    });
  });

  group('AppStrings - Button Labels (존재성)', () {
    test('submitRequest is not empty', () {
      expect(AppStrings.submitRequest, isNotEmpty);
    });

    test('submittingRequest is not empty', () {
      expect(AppStrings.submittingRequest, isNotEmpty);
    });

    test('messageOnly is not empty', () {
      expect(AppStrings.messageOnly, isNotEmpty);
    });
  });

  group('AppStrings - Dynamic Messages', () {
    test('lessonRequestPending formats count correctly', () {
      final result = AppStrings.lessonRequestPending(3);
      expect(result, contains('3'));
      expect(result, isNotEmpty);
    });

    test('paymentConfirmPending formats count correctly', () {
      final result = AppStrings.paymentConfirmPending(5);
      expect(result, contains('5'));
      expect(result, isNotEmpty);
    });

    test('urgentAlertOutstandingFormat uses 미수금 wording + exact amount', () {
      // #807: 후불 미수금 용어 통일 + 금액 정확 표기(반올림 금지).
      final rounded = AppStrings.urgentAlertOutstandingFormat(50000, 3);
      expect(rounded, contains('미수금'));
      expect(rounded, isNot(contains('입금대기')));
      expect(rounded, isNot(contains('결제')));
      expect(rounded, contains('5만원'));
      expect(rounded, contains('(3명)'));

      // 비-만단위 금액은 절사/반올림 없이 정확히 표기 (55000 != "6만원").
      final exact = AppStrings.urgentAlertOutstandingFormat(55000, 2);
      expect(exact, contains('5만 5000원'));
      expect(exact, isNot(contains('6만원')));

      // 만원 미만은 원 단위 그대로.
      final small = AppStrings.urgentAlertOutstandingFormat(5000, 1);
      expect(small, contains('5000원'));
    });
  });

  group('AppStrings - Cross-reference Consistency', () {
    test(
      'lessonRequestTitle and lessonRequestFormTitle use same base term',
      () {
        // Both should reference the same core concept
        expect(
          AppStrings.lessonRequestTitle,
          contains(AppStrings.lessonRequest),
        );
        expect(
          AppStrings.lessonRequestFormTitle,
          contains(AppStrings.lessonRequest),
        );
      },
    );

    test('requestCompleteTitle references lessonRequest term', () {
      expect(
        AppStrings.requestCompleteTitle,
        contains(AppStrings.lessonRequest),
      );
    });

    test('requestCompleteHeader references lessonRequest term', () {
      expect(
        AppStrings.requestCompleteHeader,
        contains(AppStrings.lessonRequest),
      );
    });
  });
}
