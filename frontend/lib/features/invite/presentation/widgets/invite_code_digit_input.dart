import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/profile/domain/entities/invite.dart';
import '../../../profile/profile_facade.dart';

/// Shared 6-digit invite code entry: digit boxes, paste-from-clipboard,
/// inline lookup error, and a confirm button.
///
/// Looks the code up via [inviteByCodeProvider] and reports the resolved,
/// valid [Invite] to the caller — the caller decides what happens next
/// (which confirm screen to push and with what post-connection redirect),
/// so the same input serves both the post-onboarding invite flow
/// ([CodeInputScreen]) and the onboarding invite flow
/// (`StudentInviteCodeScreen`).
class InviteCodeDigitInput extends ConsumerStatefulWidget {
  const InviteCodeDigitInput({
    super.key,
    this.initialCode,
    required this.onInviteResolved,
  });

  /// Pre-filled 6-digit code (e.g. from a deep link). When it matches the
  /// 6-digit pattern, the field prefills and auto-submits once mounted.
  final String? initialCode;

  /// Called with the resolved, valid [Invite] once the entered code passes
  /// lookup + validity checks.
  final ValueChanged<Invite> onInviteResolved;

  @override
  ConsumerState<InviteCodeDigitInput> createState() =>
      _InviteCodeDigitInputState();
}

class _InviteCodeDigitInputState extends ConsumerState<InviteCodeDigitInput> {
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
              Icon(Icons.error_outline, size: 16, color: AppColors.paperAccent),
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

        const SizedBox(height: AppSpacing.space4),

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
            onPressed: _isCodeComplete && !_isLoading ? _submitCode : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.paperAccent,
              foregroundColor: AppColors.paper,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
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
      ],
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

      widget.onInviteResolved(invite);
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
