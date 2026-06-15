import 'package:lessonaza/core/l10n/app_strings.dart';

/// 연령 톤. domain 은 톤을 모른다(presentation only) — 기본 standard,
/// 부모 override 로 child. 스펙 §8(결정 Q2).
enum JournalTone {
  standard,
  child;

  String get title => switch (this) {
    JournalTone.child => AppStrings.journalTitleChild,
    JournalTone.standard => AppStrings.journalTitleStandard,
  };
}
