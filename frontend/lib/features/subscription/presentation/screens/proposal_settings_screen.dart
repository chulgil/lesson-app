import 'package:flutter/material.dart';
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
      return Scaffold(
        appBar: AppBar(title: const Text('자동 제안 설정')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('자동 제안 설정'), centerTitle: true),
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
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
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
                      '체험 후 자동 제안',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      '체험레슨 완료 시 수강권을 자동으로 제안합니다',
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
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
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
                      '체험 후 즉시 제안하여 전환율을 높이세요',
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
          '제안할 수강권',
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          '선택하지 않으면 모든 활성 수강권이 제안됩니다',
          style: AppTypography.caption.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.space3),
        templatesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('오류가 발생했습니다.'),
          data: (templates) {
            if (templates.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.space4),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
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
                      '수강권 템플릿이 없습니다',
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
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLarge,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.space3),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? AppColors.primary.withValues(alpha: 0.05)
                                    : AppColors.paper,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusLarge,
                            ),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? AppColors.primary
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
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusSmall,
                                  ),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? AppColors.primary
                                            : AppColors.inkQuaternary,
                                    width: 2,
                                  ),
                                  color:
                                      isSelected
                                          ? AppColors.primary
                                          : Colors.transparent,
                                ),
                                child:
                                    isSelected
                                        ? const Icon(
                                          Icons.check,
                                          size: 14,
                                          color: Colors.white,
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
                                          const Text(
                                            '⭐',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      '${template.totalLessons}회 · ${template.formattedPrice}',
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
                                              ? AppColors.paperAccent.withValues(
                                                alpha: 0.2,
                                              )
                                              : AppColors.paperDark,
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusSmall,
                                      ),
                                    ),
                                    child: Text(
                                      isRecommended ? '추천' : '추천',
                                      style: AppTypography.captionSmall
                                          .copyWith(
                                            color:
                                                isRecommended
                                                    ? AppColors.paperAccent
                                                    : AppColors
                                                        .textTertiaryLight,
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
              '골든타임 할인',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.paperAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              child: Text(
                '전환율 UP',
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
          '체험 완료 후 일정 시간 내 결제 시 할인을 적용합니다',
          style: AppTypography.caption.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.space3),
        Container(
          padding: const EdgeInsets.all(AppSpacing.space4),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            border: Border.all(color: AppColors.inkQuaternary),
          ),
          child: Column(
            children: [
              // Discount percentage
              Row(
                children: [
                  Text('할인율', style: AppTypography.bodyMedium),
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
                  Text('유효 시간', style: AppTypography.bodyMedium),
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
                              child: Text('$v시간'),
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
                  decoration: BoxDecoration(
                    color: AppColors.paperAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMedium,
                    ),
                  ),
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
                          '체험 후 $_discountHours시간 이내 결제 시 $_discountPercent% 할인',
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
          '자동 리마인더',
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          '제안 후 응답이 없으면 자동으로 알림을 보냅니다',
          style: AppTypography.caption.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.space3),
        Container(
          padding: const EdgeInsets.all(AppSpacing.space4),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            border: Border.all(color: AppColors.inkQuaternary),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('자동 리마인더', style: AppTypography.bodyMedium),
                    Text(
                      '24시간, 48시간, 72시간 후 알림',
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          ),
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
            content: Text('설정이 저장되었습니다'),
            backgroundColor: AppColors.paperOk,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('저장 실패. 다시 시도해주세요.'),
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
