import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../../core/booking/entities/lesson_booking.dart';
import '../../../../features/lessons/lessons_facade.dart';
import '../widgets/approval_bottom_sheet.dart';
import '../widgets/teacher_approval_card.dart';

/// Screen showing pending booking requests for teacher approval
/// Supports multi-option schedule selection
class PendingBookingsScreen extends ConsumerWidget {
  final String teacherId;

  const PendingBookingsScreen({super.key, required this.teacherId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingBookings = ref.watch(pendingBookingsProvider(teacherId));

    return NotebookScreenScaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text(AppStrings.schedulePendingApproval)),
      body: pendingBookings.when(
        data: (bookings) {
          if (bookings.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(pendingBookingsProvider(teacherId));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.space4),
                  child: TeacherApprovalListItem(
                    booking: booking,
                    onTap: () => _showApprovalSheet(context, ref, booking),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.paperAccent,
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  Text(
                    AppStrings.errorOccurred,
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  TextButton(
                    onPressed:
                        () =>
                            ref.invalidate(pendingBookingsProvider(teacherId)),
                    child: const Text(AppStrings.retry),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 64, color: AppColors.inkTertiary),
          const SizedBox(height: AppSpacing.space4),
          // Notebook × Score: 빈 상태 타이틀은 Playfair sectionTitle (§7.87).
          Text(
            '대기 중인 신청이 없습니다',
            style: NotebookTypography.sectionTitle.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          // 빈 상태 부연 = 시스템 일반 안내 → Tier 3 Pretendard bodyMedium
          // (README §1.1.1 결정 가이드, §7.128 자필 회피).
          Text(
            '새로운 레슨 신청이 들어오면 여기에 표시돼요',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showApprovalSheet(
    BuildContext context,
    WidgetRef ref,
    LessonBooking booking,
  ) {
    showNotebookModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder:
                (context, scrollController) => ApprovalBottomSheet(
                  booking: booking,
                  teacherId: teacherId,
                  scrollController: scrollController,
                  onApproved: () {
                    ref.invalidate(pendingBookingsProvider(teacherId));
                  },
                ),
          ),
    );
  }
}
