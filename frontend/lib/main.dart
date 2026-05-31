import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/deep_link/deep_link_handler.dart';
import 'core/l10n/generated/app_localizations.dart';
import 'core/providers/repository_provider.dart';
import 'core/router/app_router.dart';
import 'core/startup/app_bootstrap.dart';
import 'core/startup/startup_provider_observer.dart';
import 'core/startup/startup_recovery.dart' as startup_recovery;
import 'core/theme/app_theme.dart';
import 'core/sync/presentation/providers/sync_provider.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/practice/presentation/providers/metronome_provider.dart';
import 'features/practice/presentation/providers/recording_provider.dart';
import 'features/practice/presentation/providers/tuner_provider.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Pre-initialize engines at app startup to eliminate first-use delay
    Future.microtask(() {
      ref.read(metronomeProvider.notifier).warmUp();
      // Tuner warm-up is intentionally deferred until user opens tuner.
      // Keeping it running globally can hold the microphone active in background.
      unawaited(_initializeSyncService());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_deepLinkHandler?.dispose());
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
    await syncService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    // Use auth-aware router in remote mode, static router in mock mode
    final useMockData = ref.watch(mockDataModeProvider);
    ref.watch(authNotifierProvider);
    final routerConfig =
        useMockData
            ? AppRouter.router
            : AppRouter.createRouter(ref, useMockData: useMockData);

    // R2 #318 — lessonapp:// 딥링크 → GoRouter 연결 (1회만 시작).
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
      ),
    );
  }
}
