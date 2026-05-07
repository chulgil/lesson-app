import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/repository_provider.dart';
import 'core/router/app_router.dart';
import 'core/startup/app_bootstrap.dart';
import 'core/startup/startup_provider_observer.dart';
import 'core/startup/startup_recovery.dart' as startup_recovery;
import 'core/theme/app_theme.dart';
import 'core/sync/presentation/providers/sync_provider.dart';
import 'features/practice/presentation/providers/metronome_provider.dart';
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

class _LessonazaAppState extends ConsumerState<LessonazaApp> {
  @override
  void initState() {
    super.initState();
    // Pre-initialize engines at app startup to eliminate first-use delay
    Future.microtask(() {
      ref.read(metronomeProvider.notifier).warmUp();
      // Warm up tuner (starts microphone stream without processing)
      // This pre-configures audio session, eliminating delay when opening practice tools
      ref.read(tunerProvider.notifier).warmUp();
      unawaited(_initializeSyncService());
    });
  }

  @override
  void dispose() {
    unawaited(ref.read(syncServiceProvider).dispose());
    super.dispose();
  }

  Future<void> _initializeSyncService() async {
    final syncService = ref.read(syncServiceProvider);
    await syncService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    // Use auth-aware router in remote mode, static router in mock mode
    final useMockData = ref.watch(mockDataModeProvider);
    final routerConfig =
        useMockData
            ? AppRouter.router
            : AppRouter.createRouter(ref, useMockData: useMockData);

    return MaterialApp.router(
      title: 'Lessonaza',
      debugShowCheckedModeBanner: false,

      // Localization
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
      locale: const Locale('ko', 'KR'),

      // Theme
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,

      // Router
      routerConfig: routerConfig,
    );
  }
}
