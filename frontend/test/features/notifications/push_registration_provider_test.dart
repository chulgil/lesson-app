import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/providers/repository_provider.dart';
import 'package:lessonaza/features/notifications/presentation/providers/push_registration_provider.dart';

void main() {
  group('PushRegistration.ensureStarted', () {
    late int initCalls;

    ProviderContainer container({required bool mock}) {
      initCalls = 0;
      final c = ProviderContainer(
        overrides: [
          mockDataModeProvider.overrideWith((ref) => mock),
          pushInitializerProvider.overrideWith(
            (ref) => () async {
              initCalls++;
            },
          ),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('registers push in remote mode', () async {
      final c = container(mock: false);
      await c.read(pushRegistrationProvider.notifier).ensureStarted();
      expect(initCalls, 1);
    });

    test('skips push in mock mode (no backend to register with)', () async {
      final c = container(mock: true);
      await c.read(pushRegistrationProvider.notifier).ensureStarted();
      expect(initCalls, 0);
    });

    test('runs at most once per session', () async {
      final c = container(mock: false);
      final notifier = c.read(pushRegistrationProvider.notifier);
      await notifier.ensureStarted();
      await notifier.ensureStarted();
      await notifier.ensureStarted();
      expect(initCalls, 1);
    });

    test('a failing initializer does not throw (non-blocking)', () async {
      initCalls = 0;
      final c = ProviderContainer(
        overrides: [
          mockDataModeProvider.overrideWith((ref) => false),
          pushInitializerProvider.overrideWith(
            (ref) =>
                () async => throw StateError('Firebase not configured'),
          ),
        ],
      );
      addTearDown(c.dispose);

      // Must complete normally despite the initializer throwing.
      await c.read(pushRegistrationProvider.notifier).ensureStarted();
    });
  });
}
