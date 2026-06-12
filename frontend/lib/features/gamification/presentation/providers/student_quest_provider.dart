// Student gamification P1 — quest providers.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/mock_student_quest_repository.dart';
import '../../domain/entities/student_quest.dart';
import '../../domain/repositories/student_quest_repository.dart';

part 'student_quest_provider.g.dart';

/// P1: Mock 만 사용. P2 에서 BE 구현체 도입 시 환경 분기 추가 (O1 결정).
@Riverpod(keepAlive: true)
StudentQuestRepository studentQuestRepository(StudentQuestRepositoryRef ref) =>
    MockStudentQuestRepository();

@riverpod
Future<List<StudentQuest>> activeQuests(
  ActiveQuestsRef ref,
  String studentId,
) async {
  final repo = ref.watch(studentQuestRepositoryProvider);
  return repo.getActiveQuests(studentId);
}
