import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/features/subscription/data/repositories/mock_makeup_credit_repository.dart';
import 'package:lessonaza/features/subscription/domain/entities/makeup_credit.dart';

void main() {
  group('MockMakeupCreditRepository', () {
    test('seeds sample student credits', () async {
      final repo = MockMakeupCreditRepository();
      final credits = await repo.listStudentCredits();
      expect(credits, isNotEmpty);
      expect(credits.any((c) => c.isUsed), isTrue);
      expect(credits.any((c) => !c.isUsed), isTrue);
    });

    test('grant adds a manualGrant credit with 30d expiry', () async {
      final repo = MockMakeupCreditRepository();
      final before = (await repo.listTeacherCredits(
        studentId: 'student-x',
      )).length;

      final granted = await repo.grantCredit(studentId: 'student-x');
      expect(granted.reason, MakeupCreditReason.manualGrant);
      expect(granted.expiresAt.isAfter(granted.createdAt), isTrue);

      final after = await repo.listTeacherCredits(studentId: 'student-x');
      expect(after.length, before + 1);
    });

    test('revoke removes an unused credit', () async {
      final repo = MockMakeupCreditRepository();
      final granted = await repo.grantCredit(studentId: 'student-y');
      await repo.revokeCredit(granted.id);
      final after = await repo.listTeacherCredits(studentId: 'student-y');
      expect(after.any((c) => c.id == granted.id), isFalse);
    });

    test('revoke throws when credit already used', () async {
      final repo = MockMakeupCreditRepository();
      final all = await repo.listStudentCredits();
      final used = all.firstWhere((c) => c.isUsed);
      expect(
        () => repo.revokeCredit(used.id),
        throwsA(isA<Exception>()),
      );
    });

    group('useCredit (spend — #928)', () {
      test('marks an unused credit used with usedAt/usedLessonId', () async {
        final repo = MockMakeupCreditRepository();
        final unused = (await repo.listStudentCredits()).firstWhere(
          (c) => !c.isUsed,
        );

        final updated = await repo.useCredit(
          creditId: unused.id,
          lessonId: 'lesson-77',
        );
        expect(updated.isUsed, isTrue);
        expect(updated.usedLessonId, 'lesson-77');

        // Persisted in the store, not just the returned copy.
        final stored = (await repo.listStudentCredits()).firstWhere(
          (c) => c.id == unused.id,
        );
        expect(stored.isUsed, isTrue);
        expect(stored.usedLessonId, 'lesson-77');
      });

      test('throws when credit already used', () async {
        final repo = MockMakeupCreditRepository();
        final used = (await repo.listStudentCredits()).firstWhere(
          (c) => c.isUsed,
        );
        expect(
          () => repo.useCredit(creditId: used.id, lessonId: 'lesson-1'),
          throwsA(isA<Exception>()),
        );
      });

      test('throws when credit not found', () async {
        final repo = MockMakeupCreditRepository();
        expect(
          () => repo.useCredit(creditId: 'no-such-id', lessonId: 'lesson-1'),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
