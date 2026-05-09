// BillingGuard — wraps student-adding actions with free plan limit check.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/billing_provider.dart';
import 'free_limit_sheet.dart';

/// Guards actions that require a paid plan (e.g., adding a 6th student).
///
/// Wrap any button's `onPressed` with [BillingGuard.check]:
/// ```dart
/// onPressed: () => BillingGuard.check(
///   context: context,
///   ref: ref,
///   onAllowed: () => addStudent(),
/// ),
/// ```
///
/// If the free limit is reached, shows [FreeLimitSheet] instead of executing
/// the action. If the user has a paid/trial plan, executes immediately.
class BillingGuard {
  BillingGuard._();

  /// Check billing limit before executing [onAllowed].
  ///
  /// Shows the paywall sheet if the free plan student limit is reached.
  static void check({
    required BuildContext context,
    required WidgetRef ref,
    required VoidCallback onAllowed,
  }) {
    final limitReached = ref.read(billingLimitReachedProvider);
    if (limitReached) {
      showFreeLimitSheet(context);
      return;
    }
    onAllowed();
  }

  /// Async version of [check] for actions that return a Future.
  static Future<T?> checkAsync<T>({
    required BuildContext context,
    required WidgetRef ref,
    required Future<T> Function() onAllowed,
  }) async {
    final limitReached = ref.read(billingLimitReachedProvider);
    if (limitReached) {
      showFreeLimitSheet(context);
      return null;
    }
    return onAllowed();
  }
}
