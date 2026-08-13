import 'package:flutter/material.dart';

import 'empty_state_widget.dart';

/// Shared full-screen error / not-found state.
///
/// Semantically distinct from [EmptyStateWidget] (valid "no data yet" state)
/// even though it currently renders through the same visual language —
/// this covers exception/failure states (load error, record not found).
/// Consolidates the icon+title(+subtitle)(+retry) blocks that were
/// previously copy-pasted across detail screens.
class ErrorStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  const ErrorStateWidget({
    super.key,
    this.icon = Icons.error_outline,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: icon,
      title: title,
      subtitle: subtitle,
      actionLabel: actionLabel,
      actionIcon: actionIcon,
      onAction: onAction,
    );
  }
}
