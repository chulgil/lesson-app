import '../../domain/entities/note_access_request.dart';
import '../../domain/repositories/note_access_repository.dart';

/// Empty stub used in remote mode until the note access API ships.
///
/// Returns no data and rejects mutations — real users see an empty state
/// instead of mock data.
class EmptyNoteAccessRepository implements NoteAccessRepository {
  @override
  Future<NoteAccessRequest?> getActiveAccess() async => null;

  @override
  Future<List<NoteAccessRequest>> getAllRequests() async => const [];

  @override
  Future<NoteAccessRequest?> getRequest(String requestId) async => null;

  @override
  Future<NoteAccessRequest> consentAccess(String requestId) async {
    throw UnsupportedError('Note access API is not available in remote mode.');
  }

  @override
  Future<NoteAccessRequest> rejectAccess(String requestId) async {
    throw UnsupportedError('Note access API is not available in remote mode.');
  }

  @override
  Future<NoteAccessRequest> revokeAccess(String requestId) async {
    throw UnsupportedError('Note access API is not available in remote mode.');
  }
}
