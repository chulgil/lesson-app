import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:lessonaza/core/widgets/notebook/thin_rule.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart' show ShareParams, SharePlus;

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../features/profile/domain/entities/invite.dart';
import '../../../profile/presentation/extensions/profile_domain_visuals.dart';
import '../../../profile/profile_facade.dart';

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
    await ref
        .read(inviteCreatorProvider.notifier)
        .createInvite(validity: const Duration(days: 7));
  }

  @override
  Widget build(BuildContext context) {
    final inviteState = ref.watch(inviteCreatorProvider);
    final userRole = ref.watch(currentInviteUserRoleProvider);

    return NotebookScreenScaffold(
      appBar: NotebookDetailAppBar(
        title:
            userRole == InviteUserRole.teacher
                ? AppStrings.inviteScreenTitleTeacher
                : AppStrings.inviteScreenTitleStudent,
        leading: DetailAppBarLeading.close,
        actions: const [DetailAppBarAction.history],
        onAction: (action) {
          if (action == DetailAppBarAction.history) {
            context.push(AppRoutes.inviteHistory);
          }
        },
      ),
      body: inviteState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildError(),
        data: (invite) {
          if (invite == null) {
            return _buildError();
          }
          return _buildContent(invite, userRole);
        },
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.paperAccent),
            const SizedBox(height: AppSpacing.space4),
            Text(
              AppStrings.inviteCreateErrorTitle,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              AppStrings.inviteCreateErrorSubtitle,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space4),
            ElevatedButton(
              onPressed: _createNewInvite,
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(Invite invite, InviteUserRole userRole) {
    final targetRole =
        userRole == InviteUserRole.teacher
            ? AppStrings.student
            : AppStrings.teacher;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header message
          Container(
            padding: const EdgeInsets.all(AppSpacing.space4),
            decoration: BoxDecoration(
              color: AppColors.paperAccentSoft,
              borderRadius: BorderRadius.zero,
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.paperAccent),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Text(
                    AppStrings.inviteShareGuideFormat(targetRole),
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.paperAccent,
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
        color: AppColors.paper,
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        children: [
          // Notebook × Score: QR 코드 카드 제목도 Playfair appBarTitle 로 통일 (§7.27 패턴).
          Text(
            AppStrings.qrCodeSectionTitle,
            style: NotebookTypography.appBarTitle,
          ),
          const SizedBox(height: AppSpacing.space3),
          QrImageView(
            data: invite.qrCodeData,
            version: QrVersions.auto,
            size: 200,
            backgroundColor: AppColors.paper,
            eyeStyle: QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: AppColors.paperAccent,
            ),
            dataModuleStyle: QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            AppStrings.qrCodeScanInstruction,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
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
        color: AppColors.paper,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        children: [
          Text(
            AppStrings.inviteCodeSectionTitle,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
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
                tooltip: AppStrings.inviteCodeCopyTooltip,
                color: AppColors.paperAccent,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            AppStrings.inviteCodeManualEntryHint,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
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
            label: const Text(AppStrings.inviteShareLinkButton),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.paperAccent,
              foregroundColor: AppColors.paper,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
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
                label: const Text(AppStrings.inviteCopyLinkButton),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.paperAccent,
                  side: BorderSide(color: AppColors.paperAccent),
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.space3,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _shareToKakao(invite),
                icon: const Icon(Icons.chat_bubble),
                label: const Text(AppStrings.inviteKakaoButton),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  backgroundColor: AppColors.kakaoBackground,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.space3,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
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
        Icon(Icons.access_time, size: 16, color: AppColors.inkSecondary),
        const SizedBox(width: AppSpacing.space1),
        Text(
          AppStrings.inviteExpiryFormat(invite.formattedExpiry),
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAlternativeOptions() {
    final userRole = ref.watch(currentInviteUserRoleProvider);

    return Column(
      children: [
        const ThinRule(),
        const SizedBox(height: AppSpacing.space4),
        Text(
          AppStrings.inviteAlternativeOptionsTitle,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.space3),
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(AppSpacing.space2),
            decoration: BoxDecoration(
              color: AppColors.paperAccentSoft,
              borderRadius: BorderRadius.zero,
            ),
            child: Icon(Icons.qr_code_scanner, color: AppColors.paperAccent),
          ),
          title: const Text(AppStrings.inviteScanQrTitle),
          subtitle: Text(
            userRole == InviteUserRole.teacher
                ? AppStrings.inviteScanQrTeacherSubtitle
                : AppStrings.inviteScanQrStudentSubtitle,
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(AppRoutes.inviteScan),
        ),
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(AppSpacing.space2),
            decoration: BoxDecoration(
              color: AppColors.inkSoft,
              borderRadius: BorderRadius.zero,
            ),
            child: Icon(Icons.dialpad, color: AppColors.ink),
          ),
          title: const Text(AppStrings.inviteCodeAppBarTitle),
          subtitle: const Text(AppStrings.inviteCodeInputShortSubtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(AppRoutes.inviteCode),
        ),
        if (userRole == InviteUserRole.student)
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(AppSpacing.space2),
              decoration: BoxDecoration(
                color: AppColors.paperAccentSoft,
                borderRadius: BorderRadius.zero,
              ),
              child: Icon(Icons.search, color: AppColors.paperAccent),
            ),
            title: const Text(AppStrings.inviteTeacherSearchTitle),
            subtitle: const Text(AppStrings.inviteTeacherSearchSubtitle),
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
        content: Text(AppStrings.inviteCodeCopiedSnack),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _copyLink(String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(AppStrings.inviteLinkCopiedSnack),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareLink(Invite invite) {
    final userRole = ref.read(currentInviteUserRoleProvider);
    final roleText =
        userRole == InviteUserRole.teacher
            ? AppStrings.teacher
            : AppStrings.student;

    String? senderName;
    List<String> instruments = const [];
    if (userRole == InviteUserRole.teacher) {
      final profile = ref.read(teacherExtendedProfileProvider).valueOrNull;
      if (profile != null) {
        senderName = profile.displayName;
        instruments = profile.instruments;
      }
    }

    SharePlus.instance.share(
      ShareParams(
        text: AppStrings.inviteShareMessageFormat(
          invite.inviteCode,
          invite.inviteUrl,
          roleText,
          senderName: senderName,
          instruments: instruments,
        ),
        subject: AppStrings.inviteShareSubject,
      ),
    );
  }

  void _shareToKakao(Invite invite) {
    // For now, use system share which includes KakaoTalk
    // In the future, can integrate Kakao SDK for native sharing
    _shareLink(invite);
  }
}
