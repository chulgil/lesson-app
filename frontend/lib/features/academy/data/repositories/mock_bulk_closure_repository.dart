import '../../domain/entities/bulk_closure.dart';
import '../../domain/repositories/bulk_closure_repository.dart';

/// In-memory mock of [BulkClosureRepository] (BE 대기).
///
/// State 키는 closureId. teacherMember scoping 은 seed 시점에 결정한다
/// (seed 단계에서 `addClosure(teacherMemberId, closure)`).
class MockBulkClosureRepository implements BulkClosureRepository {
  /// closureId → BulkClosure.
  final Map<String, BulkClosure> _store = {};

  /// teacherMemberId → set of closureId.
  final Map<String, Set<String>> _teacherIndex = {};

  @override
  Future<List<BulkClosure>> listByTeacherMember(String teacherMemberId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final ids = _teacherIndex[teacherMemberId] ?? const <String>{};
    final items = ids.map((id) => _store[id]).whereType<BulkClosure>().toList();
    items.sort((a, b) => b.closureDate.compareTo(a.closureDate));
    return items;
  }

  @override
  Future<BulkClosure?> getById(String closureId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _store[closureId];
  }

  @override
  Future<void> submitTeacherOpinion(String closureId, String comment) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final current = _store[closureId];
    if (current == null) {
      throw Exception('Closure not found: $closureId');
    }
    if (current.status != ClosureStatus.proposed) {
      throw Exception('Opinion window closed (status=${current.status.name})');
    }
    if (!current.isOpinionWindowOpen) {
      throw Exception('Opinion window expired');
    }
    _store[closureId] = current.copyWith(teacherComment: comment);
  }

  @override
  Future<void> submitMakeupSchedule(
    String closureId,
    Map<String, DateTime> makeupByLessonId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final current = _store[closureId];
    if (current == null) {
      throw Exception('Closure not found: $closureId');
    }
    if (current.status != ClosureStatus.applied) {
      throw Exception(
        'Makeup input not allowed (status=${current.status.name})',
      );
    }

    final updatedLessons =
        current.affectedLessons.map((lesson) {
          final newAt = makeupByLessonId[lesson.lessonId];
          if (newAt == null) return lesson;
          return lesson.copyWith(makeupAt: newAt);
        }).toList();

    final allFilled = updatedLessons.every((l) => l.makeupAt != null);

    _store[closureId] = current.copyWith(
      affectedLessons: updatedLessons,
      status: allFilled ? ClosureStatus.makeupCompleted : current.status,
    );
  }

  /// For testing/seed: register a closure as affecting [teacherMemberId].
  void addClosure(String teacherMemberId, BulkClosure closure) {
    _store[closure.id] = closure;
    _teacherIndex
        .putIfAbsent(teacherMemberId, () => <String>{})
        .add(closure.id);
  }

  /// For testing: reset all state.
  void reset() {
    _store.clear();
    _teacherIndex.clear();
  }
}
