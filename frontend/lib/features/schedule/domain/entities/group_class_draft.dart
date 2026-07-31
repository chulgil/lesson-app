// Teacher-authored input for group class create/update

import 'group_class.dart';

/// What a teacher fills in when opening or editing a [GroupClass].
///
/// Server-owned fields (id, teacherId, createdAt) are absent on purpose — this
/// carries only what the form can decide, so the repository never has to
/// fabricate placeholder values.
class GroupClassDraft {
  const GroupClassDraft({
    required this.name,
    required this.type,
    required this.maxCapacity,
    required this.durationMinutes,
    required this.noShowPolicy,
    required this.bookingDeadlineMinutes,
    required this.cancelDeadlineMinutes,
    this.description,
    this.instrument,
    this.repeatDaysOfWeek,
    this.repeatTimeOfDay,
    this.dropInStartsAt,
    this.pricePerSession,
    this.waitlistCapacity,
  });

  /// Seed the edit form from an existing class.
  ///
  /// [dropInStartsAt] stays null: an existing drop-in class already owns its
  /// session, and editing the class definition must not silently open a second
  /// one.
  factory GroupClassDraft.fromGroupClass(GroupClass groupClass) {
    return GroupClassDraft(
      name: groupClass.name,
      type: groupClass.type,
      maxCapacity: groupClass.maxCapacity,
      durationMinutes: groupClass.durationMinutes,
      noShowPolicy: groupClass.noShowPolicy,
      bookingDeadlineMinutes: groupClass.bookingDeadlineMinutes,
      cancelDeadlineMinutes: groupClass.cancelDeadlineMinutes,
      description: groupClass.description,
      instrument: groupClass.instrument,
      repeatDaysOfWeek: groupClass.repeatDaysOfWeek,
      repeatTimeOfDay: groupClass.repeatTimeOfDay,
      pricePerSession: groupClass.pricePerSession,
      waitlistCapacity: groupClass.waitlistCapacity,
    );
  }

  final String name;

  final GroupClassType type;

  final int maxCapacity;

  final int durationMinutes;

  final NoShowPolicy noShowPolicy;

  final int bookingDeadlineMinutes;

  final int cancelDeadlineMinutes;

  final String? description;

  final String? instrument;

  /// 1=Mon … 7=Sun. Regular classes only — the backend turns these into
  /// recurring sessions.
  final List<int>? repeatDaysOfWeek;

  /// HH:mm KST wall clock. Regular classes only.
  final String? repeatTimeOfDay;

  /// The single session a drop-in class opens with. Regular classes derive
  /// their sessions from [repeatDaysOfWeek] / [repeatTimeOfDay] instead.
  final DateTime? dropInStartsAt;

  final int? pricePerSession;

  final int? waitlistCapacity;

  bool get isDropIn => type == GroupClassType.dropIn;

  /// End of the drop-in session, derived from [durationMinutes].
  DateTime? get dropInEndsAt =>
      dropInStartsAt?.add(Duration(minutes: durationMinutes));
}
