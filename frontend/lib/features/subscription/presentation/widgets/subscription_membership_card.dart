import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../domain/entities/subscription.dart';
import '../extensions/subscription_scope_visuals.dart';
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

  /// Resolved name of the group class this ticket belongs to, when the caller
  /// knows it. Group tickets fall back to the "그룹 수강권" label, never to
  /// [fallbackClassName].
  final String? groupClassName;

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
    this.groupClassName,
  });

  @override
  Widget build(BuildContext context) {
    // 그룹 수강권은 멤버십(1:1) 수업명 조회 결과와 무관하게 그룹 경로로 표시한다 —
    // 로딩/에러 폴백까지 포함해 "개인레슨" 이 새어나오지 않게 한다.
    if (subscription.isGroupScoped) {
      return _buildCard(
        className: subscription.displayClassName(
          groupClassName: groupClassName,
          fallback: fallbackClassName,
        ),
      );
    }
    return classNameAsync.when(
      data:
          (className) => _buildCard(
            className: subscription.displayClassName(
              membershipClassName: className,
              fallback: fallbackClassName,
            ),
          ),
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
