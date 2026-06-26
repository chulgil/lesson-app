import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/gamification/domain/entities/growth_heatmap.dart';
import 'package:lessonaza/features/gamification/presentation/providers/growth_heatmap_provider.dart';
import 'package:lessonaza/features/gamification/presentation/widgets/practice_start_section.dart';
import 'package:lessonaza/features/students/domain/entities/student.dart';
import 'package:lessonaza/features/students/presentation/providers/student_crud_provider.dart';

/// PR-B 최소 smoke test — PracticeStartSection 빌드 가능 + PracticeStartCard
/// 표시. Modal show / Celebration overlay 통합 흐름은 PR-C e2e 에서 검증.
void main() {
  testWidgets('builds PracticeStartCard with mock providers', (tester) async {
    final mockStudent = Student(
      id: 's1',
      name: '민지',
      instrument: 'piano',
      nickname: '민지짱',
      createdAt: DateTime(2026, 1, 1),
    );
    final mockHeatmap = GrowthHeatmap(studentId: 's1', days: const {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studentProvider('s1').overrideWith((ref) async => mockStudent),
          growthHeatmapProvider('s1').overrideWith((ref) async => mockHeatmap),
        ],
        child: const MaterialApp(
          home: Scaffold(body: PracticeStartSection(studentId: 's1')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('practice_start_card_header')),
      findsOneWidget,
    );
    expect(find.text('민지짱의 연습'), findsOneWidget);
    expect(find.byKey(const ValueKey('practice_start_button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
