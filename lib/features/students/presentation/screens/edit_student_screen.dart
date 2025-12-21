import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/student.dart';

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
  int _lessonsPerWeek = 1; // 1 = 주 1회 (월 4회), 2 = 주 2회 (월 8회)
  int _lessonDuration = 60;
  final Set<int> _selectedDays = {};
  TimeOfDay _lessonTime = const TimeOfDay(hour: 14, minute: 0);

  bool _isLoading = true;
  bool _hasChanges = false;

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
  void initState() {
    super.initState();
    _loadStudentData();
  }

  void _loadStudentData() {
    // TODO: Load from database
    // Mock data for now
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
          _lessonsPerWeek = 1; // Default: 주 1회 (월 4회)
          _monthlyFeeController.text =
              _selectedLevel.defaultMonthlyFee.toString();
          _selectedDays.addAll([0, 2]); // Mon, Wed
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
          onPressed: () => _showExitConfirmation(context),
          icon: const Icon(Icons.close),
        ),
        actions: [
          IconButton(
            onPressed: () => _showDeleteConfirmation(context),
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

              // Level and tuition section
              _buildSectionTitle('레벨 및 수강료'),
              _buildSectionSubtitle('레벨에 따라 기본 수강료가 설정됩니다'),
              const SizedBox(height: AppSpacing.space3),
              _buildLevelAndTuitionSection(),

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

              const SizedBox(height: AppSpacing.space4),

              // Delete button
              _buildDeleteButton(),

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
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  _nameController.text.isNotEmpty
                      ? _nameController.text[0]
                      : '?',
                  style: AppTypography.displayMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
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
            '프로필 사진 변경',
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
                  _hasChanges = true;
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
      ],
    );
  }

  Widget _buildLevelAndTuitionSection() {
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
          // Level selector
          Text(
            '레벨',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          Wrap(
            spacing: AppSpacing.space2,
            runSpacing: AppSpacing.space2,
            children: StudentLevel.values.map((level) {
              final isSelected = _selectedLevel == level;
              return ChoiceChip(
                label: Text(level.label),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedLevel = level;
                      _monthlyFeeController.text =
                          level.defaultMonthlyFee.toString();
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
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textPrimaryLight,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: AppSpacing.space4),
          const Divider(),
          const SizedBox(height: AppSpacing.space4),

          // Monthly fee
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '월 수강료',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      '기본: ${_formatCurrencyInMan(_selectedLevel.defaultMonthlyFee)}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 140,
                    child: TextFormField(
                      controller: _monthlyFeeController,
                      decoration: InputDecoration(
                        suffixText: '원',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.space3,
                          vertical: AppSpacing.space2,
                        ),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMedium),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMedium),
                          borderSide:
                              const BorderSide(color: AppColors.borderLight),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      textAlign: TextAlign.end,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      onChanged: (_) {
                        _markChanged();
                        setState(() {}); // Rebuild to update preview
                      },
                    ),
                  ),
                  // 만원 단위 미리보기
                  if (_monthlyFeeController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _formatCurrencyInMan(
                          int.tryParse(_monthlyFeeController.text) ?? 0,
                        ),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space4),
          const Divider(),
          const SizedBox(height: AppSpacing.space4),

          // Lesson frequency selector
          Text(
            '레슨 횟수',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            '주 1회는 월 4회, 주 2회는 월 8회 레슨입니다',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          Row(
            children: [
              Expanded(
                child: _buildFrequencyOption(
                  value: 1,
                  title: '주 1회',
                  subtitle: '월 4회',
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: _buildFrequencyOption(
                  value: 2,
                  title: '주 2회',
                  subtitle: '월 8회',
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space4),

          // Info about custom fee
          Container(
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Text(
                    '수강료를 직접 수정하면 레벨 기본값과 다르게 설정됩니다',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyOption({
    required int value,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _lessonsPerWeek == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _lessonsPerWeek = value;
          _hasChanges = true;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space3,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surfaceSecondaryLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected) ...[
              Icon(
                Icons.check_circle,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.space2),
            ],
            Column(
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Format amount in 만원 units (e.g., 200000 -> "20만원", 65000 -> "6.5만원")
  String _formatCurrencyInMan(int amount) {
    final manWon = amount / 10000;
    if (manWon == manWon.toInt()) {
      return '${manWon.toInt()}만원';
    } else {
      // Show one decimal place for partial amounts
      return '${manWon.toStringAsFixed(1)}만원';
    }
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
                    _hasChanges = true;
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
            onTap: () {
              setState(() {
                _lessonDuration = duration;
                _hasChanges = true;
              });
            },
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
        onPressed: _hasChanges ? _saveStudent : null,
        child: const Text('변경사항 저장'),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return SizedBox(
      width: double.infinity,
      height: AppSpacing.buttonHeight,
      child: OutlinedButton.icon(
        onPressed: () => _showDeleteConfirmation(context),
        icon: Icon(Icons.delete_outline, color: AppColors.error),
        label: Text(
          '학생 삭제',
          style: TextStyle(color: AppColors.error),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
        ),
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
      setState(() {
        _lessonTime = picked;
        _hasChanges = true;
      });
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
            ListTile(
              leading: Icon(Icons.delete, color: AppColors.error),
              title: Text('사진 삭제', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                // TODO: Remove photo
              },
            ),
            const SizedBox(height: AppSpacing.space4),
          ],
        ),
      ),
    );
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

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('학생 삭제'),
        content: Text(
          '${_nameController.text} 학생을 삭제하시겠습니까?\n\n'
          '관련된 모든 레슨 기록과 연습 기록이 함께 삭제됩니다.\n'
          '이 작업은 되돌릴 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteStudent();
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

  void _deleteStudent() {
    // TODO: Delete student from database

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_nameController.text} 학생이 삭제되었습니다'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Go back to students list
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
    final monthlyFee = int.tryParse(_monthlyFeeController.text) ??
        _selectedLevel.defaultMonthlyFee;

    final studentData = {
      'id': widget.studentId,
      'name': _nameController.text,
      'phone': _phoneController.text,
      'email': _emailController.text,
      'parentName': _parentNameController.text,
      'parentPhone': _parentPhoneController.text,
      'instrument': _selectedInstrument,
      'level': _selectedLevel.name,
      'monthlyFee': monthlyFee,
      'lessonsPerWeek': _lessonsPerWeek,
      'lessonDays': _selectedDays.map((i) => _dayNames[i]).toList(),
      'lessonTime': _formatTime(_lessonTime),
      'lessonDuration': _lessonDuration,
      'notes': _notesController.text,
    };

    debugPrint('Updating student: $studentData');

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_nameController.text} 학생 정보가 수정되었습니다'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.practiceGood,
      ),
    );

    // Go back
    context.pop();
  }
}
