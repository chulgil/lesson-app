/// Phone verification model
class PhoneVerification {
  final String phoneNumber;
  final String? verificationCode;
  final DateTime? codeSentAt;
  final DateTime? verifiedAt;
  final bool isVerified;
  final int attemptCount;

  const PhoneVerification({
    required this.phoneNumber,
    this.verificationCode,
    this.codeSentAt,
    this.verifiedAt,
    this.isVerified = false,
    this.attemptCount = 0,
  });

  /// Check if code is still valid (3 minutes)
  bool get isCodeValid {
    if (codeSentAt == null) return false;
    final elapsed = DateTime.now().difference(codeSentAt!);
    return elapsed.inMinutes < 3;
  }

  /// Get remaining seconds for code validity
  int get remainingSeconds {
    if (codeSentAt == null) return 0;
    final elapsed = DateTime.now().difference(codeSentAt!);
    final remaining = 180 - elapsed.inSeconds; // 3 minutes = 180 seconds
    return remaining > 0 ? remaining : 0;
  }

  /// Check if can request new code (after 1 minute)
  bool get canRequestNewCode {
    if (codeSentAt == null) return true;
    final elapsed = DateTime.now().difference(codeSentAt!);
    return elapsed.inMinutes >= 1;
  }

  /// Maximum verification attempts
  static const maxAttempts = 5;

  /// Check if max attempts reached
  bool get isMaxAttemptsReached => attemptCount >= maxAttempts;

  PhoneVerification copyWith({
    String? phoneNumber,
    String? verificationCode,
    DateTime? codeSentAt,
    DateTime? verifiedAt,
    bool? isVerified,
    int? attemptCount,
  }) {
    return PhoneVerification(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      verificationCode: verificationCode ?? this.verificationCode,
      codeSentAt: codeSentAt ?? this.codeSentAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      isVerified: isVerified ?? this.isVerified,
      attemptCount: attemptCount ?? this.attemptCount,
    );
  }
}

/// Tutorial steps for onboarding
enum TutorialStep {
  welcome, // "Welcome to LessonApp!"
  inviteStudent, // "How to invite students"
  createLesson, // "Create lesson schedule"
  writeFeedback, // "Write lesson notes"
  completed, // "All set!"
}

/// Tutorial progress tracking
class TutorialProgress {
  final List<TutorialStep> completedSteps;
  final bool isSkipped;
  final DateTime? completedAt;

  const TutorialProgress({
    this.completedSteps = const [],
    this.isSkipped = false,
    this.completedAt,
  });

  bool get isCompleted =>
      isSkipped || completedSteps.contains(TutorialStep.completed);

  TutorialStep? get currentStep {
    if (isCompleted) return null;

    for (final step in TutorialStep.values) {
      if (!completedSteps.contains(step)) {
        return step;
      }
    }
    return null;
  }

  int get progressPercentage {
    if (isCompleted) return 100;
    // Exclude 'completed' step from calculation
    final totalSteps = TutorialStep.values.length - 1;
    final completedCount =
        completedSteps.where((s) => s != TutorialStep.completed).length;
    return ((completedCount / totalSteps) * 100).round();
  }

  TutorialProgress copyWith({
    List<TutorialStep>? completedSteps,
    bool? isSkipped,
    DateTime? completedAt,
  }) {
    return TutorialProgress(
      completedSteps: completedSteps ?? this.completedSteps,
      isSkipped: isSkipped ?? this.isSkipped,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  TutorialProgress markStepCompleted(TutorialStep step) {
    if (completedSteps.contains(step)) return this;

    final newSteps = [...completedSteps, step];
    final isNowCompleted = step == TutorialStep.completed ||
        newSteps.length >= TutorialStep.values.length;

    return copyWith(
      completedSteps: newSteps,
      completedAt: isNowCompleted ? DateTime.now() : null,
    );
  }

  TutorialProgress skip() {
    return copyWith(
      isSkipped: true,
      completedAt: DateTime.now(),
    );
  }
}

/// Onboarding step
enum OnboardingStep {
  roleSelect, // Select teacher/student role
  phoneVerification, // Verify phone number
  profileSetup, // Set up basic profile
  tutorial, // Complete tutorial
  completed, // Onboarding finished
}

/// Teacher onboarding state
class TeacherOnboardingState {
  final String? userId;
  final OnboardingStep currentStep;
  final PhoneVerification? phoneVerification;
  final TeacherOnboardingProfile? profile;
  final TutorialProgress tutorialProgress;
  final DateTime? startedAt;
  final DateTime? completedAt;

  const TeacherOnboardingState({
    this.userId,
    this.currentStep = OnboardingStep.roleSelect,
    this.phoneVerification,
    this.profile,
    this.tutorialProgress = const TutorialProgress(),
    this.startedAt,
    this.completedAt,
  });

  bool get isCompleted => currentStep == OnboardingStep.completed;

  int get progressPercentage {
    switch (currentStep) {
      case OnboardingStep.roleSelect:
        return 0;
      case OnboardingStep.phoneVerification:
        return 25;
      case OnboardingStep.profileSetup:
        return 50;
      case OnboardingStep.tutorial:
        return 75;
      case OnboardingStep.completed:
        return 100;
    }
  }

  TeacherOnboardingState copyWith({
    String? userId,
    OnboardingStep? currentStep,
    PhoneVerification? phoneVerification,
    TeacherOnboardingProfile? profile,
    TutorialProgress? tutorialProgress,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return TeacherOnboardingState(
      userId: userId ?? this.userId,
      currentStep: currentStep ?? this.currentStep,
      phoneVerification: phoneVerification ?? this.phoneVerification,
      profile: profile ?? this.profile,
      tutorialProgress: tutorialProgress ?? this.tutorialProgress,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

/// Minimal profile for onboarding (required fields only)
class TeacherOnboardingProfile {
  final String name;
  final String? profileImage;
  final List<String> instruments;
  final String introduction;

  const TeacherOnboardingProfile({
    required this.name,
    this.profileImage,
    required this.instruments,
    required this.introduction,
  });

  /// Validate profile completeness
  bool get isValid {
    return name.isNotEmpty &&
        profileImage != null &&
        profileImage!.isNotEmpty &&
        instruments.isNotEmpty &&
        introduction.length >= 20;
  }

  /// Get list of missing fields
  List<String> get missingFields {
    final missing = <String>[];
    if (name.isEmpty) missing.add('이름');
    if (profileImage == null || profileImage!.isEmpty) missing.add('프로필 사진');
    if (instruments.isEmpty) missing.add('악기');
    if (introduction.length < 20) missing.add('소개글 (20자 이상)');
    return missing;
  }

  TeacherOnboardingProfile copyWith({
    String? name,
    String? profileImage,
    List<String>? instruments,
    String? introduction,
  }) {
    return TeacherOnboardingProfile(
      name: name ?? this.name,
      profileImage: profileImage ?? this.profileImage,
      instruments: instruments ?? this.instruments,
      introduction: introduction ?? this.introduction,
    );
  }
}

/// Tutorial step content
class TutorialStepContent {
  final TutorialStep step;
  final String title;
  final String description;
  final String? imageAsset;
  final String? animationAsset;

  const TutorialStepContent({
    required this.step,
    required this.title,
    required this.description,
    this.imageAsset,
    this.animationAsset,
  });

  static const List<TutorialStepContent> allSteps = [
    TutorialStepContent(
      step: TutorialStep.welcome,
      title: '환영합니다!',
      description: '레슨앱에서 학생을 관리하고\n효과적인 레슨을 진행해보세요',
      imageAsset: 'assets/images/onboarding/welcome.png',
    ),
    TutorialStepContent(
      step: TutorialStep.inviteStudent,
      title: '학생 초대하기',
      description: 'QR 코드나 링크를 통해\n학생을 쉽게 초대할 수 있어요',
      imageAsset: 'assets/images/onboarding/invite.png',
    ),
    TutorialStepContent(
      step: TutorialStep.createLesson,
      title: '레슨 일정 등록',
      description: '캘린더에서 간편하게\n레슨 일정을 관리하세요',
      imageAsset: 'assets/images/onboarding/calendar.png',
    ),
    TutorialStepContent(
      step: TutorialStep.writeFeedback,
      title: '레슨 노트 작성',
      description: '레슨 후 피드백을 남기고\n학생의 성장을 기록하세요',
      imageAsset: 'assets/images/onboarding/feedback.png',
    ),
    TutorialStepContent(
      step: TutorialStep.completed,
      title: '준비 완료!',
      description: '이제 레슨앱을 시작할\n모든 준비가 되었어요',
      imageAsset: 'assets/images/onboarding/complete.png',
    ),
  ];

  static TutorialStepContent getContent(TutorialStep step) {
    return allSteps.firstWhere((c) => c.step == step);
  }
}
