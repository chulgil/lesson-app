import '../../../../core/l10n/app_strings.dart';
import '../../domain/entities/schedule_confirmation_card.dart';

extension ScheduleCardTypeVisualX on ScheduleCardType {
  String get label {
    switch (this) {
      case ScheduleCardType.afterTrial:
        return AppStrings.scheduleCardTypeAfterTrial;
      case ScheduleCardType.reEnrollment:
        return AppStrings.scheduleCardTypeReEnrollment;
      case ScheduleCardType.additionalInstrument:
        return AppStrings.scheduleCardTypeAdditionalInstrument;
    }
  }

  String get suggestionText {
    switch (this) {
      case ScheduleCardType.afterTrial:
        return AppStrings.scheduleCardSuggestionAfterTrial;
      case ScheduleCardType.reEnrollment:
        return AppStrings.scheduleCardSuggestionReEnrollment;
      case ScheduleCardType.additionalInstrument:
        return AppStrings.scheduleCardSuggestionAdditionalInstrument;
    }
  }
}

extension ScheduleCardStatusVisualX on ScheduleCardStatus {
  String get label {
    switch (this) {
      case ScheduleCardStatus.pending:
        return AppStrings.scheduleCardStatusPending;
      case ScheduleCardStatus.confirmed:
        return AppStrings.scheduleCardStatusConfirmed;
      case ScheduleCardStatus.changedTime:
        return AppStrings.scheduleCardStatusChangedTime;
      case ScheduleCardStatus.dismissed:
        return AppStrings.scheduleCardStatusDismissed;
    }
  }
}
