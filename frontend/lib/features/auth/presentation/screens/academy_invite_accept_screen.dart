import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../../core/widgets/notebook/paper_scaffold.dart';
import '../providers/academy_invite_provider.dart';

/// Academy invite accept screen — 학원 초대 수락 화면
/// 학원 정보 표시 + 이중 권한 안내 + 공개 동의
class AcademyInviteAcceptScreen extends ConsumerStatefulWidget {
  final String token;

  const AcademyInviteAcceptScreen({super.key, required this.token});

  @override
  ConsumerState<AcademyInviteAcceptScreen> createState() =>
      _AcademyInviteAcceptScreenState();
}

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
      await ref.read(academyInviteAcceptProvider(widget.token).future);
      if (mounted) {
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('수락 실패: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isAccepting = false);
      }
    }
  }

  Future<void> _handleReject() async {
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final previewAsync = ref.watch(academyInvitePreviewProvider(widget.token));

    return NotebookScreenScaffold(
      body: PaperScaffold(
        child: previewAsync.when(
          data: (preview) => _buildContent(preview),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorContent(error),
        ),
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

  Widget _buildErrorContent(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('초대 로드 실패'),
          SizedBox(height: AppSpacing.space3),
          Text(error.toString(), style: AppTypography.bodySmall),
          SizedBox(height: AppSpacing.space4),
          ElevatedButton(
            onPressed: () => context.go(AppRoutes.home),
            child: const Text('홈으로 이동'),
          ),
        ],
      ),
    );
  }
}
