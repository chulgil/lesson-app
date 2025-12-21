import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Screen for adding a new student
class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedInstrument;
  int _lessonDuration = 60;
  final Set<int> _selectedDays = {};
  TimeOfDay _lessonTime = const TimeOfDay(hour: 14, minute: 0);

  final List<String> _instruments = [
    '바이올린',
    '피아노',
    '첼로',
    '플루트',
    '클라리넷',
    '비올라',
    '기타',
    '성악',
    '드럼',
    '기타(직접입력)',
  ];

  final List<String> _dayNames = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('학생 추가'),
        leading: IconButton(
          onPressed: () => _showExitConfirmation(context),
          icon: const Icon(Icons.close),
        ),
        actions: [
          TextButton(
            onPressed: _saveStudent,
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
              // Profile photo section
              _buildProfileSection(),

              const SizedBox(height: AppSpacing.space6),

              // Basic info section
              _buildSectionTitle('기본 정보'),
              const SizedBox(height: AppSpacing.space3),
              _buildBasicInfoFields(),

              const SizedBox(height: AppSpacing.space6),

              // Parent/Guardian info section
              _buildSectionTitle('보호자 정보'),
              _buildSectionSubtitle('미성년 학생의 경우 입력해주세요'),
              const SizedBox(height: AppSpacing.space3),
              _buildParentInfoFields(),

              const SizedBox(height: AppSpacing.space6),

              // Instrument section
              _buildSectionTitle('악기'),
              const SizedBox(height: AppSpacing.space3),
              _buildInstrumentSelector(),

              const SizedBox(height: AppSpacing.space6),

              // Lesson schedule section
              _buildSectionTitle('레슨 일정'),
              const SizedBox(height: AppSpacing.space3),
              _buildScheduleSection(),

              const SizedBox(height: AppSpacing.space6),

              // Notes section
              _buildSectionTitle('메모'),
              _buildSectionSubtitle('레슨 시 참고할 내용을 입력해주세요'),
              const SizedBox(height: AppSpacing.space3),
              _buildNotesField(),

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

  Widget _buildProfileSection() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.surfaceSecondaryLight,
                child: Icon(
                  Icons.person,
                  size: 50,
                  color: AppColors.textTertiaryLight,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: IconButton(
                    onPressed: () {
                      // TODO: Pick image
                      _showImagePickerOptions();
                    },
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    iconSize: 20,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            '프로필 사진 추가',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTypography.headingSmall);
  }

  Widget _buildSectionSubtitle(String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        subtitle,
        style: AppTypography.caption.copyWith(
          color: AppColors.textSecondaryLight,
        ),
      ),
    );
  }

  Widget _buildBasicInfoFields() {
    return Column(
      children: [
        // Name
        TextFormField(
          controller: _nameController,
          decoration: _inputDecoration(
            label: '이름',
            hint: '학생 이름을 입력하세요',
            prefixIcon: Icons.person_outline,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '이름을 입력해주세요';
            }
            return null;
          },
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.space4),

        // Phone
        TextFormField(
          controller: _phoneController,
          decoration: _inputDecoration(
            label: '연락처',
            hint: '010-0000-0000',
            prefixIcon: Icons.phone_outlined,
          ),
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.space4),

        // Email
        TextFormField(
          controller: _emailController,
          decoration: _inputDecoration(
            label: '이메일',
            hint: 'email@example.com',
            prefixIcon: Icons.email_outlined,
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
      ],
    );
  }

  Widget _buildParentInfoFields() {
    return Column(
      children: [
        // Parent name
        TextFormField(
          controller: _parentNameController,
          decoration: _inputDecoration(
            label: '보호자 이름',
            hint: '보호자 이름을 입력하세요',
            prefixIcon: Icons.family_restroom,
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.space4),

        // Parent phone
        TextFormField(
          controller: _parentPhoneController,
          decoration: _inputDecoration(
            label: '보호자 연락처',
            hint: '010-0000-0000',
            prefixIcon: Icons.phone_outlined,
          ),
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
        ),
      ],
    );
  }

  Widget _buildInstrumentSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children: _instruments.map((instrument) {
            final isSelected = _selectedInstrument == instrument;
            return ChoiceChip(
              label: Text(instrument),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedInstrument = selected ? instrument : null;
                });
              },
              backgroundColor: AppColors.surfaceLight,
              selectedColor: AppColors.primary.withValues(alpha: 0.15),
              checkmarkColor: AppColors.primary,
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.borderLight,
              ),
              labelStyle: AppTypography.bodySmall.copyWith(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textPrimaryLight,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
        if (_selectedInstrument == null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.space2),
            child: Text(
              '악기를 선택해주세요',
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiaryLight,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildScheduleSection() {
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
          // Lesson days
          Text(
            '레슨 요일',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final isSelected = _selectedDays.contains(index);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedDays.remove(index);
                    } else {
                      _selectedDays.add(index);
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
                      _dayNames[index],
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

          const SizedBox(height: AppSpacing.space4),
          const Divider(),
          const SizedBox(height: AppSpacing.space4),

          // Lesson time
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '레슨 시간',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      '기본 레슨 시작 시간',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: OutlinedButton.icon(
                  onPressed: () => _selectTime(context),
                  icon: const Icon(Icons.access_time, size: 18),
                  label: Text(
                    _formatTime(_lessonTime),
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space4,
                      vertical: AppSpacing.space2,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space4),
          const Divider(),
          const SizedBox(height: AppSpacing.space4),

          // Lesson duration
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '레슨 시간 (분)',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      '1회 레슨 시간',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              _buildDurationSelector(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDurationSelector() {
    final durations = [30, 45, 60, 90, 120];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: durations.map((duration) {
          final isSelected = _lessonDuration == duration;
          return GestureDetector(
            onTap: () => setState(() => _lessonDuration = duration),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
              child: Text(
                '$duration',
                style: AppTypography.bodySmall.copyWith(
                  color: isSelected ? Colors.white : AppColors.textSecondaryLight,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: _inputDecoration(
        label: '메모',
        hint: '레슨 시 참고할 내용 (악기 상태, 연습 환경, 특이사항 등)',
        prefixIcon: Icons.note_alt_outlined,
      ),
      maxLines: 4,
      textInputAction: TextInputAction.done,
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: AppSpacing.buttonHeight,
      child: FilledButton(
        onPressed: _saveStudent,
        child: const Text('학생 추가하기'),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(prefixIcon),
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        borderSide: BorderSide(color: AppColors.error),
      ),
      filled: true,
      fillColor: AppColors.surfaceLight,
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _lessonTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _lessonTime = picked);
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXLarge),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: AppSpacing.space4),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('카메라로 촬영'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Open camera
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('갤러리에서 선택'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Open gallery
              },
            ),
            const SizedBox(height: AppSpacing.space4),
          ],
        ),
      ),
    );
  }

  void _showExitConfirmation(BuildContext context) {
    // Check if form has any data
    final hasData = _nameController.text.isNotEmpty ||
        _phoneController.text.isNotEmpty ||
        _emailController.text.isNotEmpty ||
        _selectedInstrument != null ||
        _selectedDays.isNotEmpty;

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

    // TODO: Save student to database
    final studentData = {
      'name': _nameController.text,
      'phone': _phoneController.text,
      'email': _emailController.text,
      'parentName': _parentNameController.text,
      'parentPhone': _parentPhoneController.text,
      'instrument': _selectedInstrument,
      'lessonDays': _selectedDays.map((i) => _dayNames[i]).toList(),
      'lessonTime': _formatTime(_lessonTime),
      'lessonDuration': _lessonDuration,
      'notes': _notesController.text,
    };

    debugPrint('Saving student: $studentData');

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_nameController.text} 학생이 추가되었습니다'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.practiceGood,
      ),
    );

    // Go back
    context.pop();
  }
}
