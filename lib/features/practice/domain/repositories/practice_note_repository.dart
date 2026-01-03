import '../entities/entities.dart';

/// Repository interface for practice notes
abstract class PracticeNoteRepository {
  /// Get all notes for a section
  Future<List<PracticeNote>> getNotes(String sectionId);

  /// Create a new note
  Future<PracticeNote> createNote({
    required String sectionId,
    required String content,
  });

  /// Update an existing note
  Future<PracticeNote> updateNote(PracticeNote note);

  /// Delete a note
  Future<void> deleteNote(String noteId);
}
