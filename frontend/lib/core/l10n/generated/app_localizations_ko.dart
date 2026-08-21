// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Lessonaza';

  @override
  String get navHome => '홈';

  @override
  String get navLessons => '레슨';

  @override
  String get navPractice => '연습';

  @override
  String get navProfile => '프로필';

  @override
  String get navAssignments => '과제';

  @override
  String get navPayments => '입금';

  @override
  String get academyClosureLoadError => '휴강 정보를 불러올 수 없습니다.';

  @override
  String get notificationAnnouncementLoadError => '공지사항을 불러올 수 없습니다.';

  @override
  String get notificationInquiryLoadError => '문의를 불러올 수 없습니다.';

  @override
  String get coachMarkSkip => '건너뛰기';

  @override
  String get selectorDirectInput => '직접 입력';

  @override
  String get selectorCountHint => '횟수';

  @override
  String get selectorDiscountPercentHint => '할인율';

  @override
  String get selectorCountInputHint => '횟수 입력';

  @override
  String get selectorDurationInputHint => '시간 입력';

  @override
  String get tunerShowComboSubtitle => 'Perfect 연속 달성 시 콤보 표시';

  @override
  String get tunerVibrationSubtitle => 'Perfect 튜닝 시 진동';

  @override
  String followCancelConfirmBody(String name) {
    return '$name의 팔로우를 취소하시겠습니까?';
  }

  @override
  String instrumentDeletedMessage(String name) {
    return '$name이(가) 삭제되었습니다';
  }

  @override
  String paymentConfirmBody(String amount) {
    return '$amount 입금을 확인하시겠습니까?';
  }

  @override
  String repertoireDeleteConfirmBody(String title) {
    return '$title을(를) 삭제하시겠습니까?';
  }

  @override
  String lessonApprovedMessage(String studentName) {
    return '$studentName님의 레슨이 승인되었습니다';
  }

  @override
  String studentInfoUpdatedMessage(String name) {
    return '$name 학생 정보가 수정되었습니다';
  }

  @override
  String parentInviteIntroBody(String studentName) {
    return '$studentName 학생의 학부모를 초대합니다';
  }

  @override
  String bulkMessageSentMessage(int count) {
    return '$count명에게 메시지를 보냈습니다';
  }

  @override
  String rescheduleAddCountButton(int count) {
    return '$count회 추가';
  }

  @override
  String editSectionNameHelper(String preview) {
    return '비워두면 \"$preview\"로 표시됩니다';
  }

  @override
  String hoursOptionLabel(int hours) {
    return '$hours시간';
  }

  @override
  String backupWrongExtensionMessage(String extension) {
    return '올바른 백업 파일이 아닙니다.\n$extension 확장자 파일을 선택해주세요.';
  }

  @override
  String get backupPathUnavailableMessage => '파일 경로를 가져올 수 없습니다.';

  @override
  String get selectorValidityDaysInputHint => '유효기간 입력';

  @override
  String get selectorValidityMonthsInputHint => '개월 입력';

  @override
  String get practiceMeasureRangeGuide => '연습할 마디 구간을 선택하세요';

  @override
  String get practiceLineRangeGuide => '연습할 줄 구간을 선택하세요 (1~10줄)';
}
