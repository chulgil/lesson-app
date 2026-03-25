import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_client.dart';
import '../../data/services/ai_notes_service.dart';

part 'ai_notes_provider.g.dart';

/// Provider for AiNotesService.
@riverpod
AiNotesService aiNotesService(AiNotesServiceRef ref) {
  final apiClient = ref.read(apiClientProvider);
  return AiNotesService(apiClient);
}

/// State for AI note generation process.
enum AiNoteStatus { idle, recording, uploading, processing, completed, failed }

/// Notifier that manages the AI note generation lifecycle.
@riverpod
class AiNoteGenerator extends _$AiNoteGenerator {
  @override
  ({AiNoteStatus status, AiNoteResult? result, String? error}) build(
    String lessonId,
  ) {
    return (status: AiNoteStatus.idle, result: null, error: null);
  }

  /// Start generating AI notes from an audio file.
  Future<void> generate({
    required String audioFilePath,
    String? studentName,
    String? instrument,
    String? level,
    List<String> pieces = const [],
  }) async {
    state = (status: AiNoteStatus.uploading, result: null, error: null);

    try {
      state = (status: AiNoteStatus.processing, result: null, error: null);

      final service = ref.read(aiNotesServiceProvider);
      final result = await service.generateFromAudio(
        audioFilePath: audioFilePath,
        lessonId: lessonId,
        studentName: studentName,
        instrument: instrument,
        level: level,
        pieces: pieces,
      );

      state = (status: AiNoteStatus.completed, result: result, error: null);
    } catch (e) {
      state = (
        status: AiNoteStatus.failed,
        result: null,
        error: 'AI 노트 생성에 실패했습니다. 다시 시도해주세요.',
      );
    }
  }

  /// Reset to idle state.
  void reset() {
    state = (status: AiNoteStatus.idle, result: null, error: null);
  }
}
