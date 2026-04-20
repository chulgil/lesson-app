import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/unified_lesson_request.dart';
import '../../../../features/profile/domain/entities/teacher_settings.dart';
import '../../../../features/settings/presentation/providers/teacher_settings_provider.dart';
import '../providers/unified_lesson_request_providers.dart';
import '../widgets/weekly_calendar_picker.dart';
import 'request_completion_screen.dart';

/// Parameters passed via GoRouter extra for the unified lesson request screen.
class UnifiedLessonRequestParams {
  final String teacherId;
  final String teacherName;
  final List<String> teacherInstruments;
  final bool isReturningStudent;
  final String? previousInstrument;
  final int? previousDay;
  final String? previousTime;

  const UnifiedLessonRequestParams({
    required this.teacherId,
    required this.teacherName,
    required this.teacherInstruments,
    this.isReturningStudent = false,
    this.previousInstrument,
    this.previousDay,
    this.previousTime,
  });
}

/// Unified lesson request screen — students fill and submit trial or regular
/// lesson requests through a single form.
class UnifiedLessonRequestScreen extends ConsumerStatefulWidget {
  final UnifiedLessonRequestParams params;

  const UnifiedLessonRequestScreen({
    super.key,
    required this.params,
  });

  @override
  ConsumerState<UnifiedLessonRequestScreen> createState() =>
      _UnifiedLessonRequestScreenState();
}

class _UnifiedLessonRequestScreenState
    extends ConsumerState<UnifiedLessonRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();

  late LessonRequestType _selectedType;
  String? _selectedInstrument;
  UnifiedLessonGoal _selectedGoal = UnifiedLessonGoal.hobby;
  UnifiedExperienceLevel _selectedExperience = UnifiedExperienceLevel.beginner;
  List<PreferredTimeSlot> _preferredSlots = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.params.isReturningStudent
        ? LessonRequestType.regular
        : LessonRequestType.trial;

    // Pre-fill instrument for returning students
    if (widget.params.isReturningStudent) {
      _selectedInstrument = widget.params.previousInstrument;
    }

    // Default instrument selection if only one available
    if (widget.params.teacherInstruments.length == 1) {
      _selectedInstrument = widget.params.teacherInstruments.first;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(AppStrings.lessonRequestFormTitle),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTeacherHeader(),
              if (widget.params.isReturningStudent) ...[
                const SizedBox(height: AppSpacing.space4),
                _buildReturningBanner(),
              ],
              const SizedBox(height: AppSpacing.space4),
              _buildGuidanceMessage(),
              const SizedBox(height: AppSpacing.space6),
              _buildLessonTypeSection(),
              const SizedBox(height: AppSpacing.space6),
              _buildInstrumentSection(),
              const SizedBox(height: AppSpacing.space6),
              _buildGoalSection(),
              const SizedBox(height: AppSpacing.space6),
              _buildExperienceSection(),
              const SizedBox(height: AppSpacing.space6),
              _buildEstimatedDuration(),
              const SizedBox(height: AppSpacing.space6),
              _buildSlotPickerSection(),
              const SizedBox(height: AppSpacing.space6),
              _buildCancellationPolicy(),
              const SizedBox(height: AppSpacing.space6),
              _buildMessageSection(),
              const SizedBox(height: AppSpacing.space6),
              _buildReferencePriceSection(),
              const SizedBox(height: AppSpacing.space8),
              _buildSubmitButton(),
              const SizedBox(height: AppSpacing.space8),
            ],
          ),
        ),
      ),
    );
  }

  // -- Teacher info header --

  Widget _buildTeacherHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: const Icon(
              Icons.person,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.params.teacherName,
                  style: AppTypography.headingSmall,
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  widget.params.teacherInstruments.join(', '),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -- Returning student banner --

  Widget _buildReturningBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(
          color: AppColors.infoBorder,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.history, size: 20, color: AppColors.info),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              '재수강 신청 — 이전 레슨 정보가 자동 입력되었습니다',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.info,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -- Guidance message (Naver benchmark) --

  Widget _buildGuidanceMessage() {
    final settingsAsync = ref.watch(teacherSettingsProvider);
    final message = settingsAsync.valueOrNull?.effectiveGuidanceMessage
        ?? TeacherSettings.defaultGuidanceMessage;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.primary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -- Lesson type selection --

  Widget _buildLessonTypeSection() {
    return _SectionWrapper(
      icon: Icons.school,
      title: '레슨 유형',
      child: SegmentedButton<LessonRequestType>(
        segments: LessonRequestType.values
            .map(
              (type) => ButtonSegment<LessonRequestType>(
                value: type,
                label: Text(type.label),
              ),
            )
            .toList(),
        selected: {_selectedType},
        onSelectionChanged: (selected) {
          setState(() {
            _selectedType = selected.first;
          });
        },
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primary;
            }
            return AppColors.surfaceLight;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return AppColors.textPrimaryLight;
          }),
        ),
      ),
    );
  }

  // -- Instrument selection --

  Widget _buildInstrumentSection() {
    final instruments = widget.params.teacherInstruments;
    if (instruments.isEmpty) return const SizedBox.shrink();

    // Single instrument → hide UI, auto-selected in initState (spec Section 11)
    if (instruments.length == 1) return const SizedBox.shrink();

    return _SectionWrapper(
      icon: Icons.music_note,
      title: '악기',
      isRequired: true,
      child: Wrap(
        spacing: AppSpacing.space2,
        runSpacing: AppSpacing.space2,
        children: instruments.map((instrument) {
          final isSelected = _selectedInstrument == instrument;
          return ChoiceChip(
            label: Text(instrument),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                _selectedInstrument = selected ? instrument : null;
              });
            },
            selectedColor: AppColors.primary.withValues(alpha: 0.2),
            backgroundColor: AppColors.surfaceLight,
            labelStyle: AppTypography.bodyMedium.copyWith(
              color:
                  isSelected ? AppColors.primary : AppColors.textPrimaryLight,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.borderLight,
            ),
          );
        }).toList(),
      ),
    );
  }

  // -- Lesson goal --

  Widget _buildGoalSection() {
    return _SectionWrapper(
      icon: Icons.flag,
      title: '레슨 목표',
      child: DropdownButtonFormField<UnifiedLessonGoal>(
        value: _selectedGoal,
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.surfaceLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            borderSide: const BorderSide(color: AppColors.borderLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            borderSide: const BorderSide(color: AppColors.borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space3,
          ),
        ),
        items: UnifiedLessonGoal.values.map((goal) {
          return DropdownMenuItem<UnifiedLessonGoal>(
            value: goal,
            child: Text(goal.label, style: AppTypography.bodyMedium),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedGoal = value;
            });
          }
        },
      ),
    );
  }

  // -- Experience level --

  Widget _buildExperienceSection() {
    return _SectionWrapper(
      icon: Icons.trending_up,
      title: '경험 수준',
      child: SegmentedButton<UnifiedExperienceLevel>(
        segments: UnifiedExperienceLevel.values
            .map(
              (level) => ButtonSegment<UnifiedExperienceLevel>(
                value: level,
                label: Text(level.label),
              ),
            )
            .toList(),
        selected: {_selectedExperience},
        onSelectionChanged: (selected) {
          setState(() {
            _selectedExperience = selected.first;
          });
        },
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primary;
            }
            return AppColors.surfaceLight;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return AppColors.textPrimaryLight;
          }),
        ),
      ),
    );
  }

  // -- Slot picker --

  Widget _buildSlotPickerSection() {
    return _SectionWrapper(
      icon: Icons.calendar_today,
      title: '희망 레슨 시간',
      isRequired: true,
      child: WeeklyCalendarPicker(
        teacherId: widget.params.teacherId,
        lessonType: _selectedType,
        onSlotsChanged: (slots) {
          setState(() {
            _preferredSlots = slots;
          });
        },
      ),
    );
  }

  // -- Estimated duration (read-only, Naver benchmark) --

  Widget _buildEstimatedDuration() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, size: 18, color: AppColors.textSecondaryLight),
          const SizedBox(width: AppSpacing.space3),
          Text(
            AppStrings.estimatedDuration,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const Spacer(),
          Text(
            '60분',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // -- Cancellation policy (read-only, Naver benchmark) --

  Widget _buildCancellationPolicy() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.info),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Text(
              AppStrings.cancellationPolicy,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.info,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -- Message --

  Widget _buildMessageSection() {
    return _SectionWrapper(
      icon: Icons.message,
      title: '메시지',
      subtitle: '(선택)',
      child: TextField(
        controller: _messageController,
        maxLines: 3,
        maxLength: 200,
        decoration: InputDecoration(
          hintText: '선생님께 전달할 메시지를 입력하세요',
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.textTertiaryLight,
          ),
          filled: true,
          fillColor: AppColors.surfaceLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            borderSide: const BorderSide(color: AppColors.borderLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            borderSide: const BorderSide(color: AppColors.borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),
    );
  }

  // -- Reference price (read-only) --

  Widget _buildReferencePriceSection() {
    // Only show when instrument and experience are selected
    if (_selectedInstrument == null) return const SizedBox.shrink();

    // TODO: Replace with actual price lookup from teacher price table
    final referencePrice = _lookupReferencePrice();
    if (referencePrice == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 20, color: AppColors.info),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '참고 레슨비',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatPrice(referencePrice)}원 / 회',
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -- Submit button --

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _handleSubmit,
        icon: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.send),
        label: Text(_isSubmitting ? AppStrings.submittingRequest : AppStrings.submitRequest),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  // -- Validation & submit --

  bool _validate() {
    if (_selectedInstrument == null) {
      _showValidationError('악기를 선택해주세요');
      return false;
    }
    if (_preferredSlots.isEmpty) {
      _showValidationError('희망 레슨 시간을 1개 이상 선택해주세요');
      return false;
    }
    return true;
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final now = DateTime.now();
      final request = UnifiedLessonRequest(
        id: const Uuid().v4(),
        studentId: '', // Set by auth context in real implementation
        teacherId: widget.params.teacherId,
        type: _selectedType,
        instrument: _selectedInstrument!,
        goal: _selectedGoal,
        experience: _selectedExperience,
        message: _messageController.text.trim().isEmpty
            ? null
            : _messageController.text.trim(),
        preferredDay: _preferredSlots.isNotEmpty
            ? _preferredSlots.first.dayOfWeek
            : null,
        preferredTime: _preferredSlots.isNotEmpty
            ? _preferredSlots.first.startTime
            : null,
        preferredDuration: 60,
        preferredSlots: _preferredSlots,
        isReturningStudent: widget.params.isReturningStudent,
        suggestedPrice: _lookupReferencePrice(),
        createdAt: now,
      );

      final actions = UnifiedLessonRequestActions(ref);
      await actions.createRequest(request);

      if (mounted) {
        context.push(
          AppRoutes.requestCompletion,
          extra: RequestCompletionParams(
            teacherName: widget.params.teacherName,
            instrument: _selectedInstrument!,
            lessonType: _selectedType,
            preferredSlots: _preferredSlots,
            duration: 60,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('신청 전송에 실패했습니다. 다시 시도해주세요.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // -- Helpers --

  int? _lookupReferencePrice() {
    if (_selectedInstrument == null) return null;
    final settings = ref.read(teacherSettingsProvider).valueOrNull;
    if (settings == null) return null;
    return settings.getPrice(_selectedInstrument!, _selectedExperience.name);
  }

  String _formatPrice(int price) {
    final buffer = StringBuffer();
    final priceStr = price.toString();
    for (var i = 0; i < priceStr.length; i++) {
      if (i > 0 && (priceStr.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(priceStr[i]);
    }
    return buffer.toString();
  }
}

// -- Reusable section wrapper --

class _SectionWrapper extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isRequired;
  final Widget child;

  const _SectionWrapper({
    required this.icon,
    required this.title,
    this.subtitle,
    this.isRequired = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: AppSpacing.space2),
            Text(title, style: AppTypography.headingSmall),
            if (isRequired)
              Text(
                ' *',
                style: AppTypography.headingSmall.copyWith(
                  color: AppColors.error,
                ),
              ),
            if (subtitle != null) ...[
              const SizedBox(width: AppSpacing.space2),
              Text(
                subtitle!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.space3),
        child,
      ],
    );
  }
}
