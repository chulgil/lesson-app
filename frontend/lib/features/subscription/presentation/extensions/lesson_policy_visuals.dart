import '../../../../core/l10n/app_strings.dart';
import '../../domain/entities/lesson_policy.dart';

extension LessonPolicyVisualX on LessonPolicy {
  /// 취소 정책 요약 텍스트
  String get cancelPolicySummary {
    if (allowSameDayCancel) {
      return AppStrings.policyCancelSameDay;
    }
    return AppStrings.policyCancelMinHours(minCancelHours);
  }

  /// 변경 정책 요약 텍스트
  String get changePolicySummary {
    if (maxChangesPerMonth == 0) {
      return AppStrings.policyChangeNone;
    }
    if (maxChangesPerMonth >= 99) {
      return AppStrings.policyChangeUnlimited;
    }
    return AppStrings.policyChangeMonthly(maxChangesPerMonth);
  }

  /// 노쇼 정책 요약 텍스트
  String get noShowPolicySummary {
    if (deductLessonOnNoShow) {
      return AppStrings.policyNoShowDeduct;
    }
    return AppStrings.policyNoShowKeep;
  }

  /// 이월 정책 요약 텍스트
  String get carryoverPolicySummary {
    if (!allowCarryover) {
      return AppStrings.policyCarryoverNone;
    }
    return AppStrings.policyCarryoverMax(
      maxCarryoverLessons,
      carryoverPeriodMonths,
    );
  }
}
