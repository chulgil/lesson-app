import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../domain/entities/bulk_closure.dart';
import '../providers/bulk_closure_provider.dart';

/// G15 — 강사 시점 휴강 상세 화면.
///
/// 정책 SSOT: docs/specs/web/academy/owner_bulk_closure_spec.md §5.2.
///
/// 책임:
/// - 휴강 사유/일자/영향 레슨 요약
/// - status=proposed: 1시간 카운트다운 + 의견 입력 폼
/// - status=applied: 보강 입력 화면 진입 CTA
/// - status=makeupCompleted/cancelled: 결과 요약만
class BulkClosureDetailScreen extends ConsumerStatefulWidget {
  final String closureId;
  final String teacherMemberId;

  const BulkClosureDetailScreen({
    super.key,
    required this.closureId,
    required this.teacherMemberId,
  });

  @override
  ConsumerState<BulkClosureDetailScreen> createState() =>
      _BulkClosureDetailScreenState();
}

class _BulkClosureDetailScreenState
    extends ConsumerState<BulkClosureDetailScreen> {
  final TextEditingController _opinionController = TextEditingController();
  Timer? _countdownTimer;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // 1분마다 카운트다운 재계산.
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _opinionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncClosure = ref.watch(bulkClosureDetailProvider(widget.closureId));

    return NotebookScreenScaffold(
      appBar: const NotebookDetailAppBar(
        title: AppStrings.bulkClosureDetailTitle,
      ),
      body: asyncClosure.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (e, _) => Center(
              child: Text(
                e.toString(),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.paperAccent,
                ),
              ),
            ),
        data: (closure) {
          if (closure == null) {
            return Center(
              child: Text(
                AppStrings.bulkClosureNotFound,
                style: AppTypography.bodyMedium,
              ),
            );
          }
          return _Body(
            closure: closure,
            teacherMemberId: widget.teacherMemberId,
            opinionController: _opinionController,
            isSubmitting: _isSubmitting,
            onSubmitOpinion: () => _submitOpinion(closure),
            onOpenMakeup: () => _openMakeupInput(closure),
          );
        },
      ),
    );
  }

  Future<void> _submitOpinion(BulkClosure closure) async {
    final text = _opinionController.text.trim();
    if (text.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(bulkClosureNotifierProvider.notifier)
          .submitOpinion(
            closureId: closure.id,
            comment: text,
            teacherMemberId: widget.teacherMemberId,
          );
      if (!mounted) return;
      _opinionController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.bulkClosureOpinionSent)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.bulkClosureOpinionFailed)),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _openMakeupInput(BulkClosure closure) {
    final path = AppRoutes.academyMakeupInput
        .replaceAll(':academyId', closure.academyId)
        .replaceAll(':closureId', closure.id);
    // closure 와 teacherMemberId 를 함께 전달한다. 실제 저장(BulkClosureNotifier)
    // 은 router 빌더가 ProviderScope 를 통해 수행한다.
    context.push(
      path,
      extra: MakeupRouteExtra(
        closure: closure,
        teacherMemberId: widget.teacherMemberId,
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final BulkClosure closure;
  final String teacherMemberId;
  final TextEditingController opinionController;
  final bool isSubmitting;
  final VoidCallback onSubmitOpinion;
  final VoidCallback onOpenMakeup;

  const _Body({
    required this.closure,
    required this.teacherMemberId,
    required this.opinionController,
    required this.isSubmitting,
    required this.onSubmitOpinion,
    required this.onOpenMakeup,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.space4),
      children: [
        _StatusBanner(closure: closure),
        const SizedBox(height: AppSpacing.space4),
        _HeaderSection(closure: closure),
        const SizedBox(height: AppSpacing.space4),
        _NotesSection(),
        const SizedBox(height: AppSpacing.space4),
        _AffectedLessonsSection(closure: closure),
        const SizedBox(height: AppSpacing.space4),
        if (closure.status == ClosureStatus.proposed)
          _OpinionInputSection(
            closure: closure,
            controller: opinionController,
            isSubmitting: isSubmitting,
            onSubmit: onSubmitOpinion,
          ),
        if (closure.status == ClosureStatus.applied)
          _MakeupCtaSection(onTap: onOpenMakeup),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final BulkClosure closure;
  const _StatusBanner({required this.closure});

  String get _label {
    switch (closure.status) {
      case ClosureStatus.proposed:
        return AppStrings.bulkClosureStatusProposed;
      case ClosureStatus.applied:
        return AppStrings.bulkClosureStatusApplied;
      case ClosureStatus.makeupCompleted:
        return AppStrings.bulkClosureStatusMakeupCompleted;
      case ClosureStatus.cancelled:
        return AppStrings.bulkClosureStatusCancelled;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.paperAccentSoft,
        border: Border.all(color: AppColors.paperAccent),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_busy, color: AppColors.paperAccent),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              _label,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.paperAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final BulkClosure closure;
  const _HeaderSection({required this.closure});

  @override
  Widget build(BuildContext context) {
    final dateText = formatDateYMD(closure.closureDate);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(dateText, style: AppTypography.headingSmall),
        const SizedBox(height: AppSpacing.space2),
        Text(
          closure.reason,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
        if (closure.status == ClosureStatus.proposed &&
            closure.isOpinionWindowOpen) ...[
          const SizedBox(height: AppSpacing.space3),
          _CountdownLine(endsAt: closure.opinionWindowEndsAt!),
        ],
        if (closure.status == ClosureStatus.proposed &&
            !closure.isOpinionWindowOpen) ...[
          const SizedBox(height: AppSpacing.space3),
          Text(
            AppStrings.bulkClosureWindowExpired,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkTertiary,
            ),
          ),
        ],
      ],
    );
  }
}

class _CountdownLine extends StatelessWidget {
  final DateTime endsAt;
  const _CountdownLine({required this.endsAt});

  @override
  Widget build(BuildContext context) {
    final remaining = endsAt.difference(DateTime.now());
    final minutes = remaining.inMinutes.clamp(0, 9999);
    return Text(
      AppStrings.bulkClosureWindowRemaining(minutes),
      style: AppTypography.bodySmall.copyWith(
        color: AppColors.paperAccent,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _NotesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.bulkClosureAcademyReasonNote,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          AppStrings.bulkClosureNoCreditNote,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
      ],
    );
  }
}

class _AffectedLessonsSection extends StatelessWidget {
  final BulkClosure closure;
  const _AffectedLessonsSection({required this.closure});

  @override
  Widget build(BuildContext context) {
    final lessons = closure.affectedLessons;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.bulkClosureAffectedHeader(lessons.length),
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.space2),
        ...lessons.map(
          (l) => Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.space1),
            child: Row(
              children: [
                const Text('• '),
                Expanded(
                  child: Text(
                    '${l.studentName} · ${_formatHHmm(l.originalStartAt)}–${_formatHHmm(l.originalEndAt)}',
                    style: AppTypography.bodySmall,
                  ),
                ),
                if (l.makeupAt != null)
                  Text(
                    '→ ${formatDateYMD(l.makeupAt!)} ${_formatHHmm(l.makeupAt!)}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.paperOk,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatHHmm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class _OpinionInputSection extends StatelessWidget {
  final BulkClosure closure;
  final TextEditingController controller;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const _OpinionInputSection({
    required this.closure,
    required this.controller,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final canSubmit = closure.isOpinionWindowOpen && !isSubmitting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.bulkClosureOpinionTitle,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.space2),
        TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: AppStrings.bulkClosureOpinionHint,
            border: OutlineInputBorder(),
          ),
          enabled: canSubmit,
        ),
        const SizedBox(height: AppSpacing.space3),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, AppSpacing.buttonHeight),
          ),
          onPressed: canSubmit ? onSubmit : null,
          child: Text(
            isSubmitting ? '...' : AppStrings.bulkClosureOpinionSubmit,
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        Text(
          AppStrings.bulkClosureAutoApplyHint,
          style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
        ),
      ],
    );
  }
}

class _MakeupCtaSection extends StatelessWidget {
  final VoidCallback onTap;
  const _MakeupCtaSection({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, AppSpacing.buttonHeight),
      ),
      onPressed: onTap,
      child: const Text(AppStrings.bulkClosureMakeupInputCta),
    );
  }
}
