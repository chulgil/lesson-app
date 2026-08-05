import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../l10n/app_strings.dart';

/// Shows a microphone-permission-denied SnackBar (#1197).
///
/// When the OS permission is *permanently* denied (the user picked "Don't
/// allow" or turned it off in Settings), a plain "권한 필요" toast is a soft
/// dead-end — re-tapping never re-prompts, so the user must leave the app and
/// hunt for Settings. This adds a '설정 열기' action that opens the app's OS
/// settings page directly via [openAppSettings], so recovery stays in-app.
///
/// For a first (non-permanent) denial the action is omitted — re-tapping the
/// mic control re-prompts, so no Settings trip is needed.
Future<void> showMicPermissionDeniedSnackBar(BuildContext context) async {
  final permanentlyDenied = await Permission.microphone.isPermanentlyDenied;
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        permanentlyDenied
            ? AppStrings.micPermissionSettingsGuide
            : AppStrings.micPermissionNeeded,
      ),
      action:
          permanentlyDenied
              ? SnackBarAction(
                label: AppStrings.openSettings,
                onPressed: () => openAppSettings(),
              )
              : null,
    ),
  );
}
