import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../features/profile/domain/entities/teacher_onboarding.dart';
import '../../../../features/profile/domain/entities/teacher_profile.dart';
import '../../../profile/domain/repositories/teacher_profile_repository.dart';
import '../../../auth/presentation/providers/user_role_provider.dart';
import 'teacher_profile_repository_provider.dart';

part 'onboarding_providers.g.dart';

// =============================================================================
// Onboarding State Notifier
// =============================================================================

/// Teacher onboarding state notifier
@Riverpod(keepAlive: true)
class TeacherOnboardingNotifier extends _$TeacherOnboardingNotifier {
  @override
  TeacherOnboardingState build() {
    final userId = ref.watch(currentUserIdProvider);
    return TeacherOnboardingState(
      userId: userId,
      startedAt: DateTime.now(),
    );
  }

  /// Move to next step
  void goToStep(OnboardingStep step) {
    state = state.copyWith(currentStep: step);
  }

  /// Start phone verification
  void startPhoneVerification(String phoneNumber) {
    final verification = PhoneVerification(
      phoneNumber: phoneNumber,
      verificationCode: _generateVerificationCode(),
      codeSentAt: DateTime.now(),
    );
    state = state.copyWith(
      phoneVerification: verification,
      currentStep: OnboardingStep.phoneVerification,
    );
  }

  /// Resend verification code
  bool resendVerificationCode() {
    final current = state.phoneVerification;
    if (current == null) return false;
    if (!current.canRequestNewCode) return false;

    final newVerification = current.copyWith(
      verificationCode: _generateVerificationCode(),
      codeSentAt: DateTime.now(),
    );
    state = state.copyWith(phoneVerification: newVerification);
    return true;
  }

  /// Verify code
  bool verifyCode(String code) {
    final current = state.phoneVerification;

    // Debug: allow any 6-digit code for testing
    if (code.length == 6) {
      final verified = (current ?? PhoneVerification(
        phoneNumber: '',
        verificationCode: code,
        codeSentAt: DateTime.now(),
      )).copyWith(
        isVerified: true,
        verifiedAt: DateTime.now(),
      );
      state = state.copyWith(
        phoneVerification: verified,
        currentStep: OnboardingStep.profileSetup,
      );
      return true;
    }

    if (current == null) return false;
    if (!current.isCodeValid) return false;
    if (current.isMaxAttemptsReached) return false;

    // Check code match
    if (current.verificationCode == code) {
      final verified = current.copyWith(
        isVerified: true,
        verifiedAt: DateTime.now(),
      );
      state = state.copyWith(
        phoneVerification: verified,
        currentStep: OnboardingStep.profileSetup,
      );
      return true;
    }

    // Increment attempt count
    final updated = current.copyWith(
      attemptCount: current.attemptCount + 1,
    );
    state = state.copyWith(phoneVerification: updated);
    return false;
  }

  /// Update profile data
  void updateProfile(TeacherOnboardingProfile profile) {
    state = state.copyWith(profile: profile);
  }

  /// Submit profile and move to tutorial
  void submitProfile() {
    if (state.profile?.isValid ?? false) {
      state = state.copyWith(currentStep: OnboardingStep.tutorial);
    }
  }

  /// Complete tutorial step
  void completeTutorialStep(TutorialStep step) {
    final newProgress = state.tutorialProgress.markStepCompleted(step);
    state = state.copyWith(tutorialProgress: newProgress);

    if (newProgress.isCompleted) {
      completeOnboarding();
    }
  }

  /// Skip tutorial
  void skipTutorial() {
    final skipped = state.tutorialProgress.skip();
    state = state.copyWith(tutorialProgress: skipped);
    completeOnboarding();
  }

  /// Complete onboarding
  void completeOnboarding() {
    state = state.copyWith(
      currentStep: OnboardingStep.completed,
      completedAt: DateTime.now(),
    );
  }

  /// Generate a random 6-digit verification code
  String _generateVerificationCode() {
    // In mock, use a predictable code for testing
    return '123456';
  }
}

// =============================================================================
// Teacher Profile Providers
// =============================================================================

/// Current teacher profile provider
@riverpod
Future<TeacherProfile?> currentTeacherProfile(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  final repository = ref.watch(teacherProfileRepositoryProvider);
  return repository.getProfileByUserId(userId);
}

/// Teacher profile by ID provider
@riverpod
Future<TeacherProfile?> teacherProfileById(Ref ref, String profileId) async {
  final repository = ref.watch(teacherProfileRepositoryProvider);
  return repository.getProfileById(profileId);
}

/// Featured teacher profiles provider
@riverpod
Future<List<TeacherProfile>> featuredTeacherProfiles(Ref ref) async {
  final repository = ref.watch(teacherProfileRepositoryProvider);
  return repository.getFeaturedProfiles();
}

/// Search teacher profiles provider
@riverpod
Future<List<TeacherProfile>> searchTeacherProfiles(
  Ref ref,
  TeacherProfileFilter filter,
) async {
  final repository = ref.watch(teacherProfileRepositoryProvider);
  return repository.searchProfiles(filter);
}

// =============================================================================
// Profile Completion Provider
// =============================================================================

/// Profile completion info for current teacher
@riverpod
class CurrentTeacherProfileNotifier extends _$CurrentTeacherProfileNotifier {
  @override
  Future<TeacherProfile?> build() async {
    final userId = ref.watch(currentUserIdProvider);
    final repository = ref.watch(teacherProfileRepositoryProvider);
    return repository.getProfileByUserId(userId);
  }

  /// Create initial profile from onboarding data
  Future<TeacherProfile> createFromOnboarding(
    TeacherOnboardingState onboardingState,
  ) async {
    if (onboardingState.profile == null) {
      throw Exception('Profile data is required');
    }

    final onboardingProfile = onboardingState.profile!;
    final profile = TeacherProfile(
      id: 'profile_${DateTime.now().millisecondsSinceEpoch}',
      userId: onboardingState.userId!,
      name: onboardingProfile.name,
      profileImage: onboardingProfile.profileImage,
      instruments: onboardingProfile.instruments,
      introduction: onboardingProfile.introduction,
      verification: TeacherVerification(
        isPhoneVerified: onboardingState.phoneVerification?.isVerified ?? false,
        phoneNumber: onboardingState.phoneVerification?.phoneNumber,
        phoneVerifiedAt: onboardingState.phoneVerification?.verifiedAt,
      ),
      createdAt: DateTime.now(),
    );

    final repository = ref.read(teacherProfileRepositoryProvider);
    final created = await repository.createProfile(profile);
    state = AsyncData(created);
    return created;
  }

  /// Update profile
  Future<TeacherProfile> updateProfile(TeacherProfile profile) async {
    final repository = ref.read(teacherProfileRepositoryProvider);
    final updated = await repository.updateProfile(profile);
    state = AsyncData(updated);
    return updated;
  }

  /// Add certificate
  Future<TeacherProfile> addCertificate(Certificate cert) async {
    final current = state.value;
    if (current == null) throw Exception('No profile loaded');

    final repository = ref.read(teacherProfileRepositoryProvider);
    final updated = await repository.addCertificate(current.id, cert);
    state = AsyncData(updated);
    return updated;
  }

  /// Update visibility settings
  Future<TeacherProfile> updateVisibility(
    ProfileVisibilitySettings settings,
  ) async {
    final current = state.value;
    if (current == null) throw Exception('No profile loaded');

    final repository = ref.read(teacherProfileRepositoryProvider);
    final updated = await repository.updateVisibilitySettings(
      current.id,
      settings,
    );
    state = AsyncData(updated);
    return updated;
  }
}

// =============================================================================
// Onboarding Status Provider
// =============================================================================

/// Check if teacher needs onboarding
@riverpod
Future<bool> teacherNeedsOnboarding(Ref ref) async {
  final profile = await ref.watch(currentTeacherProfileProvider.future);

  // No profile means needs onboarding
  if (profile == null) return true;

  // Check if minimum level is reached
  return profile.completionLevel == ProfileCompletionLevel.minimum &&
      !profile.verification.isPhoneVerified;
}

/// Check if teacher has completed onboarding
final teacherOnboardingCompletedProvider = StateProvider<bool>((ref) {
  return false;
});

// =============================================================================
// Phone Verification UI State
// =============================================================================

/// Phone verification countdown provider
@riverpod
class PhoneVerificationTimer extends _$PhoneVerificationTimer {
  @override
  int build() {
    final onboarding = ref.watch(teacherOnboardingNotifierProvider);
    return onboarding.phoneVerification?.remainingSeconds ?? 0;
  }

  void updateRemainingTime(int seconds) {
    state = seconds;
  }
}

/// Phone input validation state
final phoneNumberProvider = StateProvider<String>((ref) => '');
final verificationCodeProvider = StateProvider<String>((ref) => '');

/// Phone number validation
final isPhoneNumberValidProvider = Provider<bool>((ref) {
  final phone = ref.watch(phoneNumberProvider);
  // Korean phone number format: 010-XXXX-XXXX or 01XXXXXXXXX
  final phoneRegex = RegExp(r'^01[0-9]{8,9}$');
  final cleanPhone = phone.replaceAll('-', '').replaceAll(' ', '');
  return phoneRegex.hasMatch(cleanPhone);
});

/// Verification code validation
final isVerificationCodeValidProvider = Provider<bool>((ref) {
  final code = ref.watch(verificationCodeProvider);
  return code.length == 6 && int.tryParse(code) != null;
});

// =============================================================================
// Profile Setup UI State
// =============================================================================

/// Profile name input
final profileNameProvider = StateProvider<String>((ref) => '');

/// Profile image URL
final profileImageProvider = StateProvider<String?>((ref) => null);

/// Selected instruments
final selectedInstrumentsProvider = StateProvider<List<String>>((ref) => []);

/// Introduction text
final profileIntroductionProvider = StateProvider<String>((ref) => '');

/// Profile form validation
final isProfileFormValidProvider = Provider<bool>((ref) {
  final name = ref.watch(profileNameProvider);
  final image = ref.watch(profileImageProvider);
  final instruments = ref.watch(selectedInstrumentsProvider);
  final introduction = ref.watch(profileIntroductionProvider);

  return name.isNotEmpty &&
      image != null &&
      image.isNotEmpty &&
      instruments.isNotEmpty &&
      introduction.length >= 20;
});

/// Missing fields for profile
final profileMissingFieldsProvider = Provider<List<String>>((ref) {
  final fields = <String>[];
  final name = ref.watch(profileNameProvider);
  final image = ref.watch(profileImageProvider);
  final instruments = ref.watch(selectedInstrumentsProvider);
  final introduction = ref.watch(profileIntroductionProvider);

  if (name.isEmpty) fields.add('이름');
  if (image == null || image.isEmpty) fields.add('프로필 사진');
  if (instruments.isEmpty) fields.add('악기');
  if (introduction.length < 20) fields.add('소개글 (20자 이상)');

  return fields;
});

/// Build onboarding profile from form data
final onboardingProfileFromFormProvider = Provider<TeacherOnboardingProfile?>((ref) {
  final isValid = ref.watch(isProfileFormValidProvider);
  if (!isValid) return null;

  return TeacherOnboardingProfile(
    name: ref.read(profileNameProvider),
    profileImage: ref.read(profileImageProvider),
    instruments: ref.read(selectedInstrumentsProvider),
    introduction: ref.read(profileIntroductionProvider),
  );
});
