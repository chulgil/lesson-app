import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/auth/auth_facade.dart';
import 'package:lessonaza/features/practice_journal/data/repositories/mock_practice_journal_repository.dart';
import 'package:lessonaza/features/practice_journal/domain/entities/bound_volume.dart';
import 'package:lessonaza/features/practice_journal/domain/entities/endorsement.dart';
import 'package:lessonaza/features/practice_journal/domain/entities/guardian_seal.dart';
import 'package:lessonaza/features/practice_journal/domain/entities/practice_ledger.dart';
import 'package:lessonaza/features/practice_journal/domain/entities/practice_mark.dart';
import 'package:lessonaza/features/practice_journal/domain/repositories/practice_journal_repository.dart';
import 'package:lessonaza/features/practice_journal/presentation/extensions/journal_tone.dart';
import 'package:lessonaza/features/practice_journal/presentation/providers/practice_journal_provider.dart';
import 'package:lessonaza/features/practice_journal/presentation/screens/practice_journal_screen.dart';

// Spy repository that captures the last endorsement/seal passed to it.
class _SpyRepository implements PracticeJournalRepository {
  Endorsement? lastEndorsement;
  GuardianSeal? lastSeal;

  @override
  Future<PracticeLedger> getLedger(String c, int year, int month) async =>
      PracticeLedger.empty(childProfileId: c, year: year, month: month);

  @override
  Future<void> upsertMark(String c, DateTime d, MarkIntensity i) async {}

  @override
  Future<void> addGuardianSeal(String c, GuardianSeal seal) async {
    lastSeal = seal;
  }

  @override
  Future<void> addEndorsement(String c, Endorsement e) async {
    lastEndorsement = e;
  }

  @override
  Future<List<BoundVolume>> getBoundVolumes(String childProfileId) async => [];

  @override
  Future<BoundVolume> bindVolume({
    required String childProfileId,
    required String pieceId,
    required String pieceName,
  }) async => throw UnimplementedError();
}

Widget _buildScreen(
  JournalRole role, {
  _SpyRepository? spy,
  String currentUserId = 'real_user_42',
}) {
  return ProviderScope(
    overrides: [
      practiceJournalRepositoryProvider.overrideWithValue(
        spy ?? MockPracticeJournalRepository(),
      ),
      currentUserIdProvider.overrideWithValue(currentUserId),
    ],
    child: MaterialApp(
      home: PracticeJournalScreen(childProfileId: 'child_1', role: role),
    ),
  );
}

void main() {
  group('PracticeJournalScreen smoke tests', () {
    testWidgets('student role renders without exception', (tester) async {
      await tester.pumpWidget(_buildScreen(JournalRole.student));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('guardian role renders without exception', (tester) async {
      await tester.pumpWidget(_buildScreen(JournalRole.guardian));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('teacher role renders without exception', (tester) async {
      await tester.pumpWidget(_buildScreen(JournalRole.teacher));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('student role shows 자가 검인 button', (tester) async {
      await tester.pumpWidget(_buildScreen(JournalRole.student));
      await tester.pumpAndSettle();
      expect(find.text('자가 검인'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('guardian role shows 확인 도장 button', (tester) async {
      await tester.pumpWidget(_buildScreen(JournalRole.guardian));
      await tester.pumpAndSettle();
      expect(find.text('확인 도장'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('teacher role shows 선생님 인증 button', (tester) async {
      await tester.pumpWidget(_buildScreen(JournalRole.teacher));
      await tester.pumpAndSettle();
      // '선생님 인증' appears as the bottom action label AND in the actor legend.
      expect(find.text('선생님 인증'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('legend rendered in body — no exception', (tester) async {
      await tester.pumpWidget(_buildScreen(JournalRole.student));
      await tester.pumpAndSettle();
      // Legend title is present
      expect(find.text('도장 의미'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('child tone renders with 도장판 title', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            practiceJournalRepositoryProvider.overrideWithValue(
              MockPracticeJournalRepository(),
            ),
            currentUserIdProvider.overrideWithValue('real_user_42'),
          ],
          child: const MaterialApp(
            home: PracticeJournalScreen(
              childProfileId: 'child_1',
              role: JournalRole.student,
              tone: JournalTone.child,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('도장판'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  // #935 — endorsement/seal 생성 시 'me' 하드코딩 제거 검증
  group('#935 endorsement placeholder userId', () {
    testWidgets('student 자가 검인 tap passes real userId (not "me")', (
      tester,
    ) async {
      final spy = _SpyRepository();
      await tester.pumpWidget(
        _buildScreen(JournalRole.student, spy: spy, currentUserId: 'real_42'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('자가 검인'));
      await tester.pumpAndSettle();
      expect(spy.lastEndorsement, isNotNull);
      expect(spy.lastEndorsement!.authorUserId, equals('real_42'));
      expect(spy.lastEndorsement!.authorUserId, isNot(equals('me')));
      expect(tester.takeException(), isNull);
    });

    testWidgets('teacher 선생님 인증 tap passes real userId (not "me")', (
      tester,
    ) async {
      final spy = _SpyRepository();
      await tester.pumpWidget(
        _buildScreen(JournalRole.teacher, spy: spy, currentUserId: 'real_42'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '선생님 인증'));
      await tester.pumpAndSettle();
      expect(spy.lastEndorsement, isNotNull);
      expect(spy.lastEndorsement!.authorUserId, equals('real_42'));
      expect(spy.lastEndorsement!.authorUserId, isNot(equals('me')));
      // assignmentRef placeholder 'a1' is removed — null expected
      expect(spy.lastEndorsement!.assignmentRef, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('guardian 확인 도장 tap passes real userId (not "me")', (
      tester,
    ) async {
      final spy = _SpyRepository();
      await tester.pumpWidget(
        _buildScreen(JournalRole.guardian, spy: spy, currentUserId: 'real_42'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('확인 도장'));
      await tester.pumpAndSettle();
      expect(spy.lastSeal, isNotNull);
      expect(spy.lastSeal!.guardianUserId, equals('real_42'));
      expect(spy.lastSeal!.guardianUserId, isNot(equals('me')));
      expect(tester.takeException(), isNull);
    });
  });
}
