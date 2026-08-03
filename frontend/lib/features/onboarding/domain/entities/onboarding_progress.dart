/// Onboarding quest progress for the teacher onboarding phase.
///
/// Pure domain value: only the quest [id] and completion flags live here. The
/// user-facing title/description are resolved in the presentation layer via
/// `presentation/extensions/onboarding_quest_visuals.dart` (#602).
class OnboardingQuest {
  final String id;
  final bool isRequired;
  final bool isComplete;
  final DateTime? completedAt;

  const OnboardingQuest.required({
    required this.id,
    this.isComplete = false,
    this.completedAt,
  }) : isRequired = true;

  const OnboardingQuest.optional({
    required this.id,
    this.isComplete = false,
    this.completedAt,
  }) : isRequired = false;

  OnboardingQuest copyWith({
    String? id,
    bool? isRequired,
    bool? isComplete,
    DateTime? completedAt,
  }) {
    return OnboardingQuest._(
      id: id ?? this.id,
      isRequired: isRequired ?? this.isRequired,
      isComplete: isComplete ?? this.isComplete,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  const OnboardingQuest._({
    required this.id,
    required this.isRequired,
    required this.isComplete,
    required this.completedAt,
  });
}

/// Derived onboarding progress for the teacher quest board.
class OnboardingProgress {
  static const List<OnboardingQuest> teacherRequiredQuests = [
    OnboardingQuest.required(id: 'profile-created'),
    OnboardingQuest.required(id: 'first-student'),
    OnboardingQuest.required(id: 'first-lesson'),
    OnboardingQuest.required(id: 'first-note'),
    OnboardingQuest.required(id: 'phone-verified'),
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

  double get progressFraction => totalRequiredQuestCount == 0
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
