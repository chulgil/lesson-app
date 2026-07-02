import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../features/lessons/data/repositories/remote_lesson_repository.dart';
import '../../../../features/schedule/data/repositories/remote_teacher_availability_repository.dart';
import '../../../../features/students/data/repositories/remote_student_repository.dart';
import '../../../network/api_client.dart';
import '../../application/initial_pull_service.dart';
import 'sync_provider.dart';

part 'initial_pull_provider.g.dart';

/// Provider for [InitialPullService].
///
/// keepAlive: true so the service instance is shared across auth state changes.
/// Only instantiated in remote mode (mock mode has no network layer).
///
/// The service warms the HTTP response cache: the injected remote
/// repositories share [apiClientProvider]'s Dio, whose
/// ResponseCacheInterceptor persists the pulled responses for offline reads.
@Riverpod(keepAlive: true)
InitialPullService initialPullService(InitialPullServiceRef ref) {
  final apiClient = ref.read(apiClientProvider);
  final connectivity = ref.read(connectivityServiceProvider);
  return InitialPullService(
    remoteLessons: RemoteLessonRepository(apiClient),
    remoteStudents: RemoteStudentRepository(apiClient),
    remoteAvailability: RemoteTeacherAvailabilityRepository(apiClient),
    connectivity: connectivity,
  );
}
