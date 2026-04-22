import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/profile/domain/entities/invite.dart';
import '../../../../features/profile/presentation/providers/invite_provider.dart';

/// QR code type
enum _QrType { invite, academy }

/// Parsed QR result
class _ParsedQr {
  final _QrType type;
  final String value;

  const _ParsedQr(this.type, this.value);
}

/// Screen for scanning QR codes to connect with teachers/students
class ScanInviteScreen extends ConsumerStatefulWidget {
  const ScanInviteScreen({super.key});

  @override
  ConsumerState<ScanInviteScreen> createState() => _ScanInviteScreenState();
}

class _ScanInviteScreenState extends ConsumerState<ScanInviteScreen> {
  late MobileScannerController _scannerController;
  bool _isProcessing = false;
  bool _torchEnabled = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userRole = ref.watch(currentInviteUserRoleProvider);
    final targetRole = userRole == InviteUserRole.teacher ? '학생' : '선생님';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text('$targetRole QR 스캔'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(_torchEnabled ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleTorch,
            tooltip: '플래시',
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: _switchCamera,
            tooltip: '카메라 전환',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),

          // Overlay with scan guide
          _buildScanOverlay(targetRole),

          // Processing indicator
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay(String targetRole) {
    return SafeArea(
      child: Column(
        children: [
          const Spacer(),

          // Scan frame
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  // Corner decorations
                  Positioned(
                    top: 0,
                    left: 0,
                    child: _buildCorner(true, true),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: _buildCorner(true, false),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: _buildCorner(false, true),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: _buildCorner(false, false),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.space6),

          // Instructions
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.space6),
            padding: const EdgeInsets.all(AppSpacing.space4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Column(
              children: [
                Text(
                  '$targetRole의 QR 코드를 스캔하세요',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  'QR 코드가 프레임 안에 들어오도록 해주세요',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const Spacer(),

          // Alternative option
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: TextButton.icon(
              onPressed: () {
                context.pop();
                context.push(AppRoutes.inviteCode);
              },
              icon: const Icon(Icons.dialpad, color: Colors.white),
              label: Text(
                '코드로 입력하기',
                style: AppTypography.bodyMedium.copyWith(color: Colors.white),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.space4),
        ],
      ),
    );
  }

  Widget _buildCorner(bool isTop, bool isLeft) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? BorderSide(color: AppColors.primary, width: 4)
              : BorderSide.none,
          bottom: !isTop
              ? BorderSide(color: AppColors.primary, width: 4)
              : BorderSide.none,
          left: isLeft
              ? BorderSide(color: AppColors.primary, width: 4)
              : BorderSide.none,
          right: !isLeft
              ? BorderSide(color: AppColors.primary, width: 4)
              : BorderSide.none,
        ),
      ),
    );
  }

  void _toggleTorch() async {
    await _scannerController.toggleTorch();
    setState(() {
      _torchEnabled = !_torchEnabled;
    });
  }

  void _switchCamera() async {
    await _scannerController.switchCamera();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    final rawValue = barcode.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      // Parse the QR code data
      final parsed = _parseQrCode(rawValue);

      if (parsed != null) {
        if (parsed.type == _QrType.academy) {
          // Navigate to academy detail screen
          if (mounted) {
            context.push(AppRoutes.academyDetail.replaceFirst(':id', parsed.value));
          }
        } else if (parsed.type == _QrType.invite) {
          // Look up the invite
          final invite =
              await ref.read(inviteByCodeProvider(parsed.value).future);

          if (invite != null && invite.isValid) {
            if (mounted) {
              // Navigate to confirmation screen
              context.push(AppRoutes.inviteConfirm, extra: invite);
            }
          } else {
            _showError('유효하지 않은 초대 코드입니다');
          }
        }
      } else {
        _showError('올바른 QR 코드가 아닙니다');
      }
    } catch (e) {
      _showError('QR 코드 처리 중 오류가 발생했습니다');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  _ParsedQr? _parseQrCode(String rawValue) {
    final uri = Uri.tryParse(rawValue);
    if (uri != null && uri.scheme == 'lessonapp') {
      // lessonapp://academy/{academyId}
      if (uri.host == 'academy' && uri.pathSegments.isNotEmpty) {
        return _ParsedQr(_QrType.academy, uri.pathSegments.first);
      }
      // lessonapp://invite/{code}
      if (uri.host == 'invite' && uri.pathSegments.isNotEmpty) {
        return _ParsedQr(_QrType.invite, uri.pathSegments.first);
      }
    }

    // If it's just a 6-digit code (invite code)
    if (RegExp(r'^\d{6}$').hasMatch(rawValue)) {
      return _ParsedQr(_QrType.invite, rawValue);
    }

    return null;
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.paperAccent,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
