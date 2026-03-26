import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/mock_unified_lesson_request_repository.dart';
import '../../domain/entities/unified_lesson_request.dart';
import '../../domain/repositories/unified_lesson_request_repository.dart';

part 'unified_lesson_request_providers.g.dart';

/// Repository provider — currently Mock only (Remote in backend integration phase).
final unifiedLessonRequestRepositoryProvider =
    Provider<UnifiedLessonRequestRepository>(
  (ref) => MockUnifiedLessonRequestRepository(),
);

/// Get all unified lesson requests for a teacher
@riverpod
Future<List<UnifiedLessonRequest>> teacherUnifiedRequests(
  TeacherUnifiedRequestsRef ref,
  String teacherId,
) async {
  final repository = ref.watch(unifiedLessonRequestRepositoryProvider);
  return repository.getByTeacherId(teacherId);
}

/// Get pending unified requests for a teacher
@riverpod
Future<List<UnifiedLessonRequest>> pendingUnifiedRequests(
  PendingUnifiedRequestsRef ref,
  String teacherId,
) async {
  final repository = ref.watch(unifiedLessonRequestRepositoryProvider);
  return repository.getPendingByTeacherId(teacherId);
}

/// Get pending unified request count (for badge)
@riverpod
Future<int> pendingUnifiedRequestCount(
  PendingUnifiedRequestCountRef ref,
  String teacherId,
) async {
  final requests = await ref.watch(
    pendingUnifiedRequestsProvider(teacherId).future,
  );
  return requests.length;
}

/// Get unified requests sent by a student
@riverpod
Future<List<UnifiedLessonRequest>> studentUnifiedRequests(
  StudentUnifiedRequestsRef ref,
  String studentId,
) async {
  final repository = ref.watch(unifiedLessonRequestRepositoryProvider);
  return repository.getByStudentId(studentId);
}

/// Get a single unified request by ID
@riverpod
Future<UnifiedLessonRequest?> unifiedRequestById(
  UnifiedRequestByIdRef ref,
  String requestId,
) async {
  final repository = ref.watch(unifiedLessonRequestRepositoryProvider);
  return repository.getById(requestId);
}

/// Actions for unified lesson requests (create, approve, reject).
/// Accepts both Ref and WidgetRef since it's called from providers and widgets.
class UnifiedLessonRequestActions {
  final dynamic ref;

  UnifiedLessonRequestActions(this.ref);

  UnifiedLessonRequestRepository get _repository =>
      ref.read(unifiedLessonRequestRepositoryProvider);

  /// Create a new unified lesson request
  Future<UnifiedLessonRequest> createRequest(
    UnifiedLessonRequest request,
  ) async {
    final result = await _repository.create(request);
    _invalidateProviders(request.teacherId, request.studentId);
    return result;
  }

  /// Approve a lesson request (teacher action)
  Future<UnifiedLessonRequest> approveRequest(
    String requestId,
    String teacherId,
    String studentId,
  ) async {
    final result = await _repository.approve(requestId);
    _invalidateProviders(teacherId, studentId);
    return result;
  }

  /// Reject a lesson request (teacher action)
  Future<UnifiedLessonRequest> rejectRequest(
    String requestId,
    String teacherId,
    String studentId, {
    String? reason,
  }) async {
    final result = await _repository.reject(requestId, reason: reason);
    _invalidateProviders(teacherId, studentId);
    return result;
  }

  /// Teacher proposes alternative time slots
  Future<UnifiedLessonRequest> proposeAlternatives(
    String requestId,
    String teacherId,
    String studentId, {
    required List<TimeSlotOption> slots,
    String? message,
  }) async {
    final result = await _repository.proposeAlternatives(
      requestId,
      slots: slots,
      message: message,
    );
    _invalidateProviders(teacherId, studentId);
    return result;
  }

  /// Student accepts one of the teacher's proposed alternatives
  Future<UnifiedLessonRequest> acceptAlternative(
    String requestId,
    String teacherId,
    String studentId, {
    required int selectedSlotIndex,
    String? message,
  }) async {
    final result = await _repository.acceptAlternative(
      requestId,
      selectedSlotIndex: selectedSlotIndex,
      message: message,
    );
    _invalidateProviders(teacherId, studentId);
    return result;
  }

  /// Student counter-proposes a different time slot
  Future<UnifiedLessonRequest> counterPropose(
    String requestId,
    String teacherId,
    String studentId, {
    required TimeSlotOption slot,
    String? message,
  }) async {
    final result = await _repository.counterPropose(
      requestId,
      slot: slot,
      message: message,
    );
    _invalidateProviders(teacherId, studentId);
    return result;
  }

  void _invalidateProviders(String teacherId, String studentId) {
    ref.invalidate(teacherUnifiedRequestsProvider(teacherId));
    ref.invalidate(pendingUnifiedRequestsProvider(teacherId));
    ref.invalidate(pendingUnifiedRequestCountProvider(teacherId));
    ref.invalidate(studentUnifiedRequestsProvider(studentId));
  }
}
