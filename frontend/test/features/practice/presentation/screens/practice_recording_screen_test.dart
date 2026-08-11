import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/constants/practice_defaults.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/widgets/swipe_action_tile.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_repertoire.dart';
import 'package:lessonaza/features/practice/domain/entities/recording.dart';
import 'package:lessonaza/features/practice/domain/repositories/practice_repertoire_repository.dart';
import 'package:lessonaza/features/practice/presentation/providers/practice_repertoire_repository_provider.dart';
import 'package:lessonaza/features/practice/presentation/providers/recording_provider.dart';
import 'package:lessonaza/features/practice/presentation/screens/practice_recording_screen.dart';

class _FakeRecordingNotifier extends RecordingNotifier {
  @override
  RecordingState build(String repertoireId, String studentId) {
    final now = DateTime(2026, 5, 7);
    return RecordingState(
      isLoading: false,
      recordings: [
        Recording(
          id: 'recording_1',
          repertoireId: repertoireId,
          studentId: studentId,
          type: RecordingType.student,
          localPath: '/tmp/recording.wav',
          durationSeconds: 42,
          isRepresentative: true,
          recordedAt: now,
        ),
      ],
    );
  }
}

/// In-memory fake — only the methods [QuickRecordingService] touches.
/// Mirrors the fake in quick_recording_service_test.dart; kept local so this
/// widget test stays Hive-free (unlike [MockPracticeRepertoireRepository]).
class _FakeQuickRecordRepository implements PracticeRepertoireRepository {
  final Map<String, PracticeRepertoire> _repertoires = {};
  final Map<String, PracticeSection> _sections = {};

  @override
  Future<PracticeRepertoire?> getRepertoire(String id) async =>
      _repertoires[id];

  @override
  Future<PracticeRepertoire> createRepertoire(
    PracticeRepertoire repertoire,
  ) async {
    _repertoires[repertoire.id] = repertoire;
    return repertoire;
  }

  @override
  Future<PracticeSection?> getSection(String id) async => _sections[id];

  @override
  Future<PracticeSection> createSection(PracticeSection section) async {
    _sections[section.id] = section;
    return section;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError('Unexpected call: ${invocation.memberName}');
  }
}

void main() {
  Future<void> pumpScreen(WidgetTester tester) async {
    const repertoireId = 'repertoire_1';
    const studentId = 'student_1';
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          microphonePermissionProvider.overrideWith((ref) async => true),
          recordingNotifierProvider(
            repertoireId,
            studentId,
          ).overrideWith(_FakeRecordingNotifier.new),
        ],
        child: const MaterialApp(
          home: PracticeRecordingScreen(
            repertoireId: repertoireId,
            repertoireName: 'Canon',
            studentId: studentId,
          ),
        ),
      ),
    );
    // SwipeActionTile AnimatedContainer 가 settle 못 하는 경우가 있어 명시 pump 만.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('shows explicit teacher share action', (tester) async {
    await pumpScreen(tester);
    expect(find.text(AppStrings.practiceShareToTeacherAction), findsOneWidget);
  });

  testWidgets('does not render PopupMenuButton (swipe consistency D1)', (
    tester,
  ) async {
    await pumpScreen(tester);
    expect(
      find.byType(PopupMenuButton<String>),
      findsNothing,
      reason:
          '_RecordingItem 의 PopupMenuButton 은 SwipeActionTile + BottomSheet 로 대체되어야 한다.',
    );
  });

  testWidgets(
    'renders SwipeActionTile for recording row (swipe destructive 단일)',
    (tester) async {
      await pumpScreen(tester);
      expect(
        find.byType(SwipeActionTile),
        findsWidgets,
        reason: '_RecordingItem 은 SwipeActionTile 로 래핑되어야 한다.',
      );
    },
  );

  // quickMode 는 이 화면이 라우팅으로 도달 가능해지기 전까지 프로덕션 미도달
  // 경로였다 — smoke test 로 먼저 안전성 확인 (practice tools modal §녹음 탭 배선).
  group('quickMode', () {
    testWidgets(
      'resolves the default quick-record target and renders without crashing',
      (tester) async {
        const studentId = 'student_quick';
        final repertoireId = PracticeDefaults.defaultRepertoireIdFor(studentId);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              practiceRepertoireRepositoryProvider.overrideWithValue(
                _FakeQuickRecordRepository(),
              ),
              microphonePermissionProvider.overrideWith((ref) async => true),
              recordingNotifierProvider(
                repertoireId,
                studentId,
              ).overrideWith(_FakeRecordingNotifier.new),
            ],
            child: const MaterialApp(
              home: PracticeRecordingScreen(
                repertoireId: '',
                repertoireName: '',
                studentId: studentId,
                quickMode: true,
              ),
            ),
          ),
        );

        // First frame: spinner while _resolveQuickModeIfNeeded runs.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        // AppBar title falls back to the resolved default repertoire name
        // ("무제") once QuickRecordingService.ensureDefaultsForStudent resolves.
        expect(find.text(PracticeDefaults.repertoireName), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
