import '../../../../core/network/api_client.dart';
import '../../domain/entities/vacation_period.dart';
import '../../domain/repositories/vacation_repository.dart';

/// REST client for /api/v1/teacher/vacation endpoints (#431).
class RemoteVacationRepository implements VacationRepository {
  final ApiClient _apiClient;

  RemoteVacationRepository(this._apiClient);

  @override
  Future<VacationImpactPreview> previewImpact({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await _apiClient.get(
      '/teacher/vacation/impact',
      queryParameters: {
        'start': _formatDate(startDate),
        'end': _formatDate(endDate),
      },
    );
    return _previewFromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<VacationPeriod> registerVacation({
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
    required VacationDisposition defaultDisposition,
  }) async {
    final response = await _apiClient.post(
      '/teacher/vacation',
      data: {
        'start_date': _formatDate(startDate),
        'end_date': _formatDate(endDate),
        if (reason != null && reason.isNotEmpty) 'reason': reason,
        'default_disposition': _dispositionToWire(defaultDisposition),
      },
    );
    return _periodFromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<VacationPeriod>> listVacations({
    bool includeCancelled = false,
  }) async {
    final response = await _apiClient.get(
      '/teacher/vacation',
      queryParameters: {if (includeCancelled) 'include_cancelled': 'true'},
    );
    final data = response.data as Map<String, dynamic>;
    final items = (data['vacations'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return items.map(_periodFromJson).toList(growable: false);
  }

  @override
  Future<VacationPeriod> cancelVacation(String periodId) async {
    final response = await _apiClient.delete('/teacher/vacation/$periodId');
    return _periodFromJson(response.data as Map<String, dynamic>);
  }

  // ──────────────────────────────────────────────────────────
  // JSON helpers
  // ──────────────────────────────────────────────────────────

  static String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static VacationPeriod _periodFromJson(Map<String, dynamic> json) {
    return VacationPeriod(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      reason: json['reason'] as String?,
      defaultDisposition: _dispositionFromWire(
        json['default_disposition'] as String,
      ),
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  static VacationImpactPreview _previewFromJson(Map<String, dynamic> json) {
    final students = (json['impacted_students'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(
          (s) => VacationImpactedStudent(
            studentId: s['student_id'] as String,
            studentName: s['student_name'] as String?,
            lessonCount: (s['lesson_count'] as num).toInt(),
          ),
        )
        .toList(growable: false);
    return VacationImpactPreview(
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      impactedLessonCount: (json['impacted_lesson_count'] as num).toInt(),
      impactedStudentCount: (json['impacted_student_count'] as num).toInt(),
      impactedStudents: students,
    );
  }

  static String _dispositionToWire(VacationDisposition value) {
    switch (value) {
      case VacationDisposition.makeupCredit:
        return 'makeupCredit';
      case VacationDisposition.freeCancel:
        return 'freeCancel';
      case VacationDisposition.rollForward:
        return 'rollForward';
    }
  }

  static VacationDisposition _dispositionFromWire(String value) {
    switch (value) {
      case 'makeupCredit':
        return VacationDisposition.makeupCredit;
      case 'freeCancel':
        return VacationDisposition.freeCancel;
      case 'rollForward':
      default:
        return VacationDisposition.rollForward;
    }
  }
}
