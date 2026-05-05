import '../../../../core/l10n/app_strings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../notifications/domain/entities/notification.dart';
import '../../../notifications/notifications_facade.dart';
import '../../domain/entities/recording_feedback.dart';

part 'recording_feedback_provider.g.dart';

/// In-memory store of teacher feedbacks keyed by recordingId.
/// Mock-only — persistence/backend wired when API is available.
@Riverpod(keepAlive: true)
class RecordingFeedbackList extends _$RecordingFeedbackList {
  @override
  List<RecordingFeedback> build(String recordingId) => const [];

  Future<void> add({
    required String teacherId,
    required String content,
    String? studentId,
    String? repertoireName,
  }) async {
    final feedback = RecordingFeedback(
      id: 'fb_${DateTime.now().microsecondsSinceEpoch}',
      recordingId: recordingId,
      teacherId: teacherId,
      content: content.trim(),
      createdAt: DateTime.now(),
    );
    state = [...state, feedback];

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
}

/// Count of feedbacks for a recording (for list indicators).
@riverpod
int recordingFeedbackCount(Ref ref, String recordingId) {
  return ref.watch(recordingFeedbackListProvider(recordingId)).length;
}
