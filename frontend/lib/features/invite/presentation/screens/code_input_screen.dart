import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../features/profile/domain/entities/invite.dart';
import '../../../profile/profile_facade.dart';

/// Screen for entering a 6-digit invite code
class CodeInputScreen extends ConsumerStatefulWidget {
  const CodeInputScreen({super.key, this.initialCode});

  /// Pre-filled 6-digit code from a deep link (lessonapp://invite/{code}).
  /// When valid, the field auto-fills and submission runs automatically.
  final String? initialCode;

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
    // Deep-link prefill: fill digits + auto-submit when a valid 6-digit code
    // arrives via the route's ?code= query param.
    final initial = widget.initialCode;
    if (initial != null && RegExp(r'^[0-9]{6}$').hasMatch(initial)) {
      for (int i = 0; i < 6; i++) {
        _controllers[i].text = initial[i];
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _submitCode();
      });
      return;
    }
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
    final targetRole =
        userRole == InviteUserRole.teacher
            ? AppStrings.student
            : AppStrings.teacher;

    return NotebookScreenScaffold(
      appBar: const NotebookDetailAppBar(
        title: AppStrings.inviteCodeAppBarTitle,
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
                  color: AppColors.paperAccentSoft,
                  borderRadius: BorderRadius.zero,
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
                AppStrings.inviteCodeInputPromptFormat(targetRole),
                style: NotebookTypography.appBarTitle,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.space2),

              // Subtitle
              Text(
                AppStrings.inviteCodeInputSubtitle,
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
                label: const Text(AppStrings.inviteCodePasteFromClipboard),
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
                    foregroundColor: AppColors.paper,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.space4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.paper,
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
                label: const Text(AppStrings.inviteCodeQrScan),
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
          fillColor: AppColors.paper,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: AppColors.inkQuaternary),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: AppColors.inkQuaternary),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: AppColors.paperAccent, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
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
        _errorMessage = AppStrings.inviteCodeClipboardInvalid;
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
      if (!mounted) return;

      if (invite == null) {
        setState(() {
          _errorMessage = AppStrings.inviteCodeNotFound;
        });
        return;
      }

      if (!invite.isValid) {
        setState(() {
          _errorMessage =
              invite.status == InviteStatus.expired
                  ? AppStrings.inviteCodeExpired
                  : AppStrings.inviteCodeInvalid;
        });
        return;
      }

      // Navigate to confirmation screen
      context.push(AppRoutes.inviteConfirm, extra: invite);
    } on NotFoundException {
      // Backend returns 404 for unknown/revoked codes (never null).
      if (!mounted) return;
      setState(() {
        _errorMessage = AppStrings.inviteCodeNotFound;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = AppStrings.inviteCodeLookupError;
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
