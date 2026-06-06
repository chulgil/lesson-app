import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/context_switch_repository.dart';

/// Mock implementation of ContextSwitchRepository for development.
class MockContextSwitchRepository implements ContextSwitchRepository {
  @override
  Future<ContextInfo> getContext() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Mock dual-role user: owner + teacher in the same academy.
    return const ContextInfo(
      userId: 'mock-user',
      activeContext: 'teacher',
      academyId: 'mock-academy',
      teacherId: 'mock-teacher',
      availableContexts: [
        AvailableContext(
          context: 'academy_owner',
          academyId: 'mock-academy',
          label: '모의 학원 학원장',
          memberId: 'mock-member-owner',
        ),
        AvailableContext(
          context: 'teacher',
          academyId: 'mock-academy',
          label: '모의 학원 강사',
          memberId: 'mock-member-teacher',
        ),
      ],
    );
  }

  @override
  Future<ContextSwitchResult> switchContext({
    required String targetContext,
    String? academyId,
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
