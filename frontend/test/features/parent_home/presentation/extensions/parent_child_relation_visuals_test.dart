import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/parent_home/domain/entities/parent_child_relation.dart';
import 'package:lessonaza/features/parent_home/presentation/extensions/parent_home_domain_visuals.dart';

void main() {
  group('ParentChildRelationStatusVisuals', () {
    test('maps relation status labels for presentation', () {
      expect(ParentChildRelationStatus.pending.label, '대기');
      expect(ParentChildRelationStatus.active.label, '활성');
      expect(ParentChildRelationStatus.inactive.label, '해제');
    });
  });
}
