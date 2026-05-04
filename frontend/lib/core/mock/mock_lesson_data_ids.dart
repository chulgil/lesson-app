/// Shared ids used by cross-feature mock lesson data.
///
/// Keep relationship-sensitive mock ids here so schedule, subscription,
/// student, and auth mocks cannot drift independently.
abstract final class MockLessonDataIds {
  static const teacherPrimary = 'teacher_1';
  static const studentPrimary = 'student_1';
  static const studentPiano = 'student_2';
  static const studentCello = 'student_3';
  static const studentTrialFlute = 'student_4';
  static const studentExpiring = 'student_5';
  static const studentMultiInstrument = 'student_11';

  static const studentPrimaryViolinSubscription = 'sub_pkg_01';
  static const studentPrimaryPianoSubscription = 'sub_mon_04';
  static const studentPianoMonthlySubscription = 'sub_mon_01';
  static const studentCelloSubscription = 'sub_pkg_02';
  static const studentTrialFluteReadySubscription = 'sub_pkg_04_ready';
  static const studentExpiringSubscription = 'sub_pkg_03';
  static const studentMultiViolinSubscription = 'sub_mon_02';
  static const studentMultiPianoSubscription = 'sub_mon_03';
  static const studentPrimaryExpiredSubscription = 'sub_exp_03';
}
