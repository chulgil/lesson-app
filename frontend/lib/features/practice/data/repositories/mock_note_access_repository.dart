import '../../domain/entities/note_access_request.dart';
import '../../domain/repositories/note_access_repository.dart';

/// Mock implementation of note access repository
class MockNoteAccessRepository implements NoteAccessRepository {
  final Map<String, NoteAccessRequest> _requests = {};

  MockNoteAccessRepository() {
    _initMockData();
  }

  void _initMockData() {
    // Initialize with some mock data for demonstration
    final now = DateTime.now();
    final expiresIn7Days = now.add(const Duration(days: 7));
    final expiresIn30Days = now.add(const Duration(days: 30));

    // Mock active request
    _requests['req-001'] = NoteAccessRequest(
      id: 'req-001',
      academyId: 'acad-001',
      academyName: '음악원',
      reason: '월말 평가를 위한 참고',
      expiresAt: expiresIn30Days,
      status: NoteAccessStatus.consented,
      recipientUserId: 'user-001',
      requestorUserId: 'teacher-001',
      createdAt: now.subtract(const Duration(days: 3)),
      updatedAt: now.subtract(const Duration(days: 2)),
    );

    // Mock pending request
    _requests['req-002'] = NoteAccessRequest(
      id: 'req-002',
      academyId: 'acad-002',
      academyName: '성악학원',
      reason: '공개 수업 준비 자료',
      expiresAt: expiresIn7Days,
      status: NoteAccessStatus.requested,
      recipientUserId: 'user-001',
      requestorUserId: 'teacher-002',
      createdAt: now.subtract(const Duration(days: 1)),
    );
  }

  @override
  Future<NoteAccessRequest?> getActiveAccess() async {
    await Future.delayed(const Duration(milliseconds: 100));

    for (final request in _requests.values) {
      if (request.isActive) {
        return request;
      }
    }
    return null;
  }

  @override
  Future<List<NoteAccessRequest>> getAllRequests() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _requests.values.toList();
  }

  @override
  Future<NoteAccessRequest?> getRequest(String requestId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _requests[requestId];
  }

  @override
  Future<NoteAccessRequest> consentAccess(String requestId) async {
    await Future.delayed(const Duration(milliseconds: 150));

    final request = _requests[requestId];
    if (request == null) {
      throw Exception('Request not found: $requestId');
    }

    final updated = request.copyWith(
      status: NoteAccessStatus.consented,
      updatedAt: DateTime.now(),
    );

    _requests[requestId] = updated;
    return updated;
  }

  @override
  Future<NoteAccessRequest> rejectAccess(String requestId) async {
    await Future.delayed(const Duration(milliseconds: 150));

    final request = _requests[requestId];
    if (request == null) {
      throw Exception('Request not found: $requestId');
    }

    final updated = request.copyWith(
      status: NoteAccessStatus.rejected,
      updatedAt: DateTime.now(),
    );

    _requests[requestId] = updated;
    return updated;
  }

  @override
  Future<NoteAccessRequest> revokeAccess(String requestId) async {
    await Future.delayed(const Duration(milliseconds: 150));

    final request = _requests[requestId];
    if (request == null) {
      throw Exception('Request not found: $requestId');
    }

    final updated = request.copyWith(
      status: NoteAccessStatus.revoked,
      updatedAt: DateTime.now(),
    );

    _requests[requestId] = updated;
    return updated;
  }
}
