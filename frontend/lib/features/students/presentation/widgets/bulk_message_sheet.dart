import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../auth/auth_facade.dart';
import '../providers/bulk_teacher_action_providers.dart';

/// §7.119 B2 일괄 메시지 바텀시트.
///
/// 선택된 학생들에게 generalAnnouncement 알림을 브로드캐스트.
class BulkMessageSheet extends ConsumerStatefulWidget {
  final List<String> studentIds;

  const BulkMessageSheet({super.key, required this.studentIds});

  static Future<bool?> show(
    BuildContext context, {
    required List<String> studentIds,
  }) {
    return showNotebookModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BulkMessageSheet(studentIds: studentIds),
    );
  }

  @override
  ConsumerState<BulkMessageSheet> createState() => _BulkMessageSheetState();
}

class _BulkMessageSheetState extends ConsumerState<BulkMessageSheet> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  bool get _canSend =>
      _titleController.text.trim().isNotEmpty &&
      _bodyController.text.trim().isNotEmpty &&
      !_submitting;

  Future<void> _send() async {
    if (!_canSend) return;
    setState(() => _submitting = true);
    final teacherId = ref.read(currentUserIdProvider);
    final service = ref.read(bulkTeacherActionServiceProvider);
    final count = await service.broadcastMessage(
      teacherId: teacherId,
      studentIds: widget.studentIds,
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$count명에게 메시지를 보냈습니다')));
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets.bottom;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.55,
      maxChildSize: 0.9,
      builder: (ctx, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
          ),
          padding: EdgeInsets.only(bottom: insets),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.inkSecondary),
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                AppStrings.studentBulkMessageTitle,
                style: AppTypography.headingSmall,
              ),
              const SizedBox(height: AppSpacing.space1),
              Text(
                '${widget.studentIds.length}명에게 알림으로 전송됩니다',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              TextField(
                controller: _titleController,
                maxLength: 40,
                decoration: const InputDecoration(
                  labelText: AppStrings.titleLabel,
                  hintText: AppStrings.studentBulkMessageTitleHint,
                  border: OutlineInputBorder(),
                ),
                enabled: !_submitting,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.space3),
              TextField(
                controller: _bodyController,
                maxLines: 5,
                maxLength: 300,
                decoration: const InputDecoration(
                  labelText: '내용',
                  hintText: AppStrings.studentBulkMessageBodyHint,
                  border: OutlineInputBorder(),
                ),
                enabled: !_submitting,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.space4),
              FilledButton(
                onPressed: _canSend ? _send : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
                ),
                child: Text(
                  _submitting
                      ? AppStrings.sendingInProgress
                      : AppStrings.studentSendMessage,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
