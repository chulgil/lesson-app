// R2 #318 — DeepLinkHandler 통합 테스트.
//
// AppLinks / GoRouter 인스턴스를 모두 우회한다:
//   - AppLinks: 콜백 DI (typedef InitialUriProvider / UriStreamProvider)
//   - GoRouter: navigate 콜백 (recorded.add 직접 주입)
//
// 위젯 트리 없이 IO 어댑터 단위 동작만 검증한다.
// (feedback memory: spy mock + 동기 Future — Timer pending 회피)

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/deep_link/deep_link_handler.dart';

void main() {
  test('cold-start invite URI forwards code as query param', () async {
    final recorded = <String>[];

    final handler = DeepLinkHandler(
      navigate: recorded.add,
      initialUriProvider: () async => Uri.parse('lessonapp://invite/123456'),
      uriStreamProvider: () => const Stream<Uri>.empty(),
    );

    await handler.start();

    // Regression: code must be carried so CodeInputScreen prefills.
    expect(recorded, ['/invite/code?code=123456']);

    await handler.dispose();
  });

  test('cold-start summary URI navigates with token', () async {
    final recorded = <String>[];

    final handler = DeepLinkHandler(
      navigate: recorded.add,
      initialUriProvider:
          () async => Uri.parse('lessonapp://student/summary/tok-xyz'),
      uriStreamProvider: () => const Stream<Uri>.empty(),
    );

    await handler.start();

    expect(recorded, ['/student/summary/tok-xyz']);

    await handler.dispose();
  });

  test('warm URI from stream triggers navigation', () async {
    final recorded = <String>[];
    final controller = StreamController<Uri>.broadcast();

    final handler = DeepLinkHandler(
      navigate: recorded.add,
      initialUriProvider: () async => null,
      uriStreamProvider: () => controller.stream,
    );

    await handler.start();
    controller.add(Uri.parse('lessonapp://invite/654321'));
    await Future<void>.delayed(Duration.zero); // let stream deliver

    expect(recorded, ['/invite/code?code=654321']);

    await handler.dispose();
    await controller.close();
  });

  test('unknown URI is ignored — no navigation', () async {
    final recorded = <String>[];

    final handler = DeepLinkHandler(
      navigate: recorded.add,
      initialUriProvider: () async => Uri.parse('https://example.com/anywhere'),
      uriStreamProvider: () => const Stream<Uri>.empty(),
    );

    await handler.start();

    expect(recorded, isEmpty);

    await handler.dispose();
  });

  test('repeated start() is a no-op', () async {
    final recorded = <String>[];
    var initialCallCount = 0;

    final handler = DeepLinkHandler(
      navigate: recorded.add,
      initialUriProvider: () async {
        initialCallCount++;
        return Uri.parse('lessonapp://invite/111222');
      },
      uriStreamProvider: () => const Stream<Uri>.empty(),
    );

    await handler.start();
    await handler.start(); // duplicate call

    expect(initialCallCount, 1);
    expect(recorded, ['/invite/code?code=111222']);

    await handler.dispose();
  });

  test('handler ignores initial URI errors gracefully', () async {
    final recorded = <String>[];

    final handler = DeepLinkHandler(
      navigate: recorded.add,
      initialUriProvider: () async => throw StateError('platform error'),
      uriStreamProvider: () => const Stream<Uri>.empty(),
    );

    await handler.start(); // should not throw

    expect(recorded, isEmpty);

    await handler.dispose();
  });
}
