import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../domain/entities/teacher_profile.dart';

/// Presentation visuals (label + icon) for [LessonTypeOption].
///
/// Keeps display strings/icons out of the domain enum (flutter-architecture:
/// no display getters on entities) and gives a single SSOT so the profile
/// editor and the public teacher detail render the same label/icon (C3).
extension LessonTypeOptionVisuals on LessonTypeOption {
  String get label => switch (this) {
    LessonTypeOption.inPerson => AppStrings.searchLessonTypeInPerson,
    LessonTypeOption.online => AppStrings.locationOnlineLabel,
    LessonTypeOption.visit => AppStrings.searchLessonTypeVisit,
  };

  IconData get icon => switch (this) {
    LessonTypeOption.inPerson => Icons.person,
    LessonTypeOption.online => Icons.videocam,
    LessonTypeOption.visit => Icons.directions_walk,
  };
}
