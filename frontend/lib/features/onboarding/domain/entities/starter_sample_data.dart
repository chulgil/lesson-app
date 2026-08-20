/// Starter sample data — the opt-in "예시 데이터로 둘러보기" walkthrough (UXB-1).
///
/// A teacher with zero students sees an empty shell and cannot judge what the
/// app does. The walkthrough fills that shell through the ordinary manual
/// (수기) repositories: one student, one completed past lesson with a note, and
/// one practice log. Nothing here is a backend concept — there is no
/// `is_sample` column. The ids below are the only record that the rows came
/// from the walkthrough, and losing them degrades to "an ordinary manual
/// student the teacher can delete by hand".
library;

/// Ids of the rows the walkthrough created, so cleanup can remove exactly them.
class StarterSampleData {
  /// The sample student. The only entity the teacher sees in a list.
  final String studentId;

  /// Completed past lesson, or null when creation stopped before it.
  final String? lessonId;

  /// Practice log, or null when creation stopped before it.
  final String? practiceLogId;

  const StarterSampleData({
    required this.studentId,
    this.lessonId,
    this.practiceLogId,
  });

  StarterSampleData copyWith({String? lessonId, String? practiceLogId}) {
    return StarterSampleData(
      studentId: studentId,
      lessonId: lessonId ?? this.lessonId,
      practiceLogId: practiceLogId ?? this.practiceLogId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StarterSampleData &&
          runtimeType == other.runtimeType &&
          studentId == other.studentId &&
          lessonId == other.lessonId &&
          practiceLogId == other.practiceLogId;

  @override
  int get hashCode => Object.hash(studentId, lessonId, practiceLogId);
}

/// User-facing copy for the sample rows, resolved by the presentation layer.
///
/// The domain layer must not reach into the localization layer, so the caller
/// passes the already-resolved text in. [studentName] carries the "이건 예시예요" label
/// itself, because the name is the one field that shows up in every list, card
/// and picker the sample student appears in.
class StarterSampleContent {
  final String studentName;
  final String studentNotes;
  final String instrument;
  final String lessonFeedback;
  final List<String> lessonKeyPoints;
  final String lessonPracticeTips;
  final String practiceNotes;

  const StarterSampleContent({
    required this.studentName,
    required this.studentNotes,
    required this.instrument,
    required this.lessonFeedback,
    required this.lessonKeyPoints,
    required this.lessonPracticeTips,
    required this.practiceNotes,
  });
}

/// Creation failed part-way through.
///
/// [rolledBack] tells the caller whether the rows created before the failure
/// were removed again. When false, the teacher has to be told that a sample
/// student may be sitting in the roster — a silent partial state is worse than
/// an explicit one.
class StarterSampleCreationFailure implements Exception {
  final Object cause;
  final bool rolledBack;

  const StarterSampleCreationFailure(this.cause, {required this.rolledBack});

  @override
  String toString() =>
      'StarterSampleCreationFailure(rolledBack: $rolledBack, cause: $cause)';
}
