// Gamification providers.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../../../core/sync/presentation/providers/revalidation_events_provider.dart';
import '../../data/repositories/mock_gamification_repository.dart';
import '../../data/repositories/remote_gamification_repository.dart';
import '../../domain/entities/gamification.dart';
import '../../domain/repositories/gamification_repository.dart';

part 'gamification_provider.g.dart';

@Riverpod(keepAlive: true)
GamificationRepository gamificationRepository(GamificationRepositoryRef ref) =>
    createRepository<GamificationRepository>(
      ref: ref,
      mock: () => MockGamificationRepository(),
      remote: (api) => RemoteGamificationRepository(api),
    );

@riverpod
Future<StudentGamification> studentGamification(
  StudentGamificationRef ref,
  String studentId,
) async {
  ref.autoRevalidate('/gamification');
  final repository = ref.watch(gamificationRepositoryProvider);
  return repository.getStudentGamification(studentId);
}
