import '../entities/lesson_request.dart';

/// Repository interface for lesson requests.
///
/// Handles lesson requests from students (past status) to previous teachers.
abstract class LessonRequestRepository {
  /// Create a new lesson request
  Future<LessonRequest> create(LessonRequest request);

  /// Get a lesson request by ID
  Future<LessonRequest?> getById(String id);

  /// Get all lesson requests for a teacher (received requests)
  Future<List<LessonRequest>> getByTeacherId(String teacherId);

  /// Get all lesson requests by a student (sent requests)
  Future<List<LessonRequest>> getByStudentId(String studentId);

  /// Get pending requests for a teacher
  Future<List<LessonRequest>> getPendingByTeacherId(String teacherId);

  /// Get active request between student and teacher (if exists)
  Future<LessonRequest?> getActiveRequest({
    required String studentId,
    required String teacherId,
  });

  /// Update a lesson request
  Future<LessonRequest> update(LessonRequest request);

  /// Update request status
  Future<LessonRequest> updateStatus({
    required String id,
    required LessonRequestStatus status,
    String? proposalId,
    String? declineReason,
  });

  /// Delete a lesson request
  Future<void> delete(String id);

  /// Process expired requests (daily batch)
  Future<int> processExpiredRequests();
}
