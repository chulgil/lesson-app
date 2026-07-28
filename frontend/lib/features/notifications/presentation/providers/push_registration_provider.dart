import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import 'notification_providers.dart';

part 'push_registration_provider.g.dart';

/// The FCM initialization entry point, indirected through a provider so tests
/// can substitute it without a real Firebase instance (FcmService binds
/// `FirebaseMessaging.instance` directly).
typedef PushInitializer = Future<void> Function();

@Riverpod(keepAlive: true)
PushInitializer pushInitializer(Ref ref) {
  return ref.read(fcmServiceProvider).initialize;
}

/// The FCM token-unregistration entry point, indirected for the same reason as
/// [PushInitializer].
typedef PushUnregistrar = Future<void> Function();

@Riverpod(keepAlive: true)
PushUnregistrar pushUnregistrar(Ref ref) {
  return ref.read(fcmServiceProvider).unregisterToken;
}

/// Registers the device for push once the user finishes onboarding (#475).
///
/// Wired in `main.dart` to fire when auth reaches [AuthAuthenticated], so the
/// OS notification-permission prompt appears *after* onboarding — never at
/// cold start before the user understands why. Guarded to run at most once per
/// session and skipped in mock mode (no backend to register the token with).
@Riverpod(keepAlive: true)
class PushRegistration extends _$PushRegistration {
  bool _started = false;

  @override
  void build() {}

  /// Idempotent per session. Firebase/APNs may be unconfigured (getToken can
  /// throw) — failures are swallowed so push setup never blocks the app.
  Future<void> ensureStarted() async {
    if (_started) return;
    _started = true;

    if (ref.read(mockDataModeProvider)) return;

    try {
      await ref.read(pushInitializerProvider)();
    } catch (_) {
      // Non-blocking: push is best-effort until Firebase console setup is done.
    }
  }
}
