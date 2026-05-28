import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/note_access_request.dart';
import '../providers/note_access_provider.dart';

/// Banner to display active note access permission and allow revocation
class NoteAccessActiveBanner extends ConsumerStatefulWidget {
  const NoteAccessActiveBanner({super.key});

  @override
  ConsumerState<NoteAccessActiveBanner> createState() =>
      _NoteAccessActiveBannerState();
}

class _NoteAccessActiveBannerState
    extends ConsumerState<NoteAccessActiveBanner> {
  bool _isRevoking = false;

  @override
  Widget build(BuildContext context) {
    return ref
        .watch(activeNoteAccessProvider)
        .when(
          data: (access) {
            if (access == null || !access.isActive) {
              return const SizedBox.shrink();
            }

            return _buildBanner(context, access);
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
  }

  Widget _buildBanner(BuildContext context, NoteAccessRequest access) {
    final daysRemaining = access.remainingDays;
    final descriptionText =
        daysRemaining == 0
            ? AppStrings.noteAccessActiveBannerLastDay
            : AppStrings.noteAccessActiveBannerDays(daysRemaining);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space2,
      ),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.bubbleSuccessBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.noteAccessActiveBannerTitle,
                      style: AppTypography.buttonSmall.copyWith(
                        color: AppColors.bubbleSuccessText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      descriptionText,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.bubbleSuccessText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              // Revoke button
              SizedBox(
                height: AppSpacing.buttonHeightSmall,
                child: OutlinedButton(
                  onPressed:
                      _isRevoking ? null : () => _revoke(context, access),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, AppSpacing.buttonHeightSmall),
                    side: BorderSide(
                      color:
                          _isRevoking
                              ? Colors.grey[400]!
                              : AppColors.bubbleSuccessText,
                    ),
                  ),
                  child: Text(
                    AppStrings.revokeButton,
                    style: AppTypography.button.copyWith(
                      color:
                          _isRevoking
                              ? Colors.grey[400]
                              : AppColors.bubbleSuccessText,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _revoke(BuildContext context, NoteAccessRequest access) async {
    if (_isRevoking) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('노트 접근 권한 회수'),
            content: const Text('학원의 노트 접근 권한을 회수하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('회수'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    setState(() => _isRevoking = true);

    try {
      await ref
          .read(noteAccessActionsProvider.notifier)
          .revokeAccess(access.id);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(AppStrings.revokeSuccess)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isRevoking = false);
      }
    }
  }
}
