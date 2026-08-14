import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/refund_request.dart';
import '../extensions/refund_request_visuals.dart';

/// Small status badge for a [RefundRequest] — 요청됨/완료/반려. Reused on
/// the subscription-detail banner (both roles) and the pending list.
class RefundStatusBadge extends StatelessWidget {
  final RefundRequest request;

  const RefundStatusBadge({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final color = request.statusColor;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: 2,
      ),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12)),
      child: Text(
        request.statusLabel,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
