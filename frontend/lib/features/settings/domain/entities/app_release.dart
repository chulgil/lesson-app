enum AppRoadmapStatus { planned, inProgress, shipped }

class AppVersionSnapshot {
  final String currentVersion;
  final String? buildNumber;
  final String? latestVersion;
  final DateTime checkedAt;

  const AppVersionSnapshot({
    required this.currentVersion,
    this.buildNumber,
    this.latestVersion,
    required this.checkedAt,
  });

  bool get hasUpdate =>
      latestVersion != null && latestVersion != currentVersion;

  String get displayVersion {
    final build = buildNumber;
    if (build == null || build.isEmpty) {
      return currentVersion;
    }
    return '$currentVersion ($build)';
  }
}

class AppNewsItem {
  final String id;
  final String title;
  final String summary;
  final DateTime publishedAt;
  final String? link;

  const AppNewsItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.publishedAt,
    this.link,
  });
}

class AppRoadmapItem {
  final String id;
  final String title;
  final String summary;
  final AppRoadmapStatus status;
  final DateTime? targetDate;

  const AppRoadmapItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.status,
    this.targetDate,
  });
}

class AppReleaseSnapshot {
  final AppVersionSnapshot version;
  final List<AppNewsItem> news;
  final List<AppRoadmapItem> roadmap;

  const AppReleaseSnapshot({
    required this.version,
    this.news = const [],
    this.roadmap = const [],
  });
}

class ReviewPromptPolicy {
  final int completedLessonThreshold;
  final Duration cooldown;

  const ReviewPromptPolicy({
    this.completedLessonThreshold = 10,
    this.cooldown = const Duration(days: 30),
  });

  bool isEligible({
    required int completedLessonCount,
    DateTime? lastPromptedAt,
    DateTime? now,
  }) {
    if (completedLessonCount < completedLessonThreshold) {
      return false;
    }

    final promptedAt = lastPromptedAt;
    if (promptedAt == null) {
      return true;
    }

    final currentTime = now ?? DateTime.now();
    return currentTime.difference(promptedAt) >= cooldown;
  }
}
