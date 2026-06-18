import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';

/// Neutral loading screen shown while the app restores the auth session.
///
/// The router starts here ([AppRoutes.splash]) instead of the login screen so
/// that, on relaunch, a logged-in user does not see the login screen flash
/// before [AuthLoading] resolves. Once auth state is determined the redirect
/// sends the user to their home route (authenticated) or to login
/// (unauthenticated) — see `resolveAuthRedirect`.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const NotebookScreenScaffold(
      body: Center(
        child: CircularProgressIndicator(color: AppColors.paperAccent),
      ),
    );
  }
}
