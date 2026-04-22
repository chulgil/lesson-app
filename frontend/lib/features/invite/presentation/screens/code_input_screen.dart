import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../features/profile/domain/entities/invite.dart';
import '../../../../features/profile/presentation/providers/invite_provider.dart';

/// Screen for entering a 6-digit invite code
class CodeInputScreen extends ConsumerStatefulWidget {
  const CodeInputScreen({super.key});

  @override
  ConsumerState<CodeInputScreen> createState() => _CodeInputScreenState();
}

class _CodeInputScreenState extends ConsumerState<CodeInputScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Auto-focus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  bool get _isCodeComplete => _code.length == 6;

  @override
  Widget build(BuildContext context) {
    final userRole = ref.watch(currentInviteUserRoleProvider);
    final targetRole = userRole == InviteUserRole.teacher ? '학생' : '선생님';

    return Scaffold(
      backgroundColor: AppColors.paperDark,
      appBar: AppBar(
        title: const Text('초대 코드 입력'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.paperAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.dialpad,
                  size: 40,
                  color: AppColors.paperAccent,
                ),
              ),

              const SizedBox(height: AppSpacing.space6),

              // Title
              // Notebook × Score: 초대 코드 입력 제목도 Playfair appBarTitle 로 통일 (§7.27 패턴).
              Text(
                '$targetRole의 초대 코드를 입력하세요',
                style: NotebookTypography.appBarTitle,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.space2),

              // Subtitle
              Text(
                '6자리 숫자 코드를 입력해주세요',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.space8),

              // Code input fields
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) => _buildDigitField(index)),
              ),

              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpacing.space4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 16,
                      color: AppColors.paperAccent,
                    ),
                    const SizedBox(width: AppSpacing.space1),
                    Text(
                      _errorMessage!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.paperAccent,
                      ),
                    ),
                  ],
                ),
              ],

              const Spacer(),

              // Paste button
              TextButton.icon(
                onPressed: _pasteFromClipboard,
                icon: const Icon(Icons.paste),
                label: const Text('클립보드에서 붙여넣기'),
              ),

              const SizedBox(height: AppSpacing.space4),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      _isCodeComplete && !_isLoading ? _submitCode : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.paperAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.space4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusMedium,
                      ),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text(AppStrings.confirm),
                ),
              ),

              const SizedBox(height: AppSpacing.space4),

              // QR scan alternative
              TextButton.icon(
                onPressed: () {
                  context.pop();
                  context.push(AppRoutes.inviteScan);
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('QR 코드 스캔하기'),
              ),

              const SizedBox(height: AppSpacing.space4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDigitField(int index) {
    return Container(
      width: 48,
      height: 56,
      margin: EdgeInsets.symmetric(
        horizontal: index == 2 || index == 3 ? 8 : 4,
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: AppTypography.headingMedium.copyWith(
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            borderSide: BorderSide(color: AppColors.inkQuaternary),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            borderSide: BorderSide(color: AppColors.inkQuaternary),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            borderSide: BorderSide(color: AppColors.paperAccent, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            borderSide: BorderSide(color: AppColors.paperAccent),
          ),
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) {
          setState(() {
            _errorMessage = null;
          });

          if (value.isNotEmpty && index < 5) {
            // Move to next field
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            // Move to previous field on delete
            _focusNodes[index - 1].requestFocus();
          }

          // Auto-submit when all digits entered
          if (_isCodeComplete) {
            _submitCode();
          }
        },
        onTap: () {
          // Select all text when tapped
          _controllers[index].selection = TextSelection(
            baseOffset: 0,
            extentOffset: _controllers[index].text.length,
          );
        },
      ),
    );
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null) return;

    final text = data!.text!.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.length < 6) {
      setState(() {
        _errorMessage = '클립보드에 유효한 코드가 없습니다';
      });
      return;
    }

    // Fill in the digits
    for (int i = 0; i < 6; i++) {
      _controllers[i].text = text[i];
    }

    setState(() {
      _errorMessage = null;
    });

    // Auto-submit
    _submitCode();
  }

  Future<void> _submitCode() async {
    if (!_isCodeComplete || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final code = _code;
      final invite = await ref.read(inviteByCodeProvider(code).future);

      if (invite == null) {
        setState(() {
          _errorMessage = '초대 코드를 찾을 수 없습니다';
        });
        return;
      }

      if (!invite.isValid) {
        setState(() {
          _errorMessage =
              invite.status == InviteStatus.expired
                  ? '만료된 초대 코드입니다'
                  : '유효하지 않은 초대 코드입니다';
        });
        return;
      }

      if (mounted) {
        // Navigate to confirmation screen
        context.push(AppRoutes.inviteConfirm, extra: invite);
      }
    } catch (e) {
      setState(() {
        _errorMessage = '코드 확인 중 오류가 발생했습니다';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
