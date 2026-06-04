import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/hive_app_review_state_repository.dart';
import '../../data/repositories/local_app_review_client.dart';
import '../../domain/repositories/app_release_repository.dart';
import '../../domain/repositories/app_review_state_repository.dart';
import '../../domain/services/app_review_trigger_service.dart';

part 'app_review_providers.g.dart';

/// Singleton Hive box for app review state.
/// Box opened in `app_bootstrap.dart` at startup.
@Riverpod(keepAlive: true)
Box<String> appReviewBox(Ref ref) {
  return Hive.box<String>(kAppReviewStateBoxKey);
}

/// State repository (Hive-backed).
@Riverpod(keepAlive: true)
AppReviewStateRepository appReviewStateRepository(Ref ref) {
  return HiveAppReviewStateRepository(box: ref.watch(appReviewBoxProvider));
}

/// Native review client (in_app_review).
@Riverpod(keepAlive: true)
AppReviewClient appReviewClient(Ref ref) {
  return LocalAppReviewClient();
}

/// Trigger service — wraps state repo + review client.
@Riverpod(keepAlive: true)
AppReviewTriggerService appReviewTriggerService(Ref ref) {
  return AppReviewTriggerService(
    stateRepository: ref.watch(appReviewStateRepositoryProvider),
    reviewClient: ref.watch(appReviewClientProvider),
  );
}
