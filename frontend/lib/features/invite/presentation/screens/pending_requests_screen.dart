import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/profile/domain/entities/invite.dart';
import '../../../../features/profile/presentation/providers/invite_provider.dart';

/// Screen for viewing and managing pending connection requests
class PendingRequestsScreen extends ConsumerWidget {
  const PendingRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingRequests = ref.watch(pendingRequestsProvider);
    final userRole = ref.watch(currentInviteUserRoleProvider);
    final responderState = ref.watch(connectionRequestResponderProvider);

    return Scaffold(
      backgroundColor: AppColors.paperDark,
      appBar: AppBar(
        title: const Text('연결 요청'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: pendingRequests.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildError('요청 목록을 불러올 수 없습니다. 다시 시도해주세요.'),
        data: (requests) {
          if (requests.isEmpty) {
            return _buildEmpty(userRole);
          }
          return _buildRequestsList(context, ref, requests, responderState);
        },
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.space4),
            Text(
              '요청 목록을 불러오는 중 오류가 발생했습니다',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(InviteUserRole userRole) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_outlined,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.space6),
            Text(
              '대기 중인 연결 요청이 없습니다',
              style: AppTypography.headingSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              userRole == InviteUserRole.teacher
                  ? '학생이 초대 코드를 사용하면\n여기에 요청이 표시됩니다.'
                  : '선생님이 초대 코드를 사용하면\n여기에 요청이 표시됩니다.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsList(
    BuildContext context,
    WidgetRef ref,
    List<ConnectionRequest> requests,
    AsyncValue<void> responderState,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.space3),
      itemBuilder: (context, index) {
        final request = requests[index];
        return _RequestCard(
          request: request,
          isProcessing: responderState.isLoading,
          onAccept: () => _handleAccept(context, ref, request),
          onReject: () => _handleReject(context, ref, request),
        );
      },
    );
  }

  Future<void> _handleAccept(
    BuildContext context,
    WidgetRef ref,
    ConnectionRequest request,
  ) async {
    final connection = await ref
        .read(connectionRequestResponderProvider.notifier)
        .acceptRequest(request.id);

    if (connection != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${request.requesterName ?? request.requesterRole.label}님과 연결되었습니다!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _handleReject(
    BuildContext context,
    WidgetRef ref,
    ConnectionRequest request,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('연결 거절'),
            content: Text(
              '${request.requesterName ?? request.requesterRole.label}님의 연결 요청을 거절하시겠습니까?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(AppStrings.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('거절'),
              ),
            ],
          ),
    );

    if (confirmed == true && context.mounted) {
      final success = await ref
          .read(connectionRequestResponderProvider.notifier)
          .rejectRequest(request.id);

      if (success && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('요청이 거절되었습니다')));
      }
    }
  }
}

class _RequestCard extends StatelessWidget {
  final ConnectionRequest request;
  final bool isProcessing;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _RequestCard({
    required this.request,
    required this.isProcessing,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final requesterName = request.requesterName ?? request.requesterRole.label;
    final method = request.method;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.inkQuaternary),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  requesterName.isNotEmpty ? requesterName[0] : '?',
                  style: AppTypography.headingSmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      requesterName,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          method.icon,
                          size: 14,
                          color: AppColors.inkSecondary,
                        ),
                        const SizedBox(width: AppSpacing.space1),
                        Text(
                          '${method.label}로 연결 요청',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.inkSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildTimeRemaining(),
            ],
          ),

          // Message (if any)
          if (request.message != null && request.message!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space3),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.space3),
              decoration: BoxDecoration(
                color: AppColors.paperDark,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              child: Text(
                request.message!,
                style: AppTypography.bodyMedium.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.space4),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isProcessing ? null : onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.space3,
                    ),
                  ),
                  child: const Text('거절'),
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: ElevatedButton(
                  onPressed: isProcessing ? null : onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.space3,
                    ),
                  ),
                  child:
                      isProcessing
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text('수락'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRemaining() {
    final remaining = request.timeRemaining;
    String text;
    Color color;

    if (remaining.inDays > 0) {
      text = '${remaining.inDays}일 남음';
      color = AppColors.inkSecondary;
    } else if (remaining.inHours > 0) {
      text = '${remaining.inHours}시간 남음';
      color = AppColors.warning;
    } else {
      text = '곧 만료';
      color = AppColors.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Text(text, style: AppTypography.caption.copyWith(color: color)),
    );
  }
}
