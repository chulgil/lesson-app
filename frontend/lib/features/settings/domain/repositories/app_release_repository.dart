import '../entities/app_release.dart';

abstract class AppReleaseRepository {
  Future<AppReleaseSnapshot> fetchReleaseSnapshot();
}

abstract class AppReviewClient {
  Future<bool> canRequestReview();

  Future<void> requestReview();
}
