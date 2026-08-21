// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Lessonaza';

  @override
  String get navHome => 'Home';

  @override
  String get navLessons => 'Lessons';

  @override
  String get navPractice => 'Practice';

  @override
  String get navProfile => 'Profile';

  @override
  String get navAssignments => 'Assignments';

  @override
  String get navPayments => 'Payments';

  @override
  String get academyClosureLoadError =>
      'Couldn\'t load the closure information.';

  @override
  String get notificationAnnouncementLoadError =>
      'Couldn\'t load the announcement.';

  @override
  String get notificationInquiryLoadError => 'Couldn\'t load the inquiry.';

  @override
  String get coachMarkSkip => 'Skip';

  @override
  String get selectorDirectInput => 'Enter manually';

  @override
  String get selectorCountHint => 'Count';

  @override
  String get selectorDiscountPercentHint => 'Discount %';

  @override
  String get selectorCountInputHint => 'Enter a count';

  @override
  String get selectorDurationInputHint => 'Enter minutes';

  @override
  String get tunerShowComboSubtitle =>
      'Show a combo streak on consecutive perfects';

  @override
  String get tunerVibrationSubtitle => 'Vibrate on perfect tuning';

  @override
  String followCancelConfirmBody(String name) {
    return 'Unfollow $name?';
  }

  @override
  String instrumentDeletedMessage(String name) {
    return '$name has been removed';
  }

  @override
  String paymentConfirmBody(String amount) {
    return 'Confirm the deposit of $amount?';
  }

  @override
  String repertoireDeleteConfirmBody(String title) {
    return 'Delete $title?';
  }

  @override
  String lessonApprovedMessage(String studentName) {
    return '$studentName\'s lesson has been approved';
  }

  @override
  String studentInfoUpdatedMessage(String name) {
    return '$name\'s student info has been updated';
  }

  @override
  String parentInviteIntroBody(String studentName) {
    return 'Invite $studentName\'s parent';
  }

  @override
  String bulkMessageSentMessage(int count) {
    return 'Message sent to $count recipients';
  }

  @override
  String rescheduleAddCountButton(int count) {
    return 'Add $count sessions';
  }

  @override
  String editSectionNameHelper(String preview) {
    return 'Shown as \"$preview\" when left blank';
  }

  @override
  String hoursOptionLabel(int hours) {
    return '${hours}h';
  }

  @override
  String backupWrongExtensionMessage(String extension) {
    return 'Not a valid backup file.\nPlease choose a $extension file.';
  }

  @override
  String get backupPathUnavailableMessage => 'Couldn\'t access the file path.';

  @override
  String get selectorValidityDaysInputHint => 'Enter validity (days)';

  @override
  String get selectorValidityMonthsInputHint => 'Enter months';

  @override
  String get practiceMeasureRangeGuide =>
      'Select the measure range to practice';

  @override
  String get practiceLineRangeGuide =>
      'Select the line range to practice (lines 1–10)';
}
