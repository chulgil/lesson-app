import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/features/parent_home/domain/entities/child_profile.dart';
import 'package:lessonaza/features/parent_home/presentation/extensions/parent_home_domain_visuals.dart';

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
  });
}
