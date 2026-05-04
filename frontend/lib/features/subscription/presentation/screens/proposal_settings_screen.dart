import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/proposal_settings.dart';
import '../providers/proposal_settings_providers.dart';
import '../providers/subscription_template_providers.dart';

/// Screen for teachers to configure auto-proposal settings.
class ProposalSettingsScreen extends ConsumerStatefulWidget {
  final String teacherId;

  const ProposalSettingsScreen({super.key, required this.teacherId});

  @override
  ConsumerState<ProposalSettingsScreen> createState() =>
      _ProposalSettingsScreenState();
}

class _ProposalSettingsScreenState
    extends ConsumerState<ProposalSettingsScreen> {
  late ProposalSettings _settings;
  bool _isLoading = true;
  bool _isSaving = false;

  // Form state
  late bool _autoProposalEnabled;
  late Set<String> _selectedTemplateIds;
  late String? _recommendedTemplateId;
  late int _discountPercent;
  late int _discountHours;
  late bool _autoReminderEnabled;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await ref.read(
      teacherProposalSettingsProvider(widget.teacherId).future,
    );
    setState(() {
      _settings = settings;
      _autoProposalEnabled = settings.autoProposalEnabled;
      _selectedTemplateIds = settings.autoProposalTemplateIds.toSet();
      _recommendedTemplateId = settings.recommendedTemplateId;
      _discountPercent = settings.goldenTimeDiscountPercent;
      _discountHours = settings.goldenTimeHours;
      _autoReminderEnabled = settings.autoReminderEnabled;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return NotebookScreenScaffold(
        appBar: AppBar(
          title: const Text(AppStrings.proposalSettingsAppBarTitle),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return NotebookScreenScaffold(
      appBar: AppBar(
        title: const Text(AppStrings.proposalSettingsAppBarTitle),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Auto-proposal toggle
            _buildMainToggle(),

            if (_autoProposalEnabled) ...[
              const SizedBox(height: AppSpacing.space6),

              // Template selection
              _buildTemplateSelection(),

              const SizedBox(height: AppSpacing.space6),

              // Golden time discount
              _buildGoldenTimeSection(),

              const SizedBox(height: AppSpacing.space6),

              // Auto-reminder (disabled for now)
              _buildAutoReminderSection(),
            ],

            const SizedBox(height: AppSpacing.space8),

            // Save button
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainToggle() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color:
            _autoProposalEnabled
                ? AppColors.paperOk.withValues(alpha: 0.1)
                : AppColors.paper,
        border: Border.all(
          color:
              _autoProposalEnabled
                  ? AppColors.paperOk.withValues(alpha: 0.3)
                  : AppColors.inkQuaternary,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.proposalSettingsAutoToggleTitle,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      AppStrings.proposalSettingsAutoToggleSubtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _autoProposalEnabled,
                onChanged: (value) {
                  setState(() {
                    _autoProposalEnabled = value;
                  });
                },
                activeThumbColor: AppColors.paperOk,
              ),
            ],
          ),
          if (_autoProposalEnabled) ...[
            const SizedBox(height: AppSpacing.space3),
            Container(
              padding: const EdgeInsets.all(AppSpacing.space3),
              decoration: BoxDecoration(
                color: AppColors.ink.withValues(alpha: 0.1),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.ink,
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: Text(
                      AppStrings.proposalSettingsAutoToggleHint,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTemplateSelection() {
    final templatesAsync = ref.watch(
      activeTeacherTemplatesProvider(widget.teacherId),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.proposalSettingsTemplateSectionTitle,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          AppStrings.proposalSettingsTemplateSectionHint,
          style: AppTypography.caption.copyWith(color: AppColors.inkSecondary),
        ),
        const SizedBox(height: AppSpacing.space3),
        templatesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Text('${AppStrings.errorOccurred}.'),
          data: (templates) {
            if (templates.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.space4),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  border: Border.all(color: AppColors.inkQuaternary),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 20,
                      color: AppColors.inkSecondary,
                    ),
                    const SizedBox(width: AppSpacing.space3),
                    Text(
                      AppStrings.proposalSettingsTemplateEmpty,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children:
                  templates.map((template) {
                    final isSelected =
                        _selectedTemplateIds.isEmpty ||
                        _selectedTemplateIds.contains(template.id);
                    final isRecommended = _recommendedTemplateId == template.id;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            if (_selectedTemplateIds.isEmpty) {
                              // First selection: start with this template
                              _selectedTemplateIds = {template.id};
                            } else if (isSelected) {
                              _selectedTemplateIds.remove(template.id);
                              if (_recommendedTemplateId == template.id) {
                                _recommendedTemplateId =
                                    _selectedTemplateIds.isNotEmpty
                                        ? _selectedTemplateIds.first
                                        : null;
                              }
                            } else {
                              _selectedTemplateIds.add(template.id);
                            }
                            // Clear selection = use all
                            if (_selectedTemplateIds.length ==
                                templates.length) {
                              _selectedTemplateIds.clear();
                              _recommendedTemplateId = null;
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.space3),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? AppColors.paperAccentSoft
                                    : AppColors.paper,
                            border: Border.all(
                              color:
                                  isSelected
                                      ? AppColors.paperAccent
                                      : AppColors.inkQuaternary,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Checkbox
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? AppColors.paperAccent
                                            : AppColors.inkQuaternary,
                                    width: 2,
                                  ),
                                  color:
                                      isSelected
                                          ? AppColors.paperAccent
                                          : Colors.transparent,
                                ),
                                child:
                                    isSelected
                                        ? const Icon(
                                          Icons.check,
                                          size: 14,
                                          color: AppColors.paper,
                                        )
                                        : null,
                              ),
                              const SizedBox(width: AppSpacing.space3),

                              // Template info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          template.name,
                                          style: AppTypography.bodyMedium
                                              .copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        if (isRecommended) ...[
                                          const SizedBox(
                                            width: AppSpacing.space1,
                                          ),
                                          Text(
                                            '⭐',
                                            style: AppTypography.bodySmall,
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      AppStrings.proposalSettingsTemplateInfoFormat(
                                        template.totalLessons,
                                        template.formattedPrice,
                                      ),
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.inkSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Recommend button
                              if (isSelected && _selectedTemplateIds.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _recommendedTemplateId = template.id;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.space2,
                                      vertical: AppSpacing.space1,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isRecommended
                                              ? AppColors.paperAccent
                                                  .withValues(alpha: 0.2)
                                              : AppColors.paperDark,
                                    ),
                                    child: Text(
                                      AppStrings.templateRecommendedBadge,
                                      style: AppTypography.captionSmall
                                          .copyWith(
                                            color:
                                                isRecommended
                                                    ? AppColors.paperAccent
                                                    : AppColors.inkTertiary,
                                          ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildGoldenTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppStrings.proposalSettingsGoldenTimeTitle,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: AppColors.paperAccentSoft),
              child: Text(
                AppStrings.proposalSettingsConversionUpBadge,
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.paperAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          AppStrings.proposalSettingsGoldenTimeHint,
          style: AppTypography.caption.copyWith(color: AppColors.inkSecondary),
        ),
        const SizedBox(height: AppSpacing.space3),
        Container(
          padding: const EdgeInsets.all(AppSpacing.space4),
          decoration: BoxDecoration(
            color: AppColors.paper,
            border: Border.all(color: AppColors.inkQuaternary),
          ),
          child: Column(
            children: [
              // Discount percentage
              Row(
                children: [
                  Text(
                    AppStrings.proposalSettingsDiscountPercentLabel,
                    style: AppTypography.bodyMedium,
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 80,
                    child: DropdownButtonFormField<int>(
                      initialValue: _discountPercent,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.space3,
                        ),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items:
                          [0, 5, 10, 15, 20].map((v) {
                            return DropdownMenuItem(
                              value: v,
                              child: Text('$v%'),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _discountPercent = value ?? 10;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space3),
              // Validity hours
              Row(
                children: [
                  Text(
                    AppStrings.proposalSettingsValidityHoursLabel,
                    style: AppTypography.bodyMedium,
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 100,
                    child: DropdownButtonFormField<int>(
                      initialValue: _discountHours,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.space3,
                        ),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items:
                          [12, 24, 48, 72].map((v) {
                            return DropdownMenuItem(
                              value: v,
                              child: Text(
                                AppStrings.proposalSettingsHoursFormat(v),
                              ),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _discountHours = value ?? 24;
                        });
                      },
                    ),
                  ),
                ],
              ),
              if (_discountPercent > 0) ...[
                const SizedBox(height: AppSpacing.space3),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.space3),
                  decoration: BoxDecoration(color: AppColors.paperAccentSoft),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_offer,
                        size: 16,
                        color: AppColors.paperAccent,
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      Expanded(
                        child: Text(
                          AppStrings.proposalSettingsGoldenTimeSummaryFormat(
                            _discountHours,
                            _discountPercent,
                          ),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.paperAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAutoReminderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.proposalSettingsAutoReminderTitle,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          AppStrings.proposalSettingsAutoReminderHint,
          style: AppTypography.caption.copyWith(color: AppColors.inkSecondary),
        ),
        const SizedBox(height: AppSpacing.space3),
        Container(
          padding: const EdgeInsets.all(AppSpacing.space4),
          decoration: BoxDecoration(
            color: AppColors.paper,
            border: Border.all(color: AppColors.inkQuaternary),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.proposalSettingsAutoReminderTitle,
                      style: AppTypography.bodyMedium,
                    ),
                    Text(
                      AppStrings.proposalSettingsAutoReminderSchedule,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _autoReminderEnabled,
                onChanged: (value) {
                  setState(() {
                    _autoReminderEnabled = value;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveSettings,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
          shape: RoundedRectangleBorder(),
        ),
        child:
            _isSaving
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : const Text(AppStrings.save),
      ),
    );
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final notifier = ref.read(proposalSettingsNotifierProvider.notifier);

      final updatedSettings = _settings.copyWith(
        autoProposalEnabled: _autoProposalEnabled,
        autoProposalTemplateIds: _selectedTemplateIds.toList(),
        recommendedTemplateId: _recommendedTemplateId,
        goldenTimeDiscountPercent: _discountPercent,
        goldenTimeHours: _discountHours,
        autoReminderEnabled: _autoReminderEnabled,
        updatedAt: DateTime.now(),
      );

      await notifier.updateSettings(updatedSettings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.proposalSettingsSavedSnackbar),
            backgroundColor: AppColors.paperOk,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.proposalSettingsSaveFailedSnackbar),
            backgroundColor: AppColors.paperAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
