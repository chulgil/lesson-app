import '../../../../core/l10n/app_strings.dart';
import '../../domain/entities/subscription_usage.dart';

extension UsageTypeVisualX on UsageType {
  String get label {
    switch (this) {
      case UsageType.normal:
        return AppStrings.usageTypeNormal;
      case UsageType.lateCancellation:
        return AppStrings.usageTypeLateCancellation;
      case UsageType.studentAbsent:
        return AppStrings.usageTypeStudentAbsent;
      case UsageType.rescheduled:
        return AppStrings.usageTypeRescheduled;
    }
  }

  String? get defaultNote {
    switch (this) {
      case UsageType.lateCancellation:
        return AppStrings.usageNoteLateCancellation;
      case UsageType.studentAbsent:
        // #D4 — 라벨('학생 결석')이 아니라 실제 설명 노트를 프리필한다
        // (lateCancellation 과 동일하게 usageNote* 사용).
        return AppStrings.usageNoteStudentAbsent;
      case UsageType.normal:
      case UsageType.rescheduled:
        return null;
    }
  }
}
