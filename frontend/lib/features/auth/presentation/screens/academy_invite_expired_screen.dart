import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../../core/widgets/notebook/paper_scaffold.dart';

/// Academy invite expired/error screen
class AcademyInviteExpiredScreen extends StatelessWidget {
  final String? errorCode;
  final String? errorMessage;

  const AcademyInviteExpiredScreen({
    super.key,
    this.errorCode,
    this.errorMessage,
  });

  String _getTitle() {
    if (errorCode == 'expired') {
      return '초대 만료';
    }
    return '유효하지 않은 초대';
  }

  String _getSubtitle() {
    if (errorCode == 'expired') {
      return '초대 링크가 만료되었습니다.';
    }
    if (errorCode == 'already_used') {
      return '이미 사용된 초대 링크입니다.';
    }
    return '유효하지 않은 초대 링크입니다.';
  }

  @override
  Widget build(BuildContext context) {
    return NotebookScreenScaffold(
      body: PaperScaffold(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppSpacing.space4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: AppSpacing.space4),
                Text(_getTitle(), style: AppTypography.bodyLarge),
                SizedBox(height: AppSpacing.space2),
                Text(_getSubtitle(), style: AppTypography.bodyMedium),
                if (errorMessage != null) ...[
                  SizedBox(height: AppSpacing.space2),
                  Container(
                    padding: EdgeInsets.all(AppSpacing.space2),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      errorMessage!,
                      style: AppTypography.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                SizedBox(height: AppSpacing.space5),
                Text(
                  '학원에 다시 초대 요청을 해주세요.',
                  style: AppTypography.bodySmall,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.space4),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go(AppRoutes.home),
                    child: const Text('홈으로 이동'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
