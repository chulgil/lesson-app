import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/note_access_request.dart';
import '../providers/note_access_provider.dart';

/// Screen to display a note access consent request
class NoteAccessRequestScreen extends ConsumerStatefulWidget {
  /// The request ID to display and process
  final String requestId;

  const NoteAccessRequestScreen({required this.requestId, super.key});

  @override
  ConsumerState<NoteAccessRequestScreen> createState() =>
      _NoteAccessRequestScreenState();
}

class _NoteAccessRequestScreenState
    extends ConsumerState<NoteAccessRequestScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return ref
        .watch(noteAccessRequestProvider(widget.requestId))
        .when(
          data: (request) => _buildContent(context, request),
          loading:
              () => Scaffold(
                appBar: AppBar(
                  title: const Text(AppStrings.noteAccessRequestTitle),
                ),
                body: const Center(child: CircularProgressIndicator()),
              ),
          error:
              (error, stackTrace) => Scaffold(
                appBar: AppBar(
                  title: const Text(AppStrings.noteAccessRequestTitle),
                ),
                body: Center(child: Text('Error: $error')),
              ),
        );
  }

  Widget _buildContent(BuildContext context, NoteAccessRequest? request) {
    if (request == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.noteAccessRequestTitle)),
        body: Center(child: Text(AppStrings.requestNotFound)),
      );
    }

    // Don't allow action if already processed
    final canTakeAction = request.status == NoteAccessStatus.requested;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.noteAccessRequestTitle),
        centerTitle: false,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Academy card
              Card(
                elevation: 0,
                color: Colors.grey[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.academyLabel,
                        style: AppTypography.caption.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space2),
                      Text(
                        request.academyName,
                        style: AppTypography.headingSmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sectionSpacing),

              // Reason card
              Card(
                elevation: 0,
                color: Colors.grey[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.requestReasonLabel,
                        style: AppTypography.caption.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space2),
                      Text(request.reason, style: AppTypography.bodyMedium),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sectionSpacing),

              // Validity card
              Card(
                elevation: 0,
                color: Colors.grey[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.validityLabel,
                        style: AppTypography.caption.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space2),
                      Text(
                        _formatExpiryDate(request.expiresAt),
                        style: AppTypography.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sectionSpacing * 2),

              // Status badge
              if (!canTakeAction) _buildStatusBadge(request),

              // Action buttons
              if (canTakeAction) ...[
                FilledButton(
                  onPressed: _isProcessing ? null : () => _consent(context),
                  child: Text(
                    AppStrings.consentButton,
                    style:
                        _isProcessing
                            ? AppTypography.button.copyWith(color: Colors.grey)
                            : AppTypography.button.copyWith(
                              color: Colors.white,
                            ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space3),
                OutlinedButton(
                  onPressed: _isProcessing ? null : () => _reject(context),
                  child: Text(
                    AppStrings.rejectButton,
                    style:
                        _isProcessing
                            ? AppTypography.button.copyWith(color: Colors.grey)
                            : AppTypography.button,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(NoteAccessRequest request) {
    final statusText = switch (request.status) {
      NoteAccessStatus.consented => '동의됨',
      NoteAccessStatus.rejected => '거절됨',
      NoteAccessStatus.revoked => '회수됨',
      NoteAccessStatus.requested => '요청 중',
    };

    final badgeColor = switch (request.status) {
      NoteAccessStatus.consented => AppColors.bubbleSuccessBackground,
      NoteAccessStatus.rejected => Colors.red[50],
      NoteAccessStatus.revoked => Colors.grey[200],
      NoteAccessStatus.requested => AppColors.bubbleIdleBackground,
    };

    final textColor = switch (request.status) {
      NoteAccessStatus.consented => AppColors.bubbleSuccessText,
      NoteAccessStatus.rejected => Colors.red[700],
      NoteAccessStatus.revoked => Colors.grey[700],
      NoteAccessStatus.requested => AppColors.bubbleIdleText,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Text(
        statusText,
        style: AppTypography.caption.copyWith(color: textColor),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _formatExpiryDate(DateTime expiresAt) {
    final month = expiresAt.month.toString().padLeft(2, '0');
    final day = expiresAt.day.toString().padLeft(2, '0');
    return '${expiresAt.year}.$month.$day';
  }

  Future<void> _consent(BuildContext context) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      await ref
          .read(noteAccessActionsProvider.notifier)
          .consentAccess(widget.requestId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.consentSuccess)),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _reject(BuildContext context) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      await ref
          .read(noteAccessActionsProvider.notifier)
          .rejectAccess(widget.requestId);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(AppStrings.rejectSuccess)));
        Navigator.of(context).pop(false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
