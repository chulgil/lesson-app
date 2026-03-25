import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';

/// Service for AI lesson note generation via backend API.
class AiNotesService {
  final ApiClient _apiClient;

  AiNotesService(this._apiClient);

  /// Upload audio and generate AI notes for a lesson.
  ///
  /// Returns structured notes: feedback, keyPoints, practiceTips, suggestedAssignments.
  Future<AiNoteResult> generateFromAudio({
    required String audioFilePath,
    required String lessonId,
    String? studentName,
    String? instrument,
    String? level,
    List<String> pieces = const [],
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(audioFilePath, filename: 'lesson.m4a'),
      'lesson_id': lessonId,
      if (studentName != null) 'student_name': studentName,
      if (instrument != null) 'instrument': instrument,
      if (level != null) 'level': level,
      if (pieces.isNotEmpty) 'pieces': pieces.join(','),
    });

    final response = await _apiClient.post('/ai-notes/generate', data: formData);
    final data = response.data as Map<String, dynamic>;
    return AiNoteResult.fromJson(data);
  }

  /// Get existing AI notes for a lesson.
  Future<AiNoteResult?> getForLesson(String lessonId) async {
    try {
      final response = await _apiClient.get('/ai-notes/$lessonId');
      if (response.data == null) return null;
      return AiNoteResult.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}

/// Result from AI note generation.
class AiNoteResult {
  final String id;
  final String lessonId;
  final String? feedback;
  final List<String> keyPoints;
  final String? practiceTips;
  final List<SuggestedAssignment> suggestedAssignments;
  final String? transcription;
  final String status;

  const AiNoteResult({
    required this.id,
    required this.lessonId,
    this.feedback,
    this.keyPoints = const [],
    this.practiceTips,
    this.suggestedAssignments = const [],
    this.transcription,
    this.status = 'completed',
  });

  factory AiNoteResult.fromJson(Map<String, dynamic> json) {
    return AiNoteResult(
      id: json['id'] as String? ?? '',
      lessonId: json['lesson_id'] as String? ?? '',
      feedback: json['feedback'] as String?,
      keyPoints: (json['key_points'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      practiceTips: json['practice_tips'] as String?,
      suggestedAssignments: (json['suggested_assignments'] as List<dynamic>?)
              ?.map((e) => SuggestedAssignment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      transcription: json['transcription'] as String?,
      status: json['status'] as String? ?? 'completed',
    );
  }
}

class SuggestedAssignment {
  final String title;
  final String description;

  const SuggestedAssignment({required this.title, required this.description});

  factory SuggestedAssignment.fromJson(Map<String, dynamic> json) {
    return SuggestedAssignment(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}
