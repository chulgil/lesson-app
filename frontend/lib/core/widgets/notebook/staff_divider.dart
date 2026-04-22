import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';

/// 5선 오선지 + 높은음자리표(𝄞) + 옵션 템포 마킹.
///
/// Notebook × Score 섹션 구분선. `design-plan/hybrid/primitives.jsx` StaffDivider 포트.
///
/// 사용 예시:
/// ```dart
/// const StaffDivider()              // 순수 오선
/// const StaffDivider(showTempo: true) // "♩ = 92" 템포 표시
/// ```
class StaffDivider extends StatelessWidget {
  /// 우측 템포 마킹(♩ = 92) 노출 여부.
  final bool showTempo;

  /// 템포 텍스트. 기본 '♩ = 92'.
  final String tempoText;

  /// 오선 전체 높이. 기본 22.
  final double height;

  const StaffDivider({
    super.key,
    this.showTempo = false,
    this.tempoText = '♩ = 92',
    this.height = 22,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _StaffPainter(),
        child:
            showTempo
                ? Padding(
                  padding: const EdgeInsets.only(left: 52, top: 3),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      tempoText,
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 9,
                        color: AppColors.inkSecondary,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                )
                : null,
      ),
    );
  }
}

class _StaffPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint =
        Paint()
          ..color = AppColors.ink.withValues(alpha: 0.45)
          ..strokeWidth = 0.8
          ..style = PaintingStyle.stroke;

    // 오선 5줄. primitives.jsx 의 y 오프셋 [0, 4, 8, 12, 16] + top:3
    const offsets = [0.0, 4.0, 8.0, 12.0, 16.0];
    for (final y in offsets) {
      final yPos = y + 3;
      canvas.drawLine(Offset(28, yPos), Offset(size.width, yPos), linePaint);
    }

    // 오른쪽 끝 두 줄 세로선 (섹션 종료 바).
    final barPaint =
        Paint()
          ..color = AppColors.ink
          ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(size.width - 1.4, 3, 1.4, 16), barPaint);
    canvas.drawRect(Rect.fromLTWH(size.width - 4.2, 3, 0.8, 16), barPaint);

    // 높은음자리표 𝄞 — TextPainter 로 그린다.
    final clef = TextPainter(
      text: TextSpan(
        text: '\u{1D11E}', // 𝄞
        style: TextStyle(
          fontSize: 34,
          color: AppColors.ink,
          height: 1,
          fontFamily: 'serif',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    clef.paint(canvas, const Offset(6, -10));
  }

  @override
  bool shouldRepaint(covariant _StaffPainter oldDelegate) => false;
}
