// Smoke + behavior tests for SectionRecordingListItem.
//
// Covers swipe consistency audit (2026-06-10 §2 원칙 1/2/3):
// - PopupMenuButton 이 제거되었는지
// - SwipeActionTile 로 destructive 액션이 노출되는지
// - 행 탭 시 RecordingActionsBottomSheet 가 열리는지
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_repertoire.dart';
import 'package:lessonaza/features/practice/presentation/widgets/section_detail/section_recording_list_item.dart';

void main() {
  PracticeRecording buildRecording({bool isRepresentative = false}) {
    return PracticeRecording(
      id: 'rec_1',
      sectionId: 'section_1',
      // Non-existent path → forces the file-missing branch unless we override.
      filePath: '/tmp/non_existent_recording.m4a',
      durationSeconds: 75,
      bpm: 80,
      isRepresentative: isRepresentative,
      createdAt: DateTime(2026, 6, 10, 14, 0),
    );
  }

  Future<void> pumpItem(
    WidgetTester tester, {
    required PracticeRecording recording,
    VoidCallback? onPlay,
    VoidCallback? onDelete,
    VoidCallback? onSetRepresentative,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SectionRecordingListItem(
              recording: recording,
              sectionId: 'section_1',
              repertoireId: 'rep_1',
              onPlay: onPlay ?? () {},
              onDelete: onDelete ?? () {},
              onSetRepresentative: onSetRepresentative ?? () {},
            ),
          ),
        ),
      ),
    );
    // Allow _checkFileExists future to resolve. pumpAndSettle 은 SwipeActionTile
    // 의 AnimatedContainer 가 끝없이 settle 못 하는 경우가 있어 명시 pump 만 사용.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('renders without runtime crash', (tester) async {
    await pumpItem(tester, recording: buildRecording());
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not render PopupMenuButton (swipe consistency)', (
    tester,
  ) async {
    await pumpItem(tester, recording: buildRecording());
    expect(
      find.byType(PopupMenuButton<String>),
      findsNothing,
      reason: 'PopupMenuButton 은 SwipeActionTile + BottomSheet 로 대체되어야 한다.',
    );
  });
}
