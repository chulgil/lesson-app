import '../../../../core/network/api_client.dart';
import '../../domain/entities/teacher_announcement.dart';
import '../../domain/repositories/teacher_announcement_repository.dart';

class RemoteTeacherAnnouncementRepository
    implements TeacherAnnouncementRepository {
  RemoteTeacherAnnouncementRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<TeacherAnnouncement> create(TeacherAnnouncement announcement) async {
    final response = await _apiClient.post(
      '/announcements',
      data:
          _toJson(announcement)
            ..remove('id')
            ..remove('created_at'),
    );
    return _fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<TeacherAnnouncement>> getByTeacherId(String teacherId) async {
    final response = await _apiClient.get(
      '/announcements',
      queryParameters: {'teacher_id': teacherId},
    );
    final items = response.data as List<dynamic>;
    return items
        .map((item) => _fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<TeacherAnnouncement> update(TeacherAnnouncement announcement) {
    throw UnsupportedError('Teacher announcement update API is not available.');
  }

  @override
  Future<void> delete(String id) {
    throw UnsupportedError('Teacher announcement delete API is not available.');
  }

  @override
  Future<List<DateTime>> getDayOffs({
    required String teacherId,
    required DateTime from,
    required DateTime to,
  }) async {
    final response = await _apiClient.get(
      '/announcements/day-offs',
      queryParameters: {
        'teacher_id': teacherId,
        'from_date': _dateOnly(from),
        'to_date': _dateOnly(to),
      },
    );
    final dates = (response.data as Map<String, dynamic>)['dates'] as List;
    return dates.map((date) => DateTime.parse(date as String)).toList();
  }

  TeacherAnnouncement _fromJson(Map<String, dynamic> json) {
    return TeacherAnnouncement(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String,
      type: _type(json['type'] as String?),
      dates:
          ((json['dates'] as List<dynamic>?) ?? [])
              .map((date) => DateTime.parse(date as String))
              .toList(),
      message: json['message'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      affectedLessons:
          ((json['affected_lessons'] as List<dynamic>?) ?? [])
              .map(
                (item) => _affectedLessonFromJson(item as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  AffectedLesson _affectedLessonFromJson(Map<String, dynamic> json) {
    return AffectedLesson(
      studentId: json['student_id'] as String,
      studentName: json['student_name'] as String,
      instrument: json['instrument'] as String,
      startTime: json['start_time'] as String,
      sessionNumber: (json['session_number'] as num?)?.toInt(),
      subscriptionId: json['subscription_id'] as String?,
    );
  }

  Map<String, dynamic> _toJson(TeacherAnnouncement announcement) {
    return {
      'id': announcement.id,
      'teacher_id': announcement.teacherId,
      'type': announcement.type.name,
      'dates': announcement.dates.map(_dateOnly).toList(),
      'message': announcement.message,
      'created_at': announcement.createdAt.toIso8601String(),
    };
  }

  AnnouncementType _type(String? value) {
    return AnnouncementType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => AnnouncementType.general,
    );
  }

  String _dateOnly(DateTime date) => date.toIso8601String().split('T').first;
}
