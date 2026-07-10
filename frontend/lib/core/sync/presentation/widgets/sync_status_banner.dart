import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_strings.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../application/sync_adapter.dart' show conflictLwwRejectedCode;
import '../../application/sync_service.dart';
import '../../domain/sync_queue_entry.dart';
import '../providers/sync_provider.dart';

/// Global write-queue status strip (#1120, spec §8 / G-10).
///
/// Renders one compact strip above the app content, mounted by
/// [OfflineBannerWrapper] so every role (teacher / student / parent) sees it.
/// Priority: failed > syncing > pending — the highest-severity state wins the
/// single strip. The failed strip is tappable and expands an inline list where
/// each entry can be retried or discarded.
///
/// Receives [stats] from the wrapper (which already watches the stats stream)
/// so this widget only renders when there is a backlog.
class SyncStatusBanner extends ConsumerStatefulWidget {
  const SyncStatusBanner({required this.stats, super.key});

  final SyncServiceStats stats;

  @override
  ConsumerState<SyncStatusBanner> createState() => _SyncStatusBannerState();
}

class _SyncStatusBannerState extends ConsumerState<SyncStatusBanner> {
  bool _expanded = false;

  // Memoized failed-entries fetch so the FutureBuilder does not re-hit Hive on
  // every rebuild; invalidated when the failed count changes or after an action.
  Future<List<SyncQueueEntry>>? _failedFuture;
  int _failedNonce = 0;
  int _loadedNonce = -1;
  int _loadedCount = -1;

  Future<List<SyncQueueEntry>> _failed(int count) {
    if (_failedFuture == null ||
        _loadedNonce != _failedNonce ||
        _loadedCount != count) {
      _loadedNonce = _failedNonce;
      _loadedCount = count;
      _failedFuture = ref.read(syncServiceProvider).failedEntries();
    }
    return _failedFuture!;
  }

  void _refreshFailed() {
    setState(() => _failedNonce++);
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.stats;

    if (stats.failed > 0) {
      return _buildFailedStrip(stats.failed);
    }

    // No failures left → collapse any open panel.
    if (_expanded) {
      _expanded = false;
    }

    if (stats.syncing > 0) {
      return _MutedStrip(
        icon: Icons.sync_rounded,
        label: AppStrings.syncStatusSyncing(stats.syncing),
        showSpinner: true,
      );
    }

    if (stats.pending > 0) {
      return _MutedStrip(
        icon: Icons.cloud_upload_outlined,
        label: stats.online
            ? AppStrings.syncStatusPending(stats.pending)
            : AppStrings.syncStatusPendingOffline(stats.pending),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildFailedStrip(int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: AppColors.paperAccentSoft,
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space4,
                vertical: AppSpacing.space2,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: AppSpacing.iconSM,
                    color: AppColors.paperAccent,
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: Text(
                      AppStrings.syncStatusFailed(count),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: AppSpacing.iconSM,
                    color: AppColors.inkTertiary,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_expanded) _buildFailedPanel(count),
      ],
    );
  }

  Widget _buildFailedPanel(int count) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(bottom: BorderSide(color: AppColors.inkQuaternary)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 240),
        child: FutureBuilder<List<SyncQueueEntry>>(
          future: _failed(count),
          builder: (context, snapshot) {
            final entries = snapshot.data;
            if (entries == null) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.space3),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (entries.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.space3),
                child: Text(
                  AppStrings.syncQueueEmpty,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.inkTertiary,
                  ),
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: entries.length,
              itemBuilder: (context, index) => _FailedEntryRow(
                entry: entries[index],
                onRetry: () async {
                  await ref
                      .read(syncServiceProvider)
                      .retryEntry(entries[index].id);
                  _refreshFailed();
                },
                onDelete: () async {
                  await ref
                      .read(syncServiceProvider)
                      .deleteEntry(entries[index].id);
                  _refreshFailed();
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

/// A single failed queue entry row with retry / delete actions.
class _FailedEntryRow extends StatelessWidget {
  const _FailedEntryRow({
    required this.entry,
    required this.onRetry,
    required this.onDelete,
  });

  final SyncQueueEntry entry;
  final Future<void> Function() onRetry;
  final Future<void> Function() onDelete;

  String get _description {
    switch (entry.errorCode) {
      case SyncService.orphanedUnsafeReplayCode:
        return AppStrings.syncOrphanEntryDescription;
      case conflictLwwRejectedCode:
        return AppStrings.syncConflictEntryDescription;
      default:
        return AppStrings.syncEntryFailedDescription;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space2,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _description,
              style: AppTypography.bodySmall.copyWith(color: AppColors.ink),
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space2,
              ),
              minimumSize: const Size(0, AppSpacing.buttonHeightSmall),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              AppStrings.syncRetryAction,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.paperAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onDelete,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space2,
              ),
              minimumSize: const Size(0, AppSpacing.buttonHeightSmall),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              AppStrings.syncDeleteAction,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Muted single-line strip for the pending / syncing states (non-interactive).
class _MutedStrip extends StatelessWidget {
  const _MutedStrip({
    required this.icon,
    required this.label,
    this.showSpinner = false,
  });

  final IconData icon;
  final String label;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.offlineBannerBackground,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showSpinner)
              const SizedBox(
                width: AppSpacing.iconSM,
                height: AppSpacing.iconSM,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.offlineBannerForeground,
                  ),
                ),
              )
            else
              Icon(
                icon,
                size: AppSpacing.iconSM,
                color: AppColors.offlineBannerForeground,
              ),
            const SizedBox(width: AppSpacing.space2),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.offlineBannerForeground,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
