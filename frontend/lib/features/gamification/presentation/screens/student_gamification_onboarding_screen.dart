import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/notebook_screen_scaffold.dart';

/// 학생 게이미피케이션 P1 Onboarding 1화면.
///
/// 스펙 §4.6 / 플랜 Job 6 Task 6.1. 학생 첫 로그인 + [StudentQuest] 0개
/// 시 자동 진입. 악기 선택 + "오늘 한 가지" 추천 + 2 CTA.
class StudentGamificationOnboardingScreen extends StatefulWidget {
  /// 악기 선택 + CTA 결과 콜백. [acceptedRecommendation] true 면 추천 quest
  /// 수락 ("좋아! 시작하기"), false 면 본인 결정 ("내가 정할래").
  final void Function(String instrument, bool acceptedRecommendation) onResult;

  /// "오늘 한 가지" 추천 문구. O5 결정 default = '스케일 5분'.
  final String recommendation;

  /// 표시할 악기 선택지 (Hick's Law — 4 max + 기타 = 5).
  final List<String> instruments;

  const StudentGamificationOnboardingScreen({
    super.key,
    required this.onResult,
    this.recommendation = '스케일 5분',
    this.instruments = const ['바이올린', '피아노', '기타', '기타...'],
  });

  @override
  State<StudentGamificationOnboardingScreen> createState() =>
      _StudentGamificationOnboardingScreenState();
}

class _StudentGamificationOnboardingScreenState
    extends State<StudentGamificationOnboardingScreen> {
  String? _selectedInstrument;

  bool get _canProceed => _selectedInstrument != null;

  void _select(String instrument) {
    setState(() => _selectedInstrument = instrument);
  }

  void _confirm({required bool accepted}) {
    final inst = _selectedInstrument;
    if (inst == null) return;
    widget.onResult(inst, accepted);
  }

  @override
  Widget build(BuildContext context) {
    return NotebookScreenScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.space8),
              Text(
                key: const ValueKey('onboarding_greeting'),
                '안녕! 무슨 악기 해?',
                style: AppTypography.headingLarge,
              ),
              const SizedBox(height: AppSpacing.space5),
              Wrap(
                spacing: AppSpacing.space2,
                runSpacing: AppSpacing.space2,
                children: [
                  for (final inst in widget.instruments)
                    ChoiceChip(
                      key: ValueKey('instrument_$inst'),
                      label: Text(inst),
                      selected: _selectedInstrument == inst,
                      onSelected: (_) => _select(inst),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.space8),
              Text('오늘 한 가지 추천해줄게:', style: AppTypography.bodyMedium),
              const SizedBox(height: AppSpacing.space2),
              Text(
                key: const ValueKey('onboarding_recommendation'),
                '"${widget.recommendation}"',
                style: AppTypography.headingMedium,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeight,
                child: FilledButton(
                  key: const ValueKey('onboarding_accept'),
                  onPressed:
                      _canProceed ? () => _confirm(accepted: true) : null,
                  child: const Text('좋아! 시작하기'),
                ),
              ),
              const SizedBox(height: AppSpacing.space3),
              SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeight,
                child: OutlinedButton(
                  key: const ValueKey('onboarding_decline'),
                  onPressed:
                      _canProceed ? () => _confirm(accepted: false) : null,
                  child: const Text('내가 정할래'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
