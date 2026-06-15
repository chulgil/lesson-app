# Web / Chrome Click-Through QA Procedure

> Setup date: 2026-06-15
> Branch: feat/731-web-chrome
> Purpose: Enable Claude-driven click-through QA via chrome-devtools MCP without a physical device.

## Build Status

`flutter build web --no-tree-shake-icons` compiles successfully (JS/HTML target).
WASM dry-run reports `flutter_secure_storage_web` dart:html/dart:js_util incompatibilities — these are WASM-only warnings and do NOT block the standard JS build.

## 1. Launch the App in Chrome

```bash
cd frontend
flutter run -d chrome --web-port=4040
```

- Use a fixed `--web-port` so the Claude MCP client can reliably navigate to it.
- To keep it running headlessly for automation: `flutter run -d web-server --web-port=4040`
- The app opens at `http://localhost:4040`.

## 2. Claude-Driven Click-Through via chrome-devtools MCP

Claude uses the following MCP tools in sequence to walk UI journeys:

| MCP Tool | Purpose |
|---|---|
| `mcp__chrome_dev__navigate_page` | Open `http://localhost:4040` |
| `mcp__chrome_dev__take_screenshot` | Capture current state |
| `mcp__chrome_dev__take_snapshot` | Inspect DOM/accessibility tree |
| `mcp__chrome_dev__click` | Tap buttons / list items |
| `mcp__chrome_dev__fill` | Enter text in fields |
| `mcp__chrome_dev__list_console_messages` | Collect JS errors / Flutter exceptions |
| `mcp__chrome_dev__get_network_request` | Verify API calls |
| `mcp__chrome_dev__wait_for` | Wait for async navigation |
| `mcp__chrome_dev__evaluate_script` | Run JS assertions |

### Typical Journey Script (pseudo-code)

```
navigate_page("http://localhost:4040")
take_screenshot()                        # confirm home screen loads
click(".login-button")
fill("#email", "test@example.com")
fill("#password", "password")
click("#submit")
wait_for(selector: ".home-tab")
take_screenshot()                        # confirm authenticated home
list_console_messages()                  # check for Flutter exceptions
```

## 3. Web-Safe Screens (Green List)

These screens use only pure Dart/Flutter widgets + Riverpod providers and are
expected to render correctly in Chrome:

| Screen | Route | Notes |
|---|---|---|
| Login / Dev-Login | `/login` | google_sign_in has web plugin — may show browser popup |
| Home (Teacher) | `/home` | Stats cards, upcoming lessons — all REST-based |
| Home (Student) | `/home` | Same — gamification widgets render via fl_chart |
| Lessons list | `/lessons` | List + SwipeActionTile (mouse hover triggers swipe) |
| Lesson detail | `/lessons/:id` | Chat-style session detail, progress bar |
| Students list | `/students` | Pure list + search |
| Student detail | `/students/:id` | Profile + lesson history |
| Schedule tab | `/schedule` | Weekly grid — layout regression candidate |
| Subscription management | `/subscriptions` | Badge, countdown chip |
| Notifications | `/notifications` | List + read state |
| Academy invite | `/academy/invite` | QR code (qr_flutter renders on web) |
| Profile / Settings | `/profile` | Name, contact display |

## 4. Native-Only Features (Red List — QA on Device)

The following features use platform channels or native SDKs with no web
implementation. They will either throw `MissingPluginException` or silently
no-op in Chrome:

| Feature | Plugin | Reason |
|---|---|---|
| 메트로놈 (Metronome) | `flutter_soloud` | C++ native audio engine, no web build |
| 튜너 (Pitch Detection) | `pitch_detector_dart`, `flutter_audio_capture` | Native microphone + YIN algorithm |
| 음성 녹음 (Recording) | `record` | Native audio recorder, no web counterpart |
| 구글 로그인 (Google Sign-In) | `google_sign_in_web` | Has web plugin but requires OAuth redirect config |
| 인앱 결제 (IAP) | `in_app_purchase` | StoreKit2 / Play Billing — no web version |
| 모바일 스캐너 (QR scan) | `mobile_scanner` | Camera API native only |
| 이미지 크롭 | `image_cropper_for_web` | Has web plugin — likely functional |
| 알림 (Push notifications) | `firebase_messaging`, `flutter_local_notifications` | Service worker needed; partial web support |
| 권한 요청 | `permission_handler` | No-op on web |

## 5. Known Web Limitations

- **Hive local storage**: IndexedDB adapter exists but box initialization order may differ. Expect potential cold-start issues if Hive boxes open before web adapter registers.
- **flutter_secure_storage**: Web version uses WebCrypto / SubtleCrypto. Works in Chrome but WASM-incompatible.
- **Swipe gestures**: `SwipeActionTile` uses `Dismissible` drag mechanics. On Chrome, mouse-drag simulates swipe — test with `mcp__chrome_dev__drag`.
- **Audio**: Any screen that auto-initializes `AudioSession` or `just_audio` may log errors in Chrome console but should not crash the UI.
- **Deep links**: `app_links` has no web equivalent. `GoRouter` path-based navigation works fine.

## 6. Console Error Triage

After each journey step, call `list_console_messages()`. Classify output:

| Severity | Pattern | Action |
|---|---|---|
| IGNORE | `MissingPluginException: No implementation found for method ... on channel flutter/metronome` | Native-only plugin — expected |
| IGNORE | `dart:html unsupported` warnings | WASM-only concern |
| INVESTIGATE | `FlutterError: ...` in console | Real render or state error |
| INVESTIGATE | HTTP 4xx/5xx in network log | API connectivity issue |
| BLOCK | White screen + no Flutter bootstrap | Build or routing failure |

## 7. Running a Full Web QA Session

```bash
# Terminal 1 — start app
cd /Users/r00360/Dev/personal/development/app/lesson-app-rt-web/frontend
flutter run -d web-server --web-port=4040

# Claude (in session) — drive journeys
# navigate -> screenshot -> click -> screenshot -> list_console_messages
# Repeat for each Green List screen
```

Capture screenshots at each step. Any `FlutterError` in console logs = regression candidate.

## 8. Scope Summary

| Scope | Covered by Web QA |
|---|---|
| Navigation / routing (GoRouter) | YES |
| Layout / responsive overflow | YES |
| Provider state (Riverpod) | YES |
| REST API calls | YES (with backend running) |
| Native audio / mic | NO — device only |
| IAP / payments | NO — device only |
| Push notifications | PARTIAL — service worker |
| Google Sign-In | PARTIAL — browser OAuth popup |
