import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/subscription/data/repositories/mock_subscription_repository.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription.dart';

void main() {
  test(
    'subscription copy describes deposit status instead of in-app payment',
    () {
      expect(AppStrings.chapterSubscription, '수강권 & 입금');
      expect(AppStrings.methodPrepaidTitle, '입금 확인 후 발급 (선불)');
      expect(AppStrings.methodPrepaidDesc, contains('입금 안내'));
      expect(AppStrings.methodPostpaidDesc, contains('입금 확인은 나중에'));
      expect(AppStrings.methodFreeDesc, '입금 없이 수강권을 바로 발급합니다');
      expect(AppStrings.actionSendPaymentGuide, '입금 안내 보내기');
      expect(AppStrings.paymentGuideTitle, '입금 안내 보내기');

      expect(AppStrings.issueFormPaymentSectionTitle, '입금 확인 방식');
      expect(AppStrings.issueFormPaymentPostpaidNotice, contains('미수금'));
      expect(AppStrings.issueFormSummaryFinalAmountLabel, '입금 예정 금액');
      expect(AppStrings.issueFormSummaryPaymentLabel, '입금 상태');
      expect(AppStrings.issueFormSummaryUnpaidLabel, '미수금');
      expect(AppStrings.paymentStatusUnpaid, '미수금');
      expect(AppStrings.paymentStatusNeedsConfirmation, '입금 확인 필요');
      expect(AppStrings.proposalWaitingTitle, '입금 확인 중');
      expect(AppStrings.proposalPaymentStatusPending, '입금 확인 필요');
      expect(AppStrings.proposalConfirmEmptyTitle, '입금 확인이 필요한 제안이 없습니다');
    },
  );

  test(
    'mock subscription data does not present card as a current method',
    () async {
      final repository = MockSubscriptionRepository();
      final subscriptions = await repository.getByTeacherId('teacher_1');

      expect(
        subscriptions.map((subscription) => subscription.paymentMethod),
        isNot(contains(SubscriptionPaymentMethod.card)),
      );
    },
  );

  test(
    'active student and profile surfaces use 미수금 (postpaid receivable) wording',
    () {
      // #807: 후불 결제는 '미수금'으로 통일.
      // - 이전 '입금대기(후불)' 토큰 잔재 금지.
      // - 선불 전용 '입금 확인 대기' 가 후불 면에 새지 않도록 분리 유지.
      const deprecatedPostpaidToken =
          '입금'
          '대기';
      final checkedFiles = [
        'lib/features/students/presentation/screens/students_tab.dart',
        'lib/features/students/presentation/widgets/student_subscription_badge.dart',
        'lib/features/profile/presentation/screens/profile_tab.dart',
        'lib/features/students/data/repositories/mock_student_repository.dart',
        'lib/features/subscription/data/repositories/mock_subscription_repository.dart',
      ];

      for (final relativePath in checkedFiles) {
        final contents = File(relativePath).readAsStringSync();
        expect(contents, contains('미수금'), reason: relativePath);
        expect(
          contents,
          isNot(contains(deprecatedPostpaidToken)),
          reason: relativePath,
        );
        expect(contents, isNot(contains('입금 확인 대기')), reason: relativePath);
      }
    },
  );
}
