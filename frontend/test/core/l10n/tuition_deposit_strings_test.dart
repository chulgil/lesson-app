import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/subscription/data/repositories/mock_subscription_repository.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription.dart';

void main() {
  test('subscription copy describes deposit status instead of in-app payment',
      () {
    expect(AppStrings.chapterSubscription, '수강권 & 입금');
    expect(AppStrings.methodPrepaidTitle, '입금 확인 후 발급 (선불)');
    expect(AppStrings.methodPrepaidDesc, contains('입금 안내'));
    expect(AppStrings.methodPostpaidDesc, contains('입금 확인은 나중에'));
    expect(AppStrings.methodFreeDesc, '입금 없이 수강권을 바로 발급합니다');
    expect(AppStrings.actionSendPaymentGuide, '입금 안내 보내기');
    expect(AppStrings.paymentGuideTitle, '입금 안내 보내기');

    expect(AppStrings.issueFormPaymentSectionTitle, '입금 확인 방식');
    expect(AppStrings.issueFormPaymentPostpaidNotice, contains('입금 확인 대기'));
    expect(AppStrings.issueFormSummaryFinalAmountLabel, '입금 예정 금액');
    expect(AppStrings.issueFormSummaryPaymentLabel, '입금 상태');
    expect(AppStrings.issueFormSummaryUnpaidLabel, '입금 확인 대기 (후불)');
  });

  test('mock subscription data does not present card as a current method',
      () async {
    final repository = MockSubscriptionRepository();
    final subscriptions = await repository.getByTeacherId('teacher_1');

    expect(
      subscriptions.map((subscription) => subscription.paymentMethod),
      isNot(contains(SubscriptionPaymentMethod.card)),
    );
  });
}
