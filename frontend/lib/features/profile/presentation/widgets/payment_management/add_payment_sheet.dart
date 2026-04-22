import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../../features/lessons/domain/entities/payment.dart';
import '../../../../lessons/presentation/providers/payment_providers.dart';
import '../../../../students/presentation/providers/student_crud_provider.dart';

/// Bottom sheet for adding a new payment.
class AddPaymentSheet extends ConsumerStatefulWidget {
  const AddPaymentSheet({super.key});

  @override
  ConsumerState<AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends ConsumerState<AddPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedStudentId;
  String? _selectedStudentName;
  PaymentType _paymentType = PaymentType.regular;
  int _amount = 200000;
  PaymentMethod _method = PaymentMethod.bankTransfer;
  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  int _weekStart = 1;
  int _weekEnd = 4;
  int _lessonCount = 4;
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController(text: '200000');

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _updateAmount() {
    if (_paymentType == PaymentType.trial) {
      _amount = 30000; // Default trial fee
      _amountController.text = '30000';
      _lessonCount = 1;
      _weekStart = _weekEnd; // Single week for trial
    } else {
      // Calculate based on weeks
      final weeks = _weekEnd - _weekStart + 1;
      _lessonCount = weeks;
      // Adjust amount proportionally if not full month
      if (weeks < 4) {
        _amount = (200000 / 4 * weeks).round();
        _amountController.text = _amount.toString();
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsProvider);

    return BottomSheetContainer(
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              const BottomSheetHandle(),
              _buildSheetHeader(),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPaymentTypeSelector(),
                        const SizedBox(height: AppSpacing.space5),
                        _buildStudentSelector(studentsAsync),
                        const SizedBox(height: AppSpacing.space5),
                        if (_paymentType == PaymentType.regular)
                          _buildPeriodSelector(),
                        if (_paymentType == PaymentType.trial)
                          _buildTrialDateSelector(),
                        _buildAmountField(),
                        const SizedBox(height: AppSpacing.space5),
                        _buildPaymentMethodSelector(),
                        const SizedBox(height: AppSpacing.space5),
                        _buildDescriptionField(),
                        const SizedBox(height: AppSpacing.space6),
                        _buildSubmitButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSheetHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('결제 추가', style: AppTypography.headingMedium),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '결제 유형',
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.space2),
        Row(
          children: [
            Expanded(
              child: _PaymentTypeCard(
                type: PaymentType.regular,
                icon: Icons.event_repeat,
                description: '월별 정기 레슨',
                isSelected: _paymentType == PaymentType.regular,
                onTap: () {
                  setState(() {
                    _paymentType = PaymentType.regular;
                    _updateAmount();
                  });
                },
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: _PaymentTypeCard(
                type: PaymentType.trial,
                icon: Icons.music_note,
                description: '1회 체험 레슨',
                isSelected: _paymentType == PaymentType.trial,
                onTap: () {
                  setState(() {
                    _paymentType = PaymentType.trial;
                    _updateAmount();
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStudentSelector(AsyncValue<List<dynamic>> studentsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '학생 선택',
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.space2),
        studentsAsync.when(
          data:
              (students) => DropdownButtonFormField<String>(
                initialValue: _selectedStudentId,
                decoration: const InputDecoration(
                  hintText: '학생을 선택하세요',
                  border: OutlineInputBorder(),
                ),
                items:
                    students.map((s) {
                      return DropdownMenuItem<String>(
                        value: s.id,
                        child: Text('${s.name} (${s.level.label})'),
                      );
                    }).toList(),
                onChanged: (value) {
                  final student = students.firstWhere((s) => s.id == value);
                  setState(() {
                    _selectedStudentId = value;
                    _selectedStudentName = student.name;
                    if (_paymentType == PaymentType.regular) {
                      _amount = student.monthlyFee;
                      _amountController.text = _amount.toString();
                    }
                  });
                },
                validator: (value) {
                  if (value == null) return '학생을 선택하세요';
                  return null;
                },
              ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('학생 목록을 불러올 수 없습니다'),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '기간 선택',
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.space2),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showMonthSelector,
                icon: const Icon(Icons.calendar_month),
                label: Text('${_selectedMonth.year}년 ${_selectedMonth.month}월'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),
        Text(
          '주차 범위',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        _buildWeekRangeSelector(),
        const SizedBox(height: AppSpacing.space2),
        _buildPeriodInfoBanner(),
        const SizedBox(height: AppSpacing.space5),
      ],
    );
  }

  Widget _buildWeekRangeSelector() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            initialValue: _weekStart,
            decoration: const InputDecoration(
              labelText: '시작',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
                vertical: AppSpacing.space2,
              ),
            ),
            items:
                List.generate(5, (i) => i + 1).map((week) {
                  return DropdownMenuItem(value: week, child: Text('$week주'));
                }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _weekStart = value;
                  if (_weekEnd < value) _weekEnd = value;
                });
                _updateAmount();
              }
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.space2),
          child: Text('~'),
        ),
        Expanded(
          child: DropdownButtonFormField<int>(
            initialValue: _weekEnd,
            decoration: const InputDecoration(
              labelText: '종료',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
                vertical: AppSpacing.space2,
              ),
            ),
            items:
                List.generate(
                  5,
                  (i) => i + 1,
                ).where((w) => w >= _weekStart).map((week) {
                  return DropdownMenuItem(value: week, child: Text('$week주'));
                }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _weekEnd = value);
                _updateAmount();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: AppColors.primary),
          const SizedBox(width: AppSpacing.space2),
          Text(
            '${_weekEnd - _weekStart + 1}주 · $_lessonCount회 레슨',
            style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildTrialDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '체험 일자',
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.space2),
        OutlinedButton.icon(
          onPressed: _showDatePicker,
          icon: const Icon(Icons.event),
          label: Text('${_selectedMonth.month}월 ${_selectedMonth.day}일'),
        ),
        const SizedBox(height: AppSpacing.space5),
      ],
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '금액',
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.space2),
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: '금액을 입력하세요',
            suffixText: '원',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            _amount = int.tryParse(value) ?? 0;
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '금액을 입력하세요';
            }
            if (int.tryParse(value) == null) {
              return '올바른 금액을 입력하세요';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '결제 수단',
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.space2),
        Wrap(
          spacing: AppSpacing.space2,
          children:
              PaymentMethod.values.map((method) {
                final isSelected = _method == method;
                return ChoiceChip(
                  label: Text(method.label),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _method = method);
                    }
                  },
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '메모 (선택)',
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.space2),
        TextFormField(
          controller: _descriptionController,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: '메모를 입력하세요',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _submit,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
        ),
        child: Text(
          _paymentType == PaymentType.trial ? '체험 레슨 결제 추가' : '정규 레슨 결제 추가',
        ),
      ),
    );
  }

  Future<void> _showMonthSelector() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(now.year - 1, 1),
      lastDate: DateTime(now.year + 1, 12),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (selected != null) {
      setState(() {
        _selectedMonth = DateTime(selected.year, selected.month, 1);
      });
    }
  }

  Future<void> _showDatePicker() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(now.year - 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (selected != null) {
      setState(() {
        _selectedMonth = selected;
        // Calculate week of month
        final firstDay = DateTime(selected.year, selected.month, 1);
        _weekStart = ((selected.day + firstDay.weekday - 1) / 7).ceil();
        _weekEnd = _weekStart;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStudentId == null) return;

    DateTime periodStart;
    DateTime periodEnd;

    if (_paymentType == PaymentType.trial) {
      periodStart = _selectedMonth;
      periodEnd = _selectedMonth;
    } else {
      // Calculate period based on weeks
      final weekStartDay = ((_weekStart - 1) * 7) + 1;
      final weekEndDay = (_weekEnd * 7).clamp(1, 31);
      periodStart = DateTime(
        _selectedMonth.year,
        _selectedMonth.month,
        weekStartDay,
      );
      periodEnd = DateTime(
        _selectedMonth.year,
        _selectedMonth.month,
        weekEndDay,
      );
    }

    final payment = Payment(
      id: '',
      studentId: _selectedStudentId!,
      studentName: _selectedStudentName ?? '',
      type: _paymentType,
      amount: _amount,
      status: PaymentStatus.pending,
      method: _method,
      paymentDate: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 7)),
      lessonCount: _lessonCount,
      periodStart: periodStart,
      periodEnd: periodEnd,
      weekStart: _weekStart,
      weekEnd: _weekEnd,
      description:
          _descriptionController.text.isNotEmpty
              ? _descriptionController.text
              : null,
      createdAt: DateTime.now(),
    );

    await ref.read(paymentsNotifierProvider.notifier).addPayment(payment);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _paymentType == PaymentType.trial
                ? '체험 레슨 결제가 추가되었습니다'
                : '정규 레슨 결제가 추가되었습니다',
          ),
        ),
      );
    }
  }
}

/// Card for selecting payment type (regular/trial).
class _PaymentTypeCard extends StatelessWidget {
  const _PaymentTypeCard({
    required this.type,
    required this.icon,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  final PaymentType type;
  final IconData icon;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        type == PaymentType.trial ? AppColors.ink : AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? color.withValues(alpha: 0.1)
                  : AppColors.paper,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(
            color: isSelected ? color : AppColors.inkQuaternary,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : AppColors.inkSecondary,
              size: 28,
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              type.label,
              style: AppTypography.bodyMedium.copyWith(
                color: isSelected ? color : AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              description,
              style: AppTypography.caption.copyWith(
                color:
                    isSelected
                        ? color.withValues(alpha: 0.8)
                        : AppColors.inkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
