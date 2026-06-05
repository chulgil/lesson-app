import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/academy/domain/entities/entities.dart';

void main() {
  group('Academy Entity', () {
    test('should create Academy with all fields', () {
      final now = DateTime.now();
      const id = 'acad_1';
      const slug = 'oo-music-academy';
      const name = 'OO음악학원';
      const address = '서울시 강남구';
      const ownerUserId = 'owner_1';

      final academy = Academy(
        id: id,
        slug: slug,
        name: name,
        address: address,
        ownerUserId: ownerUserId,
        createdAt: now,
      );

      expect(academy.id, equals(id));
      expect(academy.slug, equals(slug));
      expect(academy.name, equals(name));
      expect(academy.address, equals(address));
      expect(academy.ownerUserId, equals(ownerUserId));
      expect(academy.createdAt, equals(now));
    });

    test('should support copyWith', () {
      final now = DateTime.now();
      final academy = Academy(
        id: 'acad_1',
        slug: 'old-slug',
        name: 'Old Name',
        ownerUserId: 'owner_1',
        createdAt: now,
      );

      final updated = academy.copyWith(name: 'New Name', address: '새 주소');

      expect(updated.id, equals(academy.id));
      expect(updated.slug, equals(academy.slug));
      expect(updated.name, equals('New Name'));
      expect(updated.address, equals('새 주소'));
      expect(updated.ownerUserId, equals(academy.ownerUserId));
      expect(updated.createdAt, equals(academy.createdAt));
    });

    test('should support equality comparison', () {
      final now = DateTime.now();
      final academy1 = Academy(
        id: 'acad_1',
        slug: 'test-slug',
        name: 'Test Academy',
        ownerUserId: 'owner_1',
        createdAt: now,
      );

      final academy2 = Academy(
        id: 'acad_1',
        slug: 'test-slug',
        name: 'Test Academy',
        ownerUserId: 'owner_1',
        createdAt: now,
      );

      expect(academy1, equals(academy2));
      expect(academy1.hashCode, equals(academy2.hashCode));
    });
  });

  group('AcademyMember Entity', () {
    test('should create AcademyMember with all fields', () {
      final now = DateTime.now();
      final onboardingUntil = now.add(const Duration(days: 30));

      final member = AcademyMember(
        id: 'member_1',
        academyId: 'acad_1',
        userId: 'user_1',
        role: AcademyMemberRole.teacher,
        publicPageConsent: true,
        onboardingUntil: onboardingUntil,
        createdAt: now,
      );

      expect(member.id, equals('member_1'));
      expect(member.academyId, equals('acad_1'));
      expect(member.userId, equals('user_1'));
      expect(member.role, equals(AcademyMemberRole.teacher));
      expect(member.publicPageConsent, isTrue);
      expect(member.onboardingUntil, equals(onboardingUntil));
      expect(member.createdAt, equals(now));
    });

    test('should support copyWith', () {
      final now = DateTime.now();
      final member = AcademyMember(
        id: 'member_1',
        academyId: 'acad_1',
        userId: 'user_1',
        role: AcademyMemberRole.teacher,
        publicPageConsent: false,
        createdAt: now,
      );

      final updated = member.copyWith(publicPageConsent: true);

      expect(updated.id, equals(member.id));
      expect(updated.publicPageConsent, isTrue);
      expect(updated.role, equals(member.role));
    });

    test('isOnboarding should return true when onboarding_until is future', () {
      final now = DateTime.now();
      final futureDate = now.add(const Duration(days: 10));

      final member = AcademyMember(
        id: 'member_1',
        academyId: 'acad_1',
        userId: 'user_1',
        role: AcademyMemberRole.teacher,
        onboardingUntil: futureDate,
        createdAt: now,
      );

      expect(member.isOnboarding, isTrue);
    });

    test('isOnboarding should return false when onboarding_until is past', () {
      final now = DateTime.now();
      final pastDate = now.subtract(const Duration(days: 10));

      final member = AcademyMember(
        id: 'member_1',
        academyId: 'acad_1',
        userId: 'user_1',
        role: AcademyMemberRole.teacher,
        onboardingUntil: pastDate,
        createdAt: now,
      );

      expect(member.isOnboarding, isFalse);
    });

    test('isOnboarding should return false when onboarding_until is null', () {
      final now = DateTime.now();

      final member = AcademyMember(
        id: 'member_1',
        academyId: 'acad_1',
        userId: 'user_1',
        role: AcademyMemberRole.teacher,
        createdAt: now,
      );

      expect(member.isOnboarding, isFalse);
    });

    test('access revocation fields default to inactive', () {
      final now = DateTime.now();
      final member = AcademyMember(
        id: 'member_1',
        academyId: 'acad_1',
        userId: 'user_1',
        role: AcademyMemberRole.teacher,
        createdAt: now,
      );

      expect(member.accessRevokedAt, isNull);
      expect(member.isAccessRevoked, isFalse);
      expect(member.delegateRole, equals('none'));
      expect(member.delegateRoleGrantedAt, isNull);
      expect(member.isTrustedSubstitute, isFalse);
    });

    test('isAccessRevoked is true when accessRevokedAt is set', () {
      final now = DateTime.now();
      final member = AcademyMember(
        id: 'member_1',
        academyId: 'acad_1',
        userId: 'user_1',
        role: AcademyMemberRole.teacher,
        createdAt: now,
        accessRevokedAt: now.subtract(const Duration(days: 30)),
      );

      expect(member.isAccessRevoked, isTrue);
    });

    test('isTrustedSubstitute is true for trusted_substitute role', () {
      final now = DateTime.now();
      final member = AcademyMember(
        id: 'member_1',
        academyId: 'acad_1',
        userId: 'user_1',
        role: AcademyMemberRole.teacher,
        createdAt: now,
        delegateRole: 'trusted_substitute',
        delegateRoleGrantedAt: now,
      );

      expect(member.isTrustedSubstitute, isTrue);
      expect(member.delegateRoleGrantedAt, equals(now));
    });

    test('copyWith preserves new fields', () {
      final now = DateTime.now();
      final granted = now.subtract(const Duration(days: 5));
      final member = AcademyMember(
        id: 'member_1',
        academyId: 'acad_1',
        userId: 'user_1',
        role: AcademyMemberRole.teacher,
        createdAt: now,
        delegateRole: 'trusted_substitute',
        delegateRoleGrantedAt: granted,
      );

      final updated = member.copyWith(publicPageConsent: true);

      expect(updated.delegateRole, equals('trusted_substitute'));
      expect(updated.delegateRoleGrantedAt, equals(granted));
      expect(updated.publicPageConsent, isTrue);
    });

    test('equality covers new fields', () {
      final now = DateTime.now();
      final revoked = now.subtract(const Duration(days: 10));

      final member1 = AcademyMember(
        id: 'member_1',
        academyId: 'acad_1',
        userId: 'user_1',
        role: AcademyMemberRole.teacher,
        createdAt: now,
        accessRevokedAt: revoked,
      );
      final member2 = AcademyMember(
        id: 'member_1',
        academyId: 'acad_1',
        userId: 'user_1',
        role: AcademyMemberRole.teacher,
        createdAt: now,
        accessRevokedAt: revoked,
      );
      final member3 = member1.copyWith(accessRevokedAt: now);

      expect(member1, equals(member2));
      expect(member1.hashCode, equals(member2.hashCode));
      expect(member1, isNot(equals(member3)));
    });
  });

  group('AcademyStudent Entity', () {
    test('should create AcademyStudent with all fields', () {
      final now = DateTime.now();
      final matchedAt = now.subtract(const Duration(days: 10));

      final student = AcademyStudent(
        id: 'student_1',
        academyId: 'acad_1',
        studentUserId: 'user_student_1',
        parentUserId: 'user_parent_1',
        teacherMemberId: 'member_1',
        name: 'Test Student',
        instrument: 'Piano',
        status: AcademyStudentStatus.active,
        registeredAt: now,
        matchedAt: matchedAt,
      );

      expect(student.id, equals('student_1'));
      expect(student.academyId, equals('acad_1'));
      expect(student.studentUserId, equals('user_student_1'));
      expect(student.parentUserId, equals('user_parent_1'));
      expect(student.teacherMemberId, equals('member_1'));
      expect(student.name, equals('Test Student'));
      expect(student.instrument, equals('Piano'));
      expect(student.status, equals(AcademyStudentStatus.active));
      expect(student.registeredAt, equals(now));
      expect(student.matchedAt, equals(matchedAt));
    });

    test('should support copyWith', () {
      final now = DateTime.now();
      final student = AcademyStudent(
        id: 'student_1',
        academyId: 'acad_1',
        name: 'Old Name',
        status: AcademyStudentStatus.waiting,
        registeredAt: now,
      );

      final updated = student.copyWith(
        name: 'New Name',
        status: AcademyStudentStatus.matched,
      );

      expect(updated.id, equals(student.id));
      expect(updated.name, equals('New Name'));
      expect(updated.status, equals(AcademyStudentStatus.matched));
      expect(updated.academyId, equals(student.academyId));
    });

    test('should support equality comparison', () {
      final now = DateTime.now();
      final student1 = AcademyStudent(
        id: 'student_1',
        academyId: 'acad_1',
        name: 'Test',
        status: AcademyStudentStatus.active,
        registeredAt: now,
      );

      final student2 = AcademyStudent(
        id: 'student_1',
        academyId: 'acad_1',
        name: 'Test',
        status: AcademyStudentStatus.active,
        registeredAt: now,
      );

      expect(student1, equals(student2));
      expect(student1.hashCode, equals(student2.hashCode));
    });

    test('AC-M1 follow-on fields default to null', () {
      final now = DateTime.now();
      final student = AcademyStudent(
        id: 'student_1',
        academyId: 'acad_1',
        name: 'Test',
        status: AcademyStudentStatus.waiting,
        registeredAt: now,
      );

      expect(student.statusChangedAt, isNull);
      expect(student.intakeNotes, isNull);
      expect(student.depositCode, isNull);
    });

    test('AC-M1 follow-on fields round-trip via copyWith', () {
      final now = DateTime.now();
      final statusChanged = now.subtract(const Duration(days: 2));
      final student = AcademyStudent(
        id: 'student_1',
        academyId: 'acad_1',
        name: 'Test',
        status: AcademyStudentStatus.active,
        registeredAt: now,
        statusChangedAt: statusChanged,
        intakeNotes: '초등 4학년, 부모님 연락 010-xxxx-xxxx',
        depositCode: 'A042',
      );

      final updated = student.copyWith(
        status: AcademyStudentStatus.paused,
        statusChangedAt: now,
      );

      expect(updated.statusChangedAt, equals(now));
      expect(updated.intakeNotes, equals(student.intakeNotes));
      expect(updated.depositCode, equals('A042'));
    });

    test('equality covers AC-M1 follow-on fields', () {
      final now = DateTime.now();
      final a = AcademyStudent(
        id: 'student_1',
        academyId: 'acad_1',
        name: 'Test',
        status: AcademyStudentStatus.active,
        registeredAt: now,
        depositCode: 'B021',
      );
      final b = AcademyStudent(
        id: 'student_1',
        academyId: 'acad_1',
        name: 'Test',
        status: AcademyStudentStatus.active,
        registeredAt: now,
        depositCode: 'B021',
      );
      final c = a.copyWith(depositCode: 'B022');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  group('AcademySubscription Entity', () {
    test('should create AcademySubscription with all fields', () {
      final now = DateTime.now();

      final subscription = AcademySubscription(
        id: 'sub_1',
        academyId: 'acad_1',
        subscriptionId: 'subscription_1',
        studentId: 'student_1',
        teacherMemberId: 'member_1',
        ownership: SubscriptionOwnership.academy,
        cancellationDeadlineHours: 24,
        studentCompensationExtraMinutesEnabled: true,
        includeExtraMinutesTextOnLateCancel: false,
        studentCompensationExtraMinutesMessage: 'Test message',
        notifyOwnerOnLateCancel: true,
        createdAt: now,
        createdByUserId: 'owner_1',
      );

      expect(subscription.id, equals('sub_1'));
      expect(subscription.academyId, equals('acad_1'));
      expect(subscription.subscriptionId, equals('subscription_1'));
      expect(subscription.studentId, equals('student_1'));
      expect(subscription.createdByUserId, equals('owner_1'));
      expect(subscription.teacherMemberId, equals('member_1'));
      expect(subscription.ownership, equals(SubscriptionOwnership.academy));
      expect(subscription.cancellationDeadlineHours, equals(24));
      expect(subscription.studentCompensationExtraMinutesEnabled, isTrue);
      expect(subscription.includeExtraMinutesTextOnLateCancel, isFalse);
      expect(
        subscription.studentCompensationExtraMinutesMessage,
        equals('Test message'),
      );
      expect(subscription.notifyOwnerOnLateCancel, isTrue);
      expect(subscription.createdAt, equals(now));
    });

    test('should use default values for optional fields', () {
      final now = DateTime.now();

      final subscription = AcademySubscription(
        id: 'sub_1',
        academyId: 'acad_1',
        subscriptionId: 'subscription_1',
        studentId: 'student_1',
        teacherMemberId: 'member_1',
        ownership: SubscriptionOwnership.teacher,
        createdAt: now,
      );

      expect(subscription.cancellationDeadlineHours, equals(12));
      expect(subscription.studentCompensationExtraMinutesEnabled, isTrue);
      expect(subscription.includeExtraMinutesTextOnLateCancel, isTrue);
      expect(subscription.studentCompensationExtraMinutesMessage, isNull);
      expect(subscription.notifyOwnerOnLateCancel, isTrue);
      expect(subscription.createdByUserId, isNull);
    });

    test('assert: cancellationDeadlineHours must be in 0..168', () {
      expect(
        () => AcademySubscription(
          id: 'x',
          academyId: 'a',
          subscriptionId: 's',
          studentId: 'st',
          teacherMemberId: 'm',
          ownership: SubscriptionOwnership.academy,
          cancellationDeadlineHours: 169,
          createdAt: DateTime.now(),
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => AcademySubscription(
          id: 'x',
          academyId: 'a',
          subscriptionId: 's',
          studentId: 'st',
          teacherMemberId: 'm',
          ownership: SubscriptionOwnership.academy,
          cancellationDeadlineHours: -1,
          createdAt: DateTime.now(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('subscriptionId 변경 시 equality 깨짐', () {
      final now = DateTime.now();
      final a = AcademySubscription(
        id: 'sub_1',
        academyId: 'acad_1',
        subscriptionId: 'subscription_1',
        studentId: 'student_1',
        teacherMemberId: 'member_1',
        ownership: SubscriptionOwnership.academy,
        createdAt: now,
      );
      final b = a.copyWith(subscriptionId: 'subscription_2');
      expect(a, isNot(equals(b)));
    });

    test('createdByUserId 변경 시 equality 깨짐', () {
      final now = DateTime.now();
      final a = AcademySubscription(
        id: 'sub_1',
        academyId: 'acad_1',
        subscriptionId: 'subscription_1',
        studentId: 'student_1',
        teacherMemberId: 'member_1',
        ownership: SubscriptionOwnership.academy,
        createdAt: now,
        createdByUserId: 'owner_1',
      );
      final b = a.copyWith(createdByUserId: 'owner_2');
      expect(a, isNot(equals(b)));
    });

    test('should support copyWith', () {
      final now = DateTime.now();
      final subscription = AcademySubscription(
        id: 'sub_1',
        academyId: 'acad_1',
        subscriptionId: 'subscription_1',
        studentId: 'student_1',
        teacherMemberId: 'member_1',
        ownership: SubscriptionOwnership.academy,
        cancellationDeadlineHours: 12,
        createdAt: now,
      );

      final updated = subscription.copyWith(
        cancellationDeadlineHours: 24,
        ownership: SubscriptionOwnership.teacher,
      );

      expect(updated.id, equals(subscription.id));
      expect(updated.cancellationDeadlineHours, equals(24));
      expect(updated.ownership, equals(SubscriptionOwnership.teacher));
      expect(updated.academyId, equals(subscription.academyId));
    });

    test('should support equality comparison', () {
      final now = DateTime.now();
      final sub1 = AcademySubscription(
        id: 'sub_1',
        academyId: 'acad_1',
        subscriptionId: 'subscription_1',
        studentId: 'student_1',
        teacherMemberId: 'member_1',
        ownership: SubscriptionOwnership.academy,
        createdAt: now,
      );

      final sub2 = AcademySubscription(
        id: 'sub_1',
        academyId: 'acad_1',
        subscriptionId: 'subscription_1',
        studentId: 'student_1',
        teacherMemberId: 'member_1',
        ownership: SubscriptionOwnership.academy,
        createdAt: now,
      );

      expect(sub1, equals(sub2));
      expect(sub1.hashCode, equals(sub2.hashCode));
    });
  });
}
