enum AppRoadmapStatus { planned, inProgress, shipped }

class AppVersionSnapshot {
  final String currentVersion;
  final String? buildNumber;
  final String? latestVersion;
  final String? minVersion;
  final DateTime checkedAt;

  const AppVersionSnapshot({
    required this.currentVersion,
    this.buildNumber,
    this.latestVersion,
    this.minVersion,
    required this.checkedAt,
  });

  bool get hasUpdate =>
      latestVersion != null && latestVersion != currentVersion;

  bool get requiresForceUpdate {
    final min = minVersion;
    if (min == null) return false;
    return _compareVersions(currentVersion, min) < 0;
  }

  String get displayVersion {
    final build = buildNumber;
    if (build == null || build.isEmpty) {
      return currentVersion;
    }
    return '$currentVersion ($build)';
  }

  /// Compare semver strings. Returns negative if a < b.
  static int _compareVersions(String a, String b) {
    final partsA = a.split('.').map(int.tryParse).toList();
    final partsB = b.split('.').map(int.tryParse).toList();
    final len = partsA.length > partsB.length ? partsA.length : partsB.length;
    for (int i = 0; i < len; i++) {
      final va = i < partsA.length ? (partsA[i] ?? 0) : 0;
      final vb = i < partsB.length ? (partsB[i] ?? 0) : 0;
      if (va != vb) return va - vb;
    }
    return 0;
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
