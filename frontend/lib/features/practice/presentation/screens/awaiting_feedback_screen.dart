import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/widgets/notebook/notebook_screen_scaffold.dart';
import '../../../../core/widgets/notebook/section_header.dart';
import '../../../students/students_facade.dart' show studentsProvider;
import '../../domain/entities/practice_item.dart';
import '../providers/practice_item_providers.dart';

/// 선생님 '피드백 대기 과제' 큐 (껍데기 감사 #415 / #1128).
///
/// 학생이 완료했으나 아직 선생님 Quick Reaction 이 없는 과제를 학생별로 묶어
/// 보여준다. 완료 시각 내림차순으로 정렬하고, 24시간 초과 항목은 잉크 강조.
/// 행 트레일링의 1탭 리액션([PracticeItemsNotifier.toggleLike])이 항목을 큐에서
/// 제거한다(쓰기가 [awaitingFeedbackProvider] 를 무효화 → 재조회).
class AwaitingFeedbackScreen extends ConsumerWidget {
  const AwaitingFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(awaitingFeedbackProvider);

    return NotebookScreenScaffold(
      appBar: NotebookDetailAppBar(title: AppStrings.awaitingFeedbackTitle),
      body: RefreshIndicator(
        color: AppColors.ink,
        onRefresh: () async {
          ref.invalidate(awaitingFeedbackProvider);
          await ref.read(awaitingFeedbackProvider.future);
        },
        child: itemsAsync.when(
          data: (items) => _buildBody(context, ref, items),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _ErrorView(
            onRetry: () => ref.invalidate(awaitingFeedbackProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    List<PracticeItem> items,
  ) {
    if (items.isEmpty) {
      return const _AwaitingFeedbackEmpty();
    }

    // 학생명 매핑 (없으면 studentId 폴백).
    final nameById = <String, String>{
      for (final s in ref.watch(studentsProvider).valueOrNull ?? const [])
        s.id: s.name,
    };

    final groups = _groupByStudent(items);

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        final name = nameById[group.studentId] ?? group.studentId;
        return _StudentGroup(
          studentName: name,
          items: group.items,
          onReact: (item) => _react(ref, item),
        );
      },
    );
  }

  Future<void> _react(WidgetRef ref, PracticeItem item) async {
    // 쓰기는 레슨 기반 notifier 경유. toggleLike 가 awaitingFeedbackProvider 를
    // 무효화하여 재조회 → 리액션된 항목이 큐에서 제거된다.
    await ref
        .read(practiceItemsNotifierProvider(item.lessonId).notifier)
        .toggleLike(item.id, item.studentId);
  }

  /// 학생별로 묶고, 각 그룹 내부는 완료 시각 내림차순, 그룹 자체도
  /// 그룹 내 최신 완료 시각 내림차순으로 정렬한다.
  List<_StudentGroupData> _groupByStudent(List<PracticeItem> items) {
    final byStudent = <String, List<PracticeItem>>{};
    for (final item in items) {
      byStudent.putIfAbsent(item.studentId, () => []).add(item);
    }

    final groups = byStudent.entries.map((entry) {
      final sorted = [...entry.value]
        ..sort((a, b) => _completedKey(b).compareTo(_completedKey(a)));
      return _StudentGroupData(studentId: entry.key, items: sorted);
    }).toList();

    groups.sort(
      (a, b) =>
          _completedKey(b.items.first).compareTo(_completedKey(a.items.first)),
    );
    return groups;
  }

  static DateTime _completedKey(PracticeItem item) =>
      item.completedAt ?? item.createdAt;
}

class _StudentGroupData {
  final String studentId;
  final List<PracticeItem> items;

  const _StudentGroupData({required this.studentId, required this.items});
}

/// 학생 그룹 — 헤더 + 과제 행 목록.
class _StudentGroup extends StatelessWidget {
  final String studentName;
  final List<PracticeItem> items;
  final ValueChanged<PracticeItem> onReact;

  const _StudentGroup({
    required this.studentName,
    required this.items,
    required this.onReact,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space4,
            AppSpacing.space3,
            AppSpacing.space4,
            AppSpacing.space2,
          ),
          child: NotebookSectionHeader(
            label: AppStrings.awaitingFeedbackStudentCount(
              studentName,
              items.length,
            ),
          ),
        ),
        ...items.map(
          (item) => _AwaitingFeedbackRow(item: item, onReact: onReact),
        ),
      ],
    );
  }
}

/// 과제 행 — 제목 + 완료 상대시각 + 1탭 리액션.
class _AwaitingFeedbackRow extends StatelessWidget {
  final PracticeItem item;
  final ValueChanged<PracticeItem> onReact;

  const _AwaitingFeedbackRow({required this.item, required this.onReact});

  @override
  Widget build(BuildContext context) {
    final completedAt = item.completedAt;
    // 24시간 초과 대기 → 잉크 강조 (오래 방치된 항목 시각 신호).
    final isOverdue =
        completedAt != null &&
        DateTime.now().difference(completedAt).inHours >= 24;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space1,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // §7.130: 선생님 작성 과제 제목 → Tier 1 Gaegu hand.
                Text(
                  item.title,
                  style: NotebookTypography.hand.copyWith(
                    fontSize: 15,
                    color: isOverdue ? AppColors.ink : AppColors.inkSecondary,
                    fontWeight: isOverdue ? FontWeight.w700 : FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  completedAt != null
                      ? AppStrings.awaitingFeedbackCompletedAgo(
                          formatRelativeTime(completedAt),
                        )
                      : item.completionInfo,
                  style: AppTypography.caption.copyWith(
                    color: isOverdue
                        ? AppColors.paperAccent
                        : AppColors.inkTertiary,
                    fontWeight: isOverdue ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          _ReactionButton(onTap: () => onReact(item)),
        ],
      ),
    );
  }
}

/// 1탭 Quick Reaction — 좋아요(잉크 하트) 토글. 탭 시 항목이 큐에서 제거된다.
class _ReactionButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ReactionButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: AppStrings.awaitingFeedbackReactTooltip,
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.favorite_border, size: 22, color: AppColors.ink),
    );
  }
}

/// 빈 상태 — 모든 과제 확인 완료 (C1: EmptyStateWidget).
class _AwaitingFeedbackEmpty extends StatelessWidget {
  const _AwaitingFeedbackEmpty();

  @override
  Widget build(BuildContext context) {
    return const EmptyStateWidget(
      scrollable: true,
      icon: Icons.check_circle_outline,
      title: AppStrings.awaitingFeedbackEmpty,
      subtitle: AppStrings.awaitingFeedbackEmptySubtitle,
    );
  }
}

/// 에러 상태 — 재시도 (C7 공통 패턴).
class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 32,
                color: AppColors.inkTertiary,
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                AppStrings.loadDataFailed,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  side: const BorderSide(color: AppColors.ink, width: 1),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: Text(AppStrings.retry),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
