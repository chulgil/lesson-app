import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../data/repositories/empty_note_access_repository.dart';
import '../../data/repositories/mock_note_access_repository.dart';
import '../../domain/entities/note_access_request.dart';
import '../../domain/repositories/note_access_repository.dart';

part 'note_access_provider.g.dart';

/// Note access repository provider - switches between Mock and Remote
@Riverpod(keepAlive: true)
NoteAccessRepository noteAccessRepository(NoteAccessRepositoryRef ref) {
  return createLocalFallbackRepository<NoteAccessRepository>(
    ref: ref,
    mock: () => MockNoteAccessRepository(),
    fallback: () => EmptyNoteAccessRepository(),
  );
}

/// Get the current active note access (banner display)
@Riverpod()
Future<NoteAccessRequest?> activeNoteAccess(ActiveNoteAccessRef ref) {
  final repository = ref.watch(noteAccessRepositoryProvider);
  return repository.getActiveAccess();
}

/// Get all note access requests (for history/management)
@Riverpod()
Future<List<NoteAccessRequest>> allNoteAccessRequests(
  AllNoteAccessRequestsRef ref,
) {
  final repository = ref.watch(noteAccessRepositoryProvider);
  return repository.getAllRequests();
}

/// Get a specific request by ID
@Riverpod()
Future<NoteAccessRequest?> noteAccessRequest(
  NoteAccessRequestRef ref,
  String requestId,
) {
  final repository = ref.watch(noteAccessRepositoryProvider);
  return repository.getRequest(requestId);
}

/// State notifier for managing note access actions
@Riverpod(keepAlive: true)
class NoteAccessActions extends _$NoteAccessActions {
  @override
  Future<void> build() async {}

  /// Consent to share note with the specified request
  Future<NoteAccessRequest> consentAccess(String requestId) async {
    final repository = ref.read(noteAccessRepositoryProvider);
    final result = await repository.consentAccess(requestId);

    // Invalidate related providers to trigger refresh
    ref.invalidate(activeNoteAccessProvider);
    ref.invalidate(allNoteAccessRequestsProvider);
    ref.invalidate(noteAccessRequestProvider);

    return result;
  }

  /// Reject an access request
  Future<NoteAccessRequest> rejectAccess(String requestId) async {
    final repository = ref.read(noteAccessRepositoryProvider);
    final result = await repository.rejectAccess(requestId);

    // Invalidate related providers to trigger refresh
    ref.invalidate(activeNoteAccessProvider);
    ref.invalidate(allNoteAccessRequestsProvider);
    ref.invalidate(noteAccessRequestProvider);

    return result;
  }

  /// Revoke a previously consented access
  Future<NoteAccessRequest> revokeAccess(String requestId) async {
    final repository = ref.read(noteAccessRepositoryProvider);
    final result = await repository.revokeAccess(requestId);

    // Invalidate related providers to trigger refresh
    ref.invalidate(activeNoteAccessProvider);
    ref.invalidate(allNoteAccessRequestsProvider);
    ref.invalidate(noteAccessRequestProvider);

    return result;
  }
}
