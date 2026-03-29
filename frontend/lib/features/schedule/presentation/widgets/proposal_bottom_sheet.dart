import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../profile/domain/entities/teacher_profile.dart';
import '../../../profile/presentation/providers/teacher_extended_profile_provider.dart';
import '../../../subscription/domain/entities/subscription_template.dart';
import '../../../subscription/presentation/providers/subscription_template_providers.dart';
import '../../../subscription/presentation/widgets/selectable_template_card.dart';

/// Result from the proposal bottom sheet.
class ProposalResult {
  final List<String> templateIds;
  final String? bankAccountId;
  final String? bankAccountDisplay; // "은행명 계좌번호" for chat message
  final String? message;

  const ProposalResult({
    required this.templateIds,
    this.bankAccountId,
    this.bankAccountDisplay,
    this.message,
  });
}

/// Bottom sheet for teacher to select subscription templates and send proposal.
///
/// Uses existing SelectableTemplateCard and BankAccount from teacher profile.
Future<ProposalResult?> showProposalBottomSheet(
  BuildContext context, {
  required String teacherId,
}) {
  return showModalBottomSheet<ProposalResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _ProposalSheet(teacherId: teacherId),
  );
}

class _ProposalSheet extends ConsumerStatefulWidget {
  final String teacherId;

  const _ProposalSheet({required this.teacherId});

  @override
  ConsumerState<_ProposalSheet> createState() => _ProposalSheetState();
}

class _ProposalSheetState extends ConsumerState<_ProposalSheet> {
  final Set<String> _selectedIds = {};
  String? _selectedBankAccountId;
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync =
        ref.watch(activeTeacherTemplatesProvider(widget.teacherId));
    final profileAsync = ref.watch(teacherExtendedProfileProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.space3),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space3),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            child: Row(
              children: [
                Text(
                  AppStrings.proposalTitle,
                  style: AppTypography.headingMedium,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  iconSize: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space2),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Template selection
                  Text(
                    AppStrings.proposalSelectTemplates,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  _buildTemplateList(templatesAsync),
                  const SizedBox(height: AppSpacing.space4),

                  // Bank account selection
                  Text(
                    AppStrings.proposalBankAccount,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  _buildBankAccountSelector(profileAsync),
                  const SizedBox(height: AppSpacing.space4),

                  // Optional message
                  Text(
                    AppStrings.paymentMessageHint,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  TextField(
                    controller: _messageController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: AppStrings.paymentMessageHint,
                      hintStyle: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiaryLight,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMedium),
                        borderSide: const BorderSide(
                            color: AppColors.borderLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMedium),
                        borderSide: const BorderSide(
                            color: AppColors.borderLight),
                      ),
                      contentPadding:
                          const EdgeInsets.all(AppSpacing.space3),
                    ),
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.space4),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: AppSpacing.buttonHeightSmall,
                    child: FilledButton(
                      onPressed:
                          _selectedIds.isNotEmpty ? _submit : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMedium),
                        ),
                      ),
                      child: Text(
                        AppStrings.proposalSend,
                        style: AppTypography.buttonSmall.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateList(
    AsyncValue<List<SubscriptionTemplate>> templatesAsync,
  ) {
    return templatesAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.space4),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, __) => Text(
        AppStrings.requestLoadError,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textTertiaryLight,
        ),
      ),
      data: (templates) {
        if (templates.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.space4),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius:
                  BorderRadius.circular(AppSpacing.radiusMedium),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Center(
              child: Text(
                AppStrings.proposalNoTemplates,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiaryLight,
                ),
              ),
            ),
          );
        }

        final atMax =
            _selectedIds.length >= kMaxTemplateSelections;

        return Column(
          children: [
            for (final template in templates) ...[
              SelectableTemplateCard(
                template: template,
                isSelected: _selectedIds.contains(template.id),
                isDisabled: atMax &&
                    !_selectedIds.contains(template.id),
                onTap: () => _toggleTemplate(template.id),
              ),
              const SizedBox(height: AppSpacing.space2),
            ],
          ],
        );
      },
    );
  }

  Widget _buildBankAccountSelector(
    AsyncValue<TeacherProfile?> profileAsync,
  ) {
    return profileAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();

        final accounts = profile.bankAccounts;
        if (accounts.isEmpty && profile.bankAccount == null) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius:
                  BorderRadius.circular(AppSpacing.radiusMedium),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Text(
              AppStrings.proposalNoBankAccount,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiaryLight,
              ),
            ),
          );
        }

        // Build list of all available accounts
        final allAccounts = <BankAccount>[
          ...accounts,
          if (profile.bankAccount != null &&
              !accounts.any(
                  (a) => a.accountNumber ==
                      profile.bankAccount!.accountNumber))
            profile.bankAccount!,
        ];

        // Auto-select default
        _selectedBankAccountId ??=
            profile.defaultBankAccount?.id ?? allAccounts.first.id;

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space3,
            vertical: AppSpacing.space1,
          ),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(AppSpacing.radiusMedium),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: DropdownButton<String>(
            value: _selectedBankAccountId,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            style: AppTypography.bodySmall,
            items: allAccounts.map((account) {
              final isDefault = account.isDefault;
              return DropdownMenuItem(
                value: account.id,
                child: Text(
                  '${account.bankName} ${account.accountNumber}'
                  '${isDefault ? ' (기본)' : ''}',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: isDefault
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedBankAccountId = value);
            },
          ),
        );
      },
    );
  }

  void _toggleTemplate(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else if (_selectedIds.length < kMaxTemplateSelections) {
        _selectedIds.add(id);
      }
    });
  }

  void _submit() {
    // Get bank account display for chat message
    final profile = ref.read(teacherExtendedProfileProvider).valueOrNull;
    String? bankDisplay;
    if (profile != null && _selectedBankAccountId != null) {
      final allAccounts = [
        ...profile.bankAccounts,
        if (profile.bankAccount != null) profile.bankAccount!,
      ];
      final selected = allAccounts
          .where((a) => a.id == _selectedBankAccountId)
          .firstOrNull;
      if (selected != null) {
        bankDisplay =
            '${selected.bankName} ${selected.accountNumber} ${selected.accountHolder}';
      }
    }

    Navigator.of(context).pop(ProposalResult(
      templateIds: _selectedIds.toList(),
      bankAccountId: _selectedBankAccountId,
      bankAccountDisplay: bankDisplay,
      message: _messageController.text.isEmpty
          ? null
          : _messageController.text,
    ));
  }
}
