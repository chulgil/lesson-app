import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/home/presentation/providers/teacher_profile_completion_provider.dart';

void main() {
  group('isTeacherProfileImageQuestEligible', () {
    test('does not complete the photo quest with an OAuth Google account image', () {
      expect(
        isTeacherProfileImageQuestEligible(
          'https://lh3.googleusercontent.com/a/ACg8ocK-example=s96-c',
        ),
        isFalse,
      );
    });

    test('completes the photo quest with an app-uploaded image', () {
      expect(
        isTeacherProfileImageQuestEligible(
          'https://storage.googleapis.com/lessonaza/profile/user-1.jpg',
        ),
        isTrue,
      );
    });
  });
}
