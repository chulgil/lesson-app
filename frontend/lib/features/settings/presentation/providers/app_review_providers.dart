import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/hive_app_review_state_repository.dart';
import '../../data/repositories/local_app_review_client.dart';
import '../../domain/entities/app_review_state.dart';
import '../../domain/repositories/app_release_repository.dart';
import '../../domain/repositories/app_review_state_repository.dart';
import '../../domain/services/app_review_trigger_service.dart';

part 'app_review_providers.g.dart';

/// Opens (or returns) the Hive box used for [AppReviewState] storage.
@Riverpod(keepAlive: true)
Future<Box<String>> appReviewBox(AppReviewBoxRef ref) async {
  return Hive.openBox<String>(kAppReviewStateBoxKey);
}

/// [AppReviewStateRepository] backed by Hive.
@Riverpod(keepAlive: true)
AppReviewStateRepository appReviewStateRepository(
  AppReviewStateRepositoryRef ref,
) {
  final box = ref.watch(appReviewBoxProvider).requireValue;
  return HiveAppReviewStateRepository(box: box);
}

/// [AppReviewClient] — uses the existing [LocalAppReviewClient].
@Riverpod(keepAlive: true)
AppReviewClient appReviewClientInstance(AppReviewClientInstanceRef ref) {
  return LocalAppReviewClient();
}

/// [AppReviewTriggerService] wired with repository and client.
@Riverpod(keepAlive: true)
AppReviewTriggerService appReviewTriggerService(
  AppReviewTriggerServiceRef ref,
) {
  return AppReviewTriggerService(
    stateRepository: ref.watch(appReviewStateRepositoryProvider),
    reviewClient: ref.watch(appReviewClientInstanceProvider),
  );
}

/// Current [AppReviewState] — invalidate after any state mutation.
@riverpod
Future<AppReviewState> appReviewState(AppReviewStateRef ref) async {
  final repo = ref.watch(appReviewStateRepositoryProvider);
  return repo.getState();
}
