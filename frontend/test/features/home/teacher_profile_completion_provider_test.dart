import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/home/presentation/providers/teacher_profile_completion_provider.dart';

QuestCompletionInput _input({
  bool hasSlots = false,
  bool hasPhoto = false,
  bool hasIntro = false,
  bool hasInstruments = false,
  bool hasPrice = false,
  bool hasBankAccount = false,
  bool hasStudents = false,
  bool hasSubscription = false,
  bool hasCompletedLesson = false,
  bool hasLessonNote = false,
  bool hasPracticeAssigned = false,
  bool isPhoneVerified = false,
}) => QuestCompletionInput(
  hasSlots: hasSlots,
  hasPhoto: hasPhoto,
  hasIntro: hasIntro,
  hasInstruments: hasInstruments,
  hasPrice: hasPrice,
  hasBankAccount: hasBankAccount,
  hasStudents: hasStudents,
  hasSubscription: hasSubscription,
  hasCompletedLesson: hasCompletedLesson,
  hasLessonNote: hasLessonNote,
  hasPracticeAssigned: hasPracticeAssigned,
  isPhoneVerified: isPhoneVerified,
);

QuestCompletionInput _allMandatory({bool isPhoneVerified = false}) => _input(
  hasSlots: true,
  hasPhoto: true,
  hasIntro: true,
  hasInstruments: true,
  hasPrice: true,
  hasBankAccount: true,
  hasStudents: true,
  hasSubscription: true,
  hasCompletedLesson: true,
  hasLessonNote: true,
  hasPracticeAssigned: true,
  isPhoneVerified: isPhoneVerified,
);

void main() {
  group('isTeacherProfileImageQuestEligible', () {
    test(
      'does not complete the photo quest with an OAuth Google account image',
      () {
        expect(
          isTeacherProfileImageQuestEligible(
            'https://lh3.googleusercontent.com/a/ACg8ocK-example=s96-c',
          ),
          isFalse,
        );
      },
    );

    test('completes the photo quest with an app-uploaded image', () {
      expect(
        isTeacherProfileImageQuestEligible(
          'https://storage.googleapis.com/lessonaza/profile/user-1.jpg',
        ),
        isTrue,
      );
    });
  });

  // SC-6 — spec §9.3 게이지 1:1 정합성.
  group('SC-6 게이지 1:1 정합성 (computeProfileCompletionPercent)', () {
    test('Q1~Q10 + Q3b 모두 완료 (Q11 미완료) → 게이지 100%', () {
      expect(computeProfileCompletionPercent(_allMandatory()), 100);
    });

    test('Q11 (전화인증) 만 완료 → 게이지 0%', () {
      expect(computeProfileCompletionPercent(_input(isPhoneVerified: true)), 0);
    });

    test('Q1~Q10 + Q3b + Q11 모두 완료 → 게이지 100% (Q11 보너스, 가중치 0)', () {
      expect(
        computeProfileCompletionPercent(_allMandatory(isPhoneVerified: true)),
        100,
      );
    });

    test('가중치 합 정확히 100 — Q3b instruments 포함 11개 mandatory', () {
      // 모든 mandatory 가중치 합 == 100 (회귀 가드).
      // 8+7+7+6+6+6 + 12+15+13+10+10 = 100
      final sum = 8 + 7 + 7 + 6 + 6 + 6 + 12 + 15 + 13 + 10 + 10;
      expect(sum, 100);
    });

    test('Q3b (instruments) 만 누락 → 게이지 94% (졸업 아님)', () {
      final input = _input(
        hasSlots: true,
        hasPhoto: true,
        hasIntro: true,
        // hasInstruments: false  (Q3b 만 누락)
        hasPrice: true,
        hasBankAccount: true,
        hasStudents: true,
        hasSubscription: true,
        hasCompletedLesson: true,
        hasLessonNote: true,
        hasPracticeAssigned: true,
      );
      expect(computeProfileCompletionPercent(input), 94);
      expect(isAllMandatoryQuestsCompleted(input), false);
    });
  });

  group('SC-6 isAllMandatoryQuestsCompleted — 졸업 트리거', () {
    test('Q1~Q10 + Q3b 모두 완료 → true (Q11 무관)', () {
      expect(isAllMandatoryQuestsCompleted(_allMandatory()), true);
      expect(
        isAllMandatoryQuestsCompleted(_allMandatory(isPhoneVerified: true)),
        true,
      );
    });

    test('Q11 만 완료 → false (졸업 트리거 아님)', () {
      expect(
        isAllMandatoryQuestsCompleted(_input(isPhoneVerified: true)),
        false,
      );
    });

    test('mandatory 1개라도 누락 → false', () {
      final input = _input(
        hasSlots: true,
        hasPhoto: true,
        hasIntro: true,
        hasInstruments: true,
        hasPrice: true,
        hasBankAccount: true,
        hasStudents: true,
        hasSubscription: true,
        hasCompletedLesson: true,
        hasLessonNote: true,
        // hasPracticeAssigned: false (Q10 누락)
      );
      expect(isAllMandatoryQuestsCompleted(input), false);
    });
  });
}
