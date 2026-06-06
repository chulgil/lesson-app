/// Cancellation reason per lesson_cancellation_flow_spec §2.
///
/// Pure domain value — no display strings here (presentation extension owns
/// labels). Credit impact is computed by CancellationCreditPolicy.
enum CancelReason {
  /// 학생 일정 변경 — 마감 후 차감, 마감 전 무료.
  studentSchedule,

  /// 학생 건강 이슈 — 마감 후 차감, 마감 전 무료.
  studentSick,

  /// 선생님 취소 — 차감 안 함 + 보강 안내.
  teacherCancel,

  /// 합의 취소 — 차감 안 함.
  mutual,
}

extension CancelReasonX on CancelReason {
  /// Wire value persisted in the event payload.
  String get wireValue => switch (this) {
    CancelReason.studentSchedule => 'student_schedule',
    CancelReason.studentSick => 'student_sick',
    CancelReason.teacherCancel => 'teacher_cancel',
    CancelReason.mutual => 'mutual',
  };

  /// Whether the reason is a student-initiated reason subject to the deadline
  /// credit policy. Teacher/mutual cancels are always free (spec §2).
  bool get isStudentReason =>
      this == CancelReason.studentSchedule || this == CancelReason.studentSick;

  static CancelReason fromWire(String value) => switch (value) {
    'student_schedule' => CancelReason.studentSchedule,
    'student_sick' => CancelReason.studentSick,
    'teacher_cancel' => CancelReason.teacherCancel,
    'mutual' => CancelReason.mutual,
    _ => CancelReason.studentSchedule,
  };
}
