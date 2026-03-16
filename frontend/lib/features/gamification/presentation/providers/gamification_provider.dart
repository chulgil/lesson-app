// Gamification providers.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/mock_gamification_repository.dart';
import '../../domain/entities/gamification.dart';
import '../../domain/repositories/gamification_repository.dart';

part 'gamification_provider.g.dart';

@Riverpod(keepAlive: true)
GamificationRepository gamificationRepository(
    GamificationRepositoryRef ref) {
  return MockGamificationRepository();
}

@riverpod
Future<StudentGamification> studentGamification(
  StudentGamificationRef ref,
  String studentId,
) async {
  final repository = ref.watch(gamificationRepositoryProvider);
  return repository.getStudentGamification(studentId);
}
