import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Show a success snackbar with green background.
void showSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppColors.success,
    ),
  );
}

/// Show an error snackbar with red background.
void showErrorSnackBar(BuildContext context, [String message = '오류가 발생했습니다']) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppColors.error,
    ),
  );
}

/// Show an info snackbar with muted background.
void showInfoSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppColors.textSecondaryLight,
    ),
  );
}
