import 'package:lessonaza/features/auth/domain/entities/auth_user.dart';
import 'package:lessonaza/features/auth/domain/repositories/context_switch_repository.dart';

/// Synchronous fake for context toggle widget tests (no Future.delayed timer).
class FakeContextSwitchRepository implements ContextSwitchRepository {
  FakeContextSwitchRepository({ContextInfo? info}) : _info = info ?? _dualRole;

  final ContextInfo _info;

  static const _dualRole = ContextInfo(
    userId: 'u',
    activeContext: 'teacher',
    academyId: 'a',
    teacherId: 't',
    availableContexts: [
      AvailableContext(
        context: 'academy_owner',
        academyId: 'a',
        label: '학원 학원장',
        memberId: 'm-owner',
      ),
      AvailableContext(
        context: 'teacher',
        academyId: 'a',
        label: '학원 강사',
        memberId: 'm-teacher',
      ),
    ],
  );

  @override
  Future<ContextInfo> getContext() async => _info;

  @override
  Future<ContextSwitchResult> switchContext({
    required String targetContext,
    String? academyId,
  }) async {
    return ContextSwitchResult(
      activeContext: targetContext,
      redirectUrl: '/today',
      tokens: const TokenPair(accessToken: 'new-token', refreshToken: ''),
    );
  }
}
