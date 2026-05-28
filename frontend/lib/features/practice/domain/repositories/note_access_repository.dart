import '../entities/note_access_request.dart';

/// Repository interface for note access requests
abstract class NoteAccessRepository {
  /// Get the current active note access request for the user (if any)
  Future<NoteAccessRequest?> getActiveAccess();

  /// Get all note access requests (history)
  Future<List<NoteAccessRequest>> getAllRequests();

  /// Get a specific request by ID
  Future<NoteAccessRequest?> getRequest(String requestId);

  /// Consent to share note with the specified request
  Future<NoteAccessRequest> consentAccess(String requestId);

  /// Reject an access request
  Future<NoteAccessRequest> rejectAccess(String requestId);

  /// Revoke a previously consented access
  Future<NoteAccessRequest> revokeAccess(String requestId);
}
