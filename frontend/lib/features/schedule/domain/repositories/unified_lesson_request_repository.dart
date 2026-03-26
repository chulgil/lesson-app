import '../entities/unified_lesson_request.dart';

/// Repository interface for unified lesson requests.
abstract class UnifiedLessonRequestRepository {
  /// Create a new unified lesson request
  Future<UnifiedLessonRequest> create(UnifiedLessonRequest request);

  /// Get a request by ID
  Future<UnifiedLessonRequest?> getById(String id);

  /// Get all requests for a teacher (received)
  Future<List<UnifiedLessonRequest>> getByTeacherId(String teacherId);

  /// Get all requests by a student (sent)
  Future<List<UnifiedLessonRequest>> getByStudentId(String studentId);

  /// Get pending requests for a teacher
  Future<List<UnifiedLessonRequest>> getPendingByTeacherId(String teacherId);

  /// Update a request
  Future<UnifiedLessonRequest> update(UnifiedLessonRequest request);

  /// Approve a request (teacher action)
  Future<UnifiedLessonRequest> approve(String id);

  /// Reject a request with optional reason (teacher action)
  Future<UnifiedLessonRequest> reject(String id, {String? reason});

  /// Teacher proposes up to 3 alternative time slots
  Future<UnifiedLessonRequest> proposeAlternatives(
    String id, {
    required List<TimeSlotOption> slots,
    String? message,
  });

  /// Student accepts one of the teacher's proposed alternatives
  Future<UnifiedLessonRequest> acceptAlternative(
    String id, {
    required int selectedSlotIndex,
    String? message,
  });

  /// Student counter-proposes a different time slot
  Future<UnifiedLessonRequest> counterPropose(
    String id, {
    required TimeSlotOption slot,
    String? message,
  });
}
