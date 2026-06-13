import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/core/theme/app_spacing.dart';
import 'package:lessonaza/core/theme/app_typography.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_detail_app_bar.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:lessonaza/features/academy/academy.dart';
import 'package:lessonaza/features/academy/data/repositories/mock_academy_inquiry_repository.dart';

class AcademyInquiryDetailScreen extends ConsumerStatefulWidget {
  const AcademyInquiryDetailScreen({
    required this.inquiry,
    required this.academyId,
    super.key,
  });

  final AcademyInquiry inquiry;
  final String academyId;

  @override
  ConsumerState<AcademyInquiryDetailScreen> createState() =>
      _AcademyInquiryDetailScreenState();
}

class _AcademyInquiryDetailScreenState
    extends ConsumerState<AcademyInquiryDetailScreen> {
  late TextEditingController _replyController;
  late AcademyInquiry _currentInquiry;
  bool _isReplying = false;

  @override
  void initState() {
    super.initState();
    _replyController = TextEditingController();
    _currentInquiry = widget.inquiry;
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _submitReply() async {
    if (_replyController.text.trim().isEmpty) {
      return;
    }

    setState(() => _isReplying = true);
    try {
      final repo = MockAcademyInquiryRepository();
      await repo.reply(_currentInquiry.id, _replyController.text);
      _replyController.clear();

      // Refresh inquiry
      final updated = await repo.getById(_currentInquiry.id);
      setState(() => _currentInquiry = updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.inquiryCreated),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('답변 전송 실패: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isReplying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotebookScreenScaffold(
      appBar: const NotebookDetailAppBar(title: AppStrings.inquiryTitle),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Original inquiry
                  _buildInquiryCard(_currentInquiry),
                  SizedBox(height: AppSpacing.space5),

                  // Replies
                  if (_currentInquiry.replies.isNotEmpty) ...[
                    Text(
                      '답변 (${_currentInquiry.replies.length})',
                      style: AppTypography.headingSmall.copyWith(
                        color: AppColors.ink,
                      ),
                    ),
                    SizedBox(height: AppSpacing.space3),
                    ..._currentInquiry.replies.map(
                      (reply) => _buildReplyCard(reply),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Reply input
          Padding(
            padding: EdgeInsets.all(AppSpacing.space4),
            child: Column(
              children: [
                TextField(
                  controller: _replyController,
                  decoration: InputDecoration(
                    hintText: AppStrings.inquiryReplyPlaceholder,
                    border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                    contentPadding: EdgeInsets.all(AppSpacing.space3),
                  ),
                  maxLines: 3,
                  minLines: 2,
                  enabled: !_isReplying,
                ),
                SizedBox(height: AppSpacing.space3),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isReplying ? null : _submitReply,
                    child: _isReplying
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(AppStrings.inquiryReplySend),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInquiryCard(AcademyInquiry inquiry) {
    return NotebookCard(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  inquiry.senderName,
                  style: AppTypography.headingSmall.copyWith(
                    color: AppColors.ink,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.space2,
                    vertical: AppSpacing.space1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.paperAccent.withValues(alpha: 0.1),
                  ),
                  child: Text(
                    inquiry.senderRole == InquirySenderRole.student
                        ? AppStrings.inquirySenderRoleStudent
                        : AppStrings.inquirySenderRoleParent,
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.paperAccent,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.space2),
            Text(
              _formatDate(inquiry.createdAt),
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.inkTertiary,
              ),
            ),
            SizedBox(height: AppSpacing.space3),
            Text(
              inquiry.body,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.ink,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyCard(AcademyInquiryReply reply) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.space3),
      padding: EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border(
          left: BorderSide(color: AppColors.paperAccent, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                reply.isFromAcademy ? '학원 답변' : '내 답변',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.paperAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _formatDate(reply.createdAt),
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.inkTertiary,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.space2),
          Text(
            reply.body,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.ink,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
