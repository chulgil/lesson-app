import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../students/domain/entities/student.dart';

/// 연락처·메모 카드 — 정보 탭 최상단 (#24/#25).
///
/// 학생/학부모 전화(탭 → 전화·문자), 주소(탭 → 지도), 등록 메모(학생 메모) 전문 표시.
/// 표시 전용: 개인정보 Level 2 (연결된 교사 읽기 권한). 수집/변경/공유 설정 없음.
/// 표시할 항목이 하나도 없으면 렌더하지 않는다(빈 카드 방지).
class StudentContactCard extends StatelessWidget {
  final Student student;

  const StudentContactCard({super.key, required this.student});

  bool _has(String? v) => v != null && v.isNotEmpty;

  bool get _hasContent =>
      _has(student.phone) ||
      _has(student.parentPhone) ||
      _has(student.fullAddress) ||
      _has(student.notes);

  Future<void> _launch(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasContent) return const SizedBox.shrink();

    final rows = <Widget>[];

    if (_has(student.phone)) {
      rows.add(
        _ContactRow(
          label: AppStrings.studentContactStudentLabel,
          value: student.phone!,
          onCall: () => _launch(Uri(scheme: 'tel', path: student.phone)),
          onSms: () => _launch(Uri(scheme: 'sms', path: student.phone)),
        ),
      );
    }

    if (_has(student.parentPhone)) {
      final label = _has(student.parentName)
          ? '${AppStrings.studentContactParentLabel} · ${student.parentName}'
          : AppStrings.studentContactParentLabel;
      rows.add(
        _ContactRow(
          label: label,
          value: student.parentPhone!,
          onCall: () => _launch(Uri(scheme: 'tel', path: student.parentPhone)),
          onSms: () => _launch(Uri(scheme: 'sms', path: student.parentPhone)),
        ),
      );
    }

    if (_has(student.fullAddress)) {
      rows.add(
        _ContactRow(
          label: AppStrings.studentContactAddressLabel,
          value: student.fullAddress!,
          onTap: () => _launch(
            Uri.parse(
              'https://maps.google.com/?q=${Uri.encodeComponent(student.fullAddress!)}',
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.studentContactSectionTitle,
            style: AppTypography.headingSmall.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: AppSpacing.space3),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.space3),
            rows[i],
          ],
          if (_has(student.notes)) ...[
            if (rows.isNotEmpty) const SizedBox(height: AppSpacing.space3),
            Text(
              AppStrings.studentContactMemoLabel,
              style: AppTypography.caption.copyWith(
                color: AppColors.inkTertiary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              student.notes!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 한 줄 연락처 항목: 라벨 + 값 + (전화/문자) 또는 (탭 → 지도).
class _ContactRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onCall;
  final VoidCallback? onSms;
  final VoidCallback? onTap;

  const _ContactRow({
    required this.label,
    required this.value,
    this.onCall,
    this.onSms,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
        ),
      ],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: onTap != null ? InkWell(onTap: onTap, child: info) : info,
        ),
        if (onCall != null)
          IconButton(
            onPressed: onCall,
            icon: const Icon(Icons.call, size: 20),
            color: AppColors.paperAccent,
            tooltip: AppStrings.callAction,
            visualDensity: VisualDensity.compact,
          ),
        if (onSms != null)
          IconButton(
            onPressed: onSms,
            icon: const Icon(Icons.sms_outlined, size: 20),
            color: AppColors.ink,
            tooltip: AppStrings.smsAction,
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}
