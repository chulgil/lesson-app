import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/features/parent_home/domain/entities/child_profile.dart';
import 'package:lessonaza/features/parent_home/presentation/extensions/parent_home_domain_visuals.dart';

ChildProfile _child({required String instrument, required String level}) =>
    ChildProfile(
      id: 'c1',
      parentId: 'p1',
      name: 'C',
      birthYear: 2018,
      instrument: instrument,
      level: level,
      profileColorKey: 'paperAccent',
      createdAt: DateTime(2020),
    );

void main() {
  group('ChildProfileVisuals', () {
    test('provides centralized profile status labels', () {
      expect(ChildProfileStatus.active.label, '활성');
      expect(ChildProfileStatus.inactive.label, '비활성');
    });

    test('provides connection labels and visuals', () {
      expect(ChildConnectionStatus.connected.label, '연결됨');
      expect(ChildConnectionStatus.pending.label, '대기 중');
      expect(ChildConnectionStatus.unconnected.label, '미연결');

      expect(ChildConnectionStatus.connected.color, AppColors.paperOk);
      expect(ChildConnectionStatus.pending.color, AppColors.paperAccent);
      expect(ChildConnectionStatus.unconnected.color, AppColors.inkTertiary);

      expect(ChildConnectionStatus.connected.icon, Icons.link);
      expect(ChildConnectionStatus.pending.icon, Icons.hourglass_empty);
      expect(ChildConnectionStatus.unconnected.icon, Icons.link_off);
    });

    test('instrument / level / icon visuals resolve via the SSOT', () {
      expect(
        _child(instrument: 'violin', level: 'beginner').instrumentLabel,
        AppStrings.instrumentViolin,
      );
      expect(
        _child(instrument: 'piano', level: 'beginner').instrumentLabel,
        AppStrings.instrumentPiano,
      );
      expect(
        _child(instrument: 'cello', level: 'beginner').instrumentLabel,
        AppStrings.instrumentCello,
      );
      expect(
        _child(instrument: 'viola', level: 'beginner').instrumentLabel,
        AppStrings.instrumentViola,
      );
      expect(
        _child(instrument: 'flute', level: 'beginner').instrumentLabel,
        AppStrings.instrumentFlute,
      );
      expect(
        _child(instrument: 'piano', level: 'beginner').instrumentIcon,
        Icons.piano,
      );
      expect(
        _child(instrument: 'violin', level: 'beginner').instrumentIcon,
        Icons.music_note,
      );
      expect(
        _child(instrument: 'violin', level: 'beginner').levelLabel,
        AppStrings.studentLevelBeginner,
      );
      expect(
        _child(instrument: 'violin', level: 'advanced').levelLabel,
        AppStrings.studentLevelAdvanced,
      );
    });

    test('unknown instrument / level key falls back to the raw value', () {
      final c = _child(instrument: 'guitar', level: 'pro');
      expect(c.instrumentLabel, 'guitar');
      expect(c.levelLabel, 'pro');
      expect(c.instrumentIcon, Icons.music_note);
    });
  });
}
