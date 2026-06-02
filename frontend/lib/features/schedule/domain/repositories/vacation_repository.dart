import '../entities/vacation_period.dart';

/// Repository contract for teacher vacation mode (#431).
///
/// Spec: docs/specs/schedule/teacher_vacation_mode.md §7 (Recovery) + §9 (API).
abstract class VacationRepository {
  /// Fetch the lesson/student impact summary for a candidate vacation window.
  Future<VacationImpactPreview> previewImpact({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Register a new vacation period and (for rollForward) auto-extend
  /// impacted subscriptions on the backend side.
  ///
  /// [perStudentDisposition] (spec §4.2) overrides the default disposition for
  /// individual students. Pass `null` or empty when no overrides apply.
  Future<VacationPeriod> registerVacation({
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
    required VacationDisposition defaultDisposition,
    Map<String, VacationDisposition>? perStudentDisposition,
  });

  /// List the teacher's vacation periods (active by default).
  /// Set [includeCancelled] true to also include cancelled periods.
  Future<List<VacationPeriod>> listVacations({bool includeCancelled = false});

  /// Cancel a vacation within the 24h Recovery window.
  /// Server enforces:
  /// - 400 if already cancelled
  /// - 409 if 24h elapsed or vacation already started
  /// - 403/404 if not the creator
  Future<VacationPeriod> cancelVacation(String periodId);
}
