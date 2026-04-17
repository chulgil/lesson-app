import 'lesson_policy.dart';

enum RefundRule { fullRefund, partialRefund, halfwayRefund, noRefund }

class RefundResult {
  final int amount;
  final RefundRule rule;

  const RefundResult({required this.amount, required this.rule});
}

class RefundCalculator {
  static RefundResult calculate({
    required int totalPrice,
    required int totalSessions,
    required int usedSessions,
    required LessonPolicy policy,
    required int daysUntilFirstLesson,
  }) {
    if (totalSessions <= 0) {
      return RefundResult(amount: totalPrice, rule: RefundRule.fullRefund);
    }

    if (usedSessions >= totalSessions) {
      return const RefundResult(amount: 0, rule: RefundRule.noRefund);
    }

    if (usedSessions == 0 && daysUntilFirstLesson >= policy.fullRefundDays) {
      return RefundResult(amount: totalPrice, rule: RefundRule.fullRefund);
    }

    final remaining = totalSessions - usedSessions;
    final perSession = totalPrice / totalSessions;
    final progress = usedSessions / totalSessions;

    if (progress > 0.5) {
      final amount =
          (remaining * perSession * policy.halfwayRefundRatio).round();
      return RefundResult(amount: amount, rule: RefundRule.halfwayRefund);
    }

    final amount = (remaining * perSession * policy.partialRefundRatio).round();
    return RefundResult(amount: amount, rule: RefundRule.partialRefund);
  }
}
