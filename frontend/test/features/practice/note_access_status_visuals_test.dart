import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/features/practice/domain/entities/note_access_request.dart';
import 'package:lessonaza/features/practice/presentation/extensions/note_access_status_visuals.dart';

void main() {
  group('NoteAccessStatusVisuals', () {
    test('label maps each status to its Korean badge text', () {
      expect(NoteAccessStatus.requested.label, '요청 중');
      expect(NoteAccessStatus.consented.label, '동의됨');
      expect(NoteAccessStatus.rejected.label, '거절됨');
      expect(NoteAccessStatus.revoked.label, '회수됨');
    });

    test('badgeColor maps each status to its semantic token', () {
      expect(
        NoteAccessStatus.consented.badgeColor,
        AppColors.bubbleSuccessBackground,
      );
      expect(NoteAccessStatus.rejected.badgeColor, AppColors.paperAccentSoft);
      expect(NoteAccessStatus.revoked.badgeColor, AppColors.paperDark);
      expect(
        NoteAccessStatus.requested.badgeColor,
        AppColors.bubbleIdleBackground,
      );
    });

    test('textColor maps each status to its semantic token', () {
      expect(NoteAccessStatus.consented.textColor, AppColors.bubbleSuccessText);
      expect(NoteAccessStatus.rejected.textColor, AppColors.paperAccent);
      expect(NoteAccessStatus.revoked.textColor, AppColors.inkSecondary);
      expect(NoteAccessStatus.requested.textColor, AppColors.bubbleIdleText);
    });

    test('every status resolves all three visuals (exhaustive)', () {
      for (final status in NoteAccessStatus.values) {
        expect(status.label, isNotEmpty);
        expect(status.badgeColor, isA<Color>());
        expect(status.textColor, isA<Color>());
      }
    });
  });
}
