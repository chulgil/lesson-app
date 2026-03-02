import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/config/environment.dart';
import '../../../../core/network/api_client.dart';
import '../../data/repositories/mock_lesson_request_repository.dart';
import '../../data/repositories/remote_lesson_request_repository.dart';
import '../../domain/entities/lesson_request.dart';
import '../../domain/repositories/lesson_request_repository.dart';

part 'lesson_request_providers.g.dart';

/// Repository provider - switches between Mock and Remote.
final lessonRequestRepositoryProvider = Provider<LessonRequestRepository>((
  ref,
) {
  if (EnvironmentConfig.useMockData) {
    return MockLessonRequestRepository();
  }
  return RemoteLessonRequestRepository(ref.read(apiClientProvider));
});

/// Get all lesson requests for a teacher
@riverpod
Future<List<LessonRequest>> teacherLessonRequests(
  TeacherLessonRequestsRef ref,
  String teacherId,
) async {
  final repository = ref.watch(lessonRequestRepositoryProvider);
  return repository.getByTeacherId(teacherId);
}

/// Get pending lesson requests for a teacher
@riverpod
Future<List<LessonRequest>> pendingLessonRequests(
  PendingLessonRequestsRef ref,
  String teacherId,
) async {
  final repository = ref.watch(lessonRequestRepositoryProvider);
  return repository.getPendingByTeacherId(teacherId);
}

/// Get pending request count for a teacher (for badge)
@riverpod
Future<int> pendingLessonRequestCount(
  PendingLessonRequestCountRef ref,
  String teacherId,
) async {
  final requests = await ref.watch(
    pendingLessonRequestsProvider(teacherId).future,
  );
  return requests.length;
}

/// Get all lesson requests sent by a student
@riverpod
Future<List<LessonRequest>> studentLessonRequests(
  StudentLessonRequestsRef ref,
  String studentId,
) async {
  final repository = ref.watch(lessonRequestRepositoryProvider);
  return repository.getByStudentId(studentId);
}

/// Get a single lesson request by ID
@riverpod
Future<LessonRequest?> lessonRequestById(
  LessonRequestByIdRef ref,
  String requestId,
) async {
  final repository = ref.watch(lessonRequestRepositoryProvider);
  return repository.getById(requestId);
}

/// Lesson request actions (create, update, respond)
@riverpod
class LessonRequestActions extends _$LessonRequestActions {
  @override
  Future<void> build() async {}

  /// Create a new lesson request
  Future<LessonRequest> createRequest(LessonRequest request) async {
    final repository = ref.read(lessonRequestRepositoryProvider);
    final created = await repository.create(request);

    // Invalidate related caches
    ref.invalidate(teacherLessonRequestsProvider(request.teacherId));
    ref.invalidate(pendingLessonRequestsProvider(request.teacherId));
    ref.invalidate(pendingLessonRequestCountProvider(request.teacherId));
    ref.invalidate(studentLessonRequestsProvider(request.studentId));

    return created;
  }

  /// Teacher sends subscription proposal
  Future<LessonRequest> sendProposal({
    required String requestId,
    required String proposalId,
  }) async {
    final repository = ref.read(lessonRequestRepositoryProvider);
    final updated = await repository.updateStatus(
      id: requestId,
      status: LessonRequestStatus.proposalSent,
      proposalId: proposalId,
    );

    _invalidateAll(updated);
    return updated;
  }

  /// Teacher declines the request
  Future<LessonRequest> declineRequest({
    required String requestId,
    required String reason,
  }) async {
    final repository = ref.read(lessonRequestRepositoryProvider);
    final updated = await repository.updateStatus(
      id: requestId,
      status: LessonRequestStatus.declined,
      declineReason: reason,
    );

    _invalidateAll(updated);
    return updated;
  }

  /// Student cancels the request
  Future<LessonRequest> cancelRequest(String requestId) async {
    final repository = ref.read(lessonRequestRepositoryProvider);
    final updated = await repository.updateStatus(
      id: requestId,
      status: LessonRequestStatus.cancelled,
    );

    _invalidateAll(updated);
    return updated;
  }

  void _invalidateAll(LessonRequest request) {
    ref.invalidate(lessonRequestByIdProvider(request.id));
    ref.invalidate(teacherLessonRequestsProvider(request.teacherId));
    ref.invalidate(pendingLessonRequestsProvider(request.teacherId));
    ref.invalidate(pendingLessonRequestCountProvider(request.teacherId));
    ref.invalidate(studentLessonRequestsProvider(request.studentId));
  }
}
