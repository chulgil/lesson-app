import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../auth/auth_facade.dart' show currentUserIdProvider;
import '../../../lessons/domain/entities/entities.dart';
import '../providers/bulk_teacher_action_providers.dart';

/// §7.119 B1 휴강 공지 화면.
///
/// 플로우: 날짜 선택 → 영향받는 레슨 미리보기 → 확인 → 일괄 취소 + 알림
class BulkCancelScreen extends ConsumerStatefulWidget {
  final List<String> studentIds;

  const BulkCancelScreen({super.key, required this.studentIds});

  @override
  ConsumerState<BulkCancelScreen> createState() => _BulkCancelScreenState();
}

class _BulkCancelScreenState extends ConsumerState<BulkCancelScreen> {
  DateTime? _targetDate;
  final _reasonController = TextEditingController();
  List<Lesson> _affected = const [];
  bool _previewing = false;
  bool _submitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _targetDate = DateTime(picked.year, picked.month, picked.day);
      _previewing = true;
    });
    final service = ref.read(bulkTeacherActionServiceProvider);
    final affected = await service.previewAffectedLessons(
      studentIds: widget.studentIds,
      targetDate: _targetDate!,
    );
    if (!mounted) return;
    setState(() {
      _affected = affected;
      _previewing = false;
    });
  }

  Future<void> _confirm() async {
    final date = _targetDate;
    if (date == null || _submitting) return;
    final confirmed = await showNotebookDialog<bool>(
      context: context,
      title: AppStrings.studentBulkCancelConfirmTitle,
      content: Text(
        '${formatDateYMD(date)}\n'
        '${_affected.length}건의 레슨이 취소되고, '
        '${_affected.map((l) => l.studentId).toSet().length}명에게 알림이 발송됩니다.',
      ),
      confirmLabel: '발송',
      cancelLabel: '취소',
      confirmColor: AppColors.paperAccent,
      onConfirm: () => Navigator.pop(context, true),
      onCancel: () => Navigator.pop(context, false),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _submitting = true);
    final teacherId = ref.read(currentUserIdProvider);
    final service = ref.read(bulkTeacherActionServiceProvider);
    final result = await service.cancelLessonsOnDate(
      teacherId: teacherId,
      studentIds: widget.studentIds,
      targetDate: date,
      reason:
          _reasonController.text.trim().isEmpty
              ? null
              : _reasonController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    final buffer = StringBuffer(
      '${result.cancelledLessonCount}건 취소 · '
      '${result.notifiedStudentCount}명에게 알림 발송',
    );
    if (result.hasSkipped) {
      buffer.write(' (해당 날짜 레슨 없음: ${result.skippedStudentIds.length}명)');
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(buffer.toString())));
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return NotebookScreenScaffold(
      appBar: AppBar(title: const Text(AppStrings.studentBulkCancelLabel)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${widget.studentIds.length}명 선택됨',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              OutlinedButton.icon(
                onPressed: _submitting ? null : _pickDate,
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text(
                  _targetDate == null
                      ? '휴강 날짜 선택'
                      : formatDateYMD(_targetDate!),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: '사유 (선택)',
                  hintText: AppStrings.studentBulkCancelReasonHint,
                  border: OutlineInputBorder(),
                ),
                enabled: !_submitting,
              ),
              const SizedBox(height: AppSpacing.space4),
              Expanded(child: _buildPreview()),
              const SizedBox(height: AppSpacing.space3),
              FilledButton(
                onPressed:
                    (_targetDate != null &&
                            _affected.isNotEmpty &&
                            !_submitting)
                        ? _confirm
                        : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
                ),
                child: Text(
                  _submitting ? '발송 중…' : '${_affected.length}건 휴강 공지 발송',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (_targetDate == null) {
      return Center(
        child: Text(
          '휴강할 날짜를 먼저 선택하세요',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
      );
    }
    if (_previewing) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_affected.isEmpty) {
      return Center(
        child: Text(
          '선택된 학생 중 해당 날짜에 예정된 레슨이 없습니다',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
      );
    }
    return ListView.separated(
      itemCount: _affected.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final l = _affected[i];
        return ListTile(
          dense: true,
          leading: const Icon(Icons.event_busy, size: 20),
          title: Text(l.studentName, style: AppTypography.bodyMedium),
          subtitle: Text(
            '${formatDateYMD(l.date)} ${l.startTime}',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        );
      },
    );
  }
}
