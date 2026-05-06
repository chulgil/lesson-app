import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../practice/practice_facade.dart';
import '../../../students/students_facade.dart';
import 'tip_template_providers.dart' show currentTeacherIdProvider;

part 'lesson_widget_support_provider.g.dart';

@Riverpod(keepAlive: true)
AsyncValue<List<PracticeItem>> lessonWidgetPracticeItems(
  LessonWidgetPracticeItemsRef ref,
  String lessonId,
) {
  return ref.watch(practiceItemsNotifierProvider(lessonId));
}

@Riverpod(keepAlive: true)
AsyncValue<List<PracticeRepertoire>> lessonWidgetStudentRepertoires(
  LessonWidgetStudentRepertoiresRef ref,
  String studentId,
) {
  return ref.watch(studentRepertoiresProvider(studentId));
}

@Riverpod(keepAlive: true)
AsyncValue<List<LessonLocation>> lessonWidgetTeacherLocations(
  LessonWidgetTeacherLocationsRef ref,
  String teacherId,
) {
  return ref.watch(teacherLocationsProvider(teacherId));
}

@Riverpod(keepAlive: true)
String lessonWidgetCurrentTeacherId(LessonWidgetCurrentTeacherIdRef ref) {
  return ref.watch(currentTeacherIdProvider);
}

@Riverpod(keepAlive: true)
LessonWidgetRepertoireActions lessonWidgetRepertoireActions(
  LessonWidgetRepertoireActionsRef ref,
) {
  return LessonWidgetRepertoireActions(ref);
}

@Riverpod(keepAlive: true)
LessonWidgetPracticeItemActions lessonWidgetPracticeItemActions(
  LessonWidgetPracticeItemActionsRef ref,
  String lessonId,
) {
  return LessonWidgetPracticeItemActions(ref, lessonId);
}

class LessonWidgetRepertoireActions {
  LessonWidgetRepertoireActions(this._ref);

  final LessonWidgetRepertoireActionsRef _ref;

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

  final LessonWidgetPracticeItemActionsRef _ref;
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
