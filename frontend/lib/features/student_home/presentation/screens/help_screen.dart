// Help screen with FAQ accordion and support contact.

import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';

const _supportEmail = 'support@lessonaza.com';

const _faqItems = [
  (
    question: '레슨은 어떻게 예약하나요?',
    answer:
        '홈 화면에서 스케줄 탭을 선택한 후, 우측 상단의 \'예약\' 버튼을 탭하세요. '
        '선생님을 선택하고 원하는 시간을 골라 예약할 수 있습니다.',
  ),
  (
    question: '연습 기록은 어떻게 확인하나요?',
    answer:
        '하단 네비게이션의 \'연습\' 탭에서 날짜별 연습 기록을 확인할 수 있습니다. '
        '레퍼토리별로 섹션을 관리하고 완료 여부를 체크할 수 있습니다.',
  ),
  (
    question: '녹음 파일은 어떻게 백업하나요?',
    answer:
        '프로필 > 녹음 백업에서 전체 백업을 생성할 수 있습니다. '
        '백업 파일은 공유 기능으로 클라우드에 저장하세요.',
  ),
  (
    question: '메트로놈은 어떻게 사용하나요?',
    answer:
        '연습 화면에서 중앙 하단의 연습 도구 버튼을 탭하면 '
        '메트로놈, 튜너 등의 도구를 사용할 수 있습니다.',
  ),
  (
    question: '수강권이 만료되면 어떻게 되나요?',
    answer:
        '수강권이 만료되면 레슨 예약이 제한됩니다. '
        '선생님에게 새 수강권 발급을 요청하거나, '
        '홈 화면의 수강권 섹션에서 상태를 확인하세요.',
  ),
  (
    question: '학부모님을 어떻게 초대하나요?',
    answer:
        '프로필 탭에서 \'학부모 초대\'를 탭하면 초대 코드가 생성됩니다. '
        '코드를 학부모님께 공유하면 앱에서 연결됩니다.',
  ),
];

/// Help screen with FAQ and support contact.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return NotebookScreenScaffold(
      appBar: const NotebookDetailAppBar(
        title: AppStrings.studentHomeHelpTitle,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          // FAQ header
          // Notebook × Score: 페이지 섹션 제목은 Playfair sectionTitle 로 통일 (§7.17 패턴).
          Text(
            AppStrings.studentHomeFaqTitle,
            style: NotebookTypography.sectionTitle,
          ),
          const SizedBox(height: AppSpacing.space4),

          // FAQ items
          Container(
            decoration: BoxDecoration(
              color: AppColors.paper,
              border: Border.all(color: AppColors.inkQuaternary),
            ),
            child: Column(
              children: [
                for (var i = 0; i < _faqItems.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: AppSpacing.space4,
                      endIndent: AppSpacing.space4,
                      color: AppColors.inkQuaternary,
                    ),
                  _FaqTile(
                    question: _faqItems[i].question,
                    answer: _faqItems[i].answer,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.space8),

          // Support section
          Container(
            padding: const EdgeInsets.all(AppSpacing.space5),
            decoration: BoxDecoration(
              color: AppColors.paperDark,
              border: Border.all(color: AppColors.inkQuaternary),
            ),
            child: Column(
              children: [
                Icon(Icons.support_agent, size: 40, color: AppColors.ink),
                const SizedBox(height: AppSpacing.space3),
                Text(
                  AppStrings.studentHomeNeedHelp,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  _supportEmail,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                FilledButton.icon(
                  onPressed: () => _launchEmail(context),
                  icon: const Icon(Icons.email_outlined, size: 18),
                  label: const Text(AppStrings.studentHomeContactSupport),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchEmail(BuildContext context) async {
    final uri = Uri(scheme: 'mailto', path: _supportEmail);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.studentHomeCannotOpenEmail)),
      );
    }
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space1,
      ),
      childrenPadding: const EdgeInsets.fromLTRB(
        AppSpacing.space4,
        0,
        AppSpacing.space4,
        AppSpacing.space4,
      ),
      shape: const Border(),
      collapsedShape: const Border(),
      title: Text(
        question,
        style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500),
      ),
      children: [
        Text(
          answer,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.inkSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
