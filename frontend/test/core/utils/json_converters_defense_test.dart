// 2026-06-12 — #706 strict 파서 방어 회귀 테스트.
//
// BE Pydantic `T | None = None` 필드가 null 로 와도 FE fromJson 이
// throw 하지 않고 안전 기본값으로 파싱되는지 검증 (#704 availability 류
// "데이터 0건 무사, 실데이터부터 throw" 재발 방지).
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/auth/domain/entities/auth_user.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';
import 'package:lessonaza/features/students/domain/entities/lesson_class.dart';
import 'package:lessonaza/features/students/domain/entities/lesson_location.dart';
import 'package:lessonaza/features/students/domain/entities/student.dart';

void main() {
  group('#706 — BE nullable 필드 strict 파싱 방어', () {
    test('AuthUser — email/name null (OAuth 신규 가입) → 빈 문자열', () {
      final user = AuthUser.fromJson({
        'id': 'u-1',
        'email': null,
        'name': null,
        'onboarding_completed': false,
      });
      expect(user.email, '');
      expect(user.name, '');
    });

    test('UnifiedLessonRequest — created_at null → now 대체 (throw 없음)', () {
      final req = UnifiedLessonRequest.fromJson({
        'id': 'r-1',
        'student_id': 's-1',
        'teacher_id': 't-1',
        'type': 'regular',
        'instrument': '바이올린',
        'goal': 'hobby',
        'experience': 'beginner',
        'created_at': null,
      });
      expect(req.id, 'r-1');
      expect(req.createdAt, isA<DateTime>());
    });

    test('LessonClass — type/payment_type/created_at null → 기본값', () {
      final lessonClass = LessonClass.fromJson({
        'id': 'c-1',
        'teacher_id': 't-1',
        'name': '개인 레슨',
        'type': null,
        'payment_type': null,
        'created_at': null,
      });
      expect(lessonClass.type, LessonClassType.private);
      expect(lessonClass.paymentType, PaymentType.parent);
      expect(lessonClass.createdAt, isA<DateTime>());
    });

    test('LessonLocation — created_at null → now 대체', () {
      final location = LessonLocation.fromJson({
        'id': 'loc-1',
        'name': '학생 집',
        'type': 'studentHome',
        'created_at': null,
      });
      expect(location.createdAt, isA<DateTime>());
    });

    test('Student — created_at null → now 대체', () {
      final student = Student.fromJson({
        'id': 's-1',
        'name': '김서연',
        'instrument': '바이올린',
        'created_at': null,
      });
      expect(student.createdAt, isA<DateTime>());
    });
  });
}
