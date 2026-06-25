import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:lessonaza/core/widgets/notebook/thin_rule.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/widgets/swipe_action_tile.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../features/profile/domain/entities/teacher_profile.dart';
import '../../../../features/profile/profile_facade.dart';
import '../../domain/bank_account_defaults.dart';

/// Screen for managing multiple bank accounts (list + add + default).
class BankAccountEditScreen extends ConsumerWidget {
  const BankAccountEditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(teacherExtendedProfileProvider);
    final profile = profileState.valueOrNull;
    final accounts = profile?.bankAccounts ?? [];

    return NotebookScreenScaffold(
      appBar: NotebookDetailAppBar(
        title: AppStrings.profileBankAccountTitle,
        actions: [DetailAppBarAction.add],
        onAction: (action) {
          if (action == DetailAppBarAction.add) {
            _showAddAccountSheet(context, ref, accounts);
          }
        },
      ),
      body:
          accounts.isEmpty
              ? _buildEmptyState(context, ref)
              : _buildAccountList(context, ref, accounts),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_outlined,
            size: 64,
            color: AppColors.inkTertiary,
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            AppStrings.bankAccountNoAccount,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            AppStrings.bankAccountAddPrompt,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountList(
    BuildContext context,
    WidgetRef ref,
    List<BankAccount> accounts,
  ) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        // Info banner
        Container(
          padding: const EdgeInsets.all(AppSpacing.space3),
          decoration: BoxDecoration(
            color: AppColors.paperAccentSoft.withValues(alpha: 0.3),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: AppColors.paperAccent),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Text(
                  AppStrings.bankAccountDefaultNote,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.paperAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space4),

        // Account cards
        ...accounts.map(
          (account) => _BankAccountCard(
            account: account,
            onSetDefault:
                account.isDefault
                    ? null
                    : () => _setDefault(context, ref, accounts, account),
            onDelete:
                accounts.length > 1 && !account.isDefault
                    ? () => _deleteAccount(context, ref, accounts, account)
                    : null,
          ),
        ),

        // Bottom padding for FAB
        const SizedBox(height: 80),
      ],
    );
  }

  /// 계좌 목록 저장 — 실패 시 SnackBar (2026-06-12 silent fail 방지).
  ///
  /// notifier 가 rethrow 하는 예외를 화면에서 잡지 않으면 uncaught 로
  /// 사라져 사용자에겐 "무반응" 으로 보인다 (#701 운영시간과 동일 패턴).
  Future<void> _saveAccounts(
    BuildContext context,
    WidgetRef ref,
    List<BankAccount> updated,
  ) async {
    try {
      final normalized = normalizeBankAccountDefaults(updated);
      await ref
          .read(teacherExtendedProfileProvider.notifier)
          .updateBankAccounts(normalized);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.profileBankAccountSaveError),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _setDefault(
    BuildContext context,
    WidgetRef ref,
    List<BankAccount> accounts,
    BankAccount target,
  ) async {
    final updated =
        accounts.map((a) {
          return a.copyWith(isDefault: a.id == target.id);
        }).toList();

    await _saveAccounts(context, ref, updated);
  }

  Future<void> _deleteAccount(
    BuildContext context,
    WidgetRef ref,
    List<BankAccount> accounts,
    BankAccount target,
  ) async {
    final confirmed = await showNotebookDialog<bool>(
      context: context,
      title: AppStrings.swipeActionDeleteBankAccountConfirmTitle,
      content: Text(
        '${target.bankName} ${target.accountNumber}\n${AppStrings.swipeActionDeleteBankAccountConfirmBody}',
      ),
      confirmLabel: AppStrings.delete,
      cancelLabel: AppStrings.cancel,
      isDestructive: true,
      onConfirm: () => Navigator.pop(context, true),
      onCancel: () => Navigator.pop(context, false),
    );

    if (confirmed == true) {
      final updated = accounts.where((a) => a.id != target.id).toList();
      if (!context.mounted) return;
      await _saveAccounts(context, ref, updated);
    }
  }

  Future<void> _showAddAccountSheet(
    BuildContext context,
    WidgetRef ref,
    List<BankAccount> existingAccounts,
  ) async {
    final result = await showNotebookModalBottomSheet<BankAccount>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder:
          (context) =>
              _AddBankAccountSheet(isFirstAccount: existingAccounts.isEmpty),
    );

    if (result != null) {
      final updated = [
        ...existingAccounts.map((a) {
          // If new account is default, unset others
          if (result.isDefault) return a.copyWith(isDefault: false);
          return a;
        }),
        result,
      ];
      if (!context.mounted) return;
      await _saveAccounts(context, ref, updated);
    }
  }
}

class _BankAccountCard extends StatelessWidget {
  final BankAccount account;
  final VoidCallback? onSetDefault;
  final VoidCallback? onDelete;

  const _BankAccountCard({
    required this.account,
    this.onSetDefault,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final card = NotebookCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      shape: RoundedRectangleBorder(
        side:
            account.isDefault
                ? BorderSide(color: AppColors.paperAccent, width: 1.5)
                : BorderSide(color: AppColors.inkQuaternary),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance,
                  size: 20,
                  color:
                      account.isDefault
                          ? AppColors.paperAccent
                          : AppColors.inkSecondary,
                ),
                const SizedBox(width: AppSpacing.space2),
                Text(
                  account.bankName,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (account.isDefault) ...[
                  const SizedBox(width: AppSpacing.space2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.paperAccentSoft,
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Text(
                      AppStrings.bankAccountDefaultBadge,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.paperAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              account.accountNumber,
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.space1),
            Text(
              account.accountHolder,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            if (onSetDefault != null) ...[
              const SizedBox(height: AppSpacing.space3),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onSetDefault,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.paperAccent,
                    side: BorderSide(color: AppColors.paperAccent),
                  ),
                  child: const Text(AppStrings.profileBankAccountSetDefault),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (onDelete == null) return card;

    return SwipeActionTile(
      actions: [
        SwipeAction(
          label: AppStrings.delete,
          icon: Icons.delete_outline,
          tone: SwipeActionTone.destructive,
          onPressed: onDelete!,
        ),
      ],
      startActions: [
        if (onSetDefault != null)
          SwipeAction(
            label: AppStrings.swipeActionSetDefault,
            icon: Icons.star_outline,
            tone: SwipeActionTone.convenience,
            onPressed: onSetDefault!,
          ),
      ],
      child: card,
    );
  }
}

class _AddBankAccountSheet extends StatefulWidget {
  final bool isFirstAccount;

  const _AddBankAccountSheet({this.isFirstAccount = false});

  @override
  State<_AddBankAccountSheet> createState() => _AddBankAccountSheetState();
}

class _AddBankAccountSheetState extends State<_AddBankAccountSheet> {
  final _formKey = GlobalKey<FormState>();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountHolderController = TextEditingController();

  // AppStrings.bankAccountDirectInput migrated to AppStrings.bankAccountDirectInput (#920)
  // AppStrings.bankNames migrated to AppStrings.bankNames (#920)

  String? _selectedDropdownValue;
  bool _consentChecked = false;

  // AppStrings.bankAccountConsentContent migrated to AppStrings.bankAccountConsentContent (#920)

  @override
  void initState() {
    super.initState();
    _bankNameController.addListener(_onBankNameChanged);
  }

  @override
  void dispose() {
    _bankNameController.removeListener(_onBankNameChanged);
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  void _onBankNameChanged() {
    final text = _bankNameController.text.trim();
    if (AppStrings.bankNames.contains(text)) {
      if (_selectedDropdownValue != text) {
        setState(() => _selectedDropdownValue = text);
      }
    } else {
      if (_selectedDropdownValue != AppStrings.bankAccountDirectInput) {
        setState(
          () =>
              _selectedDropdownValue = text.isEmpty ? null : AppStrings.bankAccountDirectInput,
        );
      }
    }
  }

  void _onDropdownChanged(String? value) {
    if (value == null) return;
    if (value == AppStrings.bankAccountDirectInput) {
      setState(() {
        _selectedDropdownValue = AppStrings.bankAccountDirectInput;
        _bankNameController.clear();
      });
      // Focus the text field for manual input
      FocusScope.of(context).nextFocus();
    } else {
      setState(() {
        _selectedDropdownValue = value;
        _bankNameController.text = value;
      });
    }
  }

  void _showConsentContent(BuildContext context) {
    showNotebookModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.5,
            maxChildSize: 0.8,
            minChildSize: 0.3,
            expand: false,
            builder:
                (context, scrollController) => Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.space4),
                      // Notebook × Score: 바텀시트 섹션 제목은 Playfair sectionTitle 로 통일 (§7.17).
                      child: Text(
                        AppStrings.bankAccountConsentSheetTitle,
                        style: NotebookTypography.sectionTitle,
                      ),
                    ),
                    const ThinRule(),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(AppSpacing.space4),
                        child: Text(
                          AppStrings.bankAccountConsentContent,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.inkSecondary,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  void _submit() {
    if (!_consentChecked || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final account = BankAccount(
      id: 'ba_${DateTime.now().millisecondsSinceEpoch}',
      bankName: _bankNameController.text.trim(),
      accountNumber: _accountNumberController.text.trim(),
      accountHolder: _accountHolderController.text.trim(),
      isDefault: widget.isFirstAccount,
      createdAt: DateTime.now(),
    );
    Navigator.pop(context, account);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.space4,
        AppSpacing.space4,
        AppSpacing.space4,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.space4,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notebook × Score: 폼 섹션 제목은 Playfair sectionTitle 로 통일 (§7.17).
            Text(
              AppStrings.profileBankAccountAddFormTitle,
              style: NotebookTypography.sectionTitle,
            ),
            const SizedBox(height: AppSpacing.space4),

            // Consent checkbox
            Container(
              padding: const EdgeInsets.all(AppSpacing.space3),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.zero,
                border: Border.all(
                  color:
                      _consentChecked
                          ? AppColors.paperAccent
                          : AppColors.inkQuaternary,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _consentChecked,
                      onChanged:
                          (v) => setState(() => _consentChecked = v ?? false),
                      activeColor: AppColors.paperAccent,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: GestureDetector(
                      onTap:
                          () => setState(
                            () => _consentChecked = !_consentChecked,
                          ),
                      child: Text(
                        AppStrings.bankAccountConsentCheckboxLabel,
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(color: AppColors.paperAccentSoft),
                    child: Text(
                      AppStrings.bankAccountConsentRequired,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.paperAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  GestureDetector(
                    onTap: () => _showConsentContent(context),
                    child: Text(
                      AppStrings.bankAccountConsentViewContent,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.inkTertiary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space4),

            // Bank name (dropdown + text input)
            Text(
              AppStrings.profileBankAccountBankNameLabel,
              style: AppTypography.buttonSmall,
            ),
            const SizedBox(height: AppSpacing.space2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: dropdown select
                SizedBox(
                  width: 140,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedDropdownValue,
                    isExpanded: true,
                    decoration: InputDecoration(
                      hintText: AppStrings.profileBankAccountHintBankSelect,
                      hintStyle: AppTypography.bodySmall.copyWith(
                        color: AppColors.inkTertiary,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space3,
                        vertical: AppSpacing.space3,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: AppStrings.bankAccountDirectInput,
                        child: Text(
                          AppStrings.bankAccountDirectInput,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.inkSecondary,
                          ),
                        ),
                      ),
                      ...AppStrings.bankNames.map(
                        (name) => DropdownMenuItem(
                          value: name,
                          child: Text(name, style: AppTypography.bodySmall),
                        ),
                      ),
                    ],
                    onChanged: _onDropdownChanged,
                  ),
                ),
                const SizedBox(width: AppSpacing.space2),
                // Right: manual text input
                Expanded(
                  child: TextFormField(
                    controller: _bankNameController,
                    decoration: const InputDecoration(
                      hintText: AppStrings.profileBankAccountHintBankName,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.inkQuaternary),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return AppStrings.bankAccountValidationBank;
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space4),

            // Account number
            Text(
              AppStrings.profileBankAccountNumberLabel,
              style: AppTypography.buttonSmall,
            ),
            const SizedBox(height: AppSpacing.space2),
            TextFormField(
              controller: _accountNumberController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9\-]')),
              ],
              decoration: const InputDecoration(
                hintText: AppStrings.profileBankAccountHintNumber,
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.inkQuaternary),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AppStrings.bankAccountValidationNumber;
                }
                final digitsOnly = value.replaceAll('-', '');
                if (digitsOnly.length < 8 || digitsOnly.length > 16) {
                  return AppStrings.bankAccountValidationNumberFormat;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.space4),

            // Account holder
            Text(
              AppStrings.profileBankAccountHolderLabel,
              style: AppTypography.buttonSmall,
            ),
            const SizedBox(height: AppSpacing.space2),
            TextFormField(
              controller: _accountHolderController,
              decoration: const InputDecoration(
                hintText: AppStrings.profileBankAccountHintHolder,
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.inkQuaternary),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return AppStrings.bankAccountValidationHolder;
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.space6),

            // Submit
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _consentChecked ? _submit : null,
                child: const Text(AppStrings.add),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
