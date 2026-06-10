// Widget smoke test (HARD-GATE) for BackupItem.
//
// Asserts the swipe consistency followup audit #668 D6 — the legacy
// PopupMenuButton has been replaced by SwipeActionTile + tap-to-open
// BackupItemActionsBottomSheet, and the row renders without runtime crashes.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/settings/data/services/backup_service.dart';
import 'package:lessonaza/features/settings/presentation/widgets/backup_widgets.dart';

void main() {
  testWidgets('BackupItem renders without crash and exposes no PopupMenu', (
    tester,
  ) async {
    final backup = BackupFileInfo(
      file: File('/tmp/lessonaza_backup_test.zip'),
      createdAt: DateTime(2026, 6, 10, 12, 0),
      sizeBytes: 1024 * 1024,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: BackupItem(backup: backup)),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // PopupMenuButton removed in favor of SwipeActionTile + BottomSheet.
    expect(find.byType(PopupMenuButton<String>), findsNothing);
  });
}
