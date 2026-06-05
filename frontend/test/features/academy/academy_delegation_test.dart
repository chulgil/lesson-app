import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/academy/data/repositories/mock_academy_delegation_repository.dart';
import 'package:lessonaza/features/academy/domain/entities/academy_delegation.dart';
import 'package:lessonaza/features/academy/domain/entities/academy_delegation_action.dart';
import 'package:lessonaza/features/academy/domain/entities/delegation_enums.dart';

void main() {
  group('DelegationReason enum', () {
    test('wireValue ↔ fromWire round-trip', () {
      for (final r in DelegationReason.values) {
        expect(DelegationReason.fromWire(r.wireValue), equals(r));
      }
    });

    test('fromWire throws on unknown', () {
      expect(() => DelegationReason.fromWire('unknown'), throwsArgumentError);
    });
  });

  group('DelegationState enum', () {
    test('wireValue uses snake_case (autoEnded → auto_ended)', () {
      expect(DelegationState.autoEnded.wireValue, equals('auto_ended'));
    });

    test('wireValue ↔ fromWire round-trip', () {
      for (final s in DelegationState.values) {
        expect(DelegationState.fromWire(s.wireValue), equals(s));
      }
    });

    test('isLive is true only for scheduled/active', () {
      expect(DelegationState.scheduled.isLive, isTrue);
      expect(DelegationState.active.isLive, isTrue);
      expect(DelegationState.expired.isLive, isFalse);
      expect(DelegationState.revoked.isLive, isFalse);
      expect(DelegationState.autoEnded.isLive, isFalse);
    });
  });

  group('DelegationRevokeReason enum', () {
    test('wireValue ↔ fromWire round-trip', () {
      for (final r in DelegationRevokeReason.values) {
        expect(DelegationRevokeReason.fromWire(r.wireValue), equals(r));
      }
    });

    test('snake_case wire values', () {
      expect(
        DelegationRevokeReason.ownerReturned.wireValue,
        equals('owner_returned'),
      );
      expect(
        DelegationRevokeReason.delegateeDeclined.wireValue,
        equals('delegatee_declined'),
      );
    });
  });

  group('AcademyDelegation entity', () {
    AcademyDelegation buildDelegation({String? id, DelegationState? state}) {
      final now = DateTime(2026, 6, 5, 10);
      return AcademyDelegation(
        id: id ?? 'd1',
        academyId: 'acad_1',
        delegatorUserId: 'owner_1',
        delegateeMemberId: 'member_2',
        permissions: const ['billing.collect', 'inbox.reply'],
        startsAt: now,
        endsAt: now.add(const Duration(days: 7)),
        reason: DelegationReason.trip,
        state: state ?? DelegationState.scheduled,
        createdAt: now,
      );
    }

    test('isLive proxies state.isLive', () {
      expect(buildDelegation(state: DelegationState.scheduled).isLive, isTrue);
      expect(buildDelegation(state: DelegationState.active).isLive, isTrue);
      expect(buildDelegation(state: DelegationState.expired).isLive, isFalse);
    });

    test('defaults match BE (requiresPasswordAtStart=true, template=v1)', () {
      final d = buildDelegation();
      expect(d.requiresPasswordAtStart, isTrue);
      expect(d.notificationTemplateId, equals('delegation_v1'));
      expect(d.reasonNote, isNull);
      expect(d.revokedAt, isNull);
    });

    test('copyWith preserves permissions list', () {
      final d = buildDelegation();
      final updated = d.copyWith(state: DelegationState.active);
      expect(updated.state, equals(DelegationState.active));
      expect(
        updated.permissions,
        equals(const ['billing.collect', 'inbox.reply']),
      );
    });

    test('equality covers permissions content (not identity)', () {
      final a = buildDelegation();
      final b = buildDelegation();
      final c = a.copyWith(permissions: const ['billing.collect']);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  group('AcademyDelegationAction entity', () {
    AcademyDelegationAction buildAction({
      DateTime? reviewedAt,
      String? disputeNote,
    }) {
      return AcademyDelegationAction(
        id: 'a1',
        delegationId: 'd1',
        performedAt: DateTime(2026, 6, 5, 11),
        performedByUserId: 'member_2_user',
        permissionUsed: 'billing.collect',
        endpoint: 'POST /billing/payments',
        targetResourceId: 'inv_42',
        requestSummary: const {'amount': 100000},
        responseStatus: 200,
        ownerReviewedAt: reviewedAt,
        ownerDisputeNote: disputeNote,
      );
    }

    test('isReviewed reflects ownerReviewedAt', () {
      expect(buildAction().isReviewed, isFalse);
      expect(buildAction(reviewedAt: DateTime.now()).isReviewed, isTrue);
    });

    test('isDisputed requires non-empty note', () {
      expect(buildAction().isDisputed, isFalse);
      expect(buildAction(disputeNote: '').isDisputed, isFalse);
      expect(buildAction(disputeNote: 'wrong amount').isDisputed, isTrue);
    });

    test('equality covers requestSummary content', () {
      final a = buildAction();
      final b = buildAction();
      final c = a.copyWith(requestSummary: const {'amount': 200000});
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  group('MockAcademyDelegationRepository', () {
    test(
      'create() then getActiveForAcademy returns the new delegation',
      () async {
        final repo = MockAcademyDelegationRepository();
        final created = await repo.create(
          academyId: 'a1',
          delegatorUserId: 'owner1',
          delegateeMemberId: 'm1',
          permissions: const ['inbox.reply'],
          startsAt: DateTime(2026, 6, 5),
          endsAt: DateTime(2026, 6, 7),
          reason: DelegationReason.trip,
        );
        expect(created.state, equals(DelegationState.scheduled));
        expect(await repo.getActiveForAcademy('a1'), equals(created));
      },
    );

    test(
      'create() throws when academy already has active delegation',
      () async {
        final repo = MockAcademyDelegationRepository();
        await repo.create(
          academyId: 'a1',
          delegatorUserId: 'o1',
          delegateeMemberId: 'm1',
          permissions: const ['inbox.reply'],
          startsAt: DateTime(2026, 6, 5),
          endsAt: DateTime(2026, 6, 6),
          reason: DelegationReason.trip,
        );
        expect(
          () => repo.create(
            academyId: 'a1',
            delegatorUserId: 'o1',
            delegateeMemberId: 'm2',
            permissions: const ['inbox.reply'],
            startsAt: DateTime(2026, 6, 5),
            endsAt: DateTime(2026, 6, 6),
            reason: DelegationReason.trip,
          ),
          throwsStateError,
        );
      },
    );

    test('create() requires endsAt > startsAt', () async {
      final repo = MockAcademyDelegationRepository();
      expect(
        () => repo.create(
          academyId: 'a1',
          delegatorUserId: 'o1',
          delegateeMemberId: 'm1',
          permissions: const ['inbox.reply'],
          startsAt: DateTime(2026, 6, 5),
          endsAt: DateTime(2026, 6, 5),
          reason: DelegationReason.trip,
        ),
        throwsArgumentError,
      );
    });

    test('revoke(ownerManual) marks as revoked', () async {
      final repo = MockAcademyDelegationRepository();
      final created = await repo.create(
        academyId: 'a1',
        delegatorUserId: 'o1',
        delegateeMemberId: 'm1',
        permissions: const ['inbox.reply'],
        startsAt: DateTime(2026, 6, 5),
        endsAt: DateTime(2026, 6, 7),
        reason: DelegationReason.trip,
      );
      final revoked = await repo.revoke(
        delegationId: created.id,
        revokedByUserId: 'o1',
        revokedReason: DelegationRevokeReason.ownerManual,
      );
      expect(revoked.state, equals(DelegationState.revoked));
      expect(revoked.revokedReason, equals(DelegationRevokeReason.ownerManual));
      expect(revoked.revokedAt, isNotNull);
      expect(await repo.getActiveForAcademy('a1'), isNull);
    });

    test('revoke(ownerReturned) marks as autoEnded', () async {
      final repo = MockAcademyDelegationRepository();
      final created = await repo.create(
        academyId: 'a1',
        delegatorUserId: 'o1',
        delegateeMemberId: 'm1',
        permissions: const ['inbox.reply'],
        startsAt: DateTime(2026, 6, 5),
        endsAt: DateTime(2026, 6, 7),
        reason: DelegationReason.trip,
      );
      final ended = await repo.revoke(
        delegationId: created.id,
        revokedByUserId: 'o1',
        revokedReason: DelegationRevokeReason.ownerReturned,
      );
      expect(ended.state, equals(DelegationState.autoEnded));
    });

    test('revoke() rejects when delegation already terminal', () async {
      final repo = MockAcademyDelegationRepository();
      final d = await repo.create(
        academyId: 'a1',
        delegatorUserId: 'o1',
        delegateeMemberId: 'm1',
        permissions: const ['inbox.reply'],
        startsAt: DateTime(2026, 6, 5),
        endsAt: DateTime(2026, 6, 7),
        reason: DelegationReason.trip,
      );
      await repo.revoke(
        delegationId: d.id,
        revokedByUserId: 'o1',
        revokedReason: DelegationRevokeReason.ownerManual,
      );
      expect(
        () => repo.revoke(
          delegationId: d.id,
          revokedByUserId: 'o1',
          revokedReason: DelegationRevokeReason.ownerManual,
        ),
        throwsStateError,
      );
    });

    test('getActiveForDelegatee filters by delegatee_member_id', () async {
      final repo = MockAcademyDelegationRepository();
      final d = await repo.create(
        academyId: 'a1',
        delegatorUserId: 'o1',
        delegateeMemberId: 'm1',
        permissions: const ['inbox.reply'],
        startsAt: DateTime(2026, 6, 5),
        endsAt: DateTime(2026, 6, 7),
        reason: DelegationReason.trip,
      );
      expect(await repo.getActiveForDelegatee('m1'), equals(d));
      expect(await repo.getActiveForDelegatee('m_other'), isNull);
    });

    test('listActions returns desc by performedAt', () async {
      final repo = MockAcademyDelegationRepository();
      final early = AcademyDelegationAction(
        id: 'a_early',
        delegationId: 'd1',
        performedAt: DateTime(2026, 6, 5, 10),
        performedByUserId: 'u',
        permissionUsed: 'inbox.reply',
        endpoint: 'POST /inbox',
        responseStatus: 200,
      );
      final late = early.copyWith(
        id: 'a_late',
        performedAt: DateTime(2026, 6, 5, 12),
      );
      repo.addAction(early);
      repo.addAction(late);

      final result = await repo.listActions('d1');
      expect(result.map((a) => a.id).toList(), equals(['a_late', 'a_early']));
    });

    test(
      'markActionReviewed sets ownerReviewedAt + optional disputeNote',
      () async {
        final repo = MockAcademyDelegationRepository();
        repo.addAction(
          AcademyDelegationAction(
            id: 'a1',
            delegationId: 'd1',
            performedAt: DateTime(2026, 6, 5, 10),
            performedByUserId: 'u',
            permissionUsed: 'inbox.reply',
            endpoint: 'POST /inbox',
            responseStatus: 200,
          ),
        );
        final reviewed = await repo.markActionReviewed(
          actionId: 'a1',
          disputeNote: 'wrong recipient',
        );
        expect(reviewed.ownerReviewedAt, isNotNull);
        expect(reviewed.ownerDisputeNote, equals('wrong recipient'));
        expect(reviewed.isReviewed, isTrue);
        expect(reviewed.isDisputed, isTrue);
      },
    );
  });
}
