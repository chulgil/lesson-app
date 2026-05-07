/// Onboarding quest progress for the teacher onboarding phase.
class OnboardingQuest {
  final String id;
  final String title;
  final String description;
  final bool isRequired;
  final bool isComplete;
  final DateTime? completedAt;

  const OnboardingQuest.required({
    required this.id,
    required this.title,
    required this.description,
    this.isComplete = false,
    this.completedAt,
  }) : isRequired = true;

  const OnboardingQuest.optional({
    required this.id,
    required this.title,
    required this.description,
    this.isComplete = false,
    this.completedAt,
  }) : isRequired = false;

  OnboardingQuest copyWith({
    String? id,
    String? title,
    String? description,
    bool? isRequired,
    bool? isComplete,
    DateTime? completedAt,
  }) {
    return OnboardingQuest._(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isRequired: isRequired ?? this.isRequired,
      isComplete: isComplete ?? this.isComplete,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  const OnboardingQuest._({
    required this.id,
    required this.title,
    required this.description,
    required this.isRequired,
    required this.isComplete,
    required this.completedAt,
  });
}

/// Derived onboarding progress for the teacher quest board.
class OnboardingProgress {
  static const List<OnboardingQuest> teacherRequiredQuests = [
    OnboardingQuest.required(
      id: 'profile-created',
      title: '프로필 생성',
      description: '선생님 프로필을 최소 정보로 완성합니다.',
    ),
    OnboardingQuest.required(
      id: 'first-student',
      title: '첫 학생 추가',
      description: '첫 학생을 등록합니다.',
    ),
    OnboardingQuest.required(
      id: 'first-lesson',
      title: '첫 레슨 등록',
      description: '첫 레슨 일정을 등록합니다.',
    ),
    OnboardingQuest.required(
      id: 'first-note',
      title: '첫 레슨 노트 작성',
      description: '첫 레슨 피드백을 남깁니다.',
    ),
    OnboardingQuest.required(
      id: 'phone-verified',
      title: '전화번호 인증',
      description: '전화번호 인증을 완료합니다.',
    ),
  ];

  final String userId;
  final List<OnboardingQuest> quests;
  final DateTime startedAt;
  final DateTime? completedAt;

  const OnboardingProgress({
    required this.userId,
    required this.quests,
    required this.startedAt,
    this.completedAt,
  });

  factory OnboardingProgress.teacher({required String userId}) {
    return OnboardingProgress(
      userId: userId,
      quests: teacherRequiredQuests,
      startedAt: DateTime.now(),
    );
  }

  int get completedRequiredQuestCount =>
      quests.where((quest) => quest.isRequired && quest.isComplete).length;

  int get totalRequiredQuestCount =>
      quests.where((quest) => quest.isRequired).length;

  int get totalQuestCount => quests.length;

  bool get isComplete =>
      totalRequiredQuestCount > 0 &&
      completedRequiredQuestCount == totalRequiredQuestCount;

  double get progressFraction =>
      totalRequiredQuestCount == 0
          ? 0
          : completedRequiredQuestCount / totalRequiredQuestCount;

  int get progressPercentage => (progressFraction * 100).round();

  String get progressLabel =>
      '$completedRequiredQuestCount/$totalRequiredQuestCount';

  List<OnboardingQuest> get requiredQuests =>
      quests.where((quest) => quest.isRequired).toList(growable: false);

  OnboardingProgress copyWith({
    String? userId,
    List<OnboardingQuest>? quests,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return OnboardingProgress(
      userId: userId ?? this.userId,
      quests: quests ?? this.quests,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
