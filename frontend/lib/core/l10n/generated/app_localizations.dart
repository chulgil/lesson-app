import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// Application title.
  ///
  /// In ko, this message translates to:
  /// **'Lessonaza'**
  String get appTitle;

  /// Bottom navigation label for the home tab.
  ///
  /// In ko, this message translates to:
  /// **'홈'**
  String get navHome;

  /// Bottom navigation label for the lessons tab.
  ///
  /// In ko, this message translates to:
  /// **'레슨'**
  String get navLessons;

  /// Bottom navigation label for the practice tab.
  ///
  /// In ko, this message translates to:
  /// **'연습'**
  String get navPractice;

  /// Bottom navigation label for the profile tab.
  ///
  /// In ko, this message translates to:
  /// **'프로필'**
  String get navProfile;

  /// Bottom navigation label for the assignments tab.
  ///
  /// In ko, this message translates to:
  /// **'과제'**
  String get navAssignments;

  /// Bottom navigation label for the payments tab.
  ///
  /// In ko, this message translates to:
  /// **'입금'**
  String get navPayments;

  /// Route-level fallback when a closure/makeup route is opened without valid data.
  ///
  /// In ko, this message translates to:
  /// **'휴강 정보를 불러올 수 없습니다.'**
  String get academyClosureLoadError;

  /// Route-level fallback when an announcement route is opened without valid data.
  ///
  /// In ko, this message translates to:
  /// **'공지사항을 불러올 수 없습니다.'**
  String get notificationAnnouncementLoadError;

  /// Route-level fallback when an inquiry route is opened without valid data.
  ///
  /// In ko, this message translates to:
  /// **'문의를 불러올 수 없습니다.'**
  String get notificationInquiryLoadError;

  /// Skip button on the coach-mark overlay.
  ///
  /// In ko, this message translates to:
  /// **'건너뛰기'**
  String get coachMarkSkip;

  /// Custom-input chip label shared by count/discount/duration/validity selectors.
  ///
  /// In ko, this message translates to:
  /// **'직접 입력'**
  String get selectorDirectInput;

  /// Hint for the bonus-count custom input field.
  ///
  /// In ko, this message translates to:
  /// **'횟수'**
  String get selectorCountHint;

  /// Hint for the discount-percent custom input field.
  ///
  /// In ko, this message translates to:
  /// **'할인율'**
  String get selectorDiscountPercentHint;

  /// Hint for the lesson-count custom input field.
  ///
  /// In ko, this message translates to:
  /// **'횟수 입력'**
  String get selectorCountInputHint;

  /// Hint for the lesson-duration custom input field (minutes).
  ///
  /// In ko, this message translates to:
  /// **'시간 입력'**
  String get selectorDurationInputHint;

  /// Tuner settings toggle subtitle — show combo streak.
  ///
  /// In ko, this message translates to:
  /// **'Perfect 연속 달성 시 콤보 표시'**
  String get tunerShowComboSubtitle;

  /// Tuner settings toggle subtitle — vibrate on perfect.
  ///
  /// In ko, this message translates to:
  /// **'Perfect 튜닝 시 진동'**
  String get tunerVibrationSubtitle;

  /// Unfollow confirmation dialog body.
  ///
  /// In ko, this message translates to:
  /// **'{name}의 팔로우를 취소하시겠습니까?'**
  String followCancelConfirmBody(String name);

  /// Snackbar after deleting an instrument from the teacher profile.
  ///
  /// In ko, this message translates to:
  /// **'{name}이(가) 삭제되었습니다'**
  String instrumentDeletedMessage(String name);

  /// Outstanding-payment confirmation dialog body; amount is pre-formatted with currency.
  ///
  /// In ko, this message translates to:
  /// **'{amount} 입금을 확인하시겠습니까?'**
  String paymentConfirmBody(String amount);

  /// Repertoire piece delete confirmation dialog body.
  ///
  /// In ko, this message translates to:
  /// **'{title}을(를) 삭제하시겠습니까?'**
  String repertoireDeleteConfirmBody(String title);

  /// Snackbar after approving a lesson booking.
  ///
  /// In ko, this message translates to:
  /// **'{studentName}님의 레슨이 승인되었습니다'**
  String lessonApprovedMessage(String studentName);

  /// Snackbar after editing a student's info.
  ///
  /// In ko, this message translates to:
  /// **'{name} 학생 정보가 수정되었습니다'**
  String studentInfoUpdatedMessage(String name);

  /// Parent-invite dialog intro on the student detail screen.
  ///
  /// In ko, this message translates to:
  /// **'{studentName} 학생의 학부모를 초대합니다'**
  String parentInviteIntroBody(String studentName);

  /// Snackbar after sending a bulk message.
  ///
  /// In ko, this message translates to:
  /// **'{count}명에게 메시지를 보냈습니다'**
  String bulkMessageSentMessage(int count);

  /// Submit button on the add-reschedule-credit sheet.
  ///
  /// In ko, this message translates to:
  /// **'{count}회 추가'**
  String rescheduleAddCountButton(int count);

  /// Helper under the section-name field; preview is the derived range text.
  ///
  /// In ko, this message translates to:
  /// **'비워두면 \"{preview}\"로 표시됩니다'**
  String editSectionNameHelper(String preview);

  /// Hour-preset chip label (e.g. cancel deadline).
  ///
  /// In ko, this message translates to:
  /// **'{hours}시간'**
  String hoursOptionLabel(int hours);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
