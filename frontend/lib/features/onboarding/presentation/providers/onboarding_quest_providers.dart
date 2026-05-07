import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../features/auth/auth_facade.dart';
import '../../domain/entities/onboarding_progress.dart';

part 'onboarding_quest_providers.g.dart';

@Riverpod(keepAlive: true)
List<OnboardingQuest> teacherOnboardingQuests(TeacherOnboardingQuestsRef ref) {
  return OnboardingProgress.teacherRequiredQuests;
}

@Riverpod(keepAlive: true)
OnboardingProgress teacherOnboardingProgress(TeacherOnboardingProgressRef ref) {
  final userId = ref.watch(currentUserIdProvider);
  final quests = ref.watch(teacherOnboardingQuestsProvider);
  return OnboardingProgress(
    userId: userId,
    quests: quests,
    startedAt: DateTime.now(),
  );
}
