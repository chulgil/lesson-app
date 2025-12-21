import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Screen for adding a new lesson
class AddLessonScreen extends StatefulWidget {
  final String? preselectedStudentId;

  const AddLessonScreen({
    super.key,
    this.preselectedStudentId,
  });

  @override
  State<AddLessonScreen> createState() => _AddLessonScreenState();
}

class _AddLessonScreenState extends State<AddLessonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pieceController = TextEditingController();
  final _notesController = TextEditingController();

  _StudentInfo? _selectedStudent;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 14, minute: 0);
  int _lessonDuration = 60;
  bool _isRecurring = false;
  final Set<int> _recurringDays = {};
  bool _enableReminder = true;
  int _reminderMinutes = 30;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedStudentId != null) {
      // Find and select the student
      _selectedStudent = _mockStudents.firstWhere(
        (s) => s.id == widget.preselectedStudentId,
        orElse: () => _mockStudents.first,
      );
    }
  }

  @override
  void dispose() {
    _pieceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('레슨 추가'),
        leading: IconButton(
          onPressed: () => _showExitConfirmation(context),
          icon: const Icon(Icons.close),
        ),
        actions: [
          TextButton(
            onPressed: _saveLesson,
            child: const Text('저장'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student selection
              _buildSectionTitle('학생 선택'),
              const SizedBox(height: AppSpacing.space3),
              _buildStudentSelector(),

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

              // Recurring lesson
              _buildRecurringSection(),

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

  Widget _buildStudentSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          // Selected student or placeholder
          InkWell(
            onTap: () => _showStudentPicker(),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Row(
                children: [
                  if (_selectedStudent != null) ...[
                    CircleAvatar(
                      radius: 24,
                      backgroundColor:
                          _selectedStudent!.color.withValues(alpha: 0.2),
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
                                  color: AppColors.secondaryLight
                                      .withValues(alpha: 0.3),
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
                              const SizedBox(width: AppSpacing.space2),
                              Text(
                                _selectedStudent!.currentPiece,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_add,
                        color: AppColors.textTertiaryLight,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space3),
                    Expanded(
                      child: Text(
                        '학생을 선택하세요',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ],
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.textTertiaryLight,
                  ),
                ],
              ),
            ),
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
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
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
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
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
              setState(() => _lessonDuration = d.$1);
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

  Widget _buildRecurringSection() {
    final dayNames = ['월', '화', '수', '목', '금', '토', '일'];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle recurring
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '정기 레슨',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '매주 같은 요일/시간에 레슨 예약',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isRecurring,
                onChanged: (value) {
                  setState(() {
                    _isRecurring = value;
                    if (!value) {
                      _recurringDays.clear();
                    }
                  });
                },
              ),
            ],
          ),

          // Recurring days selector
          if (_isRecurring) ...[
            const SizedBox(height: AppSpacing.space4),
            const Divider(),
            const SizedBox(height: AppSpacing.space3),
            Text(
              '반복 요일',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (index) {
                final isSelected = _recurringDays.contains(index);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _recurringDays.remove(index);
                      } else {
                        _recurringDays.add(index);
                      }
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surfaceSecondaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        dayNames[index],
                        style: AppTypography.bodySmall.copyWith(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondaryLight,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: AppSpacing.space3),
            Container(
              padding: const EdgeInsets.all(AppSpacing.space3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: Text(
                      '4주간의 레슨이 자동으로 예약됩니다',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
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
                onChanged: (value) => setState(() => _enableReminder = value),
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
            onTap: () => setState(() => _reminderMinutes = option.$1),
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
        onPressed: _saveLesson,
        child: Text(_isRecurring ? '정기 레슨 예약하기' : '레슨 추가하기'),
      ),
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
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ko'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
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
      setState(() => _selectedTime = picked);
    }
  }

  void _showStudentPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXLarge),
        ),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: AppSpacing.space2),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Text('학생 선택', style: AppTypography.headingMedium),
            ),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                itemCount: _mockStudents.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final student = _mockStudents[index];
                  final isSelected = _selectedStudent?.id == student.id;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: student.color.withValues(alpha: 0.2),
                      child: Text(
                        student.name[0],
                        style: AppTypography.bodyLarge.copyWith(
                          color: student.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    title: Text(student.name),
                    subtitle: Text('${student.instrument} · ${student.currentPiece}'),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: AppColors.primary)
                        : null,
                    onTap: () {
                      setState(() => _selectedStudent = student);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExitConfirmation(BuildContext context) {
    final hasData = _selectedStudent != null ||
        _pieceController.text.isNotEmpty ||
        _notesController.text.isNotEmpty;

    if (!hasData) {
      context.pop();
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('작성 취소'),
        content: const Text('입력한 내용이 저장되지 않습니다.\n정말 나가시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('계속 작성'),
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

  void _saveLesson() {
    if (_selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('학생을 선택해주세요'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_isRecurring && _recurringDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('반복 요일을 선택해주세요'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // TODO: Save lesson to database
    final lessonData = {
      'studentId': _selectedStudent!.id,
      'date': _selectedDate.toIso8601String(),
      'time': _formatTime(_selectedTime),
      'duration': _lessonDuration,
      'piece': _pieceController.text,
      'notes': _notesController.text,
      'isRecurring': _isRecurring,
      'recurringDays': _recurringDays.toList(),
      'enableReminder': _enableReminder,
      'reminderMinutes': _reminderMinutes,
    };

    debugPrint('Saving lesson: $lessonData');

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isRecurring
              ? '${_selectedStudent!.name} 학생의 정기 레슨이 예약되었습니다'
              : '${_selectedStudent!.name} 학생의 레슨이 추가되었습니다',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.practiceGood,
      ),
    );

    // Go back
    context.pop();
  }

  // Mock data
  List<_StudentInfo> get _mockStudents => [
        _StudentInfo(
          id: 'student_1',
          name: '홍길동',
          instrument: '바이올린',
          currentPiece: '바흐 파르티타 2번',
          color: Colors.blue,
        ),
        _StudentInfo(
          id: 'student_2',
          name: '김철수',
          instrument: '피아노',
          currentPiece: '쇼팽 에튀드 Op.10',
          color: Colors.green,
        ),
        _StudentInfo(
          id: 'student_3',
          name: '이영희',
          instrument: '첼로',
          currentPiece: '드보르작 첼로 협주곡',
          color: Colors.orange,
        ),
        _StudentInfo(
          id: 'student_4',
          name: '박민수',
          instrument: '플루트',
          currentPiece: '모차르트 플루트 협주곡',
          color: Colors.purple,
        ),
        _StudentInfo(
          id: 'student_5',
          name: '최지원',
          instrument: '바이올린',
          currentPiece: '비발디 사계 - 봄',
          color: Colors.teal,
        ),
      ];
}

class _StudentInfo {
  final String id;
  final String name;
  final String instrument;
  final String currentPiece;
  final Color color;

  _StudentInfo({
    required this.id,
    required this.name,
    required this.instrument,
    required this.currentPiece,
    required this.color,
  });
}
