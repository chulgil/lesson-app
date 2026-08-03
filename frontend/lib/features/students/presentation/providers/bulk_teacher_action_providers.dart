import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../lessons/lessons_facade.dart';
import '../../../schedule/schedule_facade.dart' as schedule;
import '../../../subscription/subscription_facade.dart';
import '../../domain/services/bulk_teacher_action_service.dart';

part 'bulk_teacher_action_providers.g.dart';

/// §7.119 v2 BulkTeacherActionService provider.
///
/// Injects [LessonRepository] + [UnifiedLessonRequestRepository]
/// + [SubscriptionRepository] so the selection mode bottom bar can fan out operations
/// across the selected students with chat event creation.
@riverpod
BulkTeacherActionService bulkTeacherActionService(Ref ref) {
  return BulkTeacherActionService(
    lessonRepository: ref.watch(lessonRepositoryProvider),
    requestRepository: ref.watch(
      schedule.unifiedLessonRequestRepositoryProvider,
    ),
    subscriptionRepository: ref.watch(subscriptionRepositoryProvider),
  );
}
