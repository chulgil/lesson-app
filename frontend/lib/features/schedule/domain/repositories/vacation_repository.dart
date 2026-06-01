import '../entities/vacation_period.dart';

/// Repository contract for teacher vacation mode (#431).
///
/// Spec: docs/specs/schedule/teacher_vacation_mode.md §9.
/// 1차 BE 범위: register + previewImpact only. 24h Recovery + list 는 후속 PR.
abstract class VacationRepository {
  /// Fetch the lesson/student impact summary for a candidate vacation window.
  Future<VacationImpactPreview> previewImpact({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Register a new vacation period and (for rollForward) auto-extend
  /// impacted subscriptions on the backend side.
  Future<VacationPeriod> registerVacation({
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
    required VacationDisposition defaultDisposition,
  });
}
