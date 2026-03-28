# 기술 패턴 — 반복 에러 방지

> lessons-learned.md에서 기술적 함정/에러 패턴을 분리. 에이전트가 관련 코드 변경 시 자동 참조.

## 오디오/마이크

- **iOS 백그라운드 복구** — 앱 전환 시 AVAudioEngine kill → dead stream. heartbeat로 감지 + `restartStream()` 강제 재시작 + `_isPaused` guard 필수 (#12)
- **이벤트 경로 단일화** — stream과 callback 이중 경로 금지. 데이터 흐름은 항상 단일 경로 (#2)
- **앱 전환 시 마이크 죽음** — 반복 발생 이슈. 오디오 관련 변경 시 반드시 앱 전환 테스트 수행

## Provider/상태 관리

- **새 Provider → _invalidateProviders 등록 필수** — 미등록 시 상태 갱신 안 됨. `grep invalidate.*Provider`로 누락 확인 (#21)
- **build_runner 새 Provider는 전체 빌드** — `--build-filter`는 기존 파일만. 새 `@riverpod`는 `--delete-conflicting-outputs` 전체 빌드 (#10)
- **빈 화면 → AutoDispose 의심** — `@Riverpod(keepAlive: true)` 확인

## Mock 데이터

- **대규모 변경 → 단계적** — 4개 mock 동시 변경 후 Hive 캐시 충돌 크래시. 실행 검증 필수 (#1)
- **요구사항 변경 → Mock 연계** — 스펙 변경 시 Mock Repository 데이터도 반드시 업데이트
- **Mock 완전성 검증** — 새 엔티티/필드 추가 시 모든 관련 Mock에 최소 1건 데이터 등록 필수. teacher_2~8 availability 누락으로 "정보 없음" 표시된 사례 (#Cherry)
- **HiveType 추가 후 앱 삭제 필수** — 새 `@HiveType(typeId:)` 추가 시 이전 캐시와 충돌. `flutter clean` + 앱 삭제 후 재설치 (#Cherry)

## CRUD

- **add vs update 혼동** — 편집 UI에서 기존 ID 존재 시 반드시 `update` 호출. `add`는 새 생성만 (#20)
- **새 메서드 → 호출 확인** — CRUD 메서드 추가 시 "이 메서드를 호출하는 곳"이 존재하는지 grep (#20)

## 구현 순서

- **Entity → Mock → Provider → UI** — 데이터 계층 먼저 완성 후 UI 바인딩. 역순이면 Provider 미존재로 에러 (#11)
- **UI-first 금지** — 반복 UX 점검(10회)의 근본 원인이 UI-first 개발
- **신규 위젯 → 기존 화면 연결 확인** — 위젯을 만들고 화면에 안 붙이면 존재하지 않는 것과 같음. grep으로 import 확인 (#Cherry)
- **TDD 후 /verify-spec 필수** — TDD는 로직만 검증. Mock 데이터 누락, 스펙 갭, UI 연결은 별도 검증 (#Cherry)

## Flutter 버전 (3.29.0)

- **ThemeData breaking changes** — `CardTheme` → `CardThemeData`, `activeColor` → `activeThumbColor`, `value` → `initialValue`, `groupValue`/`onChanged` → `RadioGroup` ancestor. 테마/위젯 관련 빌드 에러 시 Flutter changelog 확인
- **intl 패키지 버전** — flutter_localizations SDK가 intl 0.20.2를 강제. pubspec.yaml에서 `intl: ^0.20.2` 필수
- **엔티티 필수 파라미터 추가 시** — Mock 데이터와 JSON 파싱 코드 전체 grep 필수. `flutter analyze`로 감지되지만 누락 위치가 분산되어 있음

## iOS/빌드

- **새 패키지 → Info.plist 권한 문자열** — 누락 시 SIGABRT. `flutter analyze`로 감지 불가 (#8)
- **iPhone 배포 → provisioning profile 사전 확인** — Xcode Signing & Capabilities 확인 (#3)

## Flutter 레이아웃

- **ListView in SliverToBoxAdapter → 크래시** — `shrinkWrap: true` + `NeverScrollableScrollPhysics` 필수. 안 하면 무한 높이 → Null check 크래시 + mouse_tracker (#Cherry)
- **바텀시트 scrim 패턴** — `showModalBottomSheet(isScrollControlled: true)` 사용 시 반드시 `backgroundColor: Colors.transparent` + `DraggableScrollableSheet(expand: false)`. `FractionallySizedBox`는 scrim 삼켜서 배경 탭 닫기 불가 (#Cherry)
- **Column > Expanded > 긴 위젯 + 하단 고정** — Expanded 안에 긴 콘텐츠 + 바깥에 TextField/Button → overflow. `SingleChildScrollView`로 감싸고 Button만 Column 하단 고정 (#Cherry)

## 설정 필드

- **설정 값 → 비즈니스 로직 사용 추적** — 설정 UI에만 있고 실제 로직에 미사용이면 앱 신뢰 하락. grep으로 읽히는 곳 2곳+(설정 UI + 로직) 확인 (#18)
