import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/subscription/presentation/screens/subscription_detail_screen.dart';

void main() {
  test(
    'student subscription detail waits for teacher response after own request',
    () {
      expect(
        subscriptionDetailOpponentName(
          viewerRole: 'student',
          studentName: '김민준',
          teacherName: '김선아',
        ),
        '김선아',
      );
    },
  );

  test(
    'teacher subscription detail waits for student response after own request',
    () {
      expect(
        subscriptionDetailOpponentName(
          viewerRole: 'teacher',
          studentName: '김민준',
          teacherName: '김선아',
        ),
        '김민준',
      );
    },
  );
}
