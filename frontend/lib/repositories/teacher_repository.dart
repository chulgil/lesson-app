import '../models/teacher.dart';

/// Repository interface for teacher data
abstract class TeacherRepository {
  /// Get all teachers
  Future<List<Teacher>> getAllTeachers();

  /// Get teacher by ID
  Future<Teacher?> getTeacherById(String id);

  /// Search teachers by filter
  Future<List<Teacher>> searchTeachers(TeacherFilter filter);

  /// Get teachers by instrument
  Future<List<Teacher>> getTeachersByInstrument(String instrument);

  /// Get featured/recommended teachers
  Future<List<Teacher>> getFeaturedTeachers();
}

/// Mock implementation of TeacherRepository
class MockTeacherRepository implements TeacherRepository {
  final List<Teacher> _teachers = _generateMockTeachers();

  @override
  Future<List<Teacher>> getAllTeachers() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_teachers);
  }

  @override
  Future<Teacher?> getTeacherById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _teachers.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Teacher>> searchTeachers(TeacherFilter filter) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _teachers.where((t) => filter.matches(t)).toList();
  }

  @override
  Future<List<Teacher>> getTeachersByInstrument(String instrument) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _teachers.where((t) => t.instruments.contains(instrument)).toList();
  }

  @override
  Future<List<Teacher>> getFeaturedTeachers() async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Return teachers with highest ratings
    final sorted = List<Teacher>.from(_teachers)
      ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
    return sorted.take(5).toList();
  }
}

List<Teacher> _generateMockTeachers() {
  final now = DateTime.now();
  return [
    Teacher(
      id: 'teacher_1',
      name: '김선생님',
      instruments: ['바이올린', '비올라'],
      bio: '서울대학교 음악대학 졸업 후 15년간 바이올린을 가르치고 있습니다. '
          '초보자부터 전공생까지 다양한 학생들을 지도한 경험이 있으며, '
          '학생 개개인의 수준과 목표에 맞춘 맞춤형 레슨을 제공합니다.',
      education: '서울대학교 음악대학 졸업',
      experienceYears: 15,
      rating: 4.9,
      reviewCount: 128,
      trialLessonFee: 30000,
      regularLessonFee: 60000,
      location: '서울 강남구',
      isAvailable: true,
      createdAt: now.subtract(const Duration(days: 365 * 3)),
    ),
    Teacher(
      id: 'teacher_2',
      name: '박선생님',
      instruments: ['피아노'],
      bio: '독일 뮌헨 음대에서 피아노를 전공했습니다. '
          '클래식부터 재즈까지 다양한 장르의 피아노 레슨이 가능합니다. '
          '어린이부터 성인까지 체계적인 커리큘럼으로 지도합니다.',
      education: '독일 뮌헨 음대 석사',
      experienceYears: 12,
      rating: 4.8,
      reviewCount: 95,
      trialLessonFee: 35000,
      regularLessonFee: 70000,
      location: '서울 서초구',
      isAvailable: true,
      createdAt: now.subtract(const Duration(days: 365 * 2)),
    ),
    Teacher(
      id: 'teacher_3',
      name: '이선생님',
      instruments: ['첼로'],
      bio: '한국예술종합학교 음악원 졸업 후 오케스트라 단원으로 활동하며 '
          '레슨을 병행하고 있습니다. 탄탄한 기본기와 음악적 표현력을 '
          '함께 키워드리겠습니다.',
      education: '한국예술종합학교 졸업',
      experienceYears: 8,
      rating: 4.7,
      reviewCount: 67,
      trialLessonFee: 30000,
      regularLessonFee: 55000,
      location: '서울 마포구',
      isAvailable: true,
      createdAt: now.subtract(const Duration(days: 365)),
    ),
    Teacher(
      id: 'teacher_4',
      name: '최선생님',
      instruments: ['바이올린'],
      bio: '연세대학교 음대 졸업, 전문 교육자로서 10년 이상의 경력을 가지고 있습니다. '
          '학생의 잠재력을 최대한 끌어내는 것을 목표로 합니다.',
      education: '연세대학교 음대 졸업',
      experienceYears: 10,
      rating: 4.6,
      reviewCount: 82,
      trialLessonFee: 25000,
      regularLessonFee: 50000,
      location: '서울 송파구',
      isAvailable: true,
      createdAt: now.subtract(const Duration(days: 500)),
    ),
    Teacher(
      id: 'teacher_5',
      name: '정선생님',
      instruments: ['플루트', '클라리넷'],
      bio: '관악기 전문 교육자입니다. 호흡법부터 테크닉까지 '
          '체계적으로 지도해드립니다. 앙상블 활동도 함께 진행합니다.',
      education: '이화여자대학교 음대 졸업',
      experienceYears: 7,
      rating: 4.5,
      reviewCount: 45,
      trialLessonFee: 28000,
      regularLessonFee: 52000,
      location: '서울 성북구',
      isAvailable: true,
      createdAt: now.subtract(const Duration(days: 400)),
    ),
    Teacher(
      id: 'teacher_6',
      name: '강선생님',
      instruments: ['성악'],
      bio: '이탈리아 유학 후 성악 레슨을 전문으로 하고 있습니다. '
          '발성부터 무대 매너까지 종합적인 지도가 가능합니다.',
      education: '이탈리아 밀라노 음악원',
      experienceYears: 9,
      rating: 4.8,
      reviewCount: 56,
      trialLessonFee: 40000,
      regularLessonFee: 80000,
      location: '서울 용산구',
      isAvailable: false, // Currently not accepting new students
      createdAt: now.subtract(const Duration(days: 600)),
    ),
    Teacher(
      id: 'teacher_7',
      name: '윤선생님',
      instruments: ['기타'],
      bio: '클래식 기타와 어쿠스틱 기타 모두 가르칩니다. '
          '취미반부터 입시반까지 다양한 클래스 운영 중입니다.',
      education: '경희대학교 음대 졸업',
      experienceYears: 6,
      rating: 4.4,
      reviewCount: 38,
      trialLessonFee: 25000,
      regularLessonFee: 45000,
      location: '경기도 성남시',
      isAvailable: true,
      createdAt: now.subtract(const Duration(days: 300)),
    ),
    Teacher(
      id: 'teacher_8',
      name: '한선생님',
      instruments: ['바이올린', '비올라', '작곡/이론'],
      bio: '바이올린/비올라 실기와 함께 음악이론, 화성학, 시창청음 수업도 가능합니다. '
          '입시 준비생들에게 특히 추천드립니다.',
      education: '서울대학교 음대 박사과정',
      experienceYears: 11,
      rating: 4.9,
      reviewCount: 112,
      trialLessonFee: 35000,
      regularLessonFee: 65000,
      location: '서울 관악구',
      isAvailable: true,
      createdAt: now.subtract(const Duration(days: 800)),
    ),
  ];
}
