import 'package:in_app_review/in_app_review.dart';

import '../../domain/repositories/app_release_repository.dart';

class LocalAppReviewClient implements AppReviewClient {
  const LocalAppReviewClient({InAppReview? inAppReview})
    : _inAppReview = inAppReview ?? InAppReview.instance;

  final InAppReview _inAppReview;

  @override
  Future<bool> canRequestReview() async {
    return _inAppReview.isAvailable();
  }

  @override
  Future<void> requestReview() async {
    if (await canRequestReview()) {
      await _inAppReview.requestReview();
    }
  }
}
