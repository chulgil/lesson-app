import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../../features/lessons/data/repositories/remote_lesson_repository.dart';
import '../../../features/schedule/data/repositories/remote_teacher_availability_repository.dart';
import '../../../features/students/data/repositories/remote_student_repository.dart';
import 'connectivity_service.dart';

/// User-scoped Hive box that stores initialSyncComplete flags.
///
/// Key pattern: `<userId>:initialSyncDone` → `'1'`
const _flagBoxName = 'initial_pull_flags_v1';

/// Warms the HTTP response cache on first login (offline-launch backbone).
///
/// Design decisions:
/// - Covers lessons, students and schedule (availability) domains.
/// - Warming mechanism: each pull calls the SAME remote repository method the
///   app's read path uses. The request goes through ApiClient →
///   ResponseCacheInterceptor, which persists the response in
///   ResponseCacheStore under the exact cache key (path + query params) the
///   read path will later request. A subsequent offline launch is therefore
///   served from the HTTP response cache — no per-domain cache store exists.
/// - Repertoires domain has no remote endpoint warmed yet — tracked as TODO(#877).
/// - Partial-failure isolation: each domain is pulled in its own try/catch so
///   one domain failing does NOT block the others or abort the whole pull.
/// - user id scoped flag prevents re-pulling on logout → re-login.
/// - offline guard: skips silently if network is unavailable; the next
///   online session will re-run (flag not set until ALL domains succeed).
/// - non-blocking: callers fire-and-forget via `unawaited(...)`.
class InitialPullService {
  InitialPullService({
    required RemoteLessonRepository remoteLessons,
    required RemoteStudentRepository remoteStudents,
    required RemoteTeacherAvailabilityRepository remoteAvailability,
    required ConnectivityService connectivity,
  }) : _remoteLessons = remoteLessons,
       _remoteStudents = remoteStudents,
       _remoteAvailability = remoteAvailability,
       _connectivity = connectivity;

  final RemoteLessonRepository _remoteLessons;
  final RemoteStudentRepository _remoteStudents;
  final RemoteTeacherAvailabilityRepository _remoteAvailability;
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

      debugPrint('[InitialPull] starting pull for user=$userId ...');

      // Each domain is isolated: failure in one does not abort others.
      final results = await Future.wait([
        _pullLessons(),
        _pullStudents(),
        _pullAvailability(userId),
      ]);

      final allSucceeded = results.every((ok) => ok);
      if (allSucceeded) {
        await box.put(flagKey, '1');
        debugPrint('[InitialPull] all domains succeeded — flag set');
      } else {
        debugPrint(
          '[InitialPull] some domains failed — flag NOT set, will retry',
        );
      }
    } catch (e) {
      // Never surface to caller — offline/network errors should not break login.
      debugPrint('[InitialPull] outer failure (will retry next login): $e');
    }
  }

  /// Warms the lessons HTTP response cache (via ResponseCacheInterceptor).
  /// Returns true on success.
  Future<bool> _pullLessons() async {
    try {
      debugPrint('[InitialPull] pulling lessons ...');
      final lessons = await _remoteLessons.getLessons();
      debugPrint('[InitialPull] warmed ${lessons.length} lessons');
      return true;
    } catch (e) {
      debugPrint('[InitialPull] lessons pull failed (isolated): $e');
      return false;
    }
  }

  /// Warms the students HTTP response cache (via ResponseCacheInterceptor).
  /// Returns true on success.
  Future<bool> _pullStudents() async {
    try {
      debugPrint('[InitialPull] pulling students ...');
      final students = await _remoteStudents.getStudents();
      debugPrint('[InitialPull] warmed ${students.length} students');
      return true;
    } catch (e) {
      debugPrint('[InitialPull] students pull failed (isolated): $e');
      return false;
    }
  }

  /// Warms the teacher availability HTTP response cache (via
  /// ResponseCacheInterceptor).
  /// Returns true on success (including 404 → no availability yet).
  Future<bool> _pullAvailability(String userId) async {
    try {
      debugPrint('[InitialPull] pulling availability for user=$userId ...');
      final availability = await _remoteAvailability.getAvailability(userId);
      debugPrint(
        '[InitialPull] warmed availability (null=${availability == null})',
      );
      return true;
    } catch (e) {
      debugPrint('[InitialPull] availability pull failed (isolated): $e');
      return false;
    }
  }

  Future<Box<String>> _openFlagBox() async {
    if (Hive.isBoxOpen(_flagBoxName)) {
      return Hive.box<String>(_flagBoxName);
    }
    return Hive.openBox<String>(_flagBoxName);
  }
}
