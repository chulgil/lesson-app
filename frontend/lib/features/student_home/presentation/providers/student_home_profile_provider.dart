import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/auth_facade.dart';
import '../../../lessons/lessons_facade.dart';
import '../../../parent_home/parent_home_facade.dart';
import '../../../practice/practice_facade.dart';
import '../../../profile/profile_facade.dart';
import '../../../students/students_facade.dart';

final studentHomeProfileProvider = Provider.autoDispose<
  StudentHomeProfileState
>((ref) {
  final studentId = ref.watch(currentUserIdProvider);
  final studentAsync = ref.watch(studentProvider(studentId));
  final lessonsAsync = ref.watch(lessonsByStudentProvider(studentId));
  final practiceLogsAsync = ref.watch(practiceLogsProvider(studentId));
  final repertoiresAsync = ref.watch(studentRepertoiresProvider(studentId));
  final connectionsAsync = ref.watch(myConnectionsProvider);

  final student = studentAsync.valueOrNull;
  final completedLessonCount =
      lessonsAsync.valueOrNull
          ?.where((lesson) => lesson.status == LessonStatus.completed)
          .length ??
      0;
  final totalPracticeMinutes =
      practiceLogsAsync.valueOrNull?.fold<int>(
        0,
        (sum, log) => sum + log.totalMinutes,
      ) ??
      0;
  final lessonPeriodMonths =
      student != null
          ? DateTime.now().difference(student.createdAt).inDays ~/ 30
          : 0;
  final repertoireCount = repertoiresAsync.whenOrNull(
    data: (list) => list.where((repertoire) => !repertoire.isArchived).length,
  );
  final teacherSubtitle = connectionsAsync.whenOrNull(
    data: (connections) {
      final active = connections.where((connection) => connection.isActive);
      if (active.isEmpty) return null;
      if (active.length == 1) return active.first.teacherName;
      return '선생님 ${active.length}명';
    },
  );

  return StudentHomeProfileState(
    studentId: studentId,
    name: student?.name ?? '-',
    initial: student?.initial ?? '-',
    email: student?.email ?? '-',
    instrument: student?.instrument ?? '-',
    lessonCountLabel: lessonsAsync.isLoading ? null : '$completedLessonCount회',
    practiceTimeLabel:
        practiceLogsAsync.isLoading ? null : '${totalPracticeMinutes ~/ 60}시간',
    lessonPeriodLabel:
        studentAsync.isLoading
            ? null
            : lessonPeriodMonths < 1
            ? '1개월 미만'
            : '$lessonPeriodMonths개월',
    repertoireCount: repertoireCount,
    teacherSubtitle: teacherSubtitle,
  );
});

class StudentHomeProfileState {
  final String studentId;
  final String name;
  final String initial;
  final String email;
  final String instrument;
  final String? lessonCountLabel;
  final String? practiceTimeLabel;
  final String? lessonPeriodLabel;
  final int? repertoireCount;
  final String? teacherSubtitle;

  const StudentHomeProfileState({
    required this.studentId,
    required this.name,
    required this.initial,
    required this.email,
    required this.instrument,
    required this.lessonCountLabel,
    required this.practiceTimeLabel,
    required this.lessonPeriodLabel,
    required this.repertoireCount,
    required this.teacherSubtitle,
  });
}

final studentHomeProfileActionsProvider = Provider<StudentHomeProfileActions>((
  ref,
) {
  return StudentHomeProfileActions(ref);
});

class StudentHomeProfileActions {
  final Ref _ref;

  const StudentHomeProfileActions(this._ref);

  Future<String> createParentInvitationCode() async {
    final inviteCode = _generateInviteCode();
    final studentId = _ref.read(currentUserIdProvider);
    final now = DateTime.now();
    final invitation = ParentInvitation(
      id: 'inv_${now.millisecondsSinceEpoch}',
      studentId: studentId,
      source: InvitationSource.student,
      parentPhone: '',
      invitationCode: inviteCode,
      expiresAt: now.add(const Duration(hours: 24)),
      createdAt: now,
    );

    await _ref
        .read(invitationsNotifierProvider(studentId).notifier)
        .createInvitation(invitation);

    return inviteCode;
  }

  String _generateInviteCode() {
    final random = Random();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }
}
