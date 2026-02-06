import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/mock_practice_note_repository.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/practice_note_repository.dart';

/// Practice note repository provider
final practiceNoteRepositoryProvider = Provider<PracticeNoteRepository>((ref) {
  return MockPracticeNoteRepository();
});

/// Section notes provider - gets all notes for a section
final sectionNotesProvider =
    FutureProvider.family<List<PracticeNote>, String>((ref, sectionId) async {
  final repository = ref.watch(practiceNoteRepositoryProvider);
  return repository.getNotes(sectionId);
});

/// Practice note CRUD notifier
class PracticeNoteCrudNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Create a new note
  Future<PracticeNote> createNote({
    required String sectionId,
    required String content,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(practiceNoteRepositoryProvider);
      final note = await repository.createNote(
        sectionId: sectionId,
        content: content,
      );

      // Invalidate related providers
      ref.invalidate(sectionNotesProvider(sectionId));

      state = const AsyncData(null);
      return note;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Update an existing note
  Future<PracticeNote> updateNote(PracticeNote note) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(practiceNoteRepositoryProvider);
      final updatedNote = await repository.updateNote(note);

      // Invalidate related providers
      ref.invalidate(sectionNotesProvider(note.sectionId));

      state = const AsyncData(null);
      return updatedNote;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Delete a note
  Future<void> deleteNote(String noteId, String sectionId) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(practiceNoteRepositoryProvider);
      await repository.deleteNote(noteId);

      // Invalidate related providers
      ref.invalidate(sectionNotesProvider(sectionId));

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final practiceNoteCrudProvider =
    AsyncNotifierProvider<PracticeNoteCrudNotifier, void>(
  PracticeNoteCrudNotifier.new,
);
