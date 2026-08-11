import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/features/practice/presentation/widgets/practice_tools/music_practice_tools.dart';

/// 녹음 launch tab (dead-code entry point audit) — proves the panel's action
/// button closes its host bottom sheet and pushes the quick-record route with
/// `quick=true` + studentId, matching the pattern precedent in
/// practice_start_section_more_tap_test.dart (GoRouter spy mock + sync pump,
/// no Future.delayed).
void main() {
  testWidgets(
    '녹음 tab action closes the sheet and routes to quick-record with studentId',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder:
                (context, state) => Scaffold(
                  body: Builder(
                    builder:
                        (innerContext) => ElevatedButton(
                          onPressed:
                              () => showModalBottomSheet<void>(
                                context: innerContext,
                                builder:
                                    (sheetContext) => musicPracticeTools
                                        .firstWhere(
                                          (t) =>
                                              t.id == PracticeToolIds.recording,
                                        )
                                        .panelBuilder(sheetContext, 's1', null),
                              ),
                          child: const Text('open'),
                        ),
                  ),
                ),
          ),
          GoRoute(
            path: AppRoutes.practiceRecording,
            builder: (context, state) {
              final repertoireId = state.pathParameters['repertoireId'] ?? '';
              final studentId = state.uri.queryParameters['studentId'] ?? '';
              final quick = state.uri.queryParameters['quick'] ?? '';
              return Scaffold(
                body: Text(
                  'RECORDING_TARGET:$repertoireId:$studentId:$quick',
                  key: const ValueKey('recording_target'),
                ),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // title 과 action label 이 둘 다 AppStrings.quickRecordSectionTitle /
      // quickRecordButton = '바로 녹음' 로 동일 문자열이라 find.text 는 2개를
      // 잡는다 — OutlinedButton (EmptyStateWidget 의 action) 으로 특정한다.
      final actionButton = find.widgetWithText(
        OutlinedButton,
        AppStrings.quickRecordButton,
      );
      expect(
        actionButton,
        findsOneWidget,
        reason: '녹음 탭은 studentId 가 있으면 바로 녹음 액션을 노출해야 한다',
      );

      await tester.tap(actionButton);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('recording_target')),
        findsOneWidget,
        reason: '녹음 탭 액션 탭 → practiceRecording 라우트로 push 되어야 한다',
      );
      expect(find.text('RECORDING_TARGET:quick:s1:true'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('녹음 tab hides the action when no studentId is available', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder:
                (context) => musicPracticeTools
                    .firstWhere((t) => t.id == PracticeToolIds.recording)
                    .panelBuilder(context, null, null),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Title text ('바로 녹음') still renders — only the action button is gated.
    expect(find.byType(OutlinedButton), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
