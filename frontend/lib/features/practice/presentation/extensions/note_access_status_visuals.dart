import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/note_access_request.dart';

/// Status -> display mapping for [NoteAccessStatus] (label / badge background /
/// text color). Single source of truth (C3): screens delegate to these getters
/// instead of inlining a `switch` per call site, and every color comes from a
/// semantic token only (C8 -- no `Colors.red` / `Colors.grey`).
extension NoteAccessStatusVisuals on NoteAccessStatus {
  /// Korean status label shown in the badge.
  ///
  /// Literals are centralized here so the later i18n pass (C5) becomes a
  /// single-site swap; display vocabulary stays in the presentation layer.
  String get label => switch (this) {
    NoteAccessStatus.consented => '동의됨',
    NoteAccessStatus.rejected => '거절됨',
    NoteAccessStatus.revoked => '회수됨',
    NoteAccessStatus.requested => '요청 중',
  };

  /// Badge background color (semantic tokens only).
  Color get badgeColor => switch (this) {
    NoteAccessStatus.consented => AppColors.bubbleSuccessBackground,
    NoteAccessStatus.rejected => AppColors.paperAccentSoft,
    NoteAccessStatus.revoked => AppColors.paperDark,
    NoteAccessStatus.requested => AppColors.bubbleIdleBackground,
  };

  /// Badge text color (semantic tokens only).
  Color get textColor => switch (this) {
    NoteAccessStatus.consented => AppColors.bubbleSuccessText,
    NoteAccessStatus.rejected => AppColors.paperAccent,
    NoteAccessStatus.revoked => AppColors.inkSecondary,
    NoteAccessStatus.requested => AppColors.bubbleIdleText,
  };
}
