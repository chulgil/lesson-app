// Invite and connection route definitions

import 'package:go_router/go_router.dart';

import '../../../features/invite/presentation/screens/invite_screen.dart';
import '../../../features/invite/presentation/screens/scan_invite_screen.dart';
import '../../../features/invite/presentation/screens/code_input_screen.dart';
import '../../../features/invite/presentation/screens/invite_confirm_screen.dart';
import '../../../features/invite/presentation/screens/invite_history_screen.dart';
import '../../../features/invite/presentation/screens/pending_requests_screen.dart';
import '../../../features/invite/presentation/screens/my_connections_screen.dart';
import '../../../features/profile/domain/entities/invite.dart';
import '../app_routes.dart';

/// Invite and connection routes
List<GoRoute> inviteRoutes = [
  // Create/Share Invite
  GoRoute(
    path: AppRoutes.invite,
    name: 'invite',
    builder: (context, state) => const InviteScreen(),
  ),

  // Scan QR Code
  GoRoute(
    path: AppRoutes.inviteScan,
    name: 'inviteScan',
    builder: (context, state) => const ScanInviteScreen(),
  ),

  // Enter Code
  GoRoute(
    path: AppRoutes.inviteCode,
    name: 'inviteCode',
    // Deep links (lessonapp://invite/{code}) pass the 6-digit code via the
    // `?code=` query param so the field prefills + auto-verifies.
    builder: (context, state) =>
        CodeInputScreen(initialCode: state.uri.queryParameters['code']),
  ),

  // Confirm Connection
  GoRoute(
    path: AppRoutes.inviteConfirm,
    name: 'inviteConfirm',
    builder: (context, state) {
      // Nullable cast: the Invite extra can be lost (e.g. deep-link cold start,
      // process death). Fall back to code re-entry instead of crashing.
      final invite = state.extra as Invite?;
      if (invite == null) return const CodeInputScreen();
      return InviteConfirmScreen(invite: invite);
    },
  ),

  // Invite History
  GoRoute(
    path: AppRoutes.inviteHistory,
    name: 'inviteHistory',
    builder: (context, state) => const InviteHistoryScreen(),
  ),

  // Pending Requests
  GoRoute(
    path: AppRoutes.pendingRequests,
    name: 'pendingRequests',
    builder: (context, state) => const PendingRequestsScreen(),
  ),

  // My Connections
  GoRoute(
    path: AppRoutes.myConnections,
    name: 'myConnections',
    builder: (context, state) => const MyConnectionsScreen(),
  ),
];
