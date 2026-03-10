// Centralized factory functions for creating test entities with sensible defaults.
// Tests only need to specify the fields they care about.

import 'package:lessonaza/features/lessons/domain/entities/teaching_resource.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription.dart';

// Fixed date for deterministic tests
final _fixedDate = DateTime(2026, 1, 15);

/// Create a TeachingResource with YouTube defaults
TeachingResource createTeachingResource({
  String id = 'tr_test',
  String teacherId = 'teacher_1',
  TeachingResourceType type = TeachingResourceType.youtube,
  String title = 'Test Resource',
  String? description,
  String? youtubeUrl = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
  String? youtubeVideoId = 'dQw4w9WgXcQ',
  String? youtubeThumbnail,
  int? youtubeStartSeconds,
  int? youtubeEndSeconds,
  String? audioUrl,
  int? audioDurationSeconds,
  String? externalUrl,
  String? instrument,
  List<String> tags = const [],
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return TeachingResource(
    id: id,
    teacherId: teacherId,
    type: type,
    title: title,
    description: description,
    youtubeUrl: youtubeUrl,
    youtubeVideoId: youtubeVideoId,
    youtubeThumbnail: youtubeThumbnail,
    youtubeStartSeconds: youtubeStartSeconds,
    youtubeEndSeconds: youtubeEndSeconds,
    audioUrl: audioUrl,
    audioDurationSeconds: audioDurationSeconds,
    externalUrl: externalUrl,
    instrument: instrument,
    tags: tags,
    createdAt: createdAt ?? _fixedDate,
    updatedAt: updatedAt,
  );
}

/// Create a Subscription with package defaults
Subscription createSubscription({
  String id = 'sub_test',
  String studentId = 'student_1',
  String membershipId = 'cm_001',
  SubscriptionType type = SubscriptionType.package,
  int? totalLessons = 8,
  int? lessonsPerMonth,
  int usedLessons = 0,
  int bonusCount = 0,
  DateTime? startDate,
  DateTime? endDate,
  int amount = 200000,
  SubscriptionStatus status = SubscriptionStatus.active,
  DateTime? createdAt,
}) {
  return Subscription(
    id: id,
    studentId: studentId,
    membershipId: membershipId,
    type: type,
    totalLessons: totalLessons,
    lessonsPerMonth: lessonsPerMonth,
    usedLessons: usedLessons,
    bonusCount: bonusCount,
    startDate: startDate ?? _fixedDate,
    endDate: endDate ?? _fixedDate.add(const Duration(days: 30)),
    amount: amount,
    status: status,
    createdAt: createdAt ?? _fixedDate,
  );
}
