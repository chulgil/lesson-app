import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_onboarding.dart';

void main() {
  group('TeacherOnboardingProfile', () {
    test('isValid does not require profile image for profile setup flow', () {
      final profile = TeacherOnboardingProfile(
        name: '김선생',
        profileImage: null,
        instruments: ['바이올린'],
        introduction: '학생들의 음악적 성장을 함께 만들어가는 선생님입니다.',
      );

      expect(profile.isValid, isTrue);
    });

    test('missingFields does not include optional profile image', () {
      final profile = TeacherOnboardingProfile(
        name: '',
        profileImage: null,
        instruments: <String>[],
        introduction: '짧음',
      );

      expect(profile.missingFields, contains('이름'));
      expect(profile.missingFields, contains('악기'));
      expect(profile.missingFields, contains('소개글 (20자 이상)'));
      expect(profile.missingFields, isNot(contains('프로필 사진')));
    });
  });
}
