import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/widgets/swipe_action_tile.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../profile/domain/entities/teacher_settings.dart';
import '../../../settings/settings_facade.dart';
import '../../domain/entities/subscription_template.dart';
import '../extensions/subscription_template_visuals.dart';
import '../providers/subscription_template_providers.dart';
import 'subscription_template_form_sheet.dart';

/// Screen for managing subscription templates (teacher app).
class SubscriptionTemplateListScreen extends ConsumerWidget {
  final String teacherId;

  const SubscriptionTemplateListScreen({super.key, required this.teacherId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(teacherTemplatesProvider(teacherId));

    return NotebookScreenScaffold(
      appBar: NotebookDetailAppBar(
        title: AppStrings.templateListAppBarTitle,
        actions: const [DetailAppBarAction.add, DetailAppBarAction.settings],
        onAction: (action) {
          if (action == DetailAppBarAction.add) {
            _showAddTemplateDialog(context, ref);
          } else if (action == DetailAppBarAction.settings) {
            context.push('${AppRoutes.proposalSettings}?teacherId=$teacherId');
          }
        },
      ),
      body: Column(
        children: [
          // W3 Task 3.4 — 체험 레슨 정책 섹션 (spec §6.3 PLAN O1).
          // LessonTimeSettingsScreen §5 에서 이동. 위치 안정성 — 빈/로딩/에러
          // 상태와 무관하게 항상 최상단 노출.
          const _TrialLessonSection(),
          Expanded(
            child: templatesAsync.when(
              data: (templates) => _buildContent(context, ref, templates),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _buildErrorState(context, error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<SubscriptionTemplate> templates,
  ) {
    if (templates.isEmpty) {
      return _buildEmptyState(context, ref);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.space4),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return _TemplateCard(
          template: template,
          onEdit: () => _showEditTemplateDialog(context, ref, template),
          onToggleActive: () => _toggleActive(ref, template),
          onDelete: () => _confirmDelete(context, ref, template),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.card_membership_outlined,
              size: 64,
              color: AppColors.inkTertiary,
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              AppStrings.noSubscriptionsRegisteredTitle,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              AppStrings.templateEmptyHint,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.paperAccent,
            ),
            const SizedBox(height: AppSpacing.space3),
            Text(
              AppStrings.cannotLoadData,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTemplateDialog(BuildContext context, WidgetRef ref) {
    // SubscriptionTemplateFormSheet 는 자체 surface(Container)+스크롤
    // (SingleChildScrollView)+핸들을 소유하므로 self-surfaced 용
    // showNotebookModalBottomSheet 를 쓴다.
    // showNotebookBottomSheet 는 자식을 Column(min) 으로 감싸 unbounded 높이를
    // 줘 SingleChildScrollView 가 스크롤되지 못하고 폼이 세로 overflow 한다.
    showNotebookModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => SubscriptionTemplateFormSheet(
        teacherId: teacherId,
        onSave: (template) async {
          await ref
              .read(subscriptionTemplateNotifierProvider.notifier)
              .createTemplate(
                ownerId: template.ownerId,
                ownerType: template.ownerType,
                name: template.name,
                totalLessons: template.totalLessons,
                lessonDurationMinutes: template.lessonDurationMinutes,
                validityDays: template.validityDays,
                price: template.price,
                regularPrice: template.regularPrice,
                description: template.description,
              );
        },
      ),
    );
  }

  void _showEditTemplateDialog(
    BuildContext context,
    WidgetRef ref,
    SubscriptionTemplate template,
  ) {
    // self-surfaced 시트 → showNotebookModalBottomSheet (위 _showAddTemplateDialog 참조).
    showNotebookModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => SubscriptionTemplateFormSheet(
        teacherId: teacherId,
        template: template,
        onSave: (updated) async {
          await ref
              .read(subscriptionTemplateNotifierProvider.notifier)
              .updateTemplate(updated);
        },
      ),
    );
  }

  Future<void> _toggleActive(
    WidgetRef ref,
    SubscriptionTemplate template,
  ) async {
    await ref
        .read(subscriptionTemplateNotifierProvider.notifier)
        .toggleActive(template);
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    SubscriptionTemplate template,
  ) {
    showNotebookDialog(
      context: context,
      title: AppStrings.templateDeleteDialogTitle,
      content: Text(AppStrings.templateDeleteConfirmFormat(template.name)),
      cancelLabel: AppStrings.cancel,
      confirmLabel: AppStrings.delete,
      isDestructive: true,
      onConfirm: () async {
        Navigator.pop(context);
        await ref
            .read(subscriptionTemplateNotifierProvider.notifier)
            .deleteTemplate(template);
      },
    );
  }
}

/// Individual template card widget.
class _TemplateCard extends StatelessWidget {
  final SubscriptionTemplate template;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  const _TemplateCard({
    required this.template,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final card = NotebookCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: template.isActive
              ? AppColors.inkQuaternary
              : AppColors.inkBorderStrong,
        ),
      ),
      color: template.isActive ? AppColors.paper : AppColors.paperDark,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              template.name,
                              style: AppTypography.headingSmall.copyWith(
                                color: template.isActive
                                    ? AppColors.ink
                                    : AppColors.inkTertiary,
                              ),
                            ),
                            if (!template.isActive) ...[
                              const SizedBox(width: AppSpacing.space2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.inkTertiary.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                                child: Text(
                                  AppStrings.templateInactiveBadge,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.inkTertiary,
                                  ),
                                ),
                              ),
                            ],
                            // 🆕 자동 제안 배지
                            if (template.isAutoProposalEnabled &&
                                template.isActive) ...[
                              const SizedBox(width: AppSpacing.space2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.paperOk.withValues(
                                    alpha: 0.1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.flash_on,
                                      size: 12,
                                      color: AppColors.paperOk,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      AppStrings.templateAutoBadge,
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.paperOk,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppSpacing.space1),
                        Text(
                          template.summaryTextNoPrice,
                          style: AppTypography.bodyMedium.copyWith(
                            color: template.isActive
                                ? AppColors.inkSecondary
                                : AppColors.inkTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.space2),

              // Price row — 정가 취소선 + 판매가 + 할인율 배지 (정가 미설정 시 단일가).
              // Wrap 으로 narrow(375) 가로 오버플로우 방지.
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.space2,
                runSpacing: AppSpacing.space1,
                children: [
                  if (template.hasDiscount)
                    Text(
                      template.formattedRegularPrice,
                      style: AppTypography.bodySmall.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: AppColors.inkTertiary,
                      ),
                    ),
                  Text(
                    template.formattedPrice,
                    style: AppTypography.headingSmall.copyWith(
                      color: template.isActive
                          ? AppColors.paperAccent
                          : AppColors.inkTertiary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (template.hasDiscount)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.paperAccentSoft,
                      ),
                      child: Text(
                        template.formattedDiscountRate,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.paperAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: AppSpacing.space3),

              // Details row
              Row(
                children: [
                  _DetailChip(
                    icon: Icons.schedule,
                    label: AppStrings.durationMinutesValue(
                      template.lessonDurationMinutes,
                    ),
                    isActive: template.isActive,
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  _DetailChip(
                    icon: Icons.calendar_today,
                    label: template.formattedValidity,
                    isActive: template.isActive,
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  _DetailChip(
                    icon: Icons.calculate_outlined,
                    label: AppStrings.templateUnitPriceLabel(
                      template.formattedPricePerLesson,
                    ),
                    isActive: template.isActive,
                  ),
                ],
              ),

              // Description if present
              if (template.description != null &&
                  template.description!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.space2),
                Text(
                  template.description!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkTertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    // C6: 편집·삭제 = 우→좌 / 활성토글(편의) = 좌→우 스와이프 (trailing 메뉴 대체).
    return SwipeActionTile(
      actions: [
        SwipeAction(
          label: AppStrings.modify,
          icon: Icons.edit_outlined,
          onPressed: onEdit,
        ),
        SwipeAction(
          label: AppStrings.delete,
          icon: Icons.delete_outline,
          tone: SwipeActionTone.destructive,
          onPressed: onDelete,
        ),
      ],
      startActions: [
        SwipeAction(
          label: template.isActive
              ? AppStrings.templateMenuDeactivate
              : AppStrings.templateMenuActivate,
          icon: template.isActive
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          tone: SwipeActionTone.convenience,
          onPressed: onToggleActive,
        ),
      ],
      child: card,
    );
  }
}

/// Detail chip widget.
class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  const _DetailChip({
    required this.icon,
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.paperAccentSoft
            : AppColors.inkSoft,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isActive ? AppColors.paperAccent : AppColors.inkTertiary,
          ),
          const SizedBox(width: AppSpacing.space1),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: isActive ? AppColors.paperAccent : AppColors.inkTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 체험 레슨 정책 섹션 — W3 Task 3.4 (spec §6.3 PLAN O1).
///
/// `TeacherSettings.trialLessonFree` SSOT 사용. LessonTimeSettingsScreen §5
/// 에서 이동된 토글. 별도 화면을 만들지 않고 SubscriptionTemplateListScreen
/// 의 최상단에 고정.
class _TrialLessonSection extends ConsumerWidget {
  const _TrialLessonSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(teacherSettingsNotifierProvider);

    return settingsAsync.when(
      data: (settings) => _TrialLessonBody(settings: settings),
      // 로딩/에러 단계에서는 빈 자리 — 템플릿 리스트 위에 placeholder 노출 안 함.
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _TrialLessonBody extends ConsumerWidget {
  final TeacherSettings settings;

  const _TrialLessonBody({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space4,
        AppSpacing.space4,
        AppSpacing.space4,
        AppSpacing.space2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.profileTrialLessonSection,
            style: NotebookTypography.sectionTitle,
          ),
          const SizedBox(height: AppSpacing.space2),
          Container(
            decoration: const BoxDecoration(color: AppColors.paperDark),
            child: SwitchListTile(
              title: const Text(AppStrings.profileTrialLessonFree),
              subtitle: Text(
                settings.trialLessonFree
                    ? AppStrings.profileTrialLessonFreeOn
                    : AppStrings.profileTrialLessonFreeOff,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
              value: settings.trialLessonFree,
              onChanged: (value) {
                ref
                    .read(teacherSettingsNotifierProvider.notifier)
                    .updateTrialLessonFree(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}
