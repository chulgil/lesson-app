import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/context_switch_repository.dart';

/// Mock implementation of ContextSwitchRepository for development.
class MockContextSwitchRepository implements ContextSwitchRepository {
  @override
  Future<ContextSwitchResult> switchContext({
    required String targetContext,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Mock response with new JWT tokens
    return ContextSwitchResult(
      activeContext: targetContext,
      redirectUrl: '/home?redirected=true',
      tokens: TokenPair(
        accessToken:
            'mock-access-token-${DateTime.now().millisecondsSinceEpoch}',
        refreshToken:
            'mock-refresh-token-${DateTime.now().millisecondsSinceEpoch}',
      ),
    );
  }
}

/// Provider for mock context switch repository
final mockContextSwitchRepositoryProvider = Provider((ref) {
  return MockContextSwitchRepository();
});
