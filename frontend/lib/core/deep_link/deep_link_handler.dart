// R2 #318 — app_links 패키지를 GoRouter 에 연결하는 얇은 어댑터.
//
// 책임:
//   1. cold-start URI (앱이 죽어있을 때 받은 링크) 1회 처리
//   2. uriLinkStream 구독 (앱이 살아있는 동안 들어오는 추가 링크)
//   3. DeepLinkParser 가 인식한 경로만 navigation 콜백으로 위임
//
// 파싱 자체는 DeepLinkParser 가 담당하므로 본 핸들러는 IO 와 라이프사이클만 책임진다.
//
// 의존성은 세 가지 콜백으로 받는다 (AppLinks 와 GoRouter 인스턴스를 직접 받지 않음):
//   - initialUriProvider: cold-start URI 조회
//   - uriStreamProvider:  warm URI 스트림
//   - navigate:           경로 위임 (실제 운영에서는 GoRouter.go 전달)
// 이유: AppLinks 는 platform singleton, GoRouter 는 factory constructor 라
// 테스트에서 흉내내기 어렵다. 콜백 DI 로 분리하면 widget 트리 없이 단위 테스트가 가능하다.
// (feedback memory: spy mock + 동기 Future — Timer pending 회피)

import 'dart:async';

import 'package:app_links/app_links.dart';

import 'deep_link_parser.dart';

typedef InitialUriProvider = Future<Uri?> Function();
typedef UriStreamProvider = Stream<Uri> Function();
typedef DeepLinkNavigate = void Function(String path);

class DeepLinkHandler {
  DeepLinkHandler({
    required DeepLinkNavigate navigate,
    InitialUriProvider? initialUriProvider,
    UriStreamProvider? uriStreamProvider,
  }) : _navigate = navigate,
       _initialUriProvider = initialUriProvider ?? _defaultInitialUri,
       _uriStreamProvider = uriStreamProvider ?? _defaultUriStream;

  static Future<Uri?> _defaultInitialUri() => AppLinks().getInitialLink();
  static Stream<Uri> _defaultUriStream() => AppLinks().uriLinkStream;

  final DeepLinkNavigate _navigate;
  final InitialUriProvider _initialUriProvider;
  final UriStreamProvider _uriStreamProvider;

  StreamSubscription<Uri>? _subscription;
  bool _started = false;

  /// 핸들러 시작.
  ///
  /// initState 등 라이프사이클 한 번만 호출되는 시점에 사용한다.
  /// 중복 호출은 무시한다.
  Future<void> start() async {
    if (_started) return;
    _started = true;

    // cold-start: 앱이 종료된 상태에서 링크로 깨어났을 때 1회만 들어옴.
    try {
      final initialUri = await _initialUriProvider();
      if (initialUri != null) {
        _handleUri(initialUri);
      }
    } catch (_) {
      // 권한/플랫폼 문제로 실패해도 앱은 정상 동작해야 한다.
    }

    // warm: 앱이 살아있는 동안 들어오는 추가 링크.
    _subscription = _uriStreamProvider().listen(
      _handleUri,
      onError: (_) {
        // 스트림 에러는 무시 — 다음 링크 수신을 위해 구독은 유지된다.
      },
    );
  }

  void _handleUri(Uri uri) {
    final route = DeepLinkParser.toRoute(uri);
    if (route == null) return;
    // Forward the parsed invite code as a query param so the target screen can
    // prefill + auto-verify it. Without this the code was silently dropped and
    // CodeInputScreen opened empty.
    final code = route.code;
    final path = code == null
        ? route.path
        : Uri(path: route.path, queryParameters: {'code': code}).toString();
    _navigate(path);
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _started = false;
  }
}
