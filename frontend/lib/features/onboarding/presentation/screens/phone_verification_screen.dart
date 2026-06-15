import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_detail_app_bar.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../analytics/analytics_facade.dart'
    show AnalyticsEvents, analyticsEventLoggerProvider;
import '../../../auth/auth_facade.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../features/onboarding/onboarding_facade.dart';
import '../../domain/repositories/phone_verification_repository.dart';

/// Phone verification screen for teacher onboarding
class PhoneVerificationScreen extends ConsumerStatefulWidget {
  const PhoneVerificationScreen({super.key, this.trigger = 'quest'});

  /// #695 §5.5 — entry attribution for `phone_verification_completed`
  /// ('gate' = E3 gate modal, 'quest' = Phase C quest).
  final String trigger;

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

  /// #709: 검증 실패 사유 → 사용자 메시지 매핑 (쿨다운/시도초과/만료 구분).
  String _failureMessage(PhoneVerificationResult result) {
    switch (result.failure) {
      case PhoneVerificationFailure.cooldown:
        final seconds = result.cooldownSecondsRemaining;
        return seconds != null
            ? AppStrings.phoneOtpCooldownFormat(seconds)
            : AppStrings.phoneOtpCooldown;
      case PhoneVerificationFailure.dailyLimit:
        return AppStrings.phoneOtpDailyLimit;
      case PhoneVerificationFailure.expired:
        return AppStrings.phoneOtpExpired;
      case PhoneVerificationFailure.attemptsExceeded:
        return AppStrings.phoneOtpAttemptsExceeded;
      case PhoneVerificationFailure.invalidCode:
        final remaining = result.attemptsRemaining;
        return remaining != null
            ? AppStrings.phoneOtpInvalidFormat(remaining)
            : AppStrings.phoneOtpInvalid;
      case PhoneVerificationFailure.codeNotFound:
        return AppStrings.phoneOtpNotFound;
      case PhoneVerificationFailure.sendFailed:
        return AppStrings.phoneOtpSendFailed;
      case PhoneVerificationFailure.network:
      case null:
        return AppStrings.phoneOtpNetworkError;
    }
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

    // #709: mock 모드는 notifier 내부에서 로컬 시뮬레이션, remote 는 실 API.
    final result = await ref
        .read(teacherOnboardingNotifierProvider.notifier)
        .requestCode(phone);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.success) {
        _codeSent = true;
      } else {
        _errorMessage = _failureMessage(result);
      }
    });

    if (result.success) {
      _startTimer();
      _codeFocus.requestFocus();
    }
  }

  Future<void> _resendCode() async {
    if (_remainingSeconds > 120) return; // Can resend after 1 minute

    setState(() => _isLoading = true);

    final result =
        await ref
            .read(teacherOnboardingNotifierProvider.notifier)
            .resendVerificationCode();

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.success) {
        _startTimer();
        _codeController.clear();
      } else {
        _errorMessage = _failureMessage(result);
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

    // #709: remote 모드는 서버 검증 결과만 신뢰 (로컬 코드 비교 없음).
    final result = await ref
        .read(teacherOnboardingNotifierProvider.notifier)
        .verifyCode(code);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      if (mounted) {
        // #695 §5.5 — verification completed (gate/quest attribution).
        ref.read(analyticsEventLoggerProvider).log(
          AnalyticsEvents.phoneVerificationCompleted,
          {
            'userId': ref.read(currentUserIdProvider),
            'trigger': widget.trigger,
          },
        );
        // Phone verified → complete onboarding → home
        ref
            .read(teacherOnboardingNotifierProvider.notifier)
            .completeOnboarding();
        await ref.read(authNotifierProvider.notifier).completeOnboarding();
        // Re-check mounted after the async gap before touching context.
        if (!mounted) return;
        context.go(AppRoutes.home);
      }
    } else {
      setState(() => _errorMessage = _failureMessage(result));
    }
  }

  void _handleBack() {
    // Navigate back to profile setup
    GoRouter.of(context).go(AppRoutes.teacherProfileSetup);
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
      child: NotebookScreenScaffold(
        appBar: NotebookDetailAppBar(
          title: AppStrings.onboardingPhoneVerification,
          onLeadingTap: _handleBack,
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
                      foregroundColor: AppColors.paper,
                      shape: RoundedRectangleBorder(),
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.paper,
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
        _ProgressStep(
          step: 1,
          label: AppStrings.onboardingPhoneVerification,
          isActive: true,
        ),
        _ProgressDivider(isActive: false),
        _ProgressStep(
          step: 2,
          label: AppStrings.onboardingProfileSetup,
          isActive: false,
        ),
        _ProgressDivider(isActive: false),
        _ProgressStep(
          step: 3,
          label: AppStrings.onboardingTutorial,
          isActive: false,
        ),
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
            border: OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.inkQuaternary),
            ),
            focusedBorder: OutlineInputBorder(
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
            border: OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.inkQuaternary),
            ),
            focusedBorder: OutlineInputBorder(
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
              borderRadius: BorderRadius.zero,
            ),
            child: Center(
              child: Text(
                '$step',
                style: AppTypography.bodySmall.copyWith(
                  color: isActive ? AppColors.paper : AppColors.inkTertiary,
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
