import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../models/student.dart';
import '../widgets/student_form_widgets.dart';

/// Screen for editing an existing student
class EditStudentScreen extends StatefulWidget {
  final String studentId;

  const EditStudentScreen({
    super.key,
    required this.studentId,
  });

  @override
  State<EditStudentScreen> createState() => _EditStudentScreenState();
}

class _EditStudentScreenState extends State<EditStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _monthlyFeeController = TextEditingController();

  String? _selectedInstrument;
  StudentLevel _selectedLevel = StudentLevel.intermediate;
  int _lessonsPerWeek = 1;
  int _lessonDuration = 60;
  final Set<int> _selectedDays = {};
  TimeOfDay _lessonTime = const TimeOfDay(hour: 14, minute: 0);

  bool _isLoading = true;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  void _loadStudentData() {
    // TODO: Load from database
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _nameController.text = '홍길동';
          _phoneController.text = '010-1234-5678';
          _emailController.text = 'student@example.com';
          _parentNameController.text = '홍부모';
          _parentPhoneController.text = '010-9876-5432';
          _selectedInstrument = '바이올린';
          _selectedLevel = StudentLevel.intermediate;
          _lessonsPerWeek = 1;
          _monthlyFeeController.text =
              _selectedLevel.defaultMonthlyFee.toString();
          _selectedDays.addAll([0, 2]);
          _lessonTime = const TimeOfDay(hour: 14, minute: 0);
          _lessonDuration = 60;
          _notesController.text = '바흐 파르티타 연습 중';
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _notesController.dispose();
    _monthlyFeeController.dispose();
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
        appBar: AppBar(title: const Text('학생 수정')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('학생 수정'),
        leading: IconButton(
          onPressed: () => showExitConfirmation(
            context,
            hasChanges: _hasChanges,
            onExit: () => context.pop(),
          ),
          icon: const Icon(Icons.close),
        ),
        actions: [
          IconButton(
            onPressed: () => showDeleteStudentConfirmation(
              context,
              studentName: _nameController.text,
              onDelete: _deleteStudent,
            ),
            icon: Icon(Icons.delete_outline, color: AppColors.error),
            tooltip: '학생 삭제',
          ),
          TextButton(
            onPressed: _hasChanges ? _saveStudent : null,
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
              // Profile photo section
              StudentProfileSection(
                displayName: _nameController.text,
                onTapPhoto: () => showImagePickerOptions(context),
              ),

              const SizedBox(height: AppSpacing.space6),

              // Basic info section
              const FormSectionTitle('기본 정보'),
              const SizedBox(height: AppSpacing.space3),
              BasicInfoFields(
                nameController: _nameController,
                phoneController: _phoneController,
                emailController: _emailController,
              ),

              const SizedBox(height: AppSpacing.space6),

              // Parent/Guardian info section
              const FormSectionTitle('보호자 정보'),
              const FormSectionSubtitle('미성년 학생의 경우 입력해주세요'),
              const SizedBox(height: AppSpacing.space3),
              ParentInfoFields(
                parentNameController: _parentNameController,
                parentPhoneController: _parentPhoneController,
              ),

              const SizedBox(height: AppSpacing.space6),

              // Instrument section
              const FormSectionTitle('악기'),
              const SizedBox(height: AppSpacing.space3),
              InstrumentSelector(
                selectedInstrument: _selectedInstrument,
                onChanged: (value) {
                  setState(() {
                    _selectedInstrument = value;
                    _hasChanges = true;
                  });
                },
              ),

              const SizedBox(height: AppSpacing.space6),

              // Level and tuition section
              const FormSectionTitle('레벨 및 수강료'),
              const FormSectionSubtitle('레벨에 따라 기본 수강료가 설정됩니다'),
              const SizedBox(height: AppSpacing.space3),
              LevelAndTuitionSection(
                selectedLevel: _selectedLevel,
                onLevelChanged: (level) {
                  setState(() {
                    _selectedLevel = level;
                    _monthlyFeeController.text =
                        level.defaultMonthlyFee.toString();
                    _hasChanges = true;
                  });
                },
                feeController: _monthlyFeeController,
                lessonsPerWeek: _lessonsPerWeek,
                onFrequencyChanged: (value) {
                  setState(() {
                    _lessonsPerWeek = value;
                    _hasChanges = true;
                  });
                },
                onFeeChanged: () {
                  _markChanged();
                  setState(() {});
                },
              ),

              const SizedBox(height: AppSpacing.space6),

              // Lesson schedule section
              const FormSectionTitle('레슨 일정'),
              const SizedBox(height: AppSpacing.space3),
              ScheduleSection(
                selectedDays: _selectedDays,
                onDayToggle: (index) {
                  setState(() {
                    if (_selectedDays.contains(index)) {
                      _selectedDays.remove(index);
                    } else {
                      _selectedDays.add(index);
                    }
                    _hasChanges = true;
                  });
                },
                lessonTime: _lessonTime,
                onTimeTap: () async {
                  final picked = await selectTime(context, _lessonTime);
                  if (picked != null) {
                    setState(() {
                      _lessonTime = picked;
                      _hasChanges = true;
                    });
                  }
                },
                lessonDuration: _lessonDuration,
                onDurationChanged: (value) {
                  setState(() {
                    _lessonDuration = value;
                    _hasChanges = true;
                  });
                },
              ),

              const SizedBox(height: AppSpacing.space6),

              // Notes section
              const FormSectionTitle('메모'),
              const FormSectionSubtitle('레슨 시 참고할 내용을 입력해주세요'),
              const SizedBox(height: AppSpacing.space3),
              NotesField(controller: _notesController),

              const SizedBox(height: AppSpacing.space8),

              // Save button
              SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeight,
                child: FilledButton(
                  onPressed: _hasChanges ? _saveStudent : null,
                  child: const Text('변경사항 저장'),
                ),
              ),

              const SizedBox(height: AppSpacing.space4),

              // Delete button
              SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeight,
                child: OutlinedButton.icon(
                  onPressed: () => showDeleteStudentConfirmation(
                    context,
                    studentName: _nameController.text,
                    onDelete: _deleteStudent,
                  ),
                  icon: Icon(Icons.delete_outline, color: AppColors.error),
                  label: Text(
                    '학생 삭제',
                    style: TextStyle(color: AppColors.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.space6),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteStudent() {
    // TODO: Delete student from database

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_nameController.text} 학생이 삭제되었습니다'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    context.pop();
  }

  void _saveStudent() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedInstrument == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('악기를 선택해주세요'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // TODO: Update student in database
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_nameController.text} 학생 정보가 수정되었습니다'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.practiceGood,
      ),
    );

    context.pop();
  }
}
