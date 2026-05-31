import '../../../../core/l10n/app_strings.dart';
import '../../../../core/providers/repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../notifications/domain/entities/notification.dart';
import '../../../notifications/notifications_facade.dart';
import '../../data/repositories/mock_recording_feedback_repository.dart';
import '../../data/repositories/remote_recording_feedback_repository.dart';
import '../../domain/entities/recording_feedback.dart';
import '../../domain/repositories/recording_feedback_repository.dart';

part 'recording_feedback_provider.g.dart';

final recordingFeedbackRepositoryProvider =
    Provider<RecordingFeedbackRepository>(
      (ref) => createRepository<RecordingFeedbackRepository>(
        ref: ref,
        mock: MockRecordingFeedbackRepository.new,
        remote: RemoteRecordingFeedbackRepository.new,
      ),
    );

/// Feedbacks keyed by recordingId.
@Riverpod(keepAlive: true)
class RecordingFeedbackList extends _$RecordingFeedbackList {
  @override
  List<RecordingFeedback> build(String recordingId) {
    Future.microtask(_load);
    return const [];
  }

  Future<void> add({
    required String teacherId,
    required String content,
    String? studentId,
    String? repertoireName,
  }) async {
    final trimmedContent = content.trim();
    if (trimmedContent.isEmpty) {
      return;
    }

    final repository = ref.read(recordingFeedbackRepositoryProvider);
    final feedback = await repository.create(
      recordingId: recordingId,
      teacherId: teacherId,
      content: trimmedContent,
    );
    state = [
      ...state.where((existing) => existing.id != feedback.id),
      feedback,
    ];

    if (studentId != null) {
      await _notifyStudent(
        studentId: studentId,
        repertoireName: repertoireName,
      );
    }
  }

  Future<void> _notifyStudent({
    required String studentId,
    String? repertoireName,
  }) async {
    final service = ref.read(notificationServiceProvider);
    final body =
        repertoireName != null && repertoireName.isNotEmpty
            ? '$repertoireName 녹음에 새 피드백이 도착했어요'
            : '공유한 녹음에 새 피드백이 도착했어요';
    await service.showNotification(
      AppNotification(
        id: 'notif_feedback_${DateTime.now().microsecondsSinceEpoch}',
        userId: studentId,
        type: NotificationType.recordingFeedbackReceived,
        priority: NotificationPriority.normal,
        title: AppStrings.practiceTeacherFeedbackArrived,
        body: body,
        createdAt: DateTime.now(),
        actionUrl: '/recordings/$recordingId',
        actionLabel: '피드백 보기',
      ),
    );
  }

  Future<void> _load() async {
    final repository = ref.read(recordingFeedbackRepositoryProvider);
    state = await repository.list(recordingId);
  }
}

/// Count of feedbacks for a recording (for list indicators).
@riverpod
int recordingFeedbackCount(Ref ref, String recordingId) {
  return ref.watch(recordingFeedbackListProvider(recordingId)).length;
}
