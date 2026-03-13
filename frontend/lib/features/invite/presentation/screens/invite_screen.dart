import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart' show ShareParams, SharePlus;

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/invite.dart';
import '../../../../providers/invite/invite_provider.dart';

/// Screen for creating and sharing invites
class InviteScreen extends ConsumerStatefulWidget {
  const InviteScreen({super.key});

  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> {
  @override
  void initState() {
    super.initState();
    // Create a new invite when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _createNewInvite();
    });
  }

  Future<void> _createNewInvite() async {
    await ref.read(inviteCreatorProvider.notifier).createInvite(
          validity: const Duration(days: 7),
        );
  }

  @override
  Widget build(BuildContext context) {
    final inviteState = ref.watch(inviteCreatorProvider);
    final userRole = ref.watch(currentInviteUserRoleProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          userRole == InviteUserRole.teacher ? '학생 초대하기' : '선생님 연결하기',
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push(AppRoutes.inviteHistory),
            tooltip: '초대 내역',
          ),
        ],
      ),
      body: inviteState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildError('네트워크 연결을 확인하고 다시 시도해주세요.'),
        data: (invite) {
          if (invite == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildContent(invite, userRole);
        },
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.space4),
            Text(
              '초대 링크 생성 중 오류가 발생했습니다',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondaryLight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              error,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondaryLight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space4),
            ElevatedButton(
              onPressed: _createNewInvite,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(Invite invite, InviteUserRole userRole) {
    final targetRole =
        userRole == InviteUserRole.teacher ? '학생' : '선생님';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header message
          Container(
            padding: const EdgeInsets.all(AppSpacing.space4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Text(
                    '$targetRole에게 QR 코드를 보여주거나 링크를 공유해주세요',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.space6),

          // QR Code
          _buildQRCodeSection(invite),

          const SizedBox(height: AppSpacing.space6),

          // Invite code
          _buildInviteCodeSection(invite),

          const SizedBox(height: AppSpacing.space6),

          // Share buttons
          _buildShareButtons(invite),

          const SizedBox(height: AppSpacing.space4),

          // Expiry info
          _buildExpiryInfo(invite),

          const SizedBox(height: AppSpacing.space6),

          // Alternative options
          _buildAlternativeOptions(),
        ],
      ),
    );
  }

  Widget _buildQRCodeSection(Invite invite) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'QR 코드',
            style: AppTypography.headingSmall,
          ),
          const SizedBox(height: AppSpacing.space3),
          QrImageView(
            data: invite.qrCodeData,
            version: QrVersions.auto,
            size: 200,
            backgroundColor: Colors.white,
            eyeStyle: QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: AppColors.primary,
            ),
            dataModuleStyle: QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            '대면 수업 시 스캔하세요',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteCodeSection(Invite invite) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Text(
            '초대 코드',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                invite.inviteCode,
                style: AppTypography.headingLarge.copyWith(
                  letterSpacing: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              IconButton(
                onPressed: () => _copyCode(invite.inviteCode),
                icon: const Icon(Icons.copy),
                tooltip: '코드 복사',
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            '앱에서 직접 입력할 수 있는 코드입니다',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareButtons(Invite invite) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _shareLink(invite),
            icon: const Icon(Icons.share),
            label: const Text('링크 공유하기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space3),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _copyLink(invite.inviteUrl),
                icon: const Icon(Icons.link),
                label: const Text('링크 복사'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.space3),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMedium),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _shareToKakao(invite),
                icon: const Icon(Icons.chat_bubble),
                label: const Text('카카오톡'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimaryLight,
                  backgroundColor: AppColors.kakaoBackground,
                  side: BorderSide.none,
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.space3),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMedium),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpiryInfo(Invite invite) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.access_time, size: 16, color: AppColors.textSecondaryLight),
        const SizedBox(width: AppSpacing.space1),
        Text(
          '유효기간: ${invite.formattedExpiry}',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildAlternativeOptions() {
    final userRole = ref.watch(currentInviteUserRoleProvider);

    return Column(
      children: [
        const Divider(),
        const SizedBox(height: AppSpacing.space4),
        Text(
          '다른 방법으로 연결하기',
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.space3),
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.qr_code_scanner, color: AppColors.secondary),
          ),
          title: const Text('QR 코드 스캔'),
          subtitle: Text(
            userRole == InviteUserRole.teacher
                ? '학생의 QR 코드 스캔하기'
                : '선생님의 QR 코드 스캔하기',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(AppRoutes.inviteScan),
        ),
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.dialpad, color: AppColors.info),
          ),
          title: const Text('초대 코드 입력'),
          subtitle: const Text('6자리 코드로 연결하기'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(AppRoutes.inviteCode),
        ),
        if (userRole == InviteUserRole.student)
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.search, color: AppColors.primary),
            ),
            title: const Text('선생님 검색'),
            subtitle: const Text('앱에서 선생님 찾기'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.teacherSearch),
          ),
      ],
    );
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('초대 코드가 복사되었습니다'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _copyLink(String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('초대 링크가 복사되었습니다'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareLink(Invite invite) {
    final userRole = ref.read(currentInviteUserRoleProvider);
    final roleText = userRole == InviteUserRole.teacher ? '선생님' : '학생';

    SharePlus.instance.share(
      ShareParams(
        text: '레슨앱에서 저와 함께해요!\n\n'
            '초대 코드: ${invite.inviteCode}\n'
            '또는 링크: ${invite.inviteUrl}\n\n'
            '- $roleText 드림',
        subject: '레슨앱 초대',
      ),
    );
  }

  void _shareToKakao(Invite invite) {
    // For now, use system share which includes KakaoTalk
    // In the future, can integrate Kakao SDK for native sharing
    _shareLink(invite);
  }
}
