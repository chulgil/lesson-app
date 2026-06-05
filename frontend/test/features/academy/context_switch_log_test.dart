import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/academy/data/repositories/mock_context_switch_log_repository.dart';
import 'package:lessonaza/features/academy/domain/entities/context_switch_log.dart';

void main() {
  group('AcademyContext enum', () {
    test('wireValue ↔ fromWire round-trip', () {
      for (final ctx in AcademyContext.values) {
        expect(AcademyContext.fromWire(ctx.wireValue), equals(ctx));
      }
    });

    test('wireValue uses BE snake_case', () {
      expect(AcademyContext.academyOwner.wireValue, equals('academy_owner'));
      expect(AcademyContext.teacher.wireValue, equals('teacher'));
    });

    test('fromWire throws on unknown value', () {
      expect(() => AcademyContext.fromWire('unknown'), throwsArgumentError);
    });
  });

  group('ContextSwitchTrigger enum', () {
    test('wireValue ↔ fromWire round-trip', () {
      for (final trigger in ContextSwitchTrigger.values) {
        expect(
          ContextSwitchTrigger.fromWire(trigger.wireValue),
          equals(trigger),
        );
      }
    });

    test('wireValue uses BE snake_case', () {
      expect(ContextSwitchTrigger.user.wireValue, equals('user'));
      expect(
        ContextSwitchTrigger.sessionResume.wireValue,
        equals('session_resume'),
      );
    });
  });

  group('ContextSwitchLog Entity', () {
    test('should create with all fields', () {
      final now = DateTime.now();
      final log = ContextSwitchLog(
        id: 'log_1',
        userId: 'user_1',
        academyId: 'acad_1',
        fromContext: AcademyContext.teacher,
        toContext: AcademyContext.academyOwner,
        switchedAt: now,
        ip: '127.0.0.1',
        userAgent: 'Mozilla/5.0',
        triggeredBy: ContextSwitchTrigger.sessionResume,
      );

      expect(log.id, equals('log_1'));
      expect(log.fromContext, equals(AcademyContext.teacher));
      expect(log.toContext, equals(AcademyContext.academyOwner));
      expect(log.triggeredBy, equals(ContextSwitchTrigger.sessionResume));
    });

    test('triggeredBy defaults to user', () {
      final log = ContextSwitchLog(
        id: 'log_1',
        userId: 'u',
        academyId: 'a',
        fromContext: AcademyContext.academyOwner,
        toContext: AcademyContext.teacher,
        switchedAt: DateTime.now(),
      );
      expect(log.triggeredBy, equals(ContextSwitchTrigger.user));
      expect(log.ip, isNull);
      expect(log.userAgent, isNull);
    });

    test('copyWith preserves non-overridden fields', () {
      final now = DateTime.now();
      final log = ContextSwitchLog(
        id: 'log_1',
        userId: 'u',
        academyId: 'a',
        fromContext: AcademyContext.academyOwner,
        toContext: AcademyContext.teacher,
        switchedAt: now,
        ip: '10.0.0.1',
      );
      final updated = log.copyWith(toContext: AcademyContext.academyOwner);
      expect(updated.toContext, equals(AcademyContext.academyOwner));
      expect(updated.ip, equals('10.0.0.1'));
      expect(updated.switchedAt, equals(now));
    });

    test('equality + hashCode cover all fields', () {
      final now = DateTime.now();
      final a = ContextSwitchLog(
        id: 'log_1',
        userId: 'u',
        academyId: 'a',
        fromContext: AcademyContext.academyOwner,
        toContext: AcademyContext.teacher,
        switchedAt: now,
      );
      final b = ContextSwitchLog(
        id: 'log_1',
        userId: 'u',
        academyId: 'a',
        fromContext: AcademyContext.academyOwner,
        toContext: AcademyContext.teacher,
        switchedAt: now,
      );
      final d = a.copyWith(ip: '1.1.1.1');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(d)));
    });
  });

  group('MockContextSwitchLogRepository', () {
    ContextSwitchLog buildLog({
      required String id,
      required String userId,
      required String academyId,
      required DateTime switchedAt,
    }) {
      return ContextSwitchLog(
        id: id,
        userId: userId,
        academyId: academyId,
        fromContext: AcademyContext.academyOwner,
        toContext: AcademyContext.teacher,
        switchedAt: switchedAt,
      );
    }

    test('listMy returns only current user logs, desc by switchedAt', () async {
      final now = DateTime.now();
      final repo = MockContextSwitchLogRepository(
        currentUserId: 'me',
        seed: [
          buildLog(
            id: 'l1',
            userId: 'me',
            academyId: 'a1',
            switchedAt: now.subtract(const Duration(hours: 1)),
          ),
          buildLog(id: 'l2', userId: 'other', academyId: 'a1', switchedAt: now),
          buildLog(
            id: 'l3',
            userId: 'me',
            academyId: 'a2',
            switchedAt: now.subtract(const Duration(minutes: 30)),
          ),
        ],
      );

      final result = await repo.listMy();

      expect(result.map((l) => l.id).toList(), equals(['l3', 'l1']));
    });

    test('listMy respects limit', () async {
      final now = DateTime.now();
      final repo = MockContextSwitchLogRepository(
        currentUserId: 'me',
        seed: List.generate(
          5,
          (i) => buildLog(
            id: 'l$i',
            userId: 'me',
            academyId: 'a',
            switchedAt: now.subtract(Duration(minutes: i)),
          ),
        ),
      );

      final result = await repo.listMy(limit: 2);

      expect(result.length, equals(2));
    });

    test('listMyForAcademy throws when not a member', () async {
      final repo = MockContextSwitchLogRepository(
        currentUserId: 'me',
        academyMemberIds: {'a1'},
      );

      expect(
        () => repo.listMyForAcademy('a_unknown'),
        throwsA(isA<StateError>()),
      );
    });

    test(
      'listMyForAcademy returns only matching academy for current user',
      () async {
        final now = DateTime.now();
        final repo = MockContextSwitchLogRepository(
          currentUserId: 'me',
          academyMemberIds: {'a1'},
          seed: [
            buildLog(id: 'l1', userId: 'me', academyId: 'a1', switchedAt: now),
            buildLog(
              id: 'l2',
              userId: 'me',
              academyId: 'a2',
              switchedAt: now.subtract(const Duration(minutes: 5)),
            ),
            buildLog(
              id: 'l3',
              userId: 'other',
              academyId: 'a1',
              switchedAt: now.subtract(const Duration(minutes: 10)),
            ),
          ],
        );

        final result = await repo.listMyForAcademy('a1');

        expect(result.length, equals(1));
        expect(result.single.id, equals('l1'));
      },
    );

    test('add / clear mutate state', () async {
      final repo = MockContextSwitchLogRepository(currentUserId: 'me');
      expect((await repo.listMy()).length, equals(0));
      repo.add(
        buildLog(
          id: 'new',
          userId: 'me',
          academyId: 'a',
          switchedAt: DateTime.now(),
        ),
      );
      expect((await repo.listMy()).length, equals(1));
      repo.clear();
      expect((await repo.listMy()).length, equals(0));
    });
  });
}
