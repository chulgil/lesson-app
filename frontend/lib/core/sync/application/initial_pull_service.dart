import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../../features/lessons/data/local/lesson_cache_store.dart';
import '../../../features/lessons/data/repositories/remote_lesson_repository.dart';
import 'connectivity_service.dart';

/// User-scoped Hive box that stores initialSyncComplete flags.
///
/// Key pattern: `<userId>:initialSyncDone` → `'1'`
const _flagBoxName = 'initial_pull_flags_v1';

/// Pulls server-side lessons into [LessonCacheStore] on first login.
///
/// Design decisions:
/// - lessons domain only; students/schedule are handled in #869 (TODO).
/// - user id scoped flag prevents re-pulling on logout → re-login.
/// - offline guard: skips silently if network is unavailable; the next
///   online session will re-run (flag not set until success).
/// - non-blocking: callers fire-and-forget via `unawaited(...)`.
class InitialPullService {
  InitialPullService({
    required RemoteLessonRepository remoteLessons,
    required LessonCacheStore lessonCache,
    required ConnectivityService connectivity,
  }) : _remoteLessons = remoteLessons,
       _lessonCache = lessonCache,
       _connectivity = connectivity;

  final RemoteLessonRepository _remoteLessons;
  final LessonCacheStore _lessonCache;
  final ConnectivityService _connectivity;

  /// Runs the initial pull for [userId] if not already completed.
  ///
  /// Safe to call from auth flow (fire-and-forget). Never throws.
  Future<void> runIfNeeded(String userId) async {
    try {
      final box = await _openFlagBox();
      final flagKey = '$userId:initialSyncDone';

      if (box.get(flagKey) == '1') {
        debugPrint('[InitialPull] already done for user=$userId — skip');
        return;
      }

      final online = await _connectivity.isOnline;
      if (!online) {
        debugPrint('[InitialPull] offline — will retry on next online login');
        return;
      }

      debugPrint('[InitialPull] pulling lessons for user=$userId ...');
      final lessons = await _remoteLessons.getLessons();
      await _lessonCache.putLessons(LessonCacheStore.keyAll(), lessons);
      debugPrint('[InitialPull] seeded ${lessons.length} lessons into cache');

      // TODO(#869): pull students and schedule domains here when implemented.

      await box.put(flagKey, '1');
      debugPrint('[InitialPull] flag set — done');
    } catch (e) {
      // Never surface to caller — offline/network errors should not break login.
      debugPrint('[InitialPull] failed (will retry next login): $e');
    }
  }

  Future<Box<String>> _openFlagBox() async {
    if (Hive.isBoxOpen(_flagBoxName)) {
      return Hive.box<String>(_flagBoxName);
    }
    return Hive.openBox<String>(_flagBoxName);
  }
}
