// Widget smoke test for practice §6.3 Phase 1 progress dialog.
//
// Confirms the dialog renders the supplied title, the localized status
// string, and a percentage label without throwing on tight layout
// constraints — covers the RenderMetaData/BoxConstraints regression
// pattern flagged in ux-rules.md.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/practice/presentation/providers/backup_provider.dart';
import 'package:lessonaza/features/practice/presentation/widgets/backup/backup_progress_dialog.dart';

void main() {
  testWidgets('renders title and status from progress notifier', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backupControllerProvider.overrideWith(
            () => _StubBackupController(
              const BackupProgress(
                progress: 0.42,
                status: AppStrings.backupHiveExporting,
                isRunning: true,
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: BackupProgressDialog(title: AppStrings.backupExporting),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(AppStrings.backupExporting), findsOneWidget);
    expect(find.text(AppStrings.backupHiveExporting), findsOneWidget);
    expect(find.text('42%'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('idle state falls back to backupPreparing copy', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: BackupProgressDialog(title: AppStrings.backupRestoring),
          ),
        ),
      ),
    );
    // Idle state has progress == null which makes LinearProgressIndicator
    // animate forever — use pump() not pumpAndSettle().
    await tester.pump();

    expect(find.text(AppStrings.backupRestoring), findsOneWidget);
    expect(find.text(AppStrings.backupPreparing), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _StubBackupController extends BackupController {
  final BackupProgress _initial;
  _StubBackupController(this._initial);

  @override
  BackupProgress build() => _initial;
}
