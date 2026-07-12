import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_banner.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../../core/widgets/notebook/thin_rule.dart';
import '../../domain/entities/cancellation_defaults.dart';
import '../providers/cancellation_defaults_provider.dart';

/// Screen for configuring teacher cancellation policy defaults
class CancellationDefaultsScreen extends ConsumerWidget {
  const CancellationDefaultsScreen({super.key});

  /// Awaits a notifier save; on failure the notifier has already rolled the
  /// state back (#1184), so this only needs to tell the user.
  Future<void> _save(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.settingsSaveFailed),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defaultsAsync = ref.watch(cancellationDefaultsNotifierProvider);

    return NotebookScreenScaffold(
      appBar: const NotebookDetailAppBar(
        title: AppStrings.profileCancellationDefaultsTitle,
      ),
      body: defaultsAsync.when(
        data:
            (defaults) => _CancellationDefaultsContent(
              defaults: defaults,
              onDeadlineChanged: (hours) {
                _save(
                  context,
                  () => ref
                      .read(cancellationDefaultsNotifierProvider.notifier)
                      .updateDeadlineHours(hours),
                );
              },
              onCompensationToggle: (enabled) {
                _save(
                  context,
                  () => ref
                      .read(cancellationDefaultsNotifierProvider.notifier)
                      .toggleCompensationEnabled(enabled),
                );
              },
              onIncludeExtraMinutesToggle: (include) {
                _save(
                  context,
                  () => ref
                      .read(cancellationDefaultsNotifierProvider.notifier)
                      .toggleIncludeExtraMinutesText(include),
                );
              },
              onCompensationMessageChanged: (message) {
                _save(
                  context,
                  () => ref
                      .read(cancellationDefaultsNotifierProvider.notifier)
                      .updateCompensationMessage(message),
                );
              },
              onNotifyOwnerToggle: (notify) {
                _save(
                  context,
                  () => ref
                      .read(cancellationDefaultsNotifierProvider.notifier)
                      .toggleNotifyOwnerOnLateCancel(notify),
                );
              },
            ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, __) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.paperAccent,
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  const Text(AppStrings.profileLessonTimeError),
                  const SizedBox(height: AppSpacing.space4),
                  FilledButton(
                    onPressed: () {
                      ref
                          .read(cancellationDefaultsNotifierProvider.notifier)
                          .refresh();
                    },
                    child: const Text(AppStrings.retry),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}

class _CancellationDefaultsContent extends StatefulWidget {
  final CancellationDefaults defaults;
  final Function(int) onDeadlineChanged;
  final Function(bool) onCompensationToggle;
  final Function(bool) onIncludeExtraMinutesToggle;
  final Function(String) onCompensationMessageChanged;
  final Function(bool) onNotifyOwnerToggle;

  const _CancellationDefaultsContent({
    required this.defaults,
    required this.onDeadlineChanged,
    required this.onCompensationToggle,
    required this.onIncludeExtraMinutesToggle,
    required this.onCompensationMessageChanged,
    required this.onNotifyOwnerToggle,
  });

  @override
  State<_CancellationDefaultsContent> createState() =>
      _CancellationDefaultsContentState();
}

class _CancellationDefaultsContentState
    extends State<_CancellationDefaultsContent> {
  late TextEditingController _messageController;
  late TextEditingController _deadlineController;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController(
      text: widget.defaults.studentCompensationExtraMinutesMessage ?? '',
    );
    _deadlineController = TextEditingController(
      text: widget.defaults.cancellationDeadlineHours.toString(),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NotebookBanner(
            message: AppStrings.cancellationDefaultsRoleNote,
            leadingIcon: Icons.info_outline,
          ),
          _buildDeadlineSection(),
          const SizedBox(height: AppSpacing.space6),
          _buildCompensationSection(),
          const SizedBox(height: AppSpacing.space6),
          _buildNotifyOwnerSection(),
          const SizedBox(height: AppSpacing.space6),
        ],
      ),
    );
  }

  Widget _buildDeadlineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.profileCancellationDeadlineHours,
          style: NotebookTypography.sectionTitle,
        ),
        const SizedBox(height: AppSpacing.space2),
        Text(
          AppStrings.profileCancellationDeadlineDescription,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        Container(
          decoration: BoxDecoration(color: AppColors.paperDark),
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: AppStrings.profileCancellationDeadlineHoursHint,
                    filled: true,
                    fillColor: AppColors.paper,
                    border: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.inkQuaternary),
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.inkQuaternary),
                    ),
                  ),
                  controller: _deadlineController,
                  onChanged: (value) {
                    final hours = int.tryParse(value);
                    if (hours != null && hours > 0) {
                      widget.onDeadlineChanged(hours);
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Text(
                AppStrings.profileCancellationDeadlineHoursHint,
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompensationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.profileStudentCompensation,
          style: NotebookTypography.sectionTitle,
        ),
        const SizedBox(height: AppSpacing.space4),
        Container(
          decoration: BoxDecoration(color: AppColors.paperDark),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text(AppStrings.profileStudentCompensation),
                subtitle: Text(
                  AppStrings.profileStudentCompensationDescription,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
                value: widget.defaults.studentCompensationExtraMinutesEnabled,
                onChanged: widget.onCompensationToggle,
              ),
              if (widget.defaults.studentCompensationExtraMinutesEnabled)
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16),
                      child: const ThinRule(),
                    ),
                    SwitchListTile(
                      title: const Text(
                        AppStrings.profileIncludeExtraMinutesText,
                      ),
                      value:
                          widget.defaults.includeExtraMinutesTextOnLateCancel,
                      onChanged: widget.onIncludeExtraMinutesToggle,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16),
                      child: const ThinRule(),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.space4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.profileCompensationMessage,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.inkSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.space2),
                          TextField(
                            controller: _messageController,
                            maxLength: 100,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText:
                                  AppStrings.profileCompensationMessageHint,
                              hintStyle: AppTypography.bodySmall.copyWith(
                                color: AppColors.inkTertiary,
                              ),
                              filled: true,
                              fillColor: AppColors.paper,
                              border: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.inkQuaternary,
                                ),
                              ),
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.inkQuaternary,
                                ),
                              ),
                              counterText: '',
                            ),
                            onChanged: widget.onCompensationMessageChanged,
                          ),
                          const SizedBox(height: AppSpacing.space2),
                          Text(
                            AppStrings.profileCompensationMessageDescription,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.inkTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotifyOwnerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.profileNotifyOwnerOnLateCancel,
          style: NotebookTypography.sectionTitle,
        ),
        const SizedBox(height: AppSpacing.space2),
        Text(
          AppStrings.profileNotifyOwnerDescription,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        Container(
          decoration: BoxDecoration(color: AppColors.paperDark),
          child: SwitchListTile(
            title: const Text(AppStrings.profileNotifyOwnerOnLateCancel),
            value: widget.defaults.notifyOwnerOnLateCancel,
            onChanged: widget.onNotifyOwnerToggle,
          ),
        ),
      ],
    );
  }
}
