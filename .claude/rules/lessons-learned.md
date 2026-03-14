# Lessons Learned

## 1. Mock 데이터 대규모 변경 시 반드시 실행 검증 - error-pattern
- **날짜**: 2026-03-06
- **교훈**: 병렬 에이전트로 4개 mock repository를 동시 변경한 후 앱이 즉시 크래시. `flutter analyze` 통과해도 런타임 크래시 가능. Hive 캐시 충돌이 원인.
- **조치**: Mock 데이터 변경 후 반드시 `flutter run`으로 실행 검증. 대규모 변경은 단계적으로.

## 2. 오디오 엔진 이벤트 경로는 반드시 단일화 - error-pattern
- **날짜**: 2026-03-06
- **교훈**: `noteStream`(stream)과 `onPitchDetected`(callback) 이중 경로 → 상태 충돌 (음 감지→사라짐 반복).
- **조치**: stream만 사용, callback 제거. 데이터 흐름은 항상 단일 경로.

## 3. iPhone 배포 시 provisioning profile 사전 확인 - error-pattern
- **날짜**: 2026-03-06
- **교훈**: `flutter run --release`로 iPhone 배포 시 provisioning profile 에러 빈번.
- **조치**: Xcode에서 Signing & Capabilities 확인. `xcodebuild -allowProvisioningUpdates` 사용.

## 4. UX 반복 점검 — 패턴 단위 grep이 핵심 - automation-pattern
- **날짜**: 2026-03-11
- **교훈**: UX 점검 10회 반복에도 `$e` 노출·NO-OP 버튼·하드코딩 라우트 재발견. 기능 단위가 아닌 패턴 단위 grep이 핵심.
- **조치**: 새 화면 구현 순서: Entity+Provider → UI 바인딩(ref.watch) → 콜백 실제 구현 → try-catch → AppRoutes 상수 → formatDateYMD() → 전체 코드베이스 grep 점검.

## 5. BoxDecoration border가 0.5px BOTTOM OVERFLOW 유발 - error-pattern
- **날짜**: 2026-03-12
- **교훈**: `BoxDecoration(border:)` border가 content 영역을 침범하여 오버플로우.
- **조치**: border를 별도 `Container(height: 0.5)` 위젯으로 분리. 또는 `clipBehavior: Clip.hardEdge`.

## 6. 하드코딩 색상 대신 AppColors 상수 사용 강제 - error-pattern
- **날짜**: 2026-03-12
- **교훈**: `Color(0xFFF5F5F5)` 등 하드코딩 → 테마 변경/다크모드 대응 불가.
- **조치**: `AppColors`에 상수 추가 후 참조. `Color(0x` 패턴 grep으로 검출. Hook으로 자동 차단.

## 7. CJK 이름에서 성/이름 분리 — NameUtils.givenName() - automation-pattern
- **날짜**: 2026-03-12
- **교훈**: 공간 제한 UI에서 given name만 표시하면 가독성 향상.
- **조치**: `NameUtils.givenName()` 유틸 사용.

## 8. 새 패키지 추가 시 iOS Info.plist 권한 문자열 필수 - error-pattern
- **날짜**: 2026-03-13
- **교훈**: 권한 문자열 누락 시 크래시(SIGABRT). `flutter analyze`로 감지 불가.
- **조치**: pubspec.yaml에 새 패키지 추가 시 → iOS `Info.plist` + Android `AndroidManifest.xml` 권한 체크.

## 9. 분산 설정 화면 → 단일 스크롤 통합이 UX 정답 - automation-pattern
- **날짜**: 2026-03-13
- **교훈**: 3개 화면에 분산된 설정을 단일 화면 4섹션으로 통합 → 진입 경로 축소 + 인지 부하 감소.
- **조치**: 설정 화면이 3개 이상 분산되면 통합 검토 필수.

## 10. build_runner 새 Provider는 전체 빌드 필수 - error-pattern
- **날짜**: 2026-03-13
- **교훈**: `--build-filter`는 기존 파일 수정 시에만 유효. 새 `@riverpod` Provider는 전체 빌드 필요.
- **조치**: 새 Provider → `dart run build_runner build --delete-conflicting-outputs` (전체).

## 11. 새 기능 구현 순서: Entity → Mock → Provider → UI 바인딩 - automation-pattern
- **날짜**: 2026-03-13
- **교훈**: 데이터 계층 먼저 완성 → build_runner → UI 바인딩 순서로 컴파일 에러 없이 안정 구현.
- **조치**: 반대로 UI부터 만들면 Provider 미존재로 에러 폭발.

## 12. iOS 오디오 엔진 백그라운드 복구 패턴 - error-pattern
- **날짜**: 2026-03-14
- **교훈**: iOS가 백그라운드에서 AVAudioEngine kill → `_isStreamActive` 불일치 → dead stream. 또한 `inactive→paused` 이중 호출로 `_wasListeningBeforePause` 덮어쓰기.
- **조치**: (1) heartbeat로 dead stream 감지 (2) `restartStream()` 강제 재시작 (3) `_isPaused` guard (4) checkPermission → restartStream → reactivate → enableProcessing.

## 13. 조건부 카드가 Row를 깨트릴 때 별도 배너로 분리 - error-pattern
- **날짜**: 2026-03-14
- **교훈**: StatCardRow에 조건부 3번째 카드 → 좁은 화면 오버플로우.
- **조치**: Row 카드 수 고정, 조건부 항목은 별도 배너/위젯으로 분리.

## 14. 대시보드 UX 최소주의: 단색 통일 + 중복 CTA 제거 - automation-pattern
- **날짜**: 2026-03-14
- **교훈**: 3가지 semantic color 동시 사용 → 시각적 과부하. 중복 진입점 → 오버플로우 + 선택 피로.
- **조치**: stat 카드는 primary 단색 통일. 한 섹션에 동일 기능 버튼 1개만 유지.
