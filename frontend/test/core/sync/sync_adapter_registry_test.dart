import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/sync/application/sync_adapter_registry.dart';

// INV-1 (도메인-어댑터 정합, docs/specs/sync/README.md §4.2):
// queueMutation(domain: X) 로 큐잉하는 모든 도메인 X 는 반드시
// SyncAdapterRegistry 에 등록되어야 한다. 미등록이면 재생이 NO_ADAPTER 로
// 영구 실패하고 쓰기가 조용히 유실된다(G-01).
//
// 아래 목록은 실제 코드에서 queueMutation 에 전달되는 domain 문자열 전수다:
//   rg -o "domain: '[a-z-]+'" lib -g '*.dart' | sort | uniq -c
//     12 domain: 'schedule'
//      6 domain: 'student'
//      6 domain: 'lesson'
//      5 domain: 'practice'
//      4 domain: 'subscription'
// 새 도메인 큐잉을 추가하면 이 목록과 레지스트리에 함께 등록해야 한다.
const _enqueuedDomains = <String>[
  'lesson',
  'student',
  'subscription',
  'practice',
  'schedule',
];

void main() {
  group('SyncAdapterRegistry INV-1 (도메인-어댑터 정합)', () {
    test('실제 큐잉되는 모든 도메인이 어댑터로 resolve 되어야 한다', () {
      final registry = SyncAdapterRegistry.create();

      final unregistered = _enqueuedDomains
          .where((domain) => registry.resolve(domain) == null)
          .toList();

      expect(
        unregistered,
        isEmpty,
        reason:
            '미등록 도메인은 재생 시 NO_ADAPTER 로 쓰기 유실을 유발한다(G-01). '
            '레지스트리에 추가하라: $unregistered',
      );
    });

    test('schedule 도메인 어댑터가 등록되어 있어야 한다 (G-01 회귀 가드)', () {
      final registry = SyncAdapterRegistry.create();
      expect(
        registry.resolve('schedule'),
        isNotNull,
        reason:
            'availability 리포 12곳이 domain:\'schedule\' 로 큐잉한다. '
            '미등록이면 근무가능시간 저장이 오프라인/느린망에서 영구 유실된다.',
      );
    });

    test('미등록 도메인은 null 을 반환한다 (음성 대조)', () {
      final registry = SyncAdapterRegistry.create();
      expect(registry.resolve('nonexistent-domain'), isNull);
    });
  });
}
