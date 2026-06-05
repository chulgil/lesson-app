import 'package:lessonaza/features/academy/domain/entities/context_switch_log.dart';
import 'package:lessonaza/features/academy/domain/repositories/context_switch_log_repository.dart';

/// Mock implementation of ContextSwitchLogRepository.
///
/// 테스트/dev 환경용. 학원 멤버십은 [_academyMemberIds] 로 모킹.
/// switchedAt desc 정렬, 학원 필터링 + limit 적용.
class MockContextSwitchLogRepository implements ContextSwitchLogRepository {
  MockContextSwitchLogRepository({
    required this.currentUserId,
    List<ContextSwitchLog>? seed,
    Set<String>? academyMemberIds,
  }) : _logs = List.of(seed ?? const []),
       _academyMemberIds = academyMemberIds ?? const <String>{};

  final String currentUserId;
  final List<ContextSwitchLog> _logs;
  final Set<String> _academyMemberIds;

  void add(ContextSwitchLog log) {
    _logs.add(log);
  }

  void clear() {
    _logs.clear();
  }

  @override
  Future<List<ContextSwitchLog>> listMy({int limit = 100}) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final mine =
        _logs.where((log) => log.userId == currentUserId).toList()
          ..sort((a, b) => b.switchedAt.compareTo(a.switchedAt));
    return mine.take(limit).toList();
  }

  @override
  Future<List<ContextSwitchLog>> listMyForAcademy(
    String academyId, {
    int limit = 100,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!_academyMemberIds.contains(academyId)) {
      throw StateError('Not a member of academy: $academyId');
    }
    final mine =
        _logs
            .where(
              (log) =>
                  log.userId == currentUserId && log.academyId == academyId,
            )
            .toList()
          ..sort((a, b) => b.switchedAt.compareTo(a.switchedAt));
    return mine.take(limit).toList();
  }
}
