import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/core/theme/app_spacing.dart';
import 'package:lessonaza/core/theme/app_typography.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_detail_app_bar.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:lessonaza/features/academy/academy.dart';
import 'package:lessonaza/features/academy/data/repositories/mock_academy_inquiry_repository.dart';

final _inquiryListProvider =
    FutureProvider.family<List<AcademyInquiry>, String>((ref, academyId) async {
      final repo = MockAcademyInquiryRepository();
      return repo.listByAcademy(academyId);
    });

class AcademyInquiryScreen extends ConsumerWidget {
  const AcademyInquiryScreen({required this.academyId, super.key});

  final String academyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inquiryAsync = ref.watch(_inquiryListProvider(academyId));

    return NotebookScreenScaffold(
      // Icons.forum distinguishes 1:1 inquiry from personal notifications (bell).
      appBar: const NotebookDetailAppBar(titleWidget: _InquiryAppBarTitle()),
      body: inquiryAsync.when(
        data: (inquiries) {
          if (inquiries.isEmpty) {
            return Center(
              child: Text(
                AppStrings.inquiryNoInquiries,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(AppSpacing.space4),
            itemCount: inquiries.length,
            itemBuilder: (context, index) {
              final inquiry = inquiries[index];
              return _InquiryCard(
                inquiry: inquiry,
                academyId: academyId,
                onTap: () {
                  context.push(
                    '/academy/$academyId/inquiries/${inquiry.id}',
                    extra: inquiry,
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('오류: $error')),
      ),
    );
  }
}

/// Appbar title row: forum icon + "1:1 문의" text.
/// Icons.forum visually separates 1:1 inquiry from personal notifications (bell).
class _InquiryAppBarTitle extends StatelessWidget {
  const _InquiryAppBarTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.forum_outlined, size: 18, color: AppColors.ink),
        SizedBox(width: AppSpacing.space2),
        Text(AppStrings.inquiryTitle),
      ],
    );
  }
}

class _InquiryCard extends StatelessWidget {
  const _InquiryCard({
    required this.inquiry,
    required this.academyId,
    required this.onTap,
  });

  final AcademyInquiry inquiry;
  final String academyId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasReply = inquiry.replies.isNotEmpty;
    final statusColor = hasReply ? AppColors.paperOk : AppColors.paperTrial;

    return NotebookCard(
      margin: EdgeInsets.only(bottom: AppSpacing.space3),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.space2,
                      vertical: AppSpacing.space1,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                    ),
                    child: Text(
                      _senderRoleLabel(),
                      style: AppTypography.captionSmall.copyWith(
                        color: statusColor,
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: Text(
                      inquiry.senderName,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.ink,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: AppSpacing.space2),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.space2,
                      vertical: AppSpacing.space1,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                    ),
                    child: Text(
                      // "미답변" = teacher has not yet replied (unambiguous vs "대기중").
                      hasReply
                          ? AppStrings.inquiryStatusAnswered
                          : AppStrings.inquiryStatusUnanswered,
                      style: AppTypography.captionSmall.copyWith(
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.space2),
              Text(
                inquiry.body,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: AppSpacing.space3),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(inquiry.createdAt),
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.inkTertiary,
                    ),
                  ),
                  // SLA hint shown only on unanswered inquiries.
                  if (!hasReply)
                    Text(
                      AppStrings.inquiryReplySla,
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.inkTertiary,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _senderRoleLabel() {
    return inquiry.senderRole == InquirySenderRole.student
        ? AppStrings.inquirySenderRoleStudent
        : AppStrings.inquirySenderRoleParent;
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours < 1) {
        return '방금 전';
      }
      return '${difference.inHours}시간 전';
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    }
  }
}
