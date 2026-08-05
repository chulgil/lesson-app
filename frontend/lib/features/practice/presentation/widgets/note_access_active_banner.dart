import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../domain/entities/note_access_request.dart';
import '../providers/note_access_provider.dart';

/// Banner to display active note access permission and allow revocation.
///
/// [studentId] scopes the banner to a specific note owner (recipient). When
/// provided, the banner only shows if the active access belongs to that
/// student — so a multi-child parent never sees another child's access. (#586)
class NoteAccessActiveBanner extends ConsumerStatefulWidget {
  final String? studentId;

  const NoteAccessActiveBanner({super.key, this.studentId});

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
            // Scope to the selected child: hide if the active access belongs
            // to a different student. (#586)
            if (widget.studentId != null &&
                access.recipientUserId != widget.studentId) {
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
    final descriptionText = daysRemaining == 0
        ? AppStrings.noteAccessActiveBannerLastDay
        : AppStrings.noteAccessActiveBannerDays(daysRemaining);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space2,
      ),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: const BoxDecoration(color: AppColors.bubbleSuccessBackground),
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
                  onPressed: _isRevoking
                      ? null
                      : () => _revoke(context, access),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, AppSpacing.buttonHeightSmall),
                    side: BorderSide(
                      color: _isRevoking
                          ? AppColors.inkQuaternary
                          : AppColors.bubbleSuccessText,
                    ),
                  ),
                  child: Text(
                    AppStrings.revokeButton,
                    style: AppTypography.button.copyWith(
                      color: _isRevoking
                          ? AppColors.inkQuaternary
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
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showNotebookDialog<bool>(
      context: context,
      title: '노트 접근 권한 회수',
      message: '학원의 노트 접근 권한을 회수하시겠습니까?',
      confirmLabel: '회수',
      cancelLabel: '취소',
    );

    if (confirmed != true) return;

    setState(() => _isRevoking = true);

    try {
      await ref
          .read(noteAccessActionsProvider.notifier)
          .revokeAccess(access.id);

      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text(AppStrings.revokeSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isRevoking = false);
      }
    }
  }
}
