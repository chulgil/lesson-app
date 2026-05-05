import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../practice/practice_facade.dart';
import '../../../students/students_facade.dart';
import 'tip_template_providers.dart' show currentTeacherIdProvider;

final lessonWidgetPracticeItemsProvider =
    Provider.family<AsyncValue<List<PracticeItem>>, String>((ref, lessonId) {
      return ref.watch(practiceItemsNotifierProvider(lessonId));
    });

final lessonWidgetStudentRepertoiresProvider =
    Provider.family<AsyncValue<List<PracticeRepertoire>>, String>((
      ref,
      studentId,
    ) {
      return ref.watch(studentRepertoiresProvider(studentId));
    });

final lessonWidgetTeacherLocationsProvider =
    Provider.family<AsyncValue<List<LessonLocation>>, String>((ref, teacherId) {
      return ref.watch(teacherLocationsProvider(teacherId));
    });

final lessonWidgetCurrentTeacherIdProvider = Provider<String>((ref) {
  return ref.watch(currentTeacherIdProvider);
});

final lessonWidgetRepertoireActionsProvider =
    Provider<LessonWidgetRepertoireActions>((ref) {
      return LessonWidgetRepertoireActions(ref);
    });

final lessonWidgetPracticeItemActionsProvider =
    Provider.family<LessonWidgetPracticeItemActions, String>((ref, lessonId) {
      return LessonWidgetPracticeItemActions(ref, lessonId);
    });

class LessonWidgetRepertoireActions {
  LessonWidgetRepertoireActions(this._ref);

  final Ref _ref;

  Future<PracticeRepertoire> createRepertoire({
    required String studentId,
    required String name,
  }) {
    return _ref
        .read(repertoireCrudProvider.notifier)
        .createRepertoire(studentId: studentId, name: name);
  }

  Future<PracticeSection> createSection({
    required String repertoireId,
    required String pieceName,
    required int startMeasure,
    required int endMeasure,
  }) {
    return _ref
        .read(sectionCrudProvider.notifier)
        .createSection(
          repertoireId: repertoireId,
          pieceName: pieceName,
          startMeasure: startMeasure,
          endMeasure: endMeasure,
        );
  }
}

class LessonWidgetPracticeItemActions {
  LessonWidgetPracticeItemActions(this._ref, this._lessonId);

  final Ref _ref;
  final String _lessonId;

  void invalidateItems() {
    _ref.invalidate(practiceItemsNotifierProvider(_lessonId));
  }

  Future<PracticeItem> addItem({
    required String studentId,
    required String teacherId,
    required String title,
    String? description,
    required String repertoireId,
    required String sectionId,
    List<String> resourceIds = const [],
  }) {
    return _ref
        .read(practiceItemsNotifierProvider(_lessonId).notifier)
        .addItem(
          studentId: studentId,
          teacherId: teacherId,
          title: title,
          description: description,
          repertoireId: repertoireId,
          sectionId: sectionId,
          resourceIds: resourceIds,
        );
  }

  Future<PracticeItem> updateItem(PracticeItem item) {
    return _ref
        .read(practiceItemsNotifierProvider(_lessonId).notifier)
        .updateItem(item);
  }

  Future<void> deleteItem(String id, String studentId) {
    return _ref
        .read(practiceItemsNotifierProvider(_lessonId).notifier)
        .deleteItem(id, studentId);
  }

  Future<PracticeItem> toggleComplete(String id, String studentId) {
    return _ref
        .read(practiceItemsNotifierProvider(_lessonId).notifier)
        .toggleComplete(id, studentId);
  }

  Future<PracticeItem> toggleLike(String id, String studentId) {
    return _ref
        .read(practiceItemsNotifierProvider(_lessonId).notifier)
        .toggleLike(id, studentId);
  }
}
