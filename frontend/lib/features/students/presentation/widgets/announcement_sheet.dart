import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../../core/widgets/notebook/thin_rule.dart';
import '../../../auth/auth_facade.dart' show currentUserIdProvider;
import '../../domain/entities/teacher_announcement.dart';
import '../providers/teacher_announcement_providers.dart';

/// v3 공지 작성 바텀시트.
///
/// Masthead 📢 아이콘 탭 → 타입(휴강/일반) + 날짜(휴강 시) + 메시지 → 발송.
/// 휴강 시: 영향 학생 목록 결과 화면 표시.
class AnnouncementSheet extends ConsumerStatefulWidget {
  const AnnouncementSheet({super.key});

  static Future<void> show(BuildContext context, {required WidgetRef ref}) {
    return showNotebookModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AnnouncementSheet(),
    );
  }

  @override
  ConsumerState<AnnouncementSheet> createState() => _AnnouncementSheetState();
}

class _AnnouncementSheetState extends ConsumerState<AnnouncementSheet> {
  AnnouncementType _type = AnnouncementType.dayOff;
  DateTime? _selectedDate;
  final _messageController = TextEditingController();
  bool _submitting = false;
  bool _isUsingDefault = true;
  TeacherAnnouncement? _result;

  static const _systemDefaultDayOff = '개인적인 사정으로 휴강합니다.';
  static const _systemDefaultGeneral = '';

  String get _defaultMessage =>
      _type == AnnouncementType.dayOff ? _systemDefaultDayOff : _systemDefaultGeneral;

  @override
  void initState() {
    super.initState();
    // TODO: 선생님 커스텀 디폴트 메시지가 있으면 우선 사용
    _messageController.text = _defaultMessage;
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  bool get _canSend {
    if (_submitting) return false;
    if (_type == AnnouncementType.dayOff && _selectedDate == null) return false;
    // 메시지가 비어있어도 발송 가능 (디폴트 메시지 또는 빈 공지)
    return true;
  }

  String get _effectiveMessage {
    final text = _messageController.text.trim();
    return text.isNotEmpty ? text : _defaultMessage;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _send() async {
    if (!_canSend) return;
    setState(() => _submitting = true);

    final teacherId = ref.read(currentUserIdProvider);
    final repo = ref.read(teacherAnnouncementRepositoryProvider);

    final announcement = TeacherAnnouncement(
      id: '',
      teacherId: teacherId,
      type: _type,
      dates: _type == AnnouncementType.dayOff && _selectedDate != null
          ? [_selectedDate!]
          : [],
      message: _effectiveMessage,
      createdAt: DateTime.now(),
    );

    final result = await repo.create(announcement);
    if (!mounted) return;

    setState(() {
      _submitting = false;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: _result != null ? 0.85 : 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(color: AppColors.paper),
          padding: EdgeInsets.only(bottom: insets),
          child: _result != null
              ? _buildResultView(scrollController)
              : _buildFormView(scrollController),
        );
      },
    );
  }

  /// 공지 작성 폼
  Widget _buildFormView(ScrollController scrollController) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        // Handle
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: const BoxDecoration(color: AppColors.inkSecondary),
          ),
        ),
        const SizedBox(height: AppSpacing.space4),

        // Title
        Text(AppStrings.announcementTitle, style: NotebookTypography.sectionTitle),
        const SizedBox(height: AppSpacing.space4),

        // Type selection
        Row(
          children: [
            _TypeChip(
              label: AppStrings.announcementTypeDayOff,
              isSelected: _type == AnnouncementType.dayOff,
              onTap: () => setState(() => _type = AnnouncementType.dayOff),
            ),
            const SizedBox(width: AppSpacing.space2),
            _TypeChip(
              label: AppStrings.announcementTypeGeneral,
              isSelected: _type == AnnouncementType.general,
              onTap: () => setState(() => _type = AnnouncementType.general),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space4),

        // Date picker (dayOff only)
        if (_type == AnnouncementType.dayOff) ...[
          OutlinedButton.icon(
            onPressed: _submitting ? null : _pickDate,
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(
              _selectedDate == null
                  ? AppStrings.announcementSelectDate
                  : formatDateYMDWithDay(_selectedDate!),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
        ],

        // Message — 디폴트 메시지가 채워져 있음, 탭하면 빈칸으로 직접 입력
        TextField(
          controller: _messageController,
          maxLines: 4,
          maxLength: 200,
          decoration: InputDecoration(
            labelText: '메시지',
            hintText: AppStrings.announcementMessageHint,
            border: const OutlineInputBorder(),
            suffixIcon: _messageController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _messageController.clear();
                      setState(() => _isUsingDefault = false);
                    },
                  )
                : null,
          ),
          enabled: !_submitting,
          onTap: () {
            if (_isUsingDefault && _messageController.text == _defaultMessage) {
              _messageController.clear();
              setState(() => _isUsingDefault = false);
            }
          },
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.space4),

        // Send button
        FilledButton(
          onPressed: _canSend ? _send : null,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
          ),
          child: Text(_submitting ? AppStrings.announcementSending : AppStrings.announcementSend),
        ),
      ],
    );
  }

  /// 공지 발송 결과 + 영향 학생 목록
  Widget _buildResultView(ScrollController scrollController) {
    final result = _result!;
    final affected = result.affectedLessons;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        // Handle
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: const BoxDecoration(color: AppColors.inkSecondary),
          ),
        ),
        const SizedBox(height: AppSpacing.space4),

        // Success header
        Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.paperOk, size: 24),
            const SizedBox(width: AppSpacing.space2),
            Text(
              AppStrings.announcementSentTitle,
              style: NotebookTypography.sectionTitle,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space1),
        if (result.dates.isNotEmpty)
          Text(
            '${formatDateYMDWithDay(result.dates.first)} · ${AppStrings.announcementSentCount(result.affectedLessons.length)}',
            style: AppTypography.bodySmall.copyWith(color: AppColors.inkSecondary),
          ),

        // Affected students (dayOff only)
        if (affected.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space6),
          Text(
            AppStrings.announcementAffectedHeader,
            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.space2),

          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.inkQuaternary),
                bottom: BorderSide(color: AppColors.inkQuaternary),
              ),
            ),
            child: Column(
              children: [
                for (int i = 0; i < affected.length; i++) ...[
                  if (i > 0)
                    const ThinRule(),
                  _AffectedLessonItem(
                    lesson: affected[i],
                    onScheduleChange: () {
                      // 시트 닫고 → 공지 이력에서 스케줄 변경 진행
                      final teacherId = ref.read(currentUserIdProvider);
                      ref.invalidate(teacherAnnouncementsProvider(teacherId));
                      Navigator.pop(context);
                      // 수강권 상세(스케줄 변경 챗)로 이동
                      if (affected[i].subscriptionId != null) {
                        context.push(
                          AppRoutes.subscriptionDetail.replaceFirst(
                            ':id',
                            affected[i].subscriptionId!,
                          ),
                          extra: {'viewerRole': 'teacher'},
                        );
                      }
                    },
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.space3),
          Container(
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              color: AppColors.paperDark,
              border: Border.all(color: AppColors.inkQuaternary),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppColors.inkTertiary),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Text(
                    AppStrings.announcementNoAutoCancel,
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.inkTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.space4),
        FilledButton(
          onPressed: () {
            // 공지 이력 리스트 즉시 갱신
            final teacherId = ref.read(currentUserIdProvider);
            ref.invalidate(teacherAnnouncementsProvider(teacherId));
            Navigator.pop(context);
          },
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
          ),
          child: const Text(AppStrings.confirm),
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space2,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.paperAccentSoft : AppColors.paper,
          border: Border.all(
            color: isSelected ? AppColors.paperAccent : AppColors.inkQuaternary,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: isSelected ? AppColors.paperAccent : AppColors.inkSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _AffectedLessonItem extends StatelessWidget {
  final AffectedLesson lesson;
  final VoidCallback onScheduleChange;

  const _AffectedLessonItem({
    required this.lesson,
    required this.onScheduleChange,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onScheduleChange,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space3,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${lesson.studentName} · ${lesson.instrument} · ${lesson.startTime}',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (lesson.sessionNumber != null)
                    Text(
                      '${lesson.sessionNumber}회차',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.inkTertiary,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              AppStrings.announcementScheduleChange,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.paperAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpacing.space1),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.paperAccent),
          ],
        ),
      ),
    );
  }
}
