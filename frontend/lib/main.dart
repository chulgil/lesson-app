import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import 'core/auth/auth_state.dart';
import 'core/deep_link/deep_link_handler.dart';
import 'core/l10n/app_strings.dart';
import 'core/l10n/generated/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/startup/app_bootstrap.dart';
import 'core/startup/startup_provider_observer.dart';
import 'core/startup/startup_recovery.dart' as startup_recovery;
import 'core/theme/app_theme.dart';
import 'core/sync/application/sync_service.dart';
import 'core/sync/presentation/providers/sync_provider.dart';
import 'core/widgets/offline_banner.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/notifications/notifications_facade.dart';
import 'features/practice/presentation/providers/metronome_provider.dart';
import 'features/practice/presentation/providers/recording_provider.dart';
import 'features/practice/presentation/providers/tuner_provider.dart';
import 'features/settings/presentation/widgets/force_update_gate.dart';

/// Get the startup recovery result.
startup_recovery.StartupRecoveryResult? getStartupRecoveryResult() =>
    startup_recovery.getStartupRecoveryResult();

/// Clear the startup recovery result after showing.
void clearStartupRecoveryResult() {
  startup_recovery.clearStartupRecoveryResult();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrapApp();

  runApp(
    ProviderScope(observers: providerObservers(), child: const LessonazaApp()),
  );
}

class LessonazaApp extends ConsumerStatefulWidget {
  const LessonazaApp({super.key});

  @override
  ConsumerState<LessonazaApp> createState() => _LessonazaAppState();
}

class _LessonazaAppState extends ConsumerState<LessonazaApp>
    with WidgetsBindingObserver {
  DeepLinkHandler? _deepLinkHandler;

  /// Single router instance for the app lifetime. Created once so that auth
  /// state / mode changes do NOT tear down and rebuild GoRouter on every
  /// `build` (which loses navigation state and re-runs the deep-link handler).
  GoRouter? _router;

  /// Drives [GoRouter.redirect] re-evaluation when auth state changes (remote
  /// mode). Replaces the previous "rebuild the whole router" hack.
  StreamController<AuthState>? _authRefreshController;
  GoRouterRefreshStream? _authRefresh;

  /// #1119 (D4): app-root messenger so a sync write rejected by the server
  /// (LWW conflict) surfaces a SnackBar for any role, from above the router.
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  StreamSubscription<SyncRejectionEvent>? _rejectionSubscription;

  /// Builds the router exactly once, wiring auth-state changes to the router's
  /// [refreshListenable] instead of recreating the router.
  GoRouter _ensureRouter() {
    final existing = _router;
    if (existing != null) return existing;

    // Auth redirect + refreshListenable are wired regardless of mock mode:
    // mock mode only swaps data repositories, routing/redirect stays identical.
    // (Previously mock mode used a redirect-less static router, so logout never
    // bounced back to /login.)
    _authRefreshController = StreamController<AuthState>.broadcast();
    // Bridge the Riverpod auth state into a stream the router can listen to.
    ref.listenManual<AuthState>(authNotifierProvider, (_, next) {
      _authRefreshController?.add(next);
      // #475 — register for push once onboarding lands the user in the
      // authenticated state (permission prompt appears post-onboarding).
      if (next is AuthAuthenticated) {
        unawaited(ref.read(pushRegistrationProvider.notifier).ensureStarted());
      }
    });
    _authRefresh = GoRouterRefreshStream(_authRefreshController!.stream);
    _router = AppRouter.createRouter(ref, refreshListenable: _authRefresh);
    return _router!;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Pre-initialize engines at app startup to eliminate first-use delay
    Future.microtask(() {
      ref.read(metronomeProvider.notifier).warmUp();
      // Returning users are already authenticated before the auth listener is
      // wired, so the transition above never fires — kick push registration
      // here too (ensureStarted is idempotent per session).
      if (ref.read(authNotifierProvider) is AuthAuthenticated) {
        unawaited(ref.read(pushRegistrationProvider.notifier).ensureStarted());
      }
      // Tuner warm-up is intentionally deferred until user opens tuner.
      // Keeping it running globally can hold the microphone active in background.
      unawaited(_initializeSyncService());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_deepLinkHandler?.dispose());
    _authRefresh?.dispose();
    unawaited(_authRefreshController?.close());
    unawaited(_rejectionSubscription?.cancel());
    unawaited(ref.read(syncServiceProvider).dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // Preserve intentional recordings. Stop tuner stream/background capture
        // when microphone is only warm-up/processing mode.
        unawaited(ref.read(tunerProvider.notifier).onAppPaused());
        break;
      case AppLifecycleState.resumed:
        final recorder = ref.read(audioRecorderServiceProvider);

        // If a manual recording is active, keep recording ownership of the
        // microphone and only resume tuner when the user had it running.
        if (!recorder.isCaptureActive) {
          unawaited(ref.read(tunerProvider.notifier).onAppResumed());
        }
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _initializeSyncService() async {
    final syncService = ref.read(syncServiceProvider);
    // #1119 (D4): surface deterministic write rejections (LWW conflicts) the
    // user is not watching (async replay) as a SnackBar.
    _rejectionSubscription ??= syncService.rejectionStream.listen((_) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text(AppStrings.syncConflictRejected)),
      );
    });
    await syncService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    // Single router instance created once; auth/mode changes flow through the
    // router's refreshListenable, not through router re-creation.
    final routerConfig = _ensureRouter();

    // R2 #318 — lessonapp:// 딥링크 → GoRouter 연결 (1회만 시작).
    // Uses the single router instance so navigation targets the live router.
    if (_deepLinkHandler == null) {
      _deepLinkHandler = DeepLinkHandler(navigate: routerConfig.go);
      unawaited(_deepLinkHandler!.start());
    }

    // Global keyboard dismiss: tap outside any text field to close keyboard
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: MaterialApp.router(
        title: 'Lessonaza',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: _scaffoldMessengerKey,

        // Localization
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko', 'KR'),

        // Theme
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.light,

        // Router
        routerConfig: routerConfig,

        // Force-update gate wraps the whole shell: when the running version is
        // below the server min_version it swaps in ForceUpdateScreen. Fails
        // open while the version check is loading/errored (never locks out).
        // Inside the gate, the global offline banner sits above every screen.
        builder: (context, child) => ForceUpdateGate(
          child: OfflineBannerWrapper(child: child ?? const SizedBox.shrink()),
        ),
      ),
    );
  }
}
