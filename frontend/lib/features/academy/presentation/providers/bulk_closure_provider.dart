import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/mock_bulk_closure_repository.dart';
import '../../domain/entities/bulk_closure.dart';
import '../../domain/repositories/bulk_closure_repository.dart';

part 'bulk_closure_provider.g.dart';

/// Singleton mock repository — BE 대기.
@Riverpod(keepAlive: true)
BulkClosureRepository bulkClosureRepository(Ref ref) {
  return MockBulkClosureRepository();
}

/// 강사 본인이 영향 받는 closure 목록 (G15 §5).
@riverpod
Future<List<BulkClosure>> teacherBulkClosures(
  Ref ref,
  String teacherMemberId,
) async {
  final repository = ref.watch(bulkClosureRepositoryProvider);
  return repository.listByTeacherMember(teacherMemberId);
}

/// 단일 closure 상세.
@riverpod
Future<BulkClosure?> bulkClosureDetail(Ref ref, String closureId) async {
  final repository = ref.watch(bulkClosureRepositoryProvider);
  return repository.getById(closureId);
}

/// 강사 의견 입력 / 보강 일정 일괄 저장 등 mutation.
@riverpod
class BulkClosureNotifier extends _$BulkClosureNotifier {
  @override
  void build() {
    // stateless — actions only.
  }

  /// 의견 윈도우 동안 강사 의견 제출.
  Future<void> submitOpinion({
    required String closureId,
    required String comment,
    required String teacherMemberId,
  }) async {
    final repository = ref.read(bulkClosureRepositoryProvider);
    await repository.submitTeacherOpinion(closureId, comment);
    ref.invalidate(bulkClosureDetailProvider(closureId));
    ref.invalidate(teacherBulkClosuresProvider(teacherMemberId));
  }

  /// 적용된 closure 의 보강 일정 일괄 저장.
  Future<void> submitMakeupSchedule({
    required String closureId,
    required Map<String, DateTime> makeupByLessonId,
    required String teacherMemberId,
  }) async {
    final repository = ref.read(bulkClosureRepositoryProvider);
    await repository.submitMakeupSchedule(closureId, makeupByLessonId);
    ref.invalidate(bulkClosureDetailProvider(closureId));
    ref.invalidate(teacherBulkClosuresProvider(teacherMemberId));
  }
}
