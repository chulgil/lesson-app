import '../../domain/repositories/academy_visibility_repository.dart';
import '../../domain/entities/academy.dart';
import '../../domain/entities/academy_member.dart';
import '../../domain/entities/academy_enums.dart';

/// Mock implementation of AcademyVisibilityRepository
class MockAcademyVisibilityRepository implements AcademyVisibilityRepository {
  late final Map<String, Academy> _academies;
  late final Map<String, List<AcademyMember>> _membersByAcademy;
  late final Map<String, Map<String, bool>> _teacherConsentByAcademy;

  MockAcademyVisibilityRepository() {
    _initializeMockData();
  }

  void _initializeMockData() {
    final now = DateTime.now();

    // Initialize academies
    _academies = {
      'acad_1': Academy(
        id: 'acad_1',
        slug: 'oo-music-academy',
        name: 'OO음악학원',
        address: '서울시 강남구',
        ownerUserId: 'owner_1',
        createdAt: now.subtract(const Duration(days: 180)),
      ),
      'acad_2': Academy(
        id: 'acad_2',
        slug: 'xx-piano-academy',
        name: 'XX피아노학원',
        address: '서울시 강동구',
        ownerUserId: 'owner_2',
        createdAt: now.subtract(const Duration(days: 150)),
      ),
      'acad_3': Academy(
        id: 'acad_3',
        slug: 'jazz-studio',
        name: '재즈스튜디오',
        address: '서울시 마포구',
        ownerUserId: 'owner_3',
        createdAt: now.subtract(const Duration(days: 90)),
      ),
    };

    // Initialize members
    _membersByAcademy = {
      'acad_1': [
        AcademyMember(
          id: 'member_1',
          academyId: 'acad_1',
          userId: 'owner_1',
          role: AcademyMemberRole.owner,
          publicPageConsent: false,
          createdAt: now.subtract(const Duration(days: 180)),
        ),
        AcademyMember(
          id: 'member_2',
          academyId: 'acad_1',
          userId: 'teacher_1',
          role: AcademyMemberRole.teacher,
          publicPageConsent: true,
          createdAt: now.subtract(const Duration(days: 170)),
        ),
      ],
      'acad_2': [
        AcademyMember(
          id: 'member_3',
          academyId: 'acad_2',
          userId: 'owner_2',
          role: AcademyMemberRole.owner,
          publicPageConsent: false,
          createdAt: now.subtract(const Duration(days: 150)),
        ),
        AcademyMember(
          id: 'member_4',
          academyId: 'acad_2',
          userId: 'teacher_2',
          role: AcademyMemberRole.teacher,
          publicPageConsent: true,
          onboardingUntil: now.add(const Duration(days: 30)),
          createdAt: now.subtract(const Duration(days: 140)),
        ),
      ],
      'acad_3': [
        AcademyMember(
          id: 'member_5',
          academyId: 'acad_3',
          userId: 'owner_3',
          role: AcademyMemberRole.owner,
          publicPageConsent: false,
          createdAt: now.subtract(const Duration(days: 90)),
        ),
        AcademyMember(
          id: 'member_6',
          academyId: 'acad_3',
          userId: 'teacher_3',
          role: AcademyMemberRole.teacher,
          publicPageConsent: false,
          createdAt: now.subtract(const Duration(days: 80)),
        ),
      ],
    };

    // Initialize teacher consent states (mutable for this mock)
    _teacherConsentByAcademy = {
      'acad_1': {'teacher_1': true},
      'acad_2': {'teacher_2': true},
      'acad_3': {'teacher_3': false},
    };
  }

  @override
  Future<bool> getTeacherAcademyConsent(
    String academyId,
    String teacherId,
  ) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));
    return _teacherConsentByAcademy[academyId]?[teacherId] ?? false;
  }

  @override
  Future<bool> updateTeacherAcademyConsent(
    String academyId,
    String teacherId,
    bool consent,
  ) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 150));

    // Update the consent state
    _teacherConsentByAcademy.putIfAbsent(academyId, () => {});
    _teacherConsentByAcademy[academyId]![teacherId] = consent;

    return consent;
  }

  @override
  Future<List<TeacherAcademyMembership>> listTeacherAcademies(
    String teacherId,
  ) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 150));

    final memberships = <TeacherAcademyMembership>[];

    _membersByAcademy.forEach((academyId, members) {
      for (final member in members) {
        if (member.userId == teacherId &&
            member.role == AcademyMemberRole.teacher) {
          final academy = _academies[academyId];
          if (academy != null) {
            final consent =
                _teacherConsentByAcademy[academyId]?[teacherId] ?? false;
            memberships.add(
              TeacherAcademyMembership(
                academyId: academyId,
                academyName: academy.name,
                publicPageConsent: consent,
                actorMemberId: member.id,
              ),
            );
          }
        }
      }
    });

    return memberships;
  }
}
