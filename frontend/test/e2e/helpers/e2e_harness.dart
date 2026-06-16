// E2E harness for #731 Gate 3 — boots the real GoRouter app shell on the
// flutter_tester host (no device required) and logs in via the DEV account
// picker. Native bootstrap (Firebase/FCM/AudioSession) is intentionally
// skipped; only Hive + Korean date formatting are reproduced so screens that
// read local storage / format dates render exactly as in production.
//
// Design: pump a lightweight [E2eApp] that wires the *real*
// [AppRouter.createRouter] instead of [LessonazaApp]. This keeps the entire
// router + redirect + every screen under test (the Gate-3 goal: catch runtime
// render crashes across navigation) while dropping LessonazaApp.initState
// background services (metronome warm-up, sync init, deep-link) that would
// otherwise race the test or hit unmocked platform channels.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:lessonaza/core/l10n/generated/app_localizations.dart';
import 'package:lessonaza/core/router/app_router.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/auth/presentation/providers/user_role_provider.dart';
import 'package:lessonaza/features/practice/data/models/practice_recording_hive_adapter.dart';
import 'package:lessonaza/features/practice/data/models/recording_hive_adapters.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_repertoire.dart';
import 'package:lessonaza/features/practice/domain/entities/recording.dart';
import 'package:lessonaza/features/student_home/data/models/manual_teacher_hive_model.dart';

/// A DEV login account (from `dev_login_section.dart`). [name] is the card text
/// to tap; [role] is synced into the role context after login because, in mock
/// mode, `CurrentUserRoleController` always defaults to teacher and dev-login
/// only sets the auth state (not the role) — without this the parent/student
/// screens would read teacher mock data.
class DevAccount {
  const DevAccount(this.name, this.role);

  final String name;
  final UserRole role;

  /// 박미연 — 학생 3명, 레슨/구독 관리.
  static const DevAccount teacher = DevAccount('박미연', UserRole.teacher);

  /// 김소연 — 레슨 6개, 연습 기록, 수강권 보유.
  static const DevAccount student = DevAccount('김소연', UserRole.student);

  /// 김정수 — 자녀 김소연.
  static const DevAccount parent = DevAccount('김정수', UserRole.parent);
}

bool _envReady = false;

/// Initialise the minimal environment the real app needs to render on the
/// flutter_tester host: Hive (adapters + boxes, mirroring `bootstrapApp`) and
/// Korean date formatting. Idempotent across tests in one process.
Future<void> initE2eEnvironment() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Offline guard: make every network request (notably google_fonts' runtime
  // font fetch) HANG instead of failing. A failed fetch surfaces as an
  // unhandled async error that fails the test; a never-completing one is
  // harmless — pumpAndSettle ignores pending HTTP futures and the widget just
  // uses its fallback font. Mock-mode repositories do no real HTTP.
  HttpOverrides.global = _HangingHttpOverrides();
  if (_envReady) return;

  // path_provider has no native impl on the host — return a temp dir.
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (MethodCall methodCall) async => Directory.systemTemp.path,
      );

  final tempDir = Directory.systemTemp.createTempSync('lessonaza_e2e_');
  Hive.init(tempDir.path);

  _registerAdapter(RecordingTypeAdapter());
  _registerAdapter(StorageStatusAdapter());
  _registerAdapter(RecordingAdapter());
  _registerAdapter(PracticeRecordingAdapter());
  _registerAdapter(ManualTeacherAdapter());

  await Hive.openBox<Recording>('recordings');
  await Hive.openBox<PracticeRecording>('practice_recordings');
  await Hive.openBox('notification_settings');
  await Hive.openBox<String>('app_review_state');

  await initializeDateFormatting('ko');

  _envReady = true;
}

void _registerAdapter(TypeAdapter<dynamic> adapter) {
  if (!Hive.isAdapterRegistered(adapter.typeId)) {
    Hive.registerAdapter(adapter);
  }
}

/// Tear down shared state once all tests in the process complete.
Future<void> disposeE2eEnvironment() async {
  HttpOverrides.global = null;
  if (!_envReady) return;
  await Hive.close();
  _envReady = false;
}

/// Lightweight root that drives the **real** [AppRouter] without
/// [LessonazaApp]'s background services. The router is created once
/// (mirroring the app's single-router invariant). DEV login navigates via an
/// explicit `context.go`, so no auth `refreshListenable` is required here.
class E2eApp extends ConsumerStatefulWidget {
  const E2eApp({super.key});

  @override
  ConsumerState<E2eApp> createState() => _E2eAppState();
}

class _E2eAppState extends ConsumerState<E2eApp> {
  GoRouter? _router;

  @override
  Widget build(BuildContext context) {
    final router = _router ??= AppRouter.createRouter(ref);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko', 'KR'),
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}

/// Pump [E2eApp] and log in as [account], landing on the role home with the
/// mock role context synced to the account. Asserts the login tile is present
/// and that no exception is thrown reaching the home.
Future<void> bootAsRole(WidgetTester tester, DevAccount account) async {
  // Phone portrait viewport so screens lay out as in production (the default
  // 800x600 host surface triggers spurious RenderFlex overflows).
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(const ProviderScope(child: E2eApp()));
  await settle(tester);

  final tile = find.text(account.name);
  expect(
    tile,
    findsOneWidget,
    reason: 'DEV login tile "${account.name}" should be on the login screen',
  );
  await tester.ensureVisible(tile);
  await settle(tester);
  await tester.tap(tile);
  await tester.pump();

  // Sync the mock role to the logged-in account (see [DevAccount]).
  ProviderScope.containerOf(tester.element(find.byType(E2eApp)))
      .read(currentUserRoleProvider.notifier)
      .state = account.role;
  await settle(tester);

  expect(
    tester.takeException(),
    isNull,
    reason: 'reaching ${account.name} home must not throw',
  );
}

/// Pump a bounded number of frames. Unlike [WidgetTester.pumpAndSettle], this
/// tolerates persistent animations (loading spinners, the practice center
/// button) that never let the tree "settle", while still giving mock futures
/// time to resolve.
Future<void> settle(WidgetTester tester, {int frames = 10}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

/// Routes all HTTP through a client whose requests never complete, so offline
/// font fetches stay pending (and silent) rather than throwing.
class _HangingHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _HangingHttpClient();
}

class _HangingHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) =>
      Completer<HttpClientRequest>().future; // never completes

  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl('GET', url);

  @override
  void close({bool force = false}) {}

  // Any other member access no-ops (returns null) — IOClient only awaits
  // openUrl for a GET, which hangs above.
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
