import '../../domain/entities/academy.dart';
import '../../domain/entities/academy_member.dart';
import '../../domain/entities/academy_student.dart';
import '../../domain/entities/academy_enums.dart';
import '../../domain/repositories/academy_repository.dart';

/// Mock implementation of AcademyRepository
class MockAcademyRepository implements AcademyRepository {
  late final Map<String, Academy> _academies;
  late final Map<String, List<AcademyMember>> _membersByAcademy;
  late final Map<String, List<AcademyStudent>> _studentsByAcademy;

  MockAcademyRepository() {
    _initializeMockData();
  }

  void _initializeMockData() {
    final now = DateTime.now();

    // Initialize academies with current timestamp
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

    // Initialize members (2 per academy: 1 owner, 1 teacher)
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

    // Initialize students (4 per academy)
    _studentsByAcademy = {
      'acad_1': [
        AcademyStudent(
          id: 'student_1',
          academyId: 'acad_1',
          studentUserId: 'user_student_1',
          parentUserId: 'user_parent_1',
          teacherMemberId: 'member_2',
          name: '김학생',
          instrument: '피아노',
          status: AcademyStudentStatus.active,
          registeredAt: now.subtract(const Duration(days: 60)),
          matchedAt: now.subtract(const Duration(days: 55)),
        ),
        AcademyStudent(
          id: 'student_2',
          academyId: 'acad_1',
          studentUserId: 'user_student_2',
          parentUserId: 'user_parent_2',
          teacherMemberId: 'member_2',
          name: '이학생',
          instrument: '바이올린',
          status: AcademyStudentStatus.active,
          registeredAt: now.subtract(const Duration(days: 50)),
          matchedAt: now.subtract(const Duration(days: 45)),
        ),
        AcademyStudent(
          id: 'student_3',
          academyId: 'acad_1',
          name: '박학생',
          instrument: '성악',
          status: AcademyStudentStatus.waiting,
          registeredAt: now.subtract(const Duration(days: 10)),
        ),
        AcademyStudent(
          id: 'student_4',
          academyId: 'acad_1',
          studentUserId: 'user_student_4',
          parentUserId: 'user_parent_4',
          teacherMemberId: 'member_2',
          name: '정학생',
          instrument: '첼로',
          status: AcademyStudentStatus.paused,
          registeredAt: now.subtract(const Duration(days: 120)),
          matchedAt: now.subtract(const Duration(days: 115)),
        ),
      ],
      'acad_2': [
        AcademyStudent(
          id: 'student_5',
          academyId: 'acad_2',
          studentUserId: 'user_student_5',
          parentUserId: 'user_parent_5',
          teacherMemberId: 'member_4',
          name: '최학생',
          instrument: '피아노',
          status: AcademyStudentStatus.active,
          registeredAt: now.subtract(const Duration(days: 70)),
          matchedAt: now.subtract(const Duration(days: 65)),
        ),
        AcademyStudent(
          id: 'student_6',
          academyId: 'acad_2',
          studentUserId: 'user_student_6',
          parentUserId: 'user_parent_6',
          teacherMemberId: 'member_4',
          name: '조학생',
          instrument: '플루트',
          status: AcademyStudentStatus.active,
          registeredAt: now.subtract(const Duration(days: 40)),
          matchedAt: now.subtract(const Duration(days: 35)),
        ),
        AcademyStudent(
          id: 'student_7',
          academyId: 'acad_2',
          name: '손학생',
          instrument: '기타',
          status: AcademyStudentStatus.waiting,
          registeredAt: now.subtract(const Duration(days: 20)),
        ),
        AcademyStudent(
          id: 'student_8',
          academyId: 'acad_2',
          studentUserId: 'user_student_8',
          parentUserId: 'user_parent_8',
          teacherMemberId: 'member_4',
          name: '우학생',
          instrument: '피아노',
          status: AcademyStudentStatus.alumni,
          registeredAt: now.subtract(const Duration(days: 200)),
          matchedAt: now.subtract(const Duration(days: 195)),
        ),
      ],
      'acad_3': [
        AcademyStudent(
          id: 'student_9',
          academyId: 'acad_3',
          studentUserId: 'user_student_9',
          parentUserId: 'user_parent_9',
          teacherMemberId: 'member_6',
          name: '임학생',
          instrument: '색소폰',
          status: AcademyStudentStatus.active,
          registeredAt: now.subtract(const Duration(days: 80)),
          matchedAt: now.subtract(const Duration(days: 75)),
        ),
        AcademyStudent(
          id: 'student_10',
          academyId: 'acad_3',
          studentUserId: 'user_student_10',
          parentUserId: 'user_parent_10',
          teacherMemberId: 'member_6',
          name: '오학생',
          instrument: '드럼',
          status: AcademyStudentStatus.active,
          registeredAt: now.subtract(const Duration(days: 60)),
          matchedAt: now.subtract(const Duration(days: 55)),
        ),
        AcademyStudent(
          id: 'student_11',
          academyId: 'acad_3',
          name: '윤학생',
          instrument: '트럼펫',
          status: AcademyStudentStatus.waiting,
          registeredAt: now.subtract(const Duration(days: 5)),
        ),
        AcademyStudent(
          id: 'student_12',
          academyId: 'acad_3',
          studentUserId: 'user_student_12',
          parentUserId: 'user_parent_12',
          teacherMemberId: 'member_6',
          name: '이학생2',
          instrument: '베이스',
          status: AcademyStudentStatus.matched,
          registeredAt: now.subtract(const Duration(days: 15)),
          matchedAt: now.subtract(const Duration(days: 10)),
        ),
      ],
    };
  }

  @override
  Future<Academy?> getById(String id) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));
    return _academies[id];
  }

  @override
  Future<List<AcademyMember>> listMembers(String academyId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 150));
    return _membersByAcademy[academyId] ?? [];
  }

  @override
  Future<List<AcademyStudent>> listStudents(String academyId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 150));
    return _studentsByAcademy[academyId] ?? [];
  }
}
