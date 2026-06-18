import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';

/// #779 — 신원 스트립 전화/문자 1탭 단축 버튼.
///
/// 매일 쓰는 전화·문자를 more(...) 메뉴(2탭)에서 상단 신원 스트립(1탭)으로 승격.
/// 전화번호가 없으면 아무것도 렌더하지 않는다(편집에서 등록 유도).
class StudentContactActions extends StatelessWidget {
  final String? phone;

  const StudentContactActions({super.key, required this.phone});

  @override
  Widget build(BuildContext context) {
    final number = phone;
    if (number == null || number.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ContactButton(
          icon: Icons.phone_outlined,
          label: AppStrings.studentContactCallShort,
          onTap: () => launchUrl(Uri.parse('tel:$number')),
        ),
        const SizedBox(width: AppSpacing.space3),
        _ContactButton(
          icon: Icons.message_outlined,
          label: AppStrings.studentContactMessageShort,
          onTap: () => launchUrl(Uri.parse('sms:$number')),
        ),
      ],
    );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: AppColors.ink),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        // Row 내 컴팩트 배치 — 테마 minimumSize Size(∞,h) 크래시 회피.
        minimumSize: const Size(0, AppSpacing.buttonHeightSmall),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
      ),
    );
  }
}
