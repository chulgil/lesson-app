/// The learner's self-rating after seeing a flashcard's answer (#1124).
///
/// Mirrors Anki's 4-button review grading (Again / Hard / Good / Easy), which
/// maps onto the SuperMemo-2 quality scale `q` consumed by [Sm2Scheduler]:
/// again→2 (the top failing grade), hard→3, good→4, easy→5. `q < 3` is a lapse
/// (reset), `q >= 3` a pass.
enum ReviewGrade {
  again,
  hard,
  good,
  easy;

  /// SuperMemo-2 quality value for this grade (2..5).
  int get quality {
    switch (this) {
      case ReviewGrade.again:
        return 2;
      case ReviewGrade.hard:
        return 3;
      case ReviewGrade.good:
        return 4;
      case ReviewGrade.easy:
        return 5;
    }
  }

  /// Whether this grade counts as a successful recall (`q >= 3`).
  bool get passed => quality >= 3;
}
