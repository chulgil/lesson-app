import '../../../../core/network/api_client.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/practice_note_repository.dart';

class RemotePracticeNoteRepository implements PracticeNoteRepository {
  RemotePracticeNoteRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<PracticeNote>> getNotes(String sectionId) async {
    final response = await _apiClient.get(
      '/practice/sections/$sectionId/notes',
    );
    final items = response.data as List<dynamic>;
    return items
        .map((item) => PracticeNote.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<PracticeNote> createNote({
    required String sectionId,
    required String content,
  }) async {
    final response = await _apiClient.post(
      '/practice/sections/$sectionId/notes',
      data: {'content': content},
    );
    return PracticeNote.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<PracticeNote> updateNote(PracticeNote note) async {
    final response = await _apiClient.put(
      '/practice/notes/${note.id}',
      data: {'content': note.content},
    );
    return PracticeNote.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteNote(String noteId) async {
    await _apiClient.delete('/practice/notes/$noteId');
  }
}
