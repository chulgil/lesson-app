import '../entities/makeup_credit.dart';

/// Repository contract for makeup credits (#432 / Make-up Bank).
///
/// Spec: docs/specs/subscription/makeup_credit_spec.md §8 (API).
abstract class MakeupCreditRepository {
  /// Student-side: list the signed-in student's makeup credits.
  /// GET /api/students/me/makeup-credits
  Future<List<MakeupCredit>> listStudentCredits();

  /// Teacher-side: list makeup credits the teacher issued for one student.
  /// GET /api/teachers/me/makeup-credits?student_id=...
  Future<List<MakeupCredit>> listTeacherCredits({required String studentId});

  /// Teacher-side manual grant (spec §4.4 — safety net).
  /// POST /api/teachers/me/makeup-credits
  Future<MakeupCredit> grantCredit({
    required String studentId,
    String? sourceSubscriptionId,
    String? reasonNote,
  });

  /// Teacher-side revoke of an unused credit (mistaken grant cleanup).
  /// Server rejects (409) if the credit is already used.
  Future<void> revokeCredit(String creditId);
}
