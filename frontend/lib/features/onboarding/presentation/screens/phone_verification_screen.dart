import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../features/onboarding/presentation/providers/onboarding_providers.dart';

/// Phone verification screen for teacher onboarding
class PhoneVerificationScreen extends ConsumerStatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  ConsumerState<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState
    extends ConsumerState<PhoneVerificationScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _phoneFocus = FocusNode();
  final _codeFocus = FocusNode();

  Timer? _timer;
  int _remainingSeconds = 0;
  bool _codeSent = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _phoneFocus.dispose();
    _codeFocus.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _remainingSeconds = 180; // 3 minutes
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  String _formatTime(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  String _formatPhoneNumber(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length <= 3) return digits;
    if (digits.length <= 7) {
      return '${digits.substring(0, 3)}-${digits.substring(3)}';
    }
    if (digits.length <= 11) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7)}';
    }
    return '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7, 11)}';
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.replaceAll('-', '').replaceAll(' ', '');
    if (phone.length < 10) {
      setState(() => _errorMessage = '올바른 휴대폰 번호를 입력해주세요');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    ref
        .read(teacherOnboardingNotifierProvider.notifier)
        .startPhoneVerification(phone);

    setState(() {
      _isLoading = false;
      _codeSent = true;
    });

    _startTimer();
    _codeFocus.requestFocus();
  }

  Future<void> _resendCode() async {
    if (_remainingSeconds > 120) return; // Can resend after 1 minute

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));

    final success =
        ref
            .read(teacherOnboardingNotifierProvider.notifier)
            .resendVerificationCode();

    setState(() {
      _isLoading = false;
      if (success) {
        _startTimer();
        _codeController.clear();
      } else {
        _errorMessage = '인증번호 재발송에 실패했습니다';
      }
    });
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text;
    if (code.length != 6) {
      setState(() => _errorMessage = '6자리 인증번호를 입력해주세요');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await Future.delayed(const Duration(seconds: 1));

    final success = ref
        .read(teacherOnboardingNotifierProvider.notifier)
        .verifyCode(code);

    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        context.go(AppRoutes.teacherProfileSetup);
      }
    } else {
      final onboarding = ref.read(teacherOnboardingNotifierProvider);
      if (onboarding.phoneVerification?.isMaxAttemptsReached ?? false) {
        setState(() => _errorMessage = '인증 시도 횟수를 초과했습니다');
      } else {
        setState(() => _errorMessage = '인증번호가 일치하지 않습니다');
      }
    }
  }

  void _handleBack() {
    // Navigate back to login screen
    GoRouter.of(context).go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('휴대폰 인증'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBack,
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.space4),

                // Progress indicator
                _buildProgressIndicator(),

                const SizedBox(height: AppSpacing.space6),

                // Notebook × Score: 스텝 타이틀 Playfair sectionTitle (§7.87-h).
                Text(
                  _codeSent ? '인증번호 입력' : '휴대폰 인증',
                  style: NotebookTypography.sectionTitle,
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  _codeSent
                      ? '${_phoneController.text}로 전송된\n인증번호 6자리를 입력해주세요'
                      : '레슨 관리와 학생 초대를 위해\n휴대폰 인증이 필요합니다',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),

                const SizedBox(height: AppSpacing.space6),

                // Phone input or Code input
                if (!_codeSent) _buildPhoneInput() else _buildCodeInput(),

                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    _errorMessage!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.paperAccent,
                    ),
                  ),
                ],

                const Spacer(),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: AppSpacing.buttonHeight,
                  child: ElevatedButton(
                    onPressed:
                        _isLoading
                            ? null
                            : (_codeSent ? _verifyCode : _sendCode),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.paperAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLarge,
                        ),
                      ),
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : Text(
                              _codeSent ? '인증 완료' : '인증번호 받기',
                              style: AppTypography.button,
                            ),
                  ),
                ),

                const SizedBox(height: AppSpacing.space4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: [
        _ProgressStep(step: 1, label: '휴대폰 인증', isActive: true),
        _ProgressDivider(isActive: false),
        _ProgressStep(step: 2, label: '프로필 설정', isActive: false),
        _ProgressDivider(isActive: false),
        _ProgressStep(step: 3, label: '튜토리얼', isActive: false),
      ],
    );
  }

  Widget _buildPhoneInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '휴대폰 번호',
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.space2),
        TextField(
          controller: _phoneController,
          focusNode: _phoneFocus,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
          onChanged: (value) {
            final formatted = _formatPhoneNumber(value);
            if (formatted != value) {
              _phoneController.value = TextEditingValue(
                text: formatted,
                selection: TextSelection.collapsed(offset: formatted.length),
              );
            }
          },
          decoration: InputDecoration(
            hintText: '010-0000-0000',
            prefixIcon: const Icon(Icons.phone_android),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              borderSide: BorderSide(color: AppColors.inkQuaternary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              borderSide: BorderSide(color: AppColors.paperAccent, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '인증번호',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_remainingSeconds > 0)
              Text(
                _formatTime(_remainingSeconds),
                style: AppTypography.bodyMedium.copyWith(
                  color:
                      _remainingSeconds <= 30
                          ? AppColors.paperAccent
                          : AppColors.paperAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.space2),
        TextField(
          controller: _codeController,
          focusNode: _codeFocus,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          decoration: InputDecoration(
            hintText: '6자리 인증번호',
            prefixIcon: const Icon(Icons.lock_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              borderSide: BorderSide(color: AppColors.inkQuaternary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              borderSide: BorderSide(color: AppColors.paperAccent, width: 2),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space3),

        // Resend button
        Center(
          child: TextButton(
            onPressed:
                _remainingSeconds <= 120 && !_isLoading ? _resendCode : null,
            child: Text(
              '인증번호 다시 받기',
              style: AppTypography.bodyMedium.copyWith(
                color:
                    _remainingSeconds <= 120
                        ? AppColors.paperAccent
                        : AppColors.inkTertiary,
              ),
            ),
          ),
        ),

        // Change phone number
        Center(
          child: TextButton(
            onPressed: () {
              setState(() {
                _codeSent = false;
                _codeController.clear();
                _timer?.cancel();
                _remainingSeconds = 0;
              });
            },
            child: Text(
              '휴대폰 번호 변경',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkTertiary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressStep extends StatelessWidget {
  final int step;
  final String label;
  final bool isActive;

  const _ProgressStep({
    required this.step,
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isActive ? AppColors.paperAccent : AppColors.inkQuaternary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$step',
                style: AppTypography.bodySmall.copyWith(
                  color: isActive ? Colors.white : AppColors.inkTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: isActive ? AppColors.ink : AppColors.inkTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ProgressDivider extends StatelessWidget {
  final bool isActive;

  const _ProgressDivider({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 2,
      margin: const EdgeInsets.only(bottom: AppSpacing.space5),
      color: isActive ? AppColors.paperAccent : AppColors.inkQuaternary,
    );
  }
}
