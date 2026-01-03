import 'package:uuid/uuid.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/practice_note_repository.dart';

/// Mock implementation of PracticeNoteRepository
class MockPracticeNoteRepository implements PracticeNoteRepository {
  final Map<String, PracticeNote> _notes = {};
  final _uuid = const Uuid();

  MockPracticeNoteRepository() {
    // Add some sample notes for testing
    _initializeSampleNotes();
  }

  void _initializeSampleNotes() {
    // Sample notes will be created when sections are created
    // For now, we start empty and add notes as they are created
  }

  @override
  Future<List<PracticeNote>> getNotes(String sectionId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final notes =
        _notes.values.where((n) => n.sectionId == sectionId).toList();
    // Sort by createdAt descending (newest first)
    notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notes;
  }

  @override
  Future<PracticeNote> createNote({
    required String sectionId,
    required String content,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final note = PracticeNote(
      id: _uuid.v4(),
      sectionId: sectionId,
      content: content,
      createdAt: DateTime.now(),
    );
    _notes[note.id] = note;
    return note;
  }

  @override
  Future<PracticeNote> updateNote(PracticeNote note) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (!_notes.containsKey(note.id)) {
      throw Exception('Note not found: ${note.id}');
    }
    final updatedNote = note.copyWith(updatedAt: DateTime.now());
    _notes[note.id] = updatedNote;
    return updatedNote;
  }

  @override
  Future<void> deleteNote(String noteId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (!_notes.containsKey(noteId)) {
      throw Exception('Note not found: $noteId');
    }
    _notes.remove(noteId);
  }
}
