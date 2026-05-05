import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../domain/entities/subscription.dart';
import 'subscription_card.dart';

/// Shared subscription ticket used by student "내 수강권" and teacher
/// student-detail subscription sections.
class SubscriptionMembershipCard extends StatelessWidget {
  final Subscription subscription;
  final AsyncValue<String?> classNameAsync;
  final String instrument;
  final VoidCallback? onTap;
  final String fallbackClassName;
  final String loadingClassName;
  final String errorClassName;
  final String? personName;

  const SubscriptionMembershipCard({
    super.key,
    required this.subscription,
    required this.classNameAsync,
    required this.instrument,
    this.onTap,
    this.fallbackClassName = AppStrings.individualLesson,
    this.loadingClassName = '...',
    this.errorClassName = AppStrings.lessonClassErrorFallback,
    this.personName,
  });

  @override
  Widget build(BuildContext context) {
    return classNameAsync.when(
      data:
          (className) => _buildCard(className: className ?? fallbackClassName),
      loading: () => _buildCard(className: loadingClassName),
      error: (_, __) => _buildCard(className: errorClassName),
    );
  }

  Widget _buildCard({required String className}) {
    return SubscriptionCard(
      compact: true,
      subscription: subscription,
      className: className,
      instrument: instrument,
      personName: personName,
      onTap: onTap,
    );
  }
}
