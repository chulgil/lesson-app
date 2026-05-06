import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/features/parent_home/domain/entities/user_profile.dart';
import 'package:lessonaza/features/parent_home/presentation/extensions/parent_home_domain_visuals.dart';

void main() {
  group('ProfileTypeVisuals', () {
    test('maps labels for presentation', () {
      expect(ProfileType.parent.label, '학부모');
      expect(ProfileType.student.label, '학생');
      expect(ProfileType.child.label, '자녀');
    });

    test('maps icons and colors for presentation', () {
      expect(ProfileType.parent.icon, Icons.family_restroom);
      expect(ProfileType.student.icon, Icons.school);
      expect(ProfileType.child.icon, Icons.child_care);

      expect(ProfileType.parent.color, AppColors.paperAccent);
      expect(ProfileType.student.color, AppColors.paperOk);
      expect(ProfileType.child.color, AppColors.paperAccent);
    });
  });
}
