import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/academy/data/repositories/mock_academy_repository.dart';
import 'package:lessonaza/features/academy/data/repositories/mock_academy_member_repository.dart';
import 'package:lessonaza/features/academy/data/repositories/mock_academy_subscription_repository.dart';
import 'package:lessonaza/features/academy/domain/entities/academy_enums.dart';
import 'package:lessonaza/features/academy/domain/entities/academy_member.dart';

void main() {
  group('MockAcademyRepository', () {
    late MockAcademyRepository repository;

    setUp(() {
      repository = MockAcademyRepository();
    });

    test('should return academy by ID', () async {
      final academy = await repository.getById('acad_1');

      expect(academy, isNotNull);
      expect(academy!.id, equals('acad_1'));
      expect(academy.slug, equals('oo-music-academy'));
      expect(academy.name, equals('OO음악학원'));
      expect(academy.address, equals('서울시 강남구'));
      expect(academy.ownerUserId, equals('owner_1'));
    });

    test('should return null for non-existent academy', () async {
      final academy = await repository.getById('non-existent');

      expect(academy, isNull);
    });

    test('should list all members of academy', () async {
      final members = await repository.listMembers('acad_1');

      expect(members.length, equals(2));
      expect(members[0].academyId, equals('acad_1'));
      expect(members[0].role, equals(AcademyMemberRole.owner));
      expect(members[1].academyId, equals('acad_1'));
      expect(members[1].role, equals(AcademyMemberRole.teacher));
    });

    test('should return empty list for non-existent academy members', () async {
      final members = await repository.listMembers('non-existent');

      expect(members, isEmpty);
    });

    test('should list all students of academy', () async {
      final students = await repository.listStudents('acad_1');

      expect(students.length, equals(4));
      expect(students[0].academyId, equals('acad_1'));
      expect(students[0].name, equals('김학생'));
    });

    test(
      'should return empty list for non-existent academy students',
      () async {
        final students = await repository.listStudents('non-existent');

        expect(students, isEmpty);
      },
    );

    test('should have 3 academies with proper names', () async {
      final acad1 = await repository.getById('acad_1');
      final acad2 = await repository.getById('acad_2');
      final acad3 = await repository.getById('acad_3');

      expect(acad1!.name, equals('OO음악학원'));
      expect(acad2!.name, equals('XX피아노학원'));
      expect(acad3!.name, equals('재즈스튜디오'));
    });

    test('should have 6 members total (2 per academy)', () async {
      final members1 = await repository.listMembers('acad_1');
      final members2 = await repository.listMembers('acad_2');
      final members3 = await repository.listMembers('acad_3');

      expect(members1.length, equals(2));
      expect(members2.length, equals(2));
      expect(members3.length, equals(2));
    });

    test('should have 12 students total (4 per academy)', () async {
      final students1 = await repository.listStudents('acad_1');
      final students2 = await repository.listStudents('acad_2');
      final students3 = await repository.listStudents('acad_3');

      expect(students1.length, equals(4));
      expect(students2.length, equals(4));
      expect(students3.length, equals(4));
    });

    test('should have students in different statuses', () async {
      final students = await repository.listStudents('acad_1');

      final statuses = students.map((s) => s.status).toSet();
      expect(statuses.length, greaterThan(1));
    });

    test('should have teacher member with onboarding_until', () async {
      final members = await repository.listMembers('acad_2');
      final teacher = members.firstWhere(
        (m) => m.role == AcademyMemberRole.teacher,
      );

      expect(teacher.onboardingUntil, isNotNull);
    });
  });

  group('MockAcademyMemberRepository', () {
    late MockAcademyMemberRepository repository;

    setUp(() {
      repository = MockAcademyMemberRepository();
    });

    test('should accept invite with valid token', () async {
      final member = _createTestMember();
      repository.addPendingInvite('member_1', 'test_token_123', member);

      final result = await repository.acceptInvite(
        'test_token_123',
        publicPageConsent: true,
      );

      expect(result.id, equals('member_1'));
      expect(result.publicPageConsent, isTrue);
    });

    test('should throw on invalid token', () async {
      expect(
        () => repository.acceptInvite('invalid_token', publicPageConsent: true),
        throwsException,
      );
    });

    test('should reject invite with valid token', () async {
      final member = _createTestMember();
      repository.addPendingInvite('member_1', 'test_token_123', member);

      await repository.rejectInvite('test_token_123');

      expect(repository.getMember('member_1'), isNull);
    });

    test('should throw on invalid token when rejecting', () async {
      expect(() => repository.rejectInvite('invalid_token'), throwsException);
    });

    test('should update visibility for existing member', () async {
      final member = _createTestMember();
      repository.addPendingInvite('member_1', 'test_token_123', member);

      // First accept
      await repository.acceptInvite('test_token_123', publicPageConsent: false);

      // Then update visibility
      await repository.updateVisibility('member_1', publicPageConsent: true);

      final updated = repository.getMember('member_1');
      expect(updated!.publicPageConsent, isTrue);
    });

    test(
      'should throw when updating visibility for non-existent member',
      () async {
        expect(
          () => repository.updateVisibility(
            'non_existent',
            publicPageConsent: true,
          ),
          throwsException,
        );
      },
    );
  });

  group('MockAcademySubscriptionRepository', () {
    late MockAcademySubscriptionRepository repository;

    setUp(() {
      repository = MockAcademySubscriptionRepository();
    });

    test('should get subscription by ID', () async {
      final subscription = await repository.getById('sub_1');

      expect(subscription, isNotNull);
      expect(subscription!.id, equals('sub_1'));
      expect(subscription.studentId, equals('student_1'));
      expect(subscription.ownership, equals(SubscriptionOwnership.academy));
    });

    test('should return null for non-existent subscription', () async {
      final subscription = await repository.getById('non_existent');

      expect(subscription, isNull);
    });

    test('should list subscriptions for student', () async {
      final subscriptions = await repository.listByStudent('student_1');

      expect(subscriptions.isNotEmpty, isTrue);
      expect(subscriptions.every((s) => s.studentId == 'student_1'), isTrue);
    });

    test(
      'should return empty list for student with no subscriptions',
      () async {
        final subscriptions = await repository.listByStudent('non_existent');

        expect(subscriptions, isEmpty);
      },
    );

    test('should have 8 total subscriptions (6 academy + 2 teacher)', () async {
      final sub1 = await repository.getById('sub_1');
      final sub2 = await repository.getById('sub_2');
      final sub3 = await repository.getById('sub_3');
      final sub4 = await repository.getById('sub_4');
      final sub5 = await repository.getById('sub_5');
      final sub6 = await repository.getById('sub_6');
      final sub7 = await repository.getById('sub_7');
      final sub8 = await repository.getById('sub_8');

      expect(sub1, isNotNull);
      expect(sub2, isNotNull);
      expect(sub3, isNotNull);
      expect(sub4, isNotNull);
      expect(sub5, isNotNull);
      expect(sub6, isNotNull);
      expect(sub7, isNotNull);
      expect(sub8, isNotNull);
    });

    test('should have subscriptions with academy ownership', () async {
      final subscription = await repository.getById('sub_1');

      expect(subscription!.ownership, equals(SubscriptionOwnership.academy));
      expect(subscription.notifyOwnerOnLateCancel, isTrue);
    });

    test('should have subscriptions with teacher ownership', () async {
      final subscription = await repository.getById('sub_7');

      expect(subscription!.ownership, equals(SubscriptionOwnership.teacher));
    });

    test('should support different cancellation deadline hours', () async {
      final sub1 = await repository.getById('sub_1');
      final sub2 = await repository.getById('sub_2');

      expect(sub1!.cancellationDeadlineHours, equals(12));
      expect(sub2!.cancellationDeadlineHours, equals(24));
    });
  });
}

// Helper function to create test member
AcademyMember _createTestMember() {
  return AcademyMember(
    id: 'member_1',
    academyId: 'acad_1',
    userId: 'user_1',
    role: AcademyMemberRole.teacher,
    publicPageConsent: false,
    createdAt: DateTime.now(),
  );
}
