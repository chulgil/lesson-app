// #1118 — sendTimeout must be set so a stalled upload cannot hang until the
// OS TCP timeout on slow networks (spec docs/specs/sync/README.md SN-5).

import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/network/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('main Dio 는 connect/receive/send 타임아웃을 모두 설정한다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final dio = container.read(apiClientProvider).dio;

    expect(dio.options.connectTimeout, isNotNull);
    expect(dio.options.receiveTimeout, isNotNull);
    expect(
      dio.options.sendTimeout,
      isNotNull,
      reason: 'sendTimeout 미설정 시 업로드 정지가 OS TCP 타임아웃까지 행 (#1118)',
    );
  });
}
