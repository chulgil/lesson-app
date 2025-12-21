import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Screen for editing an existing lesson
class EditLessonScreen extends StatefulWidget {
  final String lessonId;

  const EditLessonScreen({
    super.key,
    required this.lessonId,
  });

  @override
  State<EditLessonScreen> createState() => _EditLessonScreenState();
}

class _EditLessonScreenState extends State<EditLessonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pieceController = TextEditingController();
  final _notesController = TextEditingController();

  _StudentInfo? _selectedStudent;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 14, minute: 0);
  int _lessonDuration = 60;
  bool _enableReminder = true;
  int _reminderMinutes = 30;

  bool _isLoading = true;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadLessonData();
  }

  void _loadLessonData() {
    // TODO: Load from database
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _selectedStudent = _mockStudents.firstWhere(
            (s) => s.id == 'student_1',
          );
          _selectedDate = DateTime.now().add(const Duration(days: 2));
          _selectedTime = const TimeOfDay(hour: 14, minute: 0);
          _lessonDuration = 60;
          _pieceController.text = '바흐 파르티타 2번 - Allemande';
          _notesController.text = '보잉 연습에 집중';
          _enableReminder = true;
          _reminderMinutes = 30;
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _pieceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('레슨 수정')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('레슨 수정'),
        leading: IconButton(
          onPressed: () => _showExitConfirmation(context),
          icon: const Icon(Icons.close),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'cancel':
                  _showCancelLessonDialog(context);
                  break;
                case 'delete':
                  _showDeleteConfirmation(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'cancel',
                child: Row(
                  children: [
                    Icon(Icons.event_busy, color: AppColors.warning),
                    const SizedBox(width: 8),
                    const Text('레슨 취소'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: AppColors.error),
                    const SizedBox(width: 8),
                    Text('레슨 삭제', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: _hasChanges ? _saveLesson : null,
            child: Text(
              '저장',
              style: TextStyle(
                color: _hasChanges ? null : AppColors.textTertiaryLight,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        onChanged: _markChanged,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student info (read-only)
              _buildSectionTitle('학생'),
              const SizedBox(height: AppSpacing.space3),
              _buildStudentInfo(),

              const SizedBox(height: AppSpacing.space6),

              // Date and time selection
              _buildSectionTitle('일시'),
              const SizedBox(height: AppSpacing.space3),
              _buildDateTimeSection(),

              const SizedBox(height: AppSpacing.space6),

              // Lesson duration
              _buildSectionTitle('레슨 시간'),
              const SizedBox(height: AppSpacing.space3),
              _buildDurationSelector(),

              const SizedBox(height: AppSpacing.space6),

              // Lesson content
              _buildSectionTitle('레슨 내용'),
              const SizedBox(height: AppSpacing.space3),
              _buildLessonContentFields(),

              const SizedBox(height: AppSpacing.space6),

              // Reminder settings
              _buildReminderSection(),

              const SizedBox(height: AppSpacing.space8),

              // Save button
              _buildSaveButton(),

              const SizedBox(height: AppSpacing.space4),

              // Cancel/Delete buttons
              _buildActionButtons(),

              const SizedBox(height: AppSpacing.space6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTypography.headingSmall);
  }

  Widget _buildStudentInfo() {
    if (_selectedStudent == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _selectedStudent!.color.withValues(alpha: 0.2),
            child: Text(
              _selectedStudent!.name[0],
              style: AppTypography.headingSmall.copyWith(
                color: _selectedStudent!.color,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedStudent!.name,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryLight.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _selectedStudent!.instrument,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              // Navigate to student detail
              context.push('/students/${_selectedStudent!.id}');
            },
            child: const Text('프로필 보기'),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSection() {
    final dateFormat = DateFormat('yyyy년 M월 d일 (E)', 'ko');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          // Date picker
          InkWell(
            onTap: () => _selectDate(context),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMedium),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '날짜',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      Text(
                        dateFormat.format(_selectedDate),
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.edit,
                  size: 18,
                  color: AppColors.textTertiaryLight,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.space3),
          const Divider(),
          const SizedBox(height: AppSpacing.space3),

          // Time picker
          InkWell(
            onTap: () => _selectTime(context),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMedium),
                  ),
                  child: const Icon(
                    Icons.access_time,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '시간',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      Text(
                        _formatTime(_selectedTime),
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.edit,
                  size: 18,
                  color: AppColors.textTertiaryLight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationSelector() {
    final durations = [
      (30, '30분'),
      (45, '45분'),
      (60, '1시간'),
      (90, '1시간 30분'),
      (120, '2시간'),
    ];

    return Wrap(
      spacing: AppSpacing.space2,
      runSpacing: AppSpacing.space2,
      children: durations.map((d) {
        final isSelected = _lessonDuration == d.$1;
        return ChoiceChip(
          label: Text(d.$2),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _lessonDuration = d.$1;
                _hasChanges = true;
              });
            }
          },
          backgroundColor: AppColors.surfaceLight,
          selectedColor: AppColors.primary.withValues(alpha: 0.15),
          checkmarkColor: AppColors.primary,
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
          ),
          labelStyle: AppTypography.bodySmall.copyWith(
            color: isSelected ? AppColors.primary : AppColors.textPrimaryLight,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLessonContentFields() {
    return Column(
      children: [
        // Piece/Content
        TextFormField(
          controller: _pieceController,
          decoration: InputDecoration(
            labelText: '레슨 곡',
            hintText: '레슨할 곡이나 내용을 입력하세요',
            prefixIcon: const Icon(Icons.music_note),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            filled: true,
            fillColor: AppColors.surfaceLight,
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.space4),

        // Notes
        TextFormField(
          controller: _notesController,
          decoration: InputDecoration(
            labelText: '메모',
            hintText: '레슨 시 참고할 내용을 입력하세요',
            prefixIcon: const Icon(Icons.note_alt_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            filled: true,
            fillColor: AppColors.surfaceLight,
          ),
          maxLines: 3,
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }

  Widget _buildReminderSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          // Toggle reminder
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.practiceGood.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
                child: const Icon(
                  Icons.notifications_active,
                  color: AppColors.practiceGood,
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '레슨 알림',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '레슨 시작 전 알림 받기',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _enableReminder,
                onChanged: (value) {
                  setState(() {
                    _enableReminder = value;
                    _hasChanges = true;
                  });
                },
              ),
            ],
          ),

          if (_enableReminder) ...[
            const SizedBox(height: AppSpacing.space3),
            const Divider(),
            const SizedBox(height: AppSpacing.space3),
            Row(
              children: [
                Text(
                  '알림 시간',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const Spacer(),
                _buildReminderTimeSelector(),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReminderTimeSelector() {
    final options = [
      (10, '10분 전'),
      (30, '30분 전'),
      (60, '1시간 전'),
      (1440, '하루 전'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((option) {
          final isSelected = _reminderMinutes == option.$1;
          return GestureDetector(
            onTap: () {
              setState(() {
                _reminderMinutes = option.$1;
                _hasChanges = true;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
              child: Text(
                option.$2,
                style: AppTypography.caption.copyWith(
                  color:
                      isSelected ? Colors.white : AppColors.textSecondaryLight,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: AppSpacing.buttonHeight,
      child: FilledButton(
        onPressed: _hasChanges ? _saveLesson : null,
        child: const Text('변경사항 저장'),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showCancelLessonDialog(context),
            icon: Icon(Icons.event_busy, color: AppColors.warning),
            label: Text(
              '레슨 취소',
              style: TextStyle(color: AppColors.warning),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: AppColors.warning.withValues(alpha: 0.5)),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showDeleteConfirmation(context),
            icon: Icon(Icons.delete_outline, color: AppColors.error),
            label: Text(
              '레슨 삭제',
              style: TextStyle(color: AppColors.error),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ko'),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _hasChanges = true;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _hasChanges = true;
      });
    }
  }

  void _showExitConfirmation(BuildContext context) {
    if (!_hasChanges) {
      context.pop();
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('변경사항 취소'),
        content: const Text('변경한 내용이 저장되지 않습니다.\n정말 나가시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('계속 수정'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('나가기'),
          ),
        ],
      ),
    );
  }

  void _showCancelLessonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('레슨 취소'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('이 레슨을 취소하시겠습니까?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_selectedStudent?.name ?? ''} 학생',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${DateFormat('M월 d일 (E)', 'ko').format(_selectedDate)} ${_formatTime(_selectedTime)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '학생에게 레슨 취소 알림이 전송됩니다.',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelLesson();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.warning,
            ),
            child: const Text('레슨 취소'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('레슨 삭제'),
        content: const Text(
          '이 레슨을 삭제하시겠습니까?\n\n'
          '삭제된 레슨은 복구할 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteLesson();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _cancelLesson() {
    // TODO: Update lesson status to cancelled

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_selectedStudent?.name ?? ''} 학생의 레슨이 취소되었습니다'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.warning,
      ),
    );

    context.pop();
  }

  void _deleteLesson() {
    // TODO: Delete lesson from database

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('레슨이 삭제되었습니다'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    context.pop();
  }

  void _saveLesson() {
    // TODO: Update lesson in database
    final lessonData = {
      'id': widget.lessonId,
      'studentId': _selectedStudent?.id,
      'date': _selectedDate.toIso8601String(),
      'time': _formatTime(_selectedTime),
      'duration': _lessonDuration,
      'piece': _pieceController.text,
      'notes': _notesController.text,
      'enableReminder': _enableReminder,
      'reminderMinutes': _reminderMinutes,
    };

    debugPrint('Updating lesson: $lessonData');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('레슨 정보가 수정되었습니다'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.practiceGood,
      ),
    );

    context.pop();
  }

  // Mock data
  List<_StudentInfo> get _mockStudents => [
        _StudentInfo(
          id: 'student_1',
          name: '홍길동',
          instrument: '바이올린',
          color: Colors.blue,
        ),
        _StudentInfo(
          id: 'student_2',
          name: '김철수',
          instrument: '피아노',
          color: Colors.green,
        ),
        _StudentInfo(
          id: 'student_3',
          name: '이영희',
          instrument: '첼로',
          color: Colors.orange,
        ),
      ];
}

class _StudentInfo {
  final String id;
  final String name;
  final String instrument;
  final Color color;

  _StudentInfo({
    required this.id,
    required this.name,
    required this.instrument,
    required this.color,
  });
}
