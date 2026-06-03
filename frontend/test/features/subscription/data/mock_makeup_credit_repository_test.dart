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
  });
}
