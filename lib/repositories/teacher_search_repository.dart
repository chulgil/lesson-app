import '../models/teacher_profile.dart';
import '../models/teacher_search.dart';

/// Repository for searching teachers
abstract class TeacherSearchRepository {
  /// Search teachers with filter
  Future<TeacherSearchResult> searchTeachers({
    TeacherSearchFilter filter = TeacherSearchFilter.empty,
    TeacherSortOption sort = TeacherSortOption.relevance,
    int page = 0,
    int pageSize = 20,
  });

  /// Get teacher public profile by id
  Future<TeacherPublicProfile?> getTeacherPublicProfile(String teacherId);

  /// Get popular/featured teachers
  Future<List<TeacherPublicProfile>> getFeaturedTeachers({int limit = 10});

  /// Get available instruments for filtering
  Future<List<String>> getAvailableInstruments();

  /// Get available areas for filtering
  Future<List<String>> getAvailableAreas();
}

/// Mock implementation for development
class MockTeacherSearchRepository implements TeacherSearchRepository {
  // Mock teacher profiles for search
  final List<TeacherProfile> _mockTeachers = [
    TeacherProfile(
      id: 'teacher_1',
      userId: 'user_teacher_1',
      name: '김지수',
      profileImage: 'https://i.pravatar.cc/150?u=teacher1',
      instruments: ['피아노', '작곡'],
      introduction:
          '서울대학교 음악대학 피아노과 졸업 후 15년간 학생들을 가르치고 있습니다. 클래식부터 재즈까지 다양한 장르를 지도합니다.',
      experienceYears: 15,
      lessonAreas: ['서울 강남', '서울 서초', '온라인'],
      lessonTypes: [LessonType.inPerson, LessonType.online],
      feeRange: const FeeRange(minFee: 60000, maxFee: 80000, duration: 60),
      education: [
        const Education(
          school: '서울대학교',
          major: '피아노',
          degree: 'bachelor',
          graduationYear: 2008,
        ),
        const Education(
          school: '독일 베를린 예술대학교',
          major: '피아노 연주',
          degree: 'master',
          graduationYear: 2012,
        ),
      ],
      career: [
        const Career(
          organization: '세종문화회관',
          position: '공연 피아니스트',
          startYear: 2012,
          endYear: 2015,
        ),
        const Career(
          organization: '김지수 음악학원',
          position: '원장',
          startYear: 2015,
        ),
      ],
      verification: TeacherVerification(
        isPhoneVerified: true,
        phoneNumber: '010-1234-5678',
        phoneVerifiedAt: DateTime(2024, 1, 15),
        certificates: [
          Certificate(
            id: 'cert_1',
            type: CertificateType.degree,
            name: '음악학 학사',
            issuingBody: '서울대학교',
            issueDate: DateTime(2008, 2, 20),
            imageUrl: 'https://example.com/cert1.jpg',
            status: CertificateStatus.approved,
            submittedAt: DateTime(2024, 1, 20),
            reviewedAt: DateTime(2024, 1, 25),
          ),
        ],
      ),
      visibilitySettings: const ProfileVisibilitySettings(
        isSearchable: true,
        nameVisibility: ProfileVisibility.public,
        photoVisibility: ProfileVisibility.public,
        contactVisibility: ProfileVisibility.students,
        feeVisibility: ProfileVisibility.public,
        careerVisibility: ProfileVisibility.public,
        certificateVisibility: ProfileVisibility.public,
      ),
      createdAt: DateTime(2024, 1, 1),
    ),
    TeacherProfile(
      id: 'teacher_2',
      userId: 'user_teacher_2',
      name: '박현우',
      profileImage: 'https://i.pravatar.cc/150?u=teacher2',
      instruments: ['바이올린', '비올라'],
      introduction:
          '음대 재학 시절부터 꾸준히 학생들을 지도해왔습니다. 초보자도 쉽게 따라할 수 있는 맞춤형 레슨을 제공합니다.',
      experienceYears: 8,
      lessonAreas: ['서울 마포', '서울 용산', '경기 고양'],
      lessonTypes: [LessonType.inPerson, LessonType.visit],
      feeRange: const FeeRange(minFee: 50000, maxFee: 70000, duration: 60),
      education: [
        const Education(
          school: '한국예술종합학교',
          major: '바이올린',
          degree: 'bachelor',
          graduationYear: 2016,
        ),
      ],
      career: [
        const Career(
          organization: '서울시립교향악단',
          position: '객원 연주자',
          startYear: 2016,
          endYear: 2020,
        ),
        const Career(
          organization: '프리랜서',
          position: '바이올린 강사',
          startYear: 2020,
        ),
      ],
      verification: TeacherVerification(
        isPhoneVerified: true,
        phoneNumber: '010-2345-6789',
        phoneVerifiedAt: DateTime(2024, 2, 10),
        certificates: [],
      ),
      visibilitySettings: const ProfileVisibilitySettings(
        isSearchable: true,
        nameVisibility: ProfileVisibility.public,
        photoVisibility: ProfileVisibility.public,
        contactVisibility: ProfileVisibility.students,
        feeVisibility: ProfileVisibility.public,
        careerVisibility: ProfileVisibility.public,
        certificateVisibility: ProfileVisibility.public,
      ),
      createdAt: DateTime(2024, 2, 1),
    ),
    TeacherProfile(
      id: 'teacher_3',
      userId: 'user_teacher_3',
      name: '이서연',
      profileImage: 'https://i.pravatar.cc/150?u=teacher3',
      instruments: ['첼로'],
      introduction:
          '첼로의 따뜻한 음색을 사랑하며, 학생들에게 음악의 즐거움을 전하고 있습니다. 취미반부터 입시반까지 모두 환영합니다.',
      experienceYears: 10,
      lessonAreas: ['서울 송파', '서울 강동', '온라인'],
      lessonTypes: [LessonType.inPerson, LessonType.online],
      feeRange: const FeeRange(minFee: 55000, maxFee: 75000, duration: 60),
      education: [
        const Education(
          school: '연세대학교',
          major: '첼로',
          degree: 'bachelor',
          graduationYear: 2014,
        ),
        const Education(
          school: '연세대학교 대학원',
          major: '첼로 연주',
          degree: 'master',
          graduationYear: 2017,
        ),
      ],
      career: [
        const Career(
          organization: '성남시립교향악단',
          position: '첼로 수석',
          startYear: 2017,
        ),
      ],
      verification: TeacherVerification(
        isPhoneVerified: true,
        phoneNumber: '010-3456-7890',
        phoneVerifiedAt: DateTime(2024, 3, 5),
        certificates: [
          Certificate(
            id: 'cert_2',
            type: CertificateType.musicTeacher,
            name: '중등학교 정교사 2급 (음악)',
            issuingBody: '교육부',
            issueDate: DateTime(2014, 8, 30),
            imageUrl: 'https://example.com/cert2.jpg',
            status: CertificateStatus.approved,
            submittedAt: DateTime(2024, 3, 10),
            reviewedAt: DateTime(2024, 3, 15),
          ),
        ],
      ),
      visibilitySettings: const ProfileVisibilitySettings(
        isSearchable: true,
        nameVisibility: ProfileVisibility.public,
        photoVisibility: ProfileVisibility.public,
        contactVisibility: ProfileVisibility.students,
        feeVisibility: ProfileVisibility.public,
        careerVisibility: ProfileVisibility.public,
        certificateVisibility: ProfileVisibility.public,
      ),
      createdAt: DateTime(2024, 3, 1),
    ),
    TeacherProfile(
      id: 'teacher_4',
      userId: 'user_teacher_4',
      name: '정민호',
      profileImage: 'https://i.pravatar.cc/150?u=teacher4',
      instruments: ['기타', '우쿨렐레', '베이스'],
      introduction:
          '기타 하나로 세상의 모든 음악을 연주해보세요! 팝, 록, 재즈, 핑거스타일까지 다양하게 배울 수 있습니다.',
      experienceYears: 12,
      lessonAreas: ['서울 홍대', '서울 신촌', '온라인'],
      lessonTypes: [LessonType.inPerson, LessonType.online],
      feeRange: const FeeRange(minFee: 40000, maxFee: 60000, duration: 60),
      education: [
        const Education(
          school: 'MI(Musicians Institute)',
          major: 'Guitar Performance',
          degree: 'certificate',
          graduationYear: 2011,
        ),
      ],
      career: [
        const Career(
          organization: '실용음악학원',
          position: '기타 강사',
          startYear: 2011,
          endYear: 2018,
        ),
        const Career(
          organization: '정민호 기타 스튜디오',
          position: '대표',
          startYear: 2018,
        ),
      ],
      verification: TeacherVerification(
        isPhoneVerified: true,
        phoneNumber: '010-4567-8901',
        phoneVerifiedAt: DateTime(2024, 4, 1),
        certificates: [],
      ),
      visibilitySettings: const ProfileVisibilitySettings(
        isSearchable: true,
        nameVisibility: ProfileVisibility.public,
        photoVisibility: ProfileVisibility.public,
        contactVisibility: ProfileVisibility.students,
        feeVisibility: ProfileVisibility.public,
        careerVisibility: ProfileVisibility.public,
        certificateVisibility: ProfileVisibility.public,
      ),
      createdAt: DateTime(2024, 4, 1),
    ),
    TeacherProfile(
      id: 'teacher_5',
      userId: 'user_teacher_5',
      name: '최유진',
      profileImage: 'https://i.pravatar.cc/150?u=teacher5',
      instruments: ['플룻', '리코더'],
      introduction:
          '관악기의 맑고 청아한 소리를 함께 배워보세요. 호흡부터 테크닉까지 체계적으로 지도합니다.',
      experienceYears: 6,
      lessonAreas: ['경기 분당', '경기 수원', '온라인'],
      lessonTypes: [LessonType.inPerson, LessonType.online, LessonType.visit],
      feeRange: const FeeRange(minFee: 45000, maxFee: 65000, duration: 60),
      education: [
        const Education(
          school: '경희대학교',
          major: '플룻',
          degree: 'bachelor',
          graduationYear: 2018,
        ),
      ],
      career: [
        const Career(
          organization: '경기필하모닉',
          position: '플룻 단원',
          startYear: 2018,
        ),
      ],
      verification: TeacherVerification(
        isPhoneVerified: true,
        phoneNumber: '010-5678-9012',
        phoneVerifiedAt: DateTime(2024, 5, 1),
        certificates: [
          Certificate(
            id: 'cert_3',
            type: CertificateType.cultureArtsEducator,
            name: '문화예술교육사 2급',
            issuingBody: '문화체육관광부',
            issueDate: DateTime(2019, 3, 15),
            imageUrl: 'https://example.com/cert3.jpg',
            status: CertificateStatus.approved,
            submittedAt: DateTime(2024, 5, 5),
            reviewedAt: DateTime(2024, 5, 10),
          ),
        ],
      ),
      visibilitySettings: const ProfileVisibilitySettings(
        isSearchable: true,
        nameVisibility: ProfileVisibility.public,
        photoVisibility: ProfileVisibility.public,
        contactVisibility: ProfileVisibility.students,
        feeVisibility: ProfileVisibility.public,
        careerVisibility: ProfileVisibility.public,
        certificateVisibility: ProfileVisibility.public,
      ),
      createdAt: DateTime(2024, 5, 1),
    ),
  ];

  @override
  Future<TeacherSearchResult> searchTeachers({
    TeacherSearchFilter filter = TeacherSearchFilter.empty,
    TeacherSortOption sort = TeacherSortOption.relevance,
    int page = 0,
    int pageSize = 20,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    var filtered = _mockTeachers
        .where((t) => t.visibilitySettings.isSearchable)
        .where((t) => t.canBeSearched)
        .toList();

    // Apply filters
    if (filter.keyword != null && filter.keyword!.isNotEmpty) {
      final keyword = filter.keyword!.toLowerCase();
      filtered = filtered.where((t) {
        return t.name.toLowerCase().contains(keyword) ||
            t.instruments.any((i) => i.toLowerCase().contains(keyword)) ||
            t.introduction.toLowerCase().contains(keyword) ||
            (t.lessonAreas?.any((a) => a.toLowerCase().contains(keyword)) ??
                false);
      }).toList();
    }

    if (filter.instruments != null && filter.instruments!.isNotEmpty) {
      filtered = filtered.where((t) {
        return t.instruments
            .any((i) => filter.instruments!.contains(i));
      }).toList();
    }

    if (filter.areas != null && filter.areas!.isNotEmpty) {
      filtered = filtered.where((t) {
        return t.lessonAreas
                ?.any((a) => filter.areas!.any((fa) => a.contains(fa))) ??
            false;
      }).toList();
    }

    if (filter.lessonTypes != null && filter.lessonTypes!.isNotEmpty) {
      filtered = filtered.where((t) {
        return t.lessonTypes
                ?.any((lt) => filter.lessonTypes!.contains(lt)) ??
            false;
      }).toList();
    }

    if (filter.minExperience != null) {
      filtered = filtered.where((t) {
        return (t.experienceYears ?? 0) >= filter.minExperience!;
      }).toList();
    }

    if (filter.hasVerifiedCertificate == true) {
      filtered = filtered.where((t) {
        return t.verification.hasVerifiedCertificate;
      }).toList();
    }

    // Apply sorting
    switch (sort) {
      case TeacherSortOption.experienceDesc:
        filtered.sort((a, b) =>
            (b.experienceYears ?? 0).compareTo(a.experienceYears ?? 0));
        break;
      case TeacherSortOption.experienceAsc:
        filtered.sort((a, b) =>
            (a.experienceYears ?? 0).compareTo(b.experienceYears ?? 0));
        break;
      case TeacherSortOption.feeAsc:
        filtered.sort((a, b) =>
            (a.feeRange?.minFee ?? 0).compareTo(b.feeRange?.minFee ?? 0));
        break;
      case TeacherSortOption.feeDesc:
        filtered.sort((a, b) =>
            (b.feeRange?.minFee ?? 0).compareTo(a.feeRange?.minFee ?? 0));
        break;
      case TeacherSortOption.completionLevel:
        filtered.sort((a, b) =>
            b.completionPercentage.compareTo(a.completionPercentage));
        break;
      case TeacherSortOption.relevance:
      case TeacherSortOption.rating:
        // Default order or by rating (not implemented yet)
        break;
    }

    // Apply pagination
    final totalCount = filtered.length;
    final startIndex = page * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, totalCount);
    final pagedTeachers = startIndex < totalCount
        ? filtered.sublist(startIndex, endIndex)
        : <TeacherProfile>[];

    return TeacherSearchResult(
      teachers: pagedTeachers,
      totalCount: totalCount,
      page: page,
      pageSize: pageSize,
      hasMore: endIndex < totalCount,
    );
  }

  @override
  Future<TeacherPublicProfile?> getTeacherPublicProfile(String teacherId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final teacher = _mockTeachers.firstWhere(
      (t) => t.id == teacherId,
      orElse: () => throw Exception('Teacher not found'),
    );

    return TeacherPublicProfile.fromProfile(teacher);
  }

  @override
  Future<List<TeacherPublicProfile>> getFeaturedTeachers({int limit = 10}) async {
    await Future.delayed(const Duration(milliseconds: 400));

    return _mockTeachers
        .where((t) => t.visibilitySettings.isSearchable && t.canBeSearched)
        .take(limit)
        .map((t) => TeacherPublicProfile.fromProfile(t))
        .toList();
  }

  @override
  Future<List<String>> getAvailableInstruments() async {
    await Future.delayed(const Duration(milliseconds: 200));

    final instruments = <String>{};
    for (final teacher in _mockTeachers) {
      instruments.addAll(teacher.instruments);
    }
    return instruments.toList()..sort();
  }

  @override
  Future<List<String>> getAvailableAreas() async {
    await Future.delayed(const Duration(milliseconds: 200));

    final areas = <String>{};
    for (final teacher in _mockTeachers) {
      if (teacher.lessonAreas != null) {
        areas.addAll(teacher.lessonAreas!);
      }
    }
    return areas.toList()..sort();
  }
}
