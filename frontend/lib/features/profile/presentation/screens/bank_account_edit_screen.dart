import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/profile/domain/entities/teacher_profile.dart';
import '../../../../features/profile/presentation/providers/teacher_extended_profile_provider.dart';

/// Screen for editing bank account information for receiving payments.
class BankAccountEditScreen extends ConsumerStatefulWidget {
  const BankAccountEditScreen({super.key});

  @override
  ConsumerState<BankAccountEditScreen> createState() =>
      _BankAccountEditScreenState();
}

class _BankAccountEditScreenState
    extends ConsumerState<BankAccountEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountHolderController = TextEditingController();

  bool _isLoading = false;
  bool _hasExistingData = false;

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

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    final profileState = ref.read(teacherExtendedProfileProvider);
    final profile = profileState.valueOrNull;
    if (profile?.bankAccount != null) {
      final bank = profile!.bankAccount!;
      _bankNameController.text = bank.bankName;
      _accountNumberController.text = bank.accountNumber;
      _accountHolderController.text = bank.accountHolder;
      _hasExistingData = true;
    }
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final bankAccount = BankAccount(
      bankName: _bankNameController.text.trim(),
      accountNumber: _accountNumberController.text.trim(),
      accountHolder: _accountHolderController.text.trim(),
    );

    try {
      await ref
          .read(teacherExtendedProfileProvider.notifier)
          .updateBankAccount(bankAccount);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('계좌 정보가 저장되었습니다.')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장 중 오류가 발생했습니다. 다시 시도해주세요.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _selectBank() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Text(
                '은행 선택',
                style: AppTypography.headingSmall,
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _bankNames.length,
                itemBuilder: (context, index) {
                  final bankName = _bankNames[index];
                  final isSelected =
                      _bankNameController.text == bankName;
                  return ListTile(
                    title: Text(bankName),
                    trailing: isSelected
                        ? Icon(Icons.check,
                            color: AppColors.primary)
                        : null,
                    onTap: () {
                      setState(() {
                        _bankNameController.text = bankName;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(_hasExistingData ? '계좌 정보 수정' : '계좌 정보 등록'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('저장'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.space4),
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(AppSpacing.space3),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 20, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: Text(
                      '학생의 수강료 입금을 위한 계좌 정보입니다.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space6),

            // Bank name
            Text('은행명 *', style: AppTypography.buttonSmall),
            const SizedBox(height: AppSpacing.space2),
            TextFormField(
              controller: _bankNameController,
              readOnly: true,
              onTap: _selectBank,
              decoration: InputDecoration(
                hintText: '은행을 선택하세요',
                suffixIcon: const Icon(Icons.arrow_drop_down),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '은행을 선택해주세요';
                }
                return null;
              },
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
                hintText: '계좌번호를 입력하세요 (숫자만)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
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
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '예금주를 입력해주세요';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
