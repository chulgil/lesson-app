import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../../core/widgets/notebook/paper_scaffold.dart';
import '../../../../features/academy/academy_facade.dart';
import '../providers/academy_invite_provider.dart';
import 'academy_invite_expired_screen.dart';

/// Academy invite accept screen — 학원 초대 수락 화면
/// 학원 정보 표시 + 이중 권한 안내 + 공개 동의
class AcademyInviteAcceptScreen extends ConsumerStatefulWidget {
  final String token;

  const AcademyInviteAcceptScreen({super.key, required this.token});

  @override
  ConsumerState<AcademyInviteAcceptScreen> createState() =>
      _AcademyInviteAcceptScreenState();
}

/// Predefined reject reasons (G9/W4 §3.7).
const _kRejectReasons = <String>['관심 없음', '이미 다른 학원 소속', '기타'];

class _AcademyInviteAcceptScreenState
    extends ConsumerState<AcademyInviteAcceptScreen> {
  bool _publicPageConsent = false;
  bool _isAccepting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(academyInvitePreviewProvider(widget.token));
    });
  }

  Future<void> _handleAccept() async {
    setState(() => _isAccepting = true);
    try {
      final repository = ref.read(academyInviteRepositoryProvider);
      await repository.acceptInvite(
        widget.token,
        publicPageConsent: _publicPageConsent,
      );
      // Refresh cached academy providers so the home screen reflects the
      // newly joined academy without requiring a manual reload.
      ref.invalidate(teacherAcademiesProvider);
      if (mounted) {
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          const SnackBar(content: Text(AppStrings.academyInviteAcceptFailed)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAccepting = false);
      }
    }
  }

  Future<void> _handleReject() async {
    final reason = await _pickRejectReason();
    if (reason == null) {
      return;
    }
    try {
      final repository = ref.read(academyInviteRepositoryProvider);
      await repository.rejectInvite(widget.token, reason: reason);
    } catch (_) {
      // Best-effort reject; navigate home regardless.
    }
    if (mounted) {
      context.go(AppRoutes.home);
    }
  }

  Future<String?> _pickRejectReason() {
    return showNotebookBottomSheet<String>(
      context: context,
      builder: (sheetContext) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.all(AppSpacing.space3),
              child: Text('거절 사유를 선택해주세요', style: AppTypography.bodyLarge),
            ),
            for (final reason in _kRejectReasons)
              ListTile(
                title: Text(reason),
                onTap: () => Navigator.of(sheetContext).pop(reason),
              ),
            const Divider(height: 1),
            ListTile(
              title: const Text('취소'),
              onTap: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        );
      },
    );
  }

  /// Classifies a preview load error code for the expired screen.
  String _errorCodeFor(Object error) {
    final text = error.toString();
    if (text.contains('expired')) return 'expired';
    if (text.contains('not found')) return 'not_found';
    if (text.contains('invalid')) return 'already_used';
    return 'unknown';
  }

  @override
  Widget build(BuildContext context) {
    final previewAsync = ref.watch(academyInvitePreviewProvider(widget.token));

    return previewAsync.when(
      data:
          (preview) => NotebookScreenScaffold(
            body: PaperScaffold(child: _buildContent(preview)),
          ),
      loading:
          () => const NotebookScreenScaffold(
            body: PaperScaffold(
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      error:
          (error, stack) => AcademyInviteExpiredScreen(
            errorCode: _errorCodeFor(error),
            errorMessage: error.toString(),
          ),
    );
  }

  Widget _buildContent(dynamic preview) {
    final academy = preview.academy;
    final ownerName = preview.ownerName;
    final roles = preview.roles;

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('학원 초대', style: AppTypography.bodyLarge),
          SizedBox(height: AppSpacing.space3),
          Container(
            padding: EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              border: Border.all(),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(academy.name, style: AppTypography.bodyLarge),
                SizedBox(height: AppSpacing.space2),
                if (academy.address != null)
                  Text(academy.address!, style: AppTypography.bodySmall),
                SizedBox(height: AppSpacing.space2),
                Text('대표: $ownerName', style: AppTypography.bodySmall),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.space4),
          Container(
            padding: EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              border: Border.all(),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('부여될 권한', style: AppTypography.bodyMedium),
                SizedBox(height: AppSpacing.space2),
                ...roles.map(
                  (r) => Text('- $r', style: AppTypography.bodySmall),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.space4),
          Row(
            children: [
              Checkbox(
                value: _publicPageConsent,
                onChanged: (v) {
                  setState(() => _publicPageConsent = v ?? false);
                },
              ),
              Expanded(
                child: Text(
                  '학원 공개 페이지에 내 프로필 노출 허용',
                  style: AppTypography.bodySmall,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.space5),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isAccepting ? null : _handleReject,
                  child: const Text('거절'),
                ),
              ),
              SizedBox(width: AppSpacing.space3),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isAccepting ? null : _handleAccept,
                  child:
                      _isAccepting
                          ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('수락'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
