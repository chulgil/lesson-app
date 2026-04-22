import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/profile/domain/entities/teacher_profile.dart';
import '../../../../features/profile/presentation/providers/teacher_extended_profile_provider.dart';

/// Screen for managing multiple bank accounts (list + add + default).
class BankAccountEditScreen extends ConsumerWidget {
  const BankAccountEditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(teacherExtendedProfileProvider);
    final profile = profileState.valueOrNull;
    final accounts = profile?.bankAccounts ?? [];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('입금 계좌'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAccountSheet(context, ref, accounts),
        icon: const Icon(Icons.add),
        label: const Text('계좌 추가'),
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
            '등록된 계좌가 없습니다',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            '학생의 수강료 입금을 위한 계좌를 추가하세요.',
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
            color: AppColors.primaryLight.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Text(
                  '기본 계좌가 수강권 제안 시 학생에게 표시됩니다.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
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
                    : () => _setDefault(ref, accounts, account),
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

  Future<void> _setDefault(
    WidgetRef ref,
    List<BankAccount> accounts,
    BankAccount target,
  ) async {
    final updated =
        accounts.map((a) {
          return a.copyWith(isDefault: a.id == target.id);
        }).toList();

    await ref
        .read(teacherExtendedProfileProvider.notifier)
        .updateBankAccounts(updated);
  }

  Future<void> _deleteAccount(
    BuildContext context,
    WidgetRef ref,
    List<BankAccount> accounts,
    BankAccount target,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('계좌 삭제'),
            content: Text(
              '${target.bankName} ${target.accountNumber}을 삭제하시겠습니까?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(AppStrings.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: AppColors.paperAccent),
                child: const Text(AppStrings.delete),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final updated = accounts.where((a) => a.id != target.id).toList();
      await ref
          .read(teacherExtendedProfileProvider.notifier)
          .updateBankAccounts(updated);
    }
  }

  Future<void> _showAddAccountSheet(
    BuildContext context,
    WidgetRef ref,
    List<BankAccount> existingAccounts,
  ) async {
    final result = await showModalBottomSheet<BankAccount>(
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
      await ref
          .read(teacherExtendedProfileProvider.notifier)
          .updateBankAccounts(updated);
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
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        side:
            account.isDefault
                ? BorderSide(color: AppColors.primary, width: 1.5)
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
                          ? AppColors.primary
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
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusSmall,
                      ),
                    ),
                    child: Text(
                      '기본',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (onDelete != null)
                  IconButton(
                    onPressed: onDelete,
                    icon: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: AppColors.paperAccent,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
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
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                  ),
                  child: const Text('기본 계좌로 설정'),
                ),
              ),
            ],
          ],
        ),
      ),
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

  static const _directInputLabel = '직접입력';
  static const _bankNames = [
    '국민은행',
    '신한은행',
    '우리은행',
    '하나은행',
    '농협은행',
    'SC제일은행',
    '한국씨티은행',
    '기업은행',
    '카카오뱅크',
    '토스뱅크',
    '케이뱅크',
    '새마을금고',
    '신협',
    '우체국',
    '수협은행',
    '대구은행',
    '부산은행',
    '경남은행',
    '광주은행',
    '전북은행',
    '제주은행',
  ];

  String? _selectedDropdownValue;
  bool _consentChecked = false;

  static const _consentContent = '''
[개인정보(계좌정보) 수집·이용 동의]

1. 수집 항목
  - 은행명, 계좌번호, 예금주

2. 수집 목적
  - 수강료 입금 안내를 위해 학생에게 계좌 정보를 표시

3. 보유 기간
  - 회원탈퇴 시까지 (탈퇴 후 30일 이내 파기)
  - 계좌 변경이력: 전자상거래법에 따라 5년 보관

4. 동의 거부 시 불이익
  - 동의를 거부할 수 있으나, 계좌 등록이 불가합니다.
''';

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
    if (_bankNames.contains(text)) {
      if (_selectedDropdownValue != text) {
        setState(() => _selectedDropdownValue = text);
      }
    } else {
      if (_selectedDropdownValue != _directInputLabel) {
        setState(
          () =>
              _selectedDropdownValue = text.isEmpty ? null : _directInputLabel,
        );
      }
    }
  }

  void _onDropdownChanged(String? value) {
    if (value == null) return;
    if (value == _directInputLabel) {
      setState(() {
        _selectedDropdownValue = _directInputLabel;
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
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
                      child: Text(
                        '개인정보 수집·이용 동의',
                        style: AppTypography.headingSmall,
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(AppSpacing.space4),
                        child: Text(
                          _consentContent,
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
    if (!_consentChecked || !_formKey.currentState!.validate()) return;

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
            Text('계좌 추가', style: AppTypography.headingSmall),
            const SizedBox(height: AppSpacing.space4),

            // Consent checkbox
            Container(
              padding: const EdgeInsets.all(AppSpacing.space3),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(
                  color:
                      _consentChecked
                          ? AppColors.primary.withValues(alpha: 0.5)
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
                      activeColor: AppColors.primary,
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
                        '개인정보(계좌정보) 수집·이용 동의',
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
                    decoration: BoxDecoration(
                      color: AppColors.paperAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusSmall,
                      ),
                    ),
                    child: Text(
                      '필수',
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
                      '내용보기',
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
            Text('은행명 *', style: AppTypography.buttonSmall),
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
                      hintText: '은행 선택',
                      hintStyle: AppTypography.bodySmall.copyWith(
                        color: AppColors.inkTertiary,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space3,
                        vertical: AppSpacing.space3,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMedium,
                        ),
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: _directInputLabel,
                        child: Text(
                          _directInputLabel,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.inkSecondary,
                          ),
                        ),
                      ),
                      ..._bankNames.map(
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
                    decoration: InputDecoration(
                      hintText: '은행명 입력',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMedium,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '은행명을 입력해주세요';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space4),

            // Account number
            Text('계좌번호 *', style: AppTypography.buttonSmall),
            const SizedBox(height: AppSpacing.space2),
            TextFormField(
              controller: _accountNumberController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9\-]')),
              ],
              decoration: InputDecoration(
                hintText: '계좌번호를 입력하세요',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '계좌번호를 입력해주세요';
                }
                final digitsOnly = value.replaceAll('-', '');
                if (digitsOnly.length < 8 || digitsOnly.length > 16) {
                  return '올바른 계좌번호를 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.space4),

            // Account holder
            Text('예금주 *', style: AppTypography.buttonSmall),
            const SizedBox(height: AppSpacing.space2),
            TextFormField(
              controller: _accountHolderController,
              decoration: InputDecoration(
                hintText: '예금주명을 입력하세요',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return '예금주를 입력해주세요';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.space6),

            // Submit
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _consentChecked ? _submit : null,
                child: const Text('추가'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
