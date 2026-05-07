import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lessonaza/features/auth/auth_facade.dart';
import 'package:lessonaza/features/onboarding/domain/entities/onboarding_progress.dart';
import 'package:lessonaza/features/onboarding/presentation/providers/onboarding_quest_providers.dart';

void main() {
  group('onboarding quest providers', () {
    test(
      'expose the teacher quest checklist and progress for the current user',
      () {
        final container = ProviderContainer(
          overrides: [currentUserIdProvider.overrideWith((ref) => 'teacher_1')],
        );
        addTearDown(container.dispose);

        final quests = container.read(teacherOnboardingQuestsProvider);
        final progress = container.read(teacherOnboardingProgressProvider);

        expect(quests, hasLength(5));
        expect(progress.userId, 'teacher_1');
        expect(progress.quests, quests);
        expect(progress.progressLabel, '0/5');
        expect(progress.isComplete, isFalse);
      },
    );

    test(
      'keeps the five-quest denominator even when some quests are complete',
      () {
        final container = ProviderContainer(
          overrides: [
            currentUserIdProvider.overrideWith((ref) => 'teacher_1'),
            teacherOnboardingQuestsProvider.overrideWithValue([
              const OnboardingQuest.required(
                id: 'profile-created',
                title: '프로필 생성',
                description: '선생님 프로필을 만듭니다.',
                isComplete: true,
              ),
              const OnboardingQuest.required(
                id: 'first-student',
                title: '첫 학생 추가',
                description: '첫 학생을 추가합니다.',
              ),
              const OnboardingQuest.required(
                id: 'first-lesson',
                title: '첫 레슨 등록',
                description: '첫 레슨을 등록합니다.',
              ),
              const OnboardingQuest.required(
                id: 'first-note',
                title: '첫 레슨 노트 작성',
                description: '첫 레슨 노트를 작성합니다.',
              ),
              const OnboardingQuest.required(
                id: 'phone-verified',
                title: '전화번호 인증',
                description: '휴대폰 번호를 인증합니다.',
              ),
            ]),
          ],
        );
        addTearDown(container.dispose);

        final progress = container.read(teacherOnboardingProgressProvider);

        expect(progress.completedRequiredQuestCount, 1);
        expect(progress.totalRequiredQuestCount, 5);
        expect(progress.progressPercentage, 20);
        expect(progress.progressLabel, '1/5');
        expect(progress.isComplete, isFalse);
      },
    );
  });
}
