// Gamification providers.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/config/environment.dart';
import '../../../../core/network/api_client.dart';
import '../../data/repositories/mock_gamification_repository.dart';
import '../../data/repositories/remote_gamification_repository.dart';
import '../../domain/entities/gamification.dart';
import '../../domain/repositories/gamification_repository.dart';

part 'gamification_provider.g.dart';

@Riverpod(keepAlive: true)
GamificationRepository gamificationRepository(
    GamificationRepositoryRef ref) {
  if (EnvironmentConfig.useMockData) {
    return MockGamificationRepository();
  }
  return RemoteGamificationRepository(ref.read(apiClientProvider));
}

@riverpod
Future<StudentGamification> studentGamification(
  StudentGamificationRef ref,
  String studentId,
) async {
  final repository = ref.watch(gamificationRepositoryProvider);
  return repository.getStudentGamification(studentId);
}
