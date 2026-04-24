import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../lessons/presentation/providers/lesson_repository_provider.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../domain/services/bulk_teacher_action_service.dart';

part 'bulk_teacher_action_providers.g.dart';

/// §7.119 BulkTeacherActionService provider.
///
/// Injects [LessonRepository] + [NotificationService] so the selection mode
/// bottom bar ([BulkCancelScreen] / [BulkMessageSheet]) can fan out operations
/// across the selected students.
@riverpod
BulkTeacherActionService bulkTeacherActionService(Ref ref) {
  return BulkTeacherActionService(
    lessonRepository: ref.watch(lessonRepositoryProvider),
    notificationService: ref.watch(notificationServiceProvider),
  );
}
