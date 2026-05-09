import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/app_release.dart';
import '../../domain/repositories/app_release_repository.dart';

/// Remote implementation of [AppReleaseRepository] using backend /app/version API.
class RemoteAppReleaseRepository implements AppReleaseRepository {
  RemoteAppReleaseRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<AppReleaseSnapshot> fetchReleaseSnapshot() async {
    try {
      final response = await _apiClient.get<dynamic>('/app/version');
      final data = response.data;

      final map = (data is Map<String, dynamic>) ? data : <String, dynamic>{};
      return AppReleaseSnapshot(
        version: _parseVersion(map['version'] ?? map),
        news: _parseNewsList(
          map['news'] ?? map['newsItems'] ?? map['news_items'],
        ),
        roadmap: _parseRoadmapList(
          map['roadmap'] ??
              map['roadmapItems'] ??
              map['roadmap_items'],
        ),
      );
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 404 || statusCode == 405 || statusCode == 501) {
        return _fallbackSnapshot();
      }
      rethrow;
    }
  }

  AppVersionSnapshot _parseVersion(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return AppVersionSnapshot(
        currentVersion: _asString(raw, 'currentVersion') ??
            _asString(raw, 'current_version') ??
            '1.0.0',
        buildNumber: _asString(raw, 'buildNumber') ?? _asString(raw, 'build_number'),
        latestVersion:
            _asString(raw, 'latestVersion') ?? _asString(raw, 'latest_version'),
        minVersion:
            _asString(raw, 'minVersion') ?? _asString(raw, 'min_version'),
        checkedAt: _parseDate(raw['checkedAt'] ?? raw['checked_at']) ??
            DateTime.now().toUtc(),
      );
    }

    return AppVersionSnapshot(
      currentVersion: '1.0.0',
      buildNumber: null,
      latestVersion: null,
      checkedAt: DateTime.now().toUtc(),
    );
  }

  List<AppNewsItem> _parseNewsList(dynamic raw) {
    if (raw is! List) {
      return const [];
    }

    return raw
        .whereType<Map<String, dynamic>>()
        .map(
          (entry) => AppNewsItem(
            id: _asString(entry, 'id') ?? '',
            title: _asString(entry, 'title') ?? '',
            summary: _asString(entry, 'summary') ?? '',
            publishedAt:
                _parseDate(entry['publishedAt'] ?? entry['published_at']) ??
                DateTime.now().toUtc(),
            link: _asString(entry, 'link'),
          ),
        )
        .toList(growable: false);
  }

  List<AppRoadmapItem> _parseRoadmapList(dynamic raw) {
    if (raw is! List) {
      return const [];
    }

    return raw
        .whereType<Map<String, dynamic>>()
        .map(
          (entry) => AppRoadmapItem(
            id: _asString(entry, 'id') ?? '',
            title: _asString(entry, 'title') ?? '',
            summary: _asString(entry, 'summary') ?? '',
            status: _parseStatus(_asString(entry, 'status')),
            targetDate: _parseDate(entry['targetDate'] ?? entry['target_date']),
          ),
        )
        .toList(growable: false);
  }

  static AppRoadmapStatus _parseStatus(String? rawStatus) {
    switch ((rawStatus ?? 'planned').toLowerCase()) {
      case 'in_progress':
      case 'inprogress':
      case 'in_progress_':
      case 'progress':
        return AppRoadmapStatus.inProgress;
      case 'shipped':
      case 'completed':
      case 'done':
        return AppRoadmapStatus.shipped;
      case 'planned':
      case 'plan':
      default:
        return AppRoadmapStatus.planned;
    }
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw)?.toUtc();
    }
    return null;
  }

  static String? _asString(Map<String, dynamic> source, String key) {
    final value = source[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return null;
  }

  static AppReleaseSnapshot _fallbackSnapshot() {
    return AppReleaseSnapshot(
      version: AppVersionSnapshot(
        currentVersion: '1.0.0',
        latestVersion: '1.1.0',
        checkedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      ),
      news: [],
      roadmap: [],
    );
  }
}
