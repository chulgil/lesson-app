import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../profile/domain/entities/teacher_profile.dart';
import '../../../profile/presentation/providers/teacher_extended_profile_provider.dart';
import '../../../subscription/domain/entities/subscription_template.dart';
import '../../../subscription/presentation/providers/subscription_template_providers.dart';
import '../../../subscription/presentation/widgets/selectable_template_card.dart';

/// Payment method for subscription issuance.
enum PaymentMethod { prepaid, postpaid, free }

/// Result from the unified proposal bottom sheet.
class ProposalResult {
  final PaymentMethod paymentMethod;
  final List<String> templateIds;
  final String? bankAccountId;
  final String? bankAccountDisplay;
  final String? message;

  const ProposalResult({
    required this.paymentMethod,
    required this.templateIds,
    this.bankAccountId,
    this.bankAccountDisplay,
    this.message,
  });
}

/// Unified bottom sheet for subscription issuance.
///
/// Combines payment method selection, template selection, and bank account
/// into a single flow. Bank account is only shown for prepaid method.
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
  PaymentMethod _paymentMethod = PaymentMethod.prepaid;
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
    final templatesAsync = ref.watch(
      activeTeacherTemplatesProvider(widget.teacherId),
    );
    final profileAsync = ref.watch(teacherExtendedProfileProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.paper,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.space3),
            child: Center(child: BottomSheetHandle(margin: EdgeInsets.zero)),
          ),
          const SizedBox(height: AppSpacing.space3),

          // Title + close
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            child: Row(
              children: [
                // Notebook × Score: 바텀시트 헤더 (§7.27) — Playfair sectionTitle.
                Text(
                  AppStrings.proposalTitle,
                  style: NotebookTypography.sectionTitle,
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
                  // 1. Payment method selection
                  _buildSectionLabel(AppStrings.proposalPaymentMethod),
                  const SizedBox(height: AppSpacing.space2),
                  _buildPaymentMethodSelector(),
                  const SizedBox(height: AppSpacing.space4),

                  // 2. Template selection
                  _buildSectionLabel(AppStrings.proposalSelectTemplates),
                  const SizedBox(height: AppSpacing.space2),
                  _buildTemplateList(templatesAsync),
                  const SizedBox(height: AppSpacing.space4),

                  // 3. Bank account (prepaid only)
                  if (_paymentMethod == PaymentMethod.prepaid) ...[
                    _buildSectionLabel(AppStrings.proposalBankAccount),
                    const SizedBox(height: AppSpacing.space2),
                    _buildBankAccountSelector(profileAsync),
                    const SizedBox(height: AppSpacing.space4),
                  ],

                  // 4. Optional message
                  _buildSectionLabel(AppStrings.paymentMessageHint),
                  const SizedBox(height: AppSpacing.space1),
                  TextField(
                    controller: _messageController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: AppStrings.paymentMessageHint,
                      hintStyle: AppTypography.bodySmall.copyWith(
                        color: AppColors.inkTertiary,
                      ),
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: AppColors.inkQuaternary,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: AppColors.inkQuaternary,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(AppSpacing.space3),
                    ),
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.space4),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: AppSpacing.buttonHeightSmall,
                    child: FilledButton(
                      onPressed: _selectedIds.isNotEmpty ? _submit : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.paperAccent,
                        shape: RoundedRectangleBorder(
                        ),
                      ),
                      child: Text(
                        _submitLabel,
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

  String get _submitLabel {
    return switch (_paymentMethod) {
      PaymentMethod.prepaid => AppStrings.actionSendPaymentGuide,
      PaymentMethod.postpaid => AppStrings.actionIssuePostpaid,
      PaymentMethod.free => AppStrings.actionIssueFree,
    };
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: AppTypography.bodySmall.copyWith(
        color: AppColors.inkSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // ── Payment Method Selector ────────────────────────────────

  Widget _buildPaymentMethodSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Row(
        children: [
          _buildMethodChip(
            label: AppStrings.methodPrepaidChip,
            method: PaymentMethod.prepaid,
          ),
          _buildMethodChip(
            label: AppStrings.methodPostpaidChip,
            method: PaymentMethod.postpaid,
          ),
          _buildMethodChip(
            label: AppStrings.methodFreeChip,
            method: PaymentMethod.free,
          ),
        ],
      ),
    );
  }

  Widget _buildMethodChip({
    required String label,
    required PaymentMethod method,
  }) {
    final isSelected = _paymentMethod == method;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _paymentMethod = method),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.paperAccent : Colors.transparent,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: isSelected ? Colors.white : AppColors.inkSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  // ── Template List ──────────────────────────────────────────

  Widget _buildTemplateList(
    AsyncValue<List<SubscriptionTemplate>> templatesAsync,
  ) {
    return templatesAsync.when(
      loading:
          () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.space4),
              child: CircularProgressIndicator(),
            ),
          ),
      error:
          (_, __) => Text(
            AppStrings.requestLoadError,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkTertiary,
            ),
          ),
      data: (templates) {
        if (templates.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.space4),
            decoration: BoxDecoration(
              color: AppColors.paperDark,
              border: Border.all(color: AppColors.inkQuaternary),
            ),
            child: Center(
              child: Text(
                AppStrings.proposalNoTemplates,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkTertiary,
                ),
              ),
            ),
          );
        }

        final atMax = _selectedIds.length >= kMaxTemplateSelections;

        return Column(
          children: [
            for (final template in templates) ...[
              SelectableTemplateCard(
                template: template,
                isSelected: _selectedIds.contains(template.id),
                isDisabled: atMax && !_selectedIds.contains(template.id),
                onTap: () => _toggleTemplate(template.id),
              ),
              const SizedBox(height: AppSpacing.space2),
            ],
          ],
        );
      },
    );
  }

  // ── Bank Account Selector ──────────────────────────────────

  Widget _buildBankAccountSelector(AsyncValue<TeacherProfile?> profileAsync) {
    final profile = profileAsync.valueOrNull;
    if (profile == null) return const SizedBox.shrink();

    final accounts = profile.bankAccounts;
    if (accounts.isEmpty && profile.bankAccount == null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.space3),
        decoration: BoxDecoration(
          color: AppColors.paperDark,
          border: Border.all(color: AppColors.inkQuaternary),
        ),
        child: Text(
          AppStrings.proposalNoBankAccount,
          style: AppTypography.bodySmall.copyWith(color: AppColors.inkTertiary),
        ),
      );
    }

    // Build list of all available accounts
    final allAccounts = <BankAccount>[
      ...accounts,
      if (profile.bankAccount != null &&
          !accounts.any(
            (a) => a.accountNumber == profile.bankAccount!.accountNumber,
          ))
        profile.bankAccount!,
    ];

    // Auto-select default
    _selectedBankAccountId ??=
        profile.defaultBankAccount?.id ?? allAccounts.first.id;

    // Validate selected ID still exists in accounts
    if (!allAccounts.any((a) => a.id == _selectedBankAccountId)) {
      _selectedBankAccountId =
          profile.defaultBankAccount?.id ?? allAccounts.first.id;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: DropdownButton<String>(
        value: _selectedBankAccountId,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        style: AppTypography.bodySmall.copyWith(color: AppColors.ink),
        selectedItemBuilder: (context) {
          return allAccounts.map((account) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${account.bankName} ${account.accountNumber}'
                '${account.isDefault ? ' (기본)' : ''}',
                style: AppTypography.bodySmall.copyWith(color: AppColors.ink),
              ),
            );
          }).toList();
        },
        items:
            allAccounts.map((account) {
              final isDefault = account.isDefault;
              return DropdownMenuItem(
                value: account.id,
                child: Text(
                  '${account.bankName} ${account.accountNumber}'
                  '${isDefault ? ' (기본)' : ''}',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: isDefault ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
        onChanged: (value) {
          setState(() => _selectedBankAccountId = value);
        },
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────

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
    String? bankDisplay;
    if (_paymentMethod == PaymentMethod.prepaid &&
        _selectedBankAccountId != null) {
      final profile = ref.read(teacherExtendedProfileProvider).valueOrNull;
      if (profile != null) {
        final allAccounts = [
          ...profile.bankAccounts,
          if (profile.bankAccount != null) profile.bankAccount!,
        ];
        final selected =
            allAccounts
                .where((a) => a.id == _selectedBankAccountId)
                .firstOrNull;
        if (selected != null) {
          bankDisplay =
              '${selected.bankName} ${selected.accountNumber} ${selected.accountHolder}';
        }
      }
    }

    Navigator.of(context).pop(
      ProposalResult(
        paymentMethod: _paymentMethod,
        templateIds: _selectedIds.toList(),
        bankAccountId:
            _paymentMethod == PaymentMethod.prepaid
                ? _selectedBankAccountId
                : null,
        bankAccountDisplay:
            _paymentMethod == PaymentMethod.prepaid ? bankDisplay : null,
        message:
            _messageController.text.isEmpty ? null : _messageController.text,
      ),
    );
  }
}
