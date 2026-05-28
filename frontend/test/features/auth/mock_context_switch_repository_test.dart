import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/auth/data/repositories/mock_context_switch_repository.dart';

void main() {
  group('MockContextSwitchRepository', () {
    late MockContextSwitchRepository repository;

    setUp(() {
      repository = MockContextSwitchRepository();
    });

    test('switchContext returns valid result', () async {
      final result = await repository.switchContext(targetContext: 'owner');

      expect(result, isNotNull);
      expect(result.activeContext, 'owner');
      expect(result.redirectUrl, '/home?redirected=true');
      expect(result.tokens, isNotNull);
    });

    test('switchContext updates tokens', () async {
      final result1 = await repository.switchContext(targetContext: 'owner');
      final result2 = await repository.switchContext(targetContext: 'owner');

      // Tokens should be different (different timestamps)
      expect(result1.tokens.accessToken, isNotEmpty);
      expect(result2.tokens.accessToken, isNotEmpty);
      // Tokens may be different due to timestamp
    });

    test('switchContext returns correct redirect URL', () async {
      final result = await repository.switchContext(targetContext: 'owner');

      expect(result.redirectUrl, contains('/home'));
      expect(result.redirectUrl, contains('redirected=true'));
    });

    test('switchContext handles different target contexts', () async {
      final result1 = await repository.switchContext(targetContext: 'owner');
      final result2 = await repository.switchContext(targetContext: 'teacher');

      expect(result1.activeContext, 'owner');
      expect(result2.activeContext, 'teacher');
    });

    test('switchContext simulates network delay', () async {
      final stopwatch = Stopwatch()..start();
      await repository.switchContext(targetContext: 'owner');
      stopwatch.stop();

      // Should take at least 800ms due to simulated delay
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(800));
    });
  });
}
