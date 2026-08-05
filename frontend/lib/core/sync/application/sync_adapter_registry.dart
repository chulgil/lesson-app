import 'package:flutter/foundation.dart';

import 'sync_adapter.dart';

class SyncAdapterRegistry {
  SyncAdapterRegistry._(this._adapters);

  final Map<String, SyncAdapter> _adapters;

  factory SyncAdapterRegistry.create() {
    return SyncAdapterRegistry._({
      for (final adapter in _createDefaultAdapters()) adapter.domain: adapter,
    });
  }

  SyncAdapter? resolve(String domain) => _adapters[domain];

  static Iterable<SyncAdapter> _createDefaultAdapters() {
    const domains = [
      'analytics',
      'auth',
      'follow',
      'lesson',
      'teaching-resource',
      'notification',
      'onboarding',
      'parent',
      'practice',
      'relationship',
      // G-01: availability 리포는 domain:'schedule' 로 큐잉한다(12곳).
      // 이전 'booking' 은 큐잉 호출처가 없는 미사용 도메인 → 'schedule' 로
      // 교정해 근무가능시간 쓰기 유실(재생 NO_ADAPTER)을 막는다.
      'schedule',
      'search',
      'settings',
      'student-home',
      'student',
      'subscription',
      'teacher-profile',
      'feedback',
      'notification-settings',
      'manual-teacher',
      'location',
    ];
    const expectedDomainCount = 21;
    if (kDebugMode && domains.length != expectedDomainCount) {
      throw StateError(
        'SyncAdapter domain count should be $expectedDomainCount in baseline',
      );
    }

    return domains.map((domain) => RestSyncAdapter(domain: domain));
  }
}
