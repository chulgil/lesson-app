import 'package:uuid/uuid.dart';

import '../../domain/entities/entities.dart';
import '../../domain/entities/lesson_slot.dart';
import '../../domain/repositories/student_repository.dart';

/// Mock implementation for development
class MockStudentRepository implements StudentRepository {
  final _uuid = const Uuid();
  final List<Student> _students = [];

  MockStudentRepository() {
    _initMockData();
  }

  void _initMockData() {
    final now = DateTime.now();

    _students.addAll([
      // === Active Students (5) ===

      // student_1: 장기 수강생 (2년), 수강권 다수, 주 2회 레슨
      Student(
        id: 'student_1',
        name: '김민준',
        instrument: '바이올린',
        level: StudentLevel.intermediate,
        status: StudentStatus.active,
        isActive: true,
        monthlyFee: 400000,
        lessonsPerWeek: 2,
        profileColorKey: 'paperAccent',
        createdAt: now.subtract(const Duration(days: 730)),
        phone: '010-1234-5678',
        email: 'minjun.kim@example.com',
        lessonSlots: [
          LessonSlot(dayOfWeek: 1, startTime: '16:00', endTime: '17:00'),
          LessonSlot(dayOfWeek: 4, startTime: '16:00', endTime: '17:00'),
        ],
        lessonDuration: 60,
        totalLessons: 192,
        monthlyLessons: 7,
        practiceStatus: PracticeStatus.good,
        practiceRate: 5,
        connectionStatus: ConnectionStatus.connected,
        connectedAt: now.subtract(const Duration(days: 700)),
        birthDate: DateTime(2012, 3, 15),
        practiceLevel: PracticeLevel.excellent,
        postalCode: '06141',
        address: '서울시 강남구 역삼동',
        addressDetail: '역삼아파트 101동 1201호',
        district: '강남구 역삼동',
        notes:
            '장기 수강생 (2년). 수강권 14개 보유 이력. 콩쿠르 준비 중. '
            '주 2회 레슨으로 집중 훈련.',
      ),

      // student_2: 신규 수강생 (2개월), 입문 단계
      Student(
        id: 'student_2',
        name: '이서연',
        instrument: '피아노',
        level: StudentLevel.beginner,
        status: StudentStatus.active,
        isActive: true,
        monthlyFee: 160000,
        lessonsPerWeek: 1,
        profileColorKey: 'paperAccent',
        createdAt: now.subtract(const Duration(days: 60)),
        phone: '010-2345-6789',
        email: 'seoyeon.lee@example.com',
        lessonSlots: [
          LessonSlot(dayOfWeek: 2, startTime: '15:00', endTime: '15:45'),
        ],
        lessonDuration: 45,
        totalLessons: 8,
        monthlyLessons: 4,
        practiceStatus: PracticeStatus.normal,
        practiceRate: 3,
        connectionStatus: ConnectionStatus.connected,
        connectedAt: now.subtract(const Duration(days: 58)),
        birthDate: DateTime(2015, 7, 22),
        practiceLevel: PracticeLevel.average,
        postalCode: '06035',
        address: '서울시 강남구 개포동',
        addressDetail: '개포주공 3단지 205동',
        district: '강남구 개포동',
        notes:
            '신규 수강생 (2개월). 체험 레슨 후 정규 등록. '
            '바이엘 진도 중. 집중력 좋음.',
      ),

      // student_3: 고급 학생, 멀티 악기 (첼로 메인)
      Student(
        id: 'student_3',
        name: '박지호',
        instrument: '첼로',
        level: StudentLevel.advanced,
        status: StudentStatus.active,
        isActive: true,
        monthlyFee: 280000,
        lessonsPerWeek: 1,
        profileColorKey: 'paperOk',
        createdAt: now.subtract(const Duration(days: 540)),
        phone: '010-3456-7890',
        email: 'jiho.park@example.com',
        lessonSlots: [
          LessonSlot(dayOfWeek: 5, startTime: '10:00', endTime: '11:30'),
        ],
        lessonDuration: 90,
        totalLessons: 72,
        monthlyLessons: 4,
        practiceStatus: PracticeStatus.good,
        practiceRate: 6,
        connectionStatus: ConnectionStatus.connected,
        connectedAt: now.subtract(const Duration(days: 500)),
        birthDate: DateTime(2008, 11, 3),
        practiceLevel: PracticeLevel.excellent,
        notes:
            '고급 학생. 첼로 메인 + 피아노 부전공. '
            '음대 입시 준비 중. 90분 레슨.',
      ),

      // student_4: 체험 레슨 단계
      Student(
        id: 'student_4',
        name: '최유진',
        instrument: '플루트',
        level: StudentLevel.beginner,
        status: StudentStatus.trial,
        isActive: true,
        monthlyFee: 160000,
        lessonsPerWeek: 1,
        profileColorKey: 'ink',
        createdAt: now.subtract(const Duration(days: 5)),
        phone: '010-4567-8901',
        parentPhone: '010-4567-1234',
        lessonSlots: [
          LessonSlot(dayOfWeek: 3, startTime: '17:00', endTime: '17:30'),
        ],
        lessonDuration: 30,
        totalLessons: 1,
        monthlyLessons: 1,
        practiceStatus: PracticeStatus.normal,
        practiceRate: 0,
        connectionStatus: ConnectionStatus.inviteSent,
        birthDate: DateTime(2016, 5, 10),
        practiceLevel: PracticeLevel.newStudent,
        postalCode: '06524',
        address: '서울시 서초구 반포동',
        district: '서초구 반포동',
        notes:
            '체험 레슨 1회 완료. 학부모와 정규 등록 상담 예정. '
            '30분 체험 레슨 진행.',
      ),

      // student_5: 초등학생, 학부모 연결
      Student(
        id: 'student_5',
        name: '정다은',
        instrument: '바이올린',
        level: StudentLevel.elementary,
        status: StudentStatus.active,
        isActive: true,
        monthlyFee: 180000,
        lessonsPerWeek: 1,
        profileColorKey: 'profileRed',
        createdAt: now.subtract(const Duration(days: 365)),
        phone: '010-5678-9012',
        parentPhone: '010-5678-3456',
        email: 'daeun.parent@example.com',
        lessonSlots: [
          LessonSlot(dayOfWeek: 0, startTime: '16:30', endTime: '17:15'),
        ],
        lessonDuration: 45,
        totalLessons: 48,
        monthlyLessons: 4,
        practiceStatus: PracticeStatus.good,
        practiceRate: 4,
        connectionStatus: ConnectionStatus.connected,
        connectedAt: now.subtract(const Duration(days: 360)),
        birthDate: DateTime(2017, 9, 28),
        manualAgeGroup: AgeGroup.child,
        practiceLevel: PracticeLevel.average,
        notes:
            '초등학생 (3학년). 학부모 앱 연결됨. '
            '스즈키 3권 진행 중. 연습 습관 잘 잡혀 있음.',
      ),

      // === Paused Students (2) ===

      // student_6: 시험 기간 단기 휴강 (2주)
      Student(
        id: 'student_6',
        name: '한서준',
        instrument: '피아노',
        level: StudentLevel.intermediate,
        status: StudentStatus.paused,
        isActive: false,
        monthlyFee: 200000,
        lessonsPerWeek: 1,
        profileColorKey: 'profilePurple',
        createdAt: now.subtract(const Duration(days: 300)),
        phone: '010-6789-0123',
        email: 'seojun.han@example.com',
        lessonSlots: [
          LessonSlot(dayOfWeek: 2, startTime: '18:00', endTime: '19:00'),
        ],
        lessonDuration: 60,
        totalLessons: 38,
        monthlyLessons: 0,
        practiceStatus: PracticeStatus.paused,
        practiceRate: 0,
        connectionStatus: ConnectionStatus.connected,
        connectedAt: now.subtract(const Duration(days: 295)),
        birthDate: DateTime(2010, 1, 20),
        breakReason: '중간고사 시험 기간',
        expectedReturnDate: now.add(const Duration(days: 10)),
        practiceLevel: PracticeLevel.onBreak,
        notes:
            '시험 기간 단기 휴강 (2주). 3월 중순 복귀 예정. '
            '쇼팽 발라드 진도 중. 수강권 잔여 2회.',
      ),

      // student_7: 건강 이유 장기 휴강 (2개월)
      Student(
        id: 'student_7',
        name: '강하윤',
        instrument: '바이올린',
        level: StudentLevel.beginner,
        status: StudentStatus.paused,
        isActive: false,
        monthlyFee: 160000,
        lessonsPerWeek: 1,
        profileColorKey: 'profileOrange',
        createdAt: now.subtract(const Duration(days: 210)),
        phone: '010-7890-1234',
        parentPhone: '010-7890-5678',
        lessonSlots: [
          LessonSlot(dayOfWeek: 4, startTime: '15:30', endTime: '16:15'),
        ],
        lessonDuration: 45,
        totalLessons: 20,
        monthlyLessons: 0,
        practiceStatus: PracticeStatus.paused,
        practiceRate: 0,
        connectionStatus: ConnectionStatus.connected,
        connectedAt: now.subtract(const Duration(days: 200)),
        birthDate: DateTime(2014, 12, 5),
        breakReason: '손목 부상 치료',
        expectedReturnDate: now.add(const Duration(days: 45)),
        practiceLevel: PracticeLevel.onBreak,
        notes:
            '손목 부상으로 장기 휴강 (2개월). 4월 중순 복귀 예정. '
            '학부모와 주기적 연락 중. 수강권 유효기간 연장 처리 완료.',
      ),

      // === Inactive Students (3) ===

      // student_8: 졸업/수료 (2년 이력)
      Student(
        id: 'student_8',
        name: '김소연',
        instrument: '바이올린',
        level: StudentLevel.advanced,
        status: StudentStatus.inactive,
        isActive: false,
        monthlyFee: 240000,
        lessonsPerWeek: 1,
        profileColorKey: 'inkTertiary',
        createdAt: now.subtract(const Duration(days: 900)),
        updatedAt: now.subtract(const Duration(days: 60)),
        phone: '010-8901-2345',
        email: 'soyeon.kim@example.com',
        totalLessons: 96,
        practiceStatus: PracticeStatus.good,
        practiceRate: 0,
        connectionStatus: ConnectionStatus.connected,
        connectedAt: now.subtract(const Duration(days: 850)),
        birthDate: DateTime(2006, 4, 18),
        practiceLevel: PracticeLevel.excellent,
        notes:
            '수료 완료 (2년 수강). 음대 합격 후 졸업. '
            '총 96회 레슨 완료. 우수 수료생.',
      ),

      // student_9: 수강권 만료 미갱신
      Student(
        id: 'student_9',
        name: '한지민',
        instrument: '피아노',
        level: StudentLevel.beginner,
        status: StudentStatus.inactive,
        isActive: false,
        monthlyFee: 160000,
        lessonsPerWeek: 1,
        profileColorKey: 'inkTertiary',
        createdAt: now.subtract(const Duration(days: 150)),
        updatedAt: now.subtract(const Duration(days: 30)),
        phone: '010-9012-3456',
        parentPhone: '010-9012-7890',
        totalLessons: 12,
        practiceStatus: PracticeStatus.poor,
        practiceRate: 0,
        connectionStatus: ConnectionStatus.offline,
        birthDate: DateTime(2016, 8, 14),
        practiceLevel: PracticeLevel.poor,
        notes:
            '수강권 만료 후 미갱신. 3회 연락 시도했으나 응답 없음. '
            '연습 참여율 저조했음. 재등록 가능성 낮음.',
      ),

      // student_10: 다른 선생님으로 변경
      Student(
        id: 'student_10',
        name: '윤서준',
        instrument: '첼로',
        level: StudentLevel.intermediate,
        status: StudentStatus.inactive,
        isActive: false,
        monthlyFee: 200000,
        lessonsPerWeek: 1,
        profileColorKey: 'inkTertiary',
        createdAt: now.subtract(const Duration(days: 400)),
        updatedAt: now.subtract(const Duration(days: 90)),
        phone: '010-0123-4567',
        email: 'seojun.yoon@example.com',
        totalLessons: 40,
        practiceStatus: PracticeStatus.normal,
        practiceRate: 0,
        connectionStatus: ConnectionStatus.offline,
        birthDate: DateTime(2011, 6, 30),
        practiceLevel: PracticeLevel.average,
        notes:
            '다른 선생님으로 변경 (거리 문제). 총 40회 레슨. '
            '원만하게 종료. 추후 재등록 가능성 있음.',
      ),

      // === Special Cases (2) ===

      // student_11: 복수 악기 수강생 (바이올린 + 피아노)
      Student(
        id: 'student_11',
        name: '이하은',
        instrument: '바이올린, 피아노',
        level: StudentLevel.intermediate,
        status: StudentStatus.active,
        isActive: true,
        monthlyFee: 360000,
        lessonsPerWeek: 2,
        profileColorKey: 'profileTeal',
        createdAt: now.subtract(const Duration(days: 450)),
        phone: '010-1357-2468',
        parentPhone: '010-1357-9876',
        email: 'haeun.lee@example.com',
        lessonSlots: [
          LessonSlot(dayOfWeek: 0, startTime: '17:00', endTime: '18:00'),
          LessonSlot(dayOfWeek: 3, startTime: '17:00', endTime: '18:00'),
        ],
        lessonDuration: 60,
        totalLessons: 110,
        monthlyLessons: 8,
        practiceStatus: PracticeStatus.good,
        practiceRate: 5,
        connectionStatus: ConnectionStatus.connected,
        connectedAt: now.subtract(const Duration(days: 440)),
        birthDate: DateTime(2013, 2, 11),
        practiceLevel: PracticeLevel.excellent,
        notes:
            '복수 악기 수강생. 월요일 바이올린, 목요일 피아노. '
            '두 악기 모두 중급 수준. 월 수강료 36만원 (18만 x 2).',
      ),

      // student_12: 입금대기(후불) 수강권이 있는 학생
      Student(
        id: 'student_12',
        name: '박준혁',
        instrument: '바이올린',
        level: StudentLevel.beginner,
        status: StudentStatus.active,
        isActive: true,
        monthlyFee: 160000,
        lessonsPerWeek: 1,
        profileColorKey: 'paperAccent',
        createdAt: now.subtract(const Duration(days: 120)),
        phone: '010-2468-1357',
        parentPhone: '010-2468-9753',
        lessonSlots: [
          LessonSlot(dayOfWeek: 1, startTime: '17:30', endTime: '18:15'),
        ],
        lessonDuration: 45,
        totalLessons: 14,
        monthlyLessons: 3,
        practiceStatus: PracticeStatus.poor,
        practiceRate: 1,
        connectionStatus: ConnectionStatus.connected,
        connectedAt: now.subtract(const Duration(days: 115)),
        birthDate: DateTime(2015, 10, 7),
        practiceLevel: PracticeLevel.poor,
        notes:
            '입금대기(후불) 있음 (2개월분 32만원). 학부모에게 입금 안내 2회 발송. '
            '연습 참여율 저조. 동기부여 방법 논의 필요.',
      ),
    ]);
  }

  @override
  Future<List<Student>> getStudents() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_students.where((s) => s.isActive));
  }

  @override
  Future<Student?> getStudent(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _students.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Student> createStudent(Student student) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newStudent = student.copyWith(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
    );
    _students.add(newStudent);
    return newStudent;
  }

  @override
  Future<Student> updateStudent(Student student) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _students.indexWhere((s) => s.id == student.id);
    if (index == -1) {
      throw Exception('Student not found');
    }
    final updated = student.copyWith(updatedAt: DateTime.now());
    _students[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteStudent(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _students.removeWhere((s) => s.id == id);
  }

  @override
  Future<List<Student>> searchStudents(String query) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final lowerQuery = query.toLowerCase();
    return _students
        .where(
          (s) =>
              s.name.toLowerCase().contains(lowerQuery) ||
              s.instrument.toLowerCase().contains(lowerQuery),
        )
        .toList();
  }

  @override
  Future<Student> updateStudentStatus(
    String studentId,
    StudentStatus status,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _students.indexWhere((s) => s.id == studentId);
    if (index == -1) {
      throw Exception('Student not found');
    }

    // Update isActive based on status
    final isActive =
        status == StudentStatus.trial || status == StudentStatus.active;

    final updated = _students[index].copyWith(
      status: status,
      isActive: isActive,
      updatedAt: DateTime.now(),
    );
    _students[index] = updated;
    return updated;
  }

  @override
  Future<List<Student>> getStudentsByStatus(StudentStatus status) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _students.where((s) => s.status == status).toList();
  }
}
