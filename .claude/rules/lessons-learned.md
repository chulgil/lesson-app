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

## 15. 기능 없는 UI 요소는 즉시 제거 — 플레이스홀더 금지 - automation-pattern
- **날짜**: 2026-03-15
- **교훈**: 레슨 상세의 녹음 FAB가 타이머만 돌리는 껍데기였음. 사용자가 탭해도 아무 일도 안 일어나면 앱 신뢰가 즉시 하락. "나중에 구현" 의도의 플레이스홀더 UI는 사용자에게 버그로 인식됨.
- **조치**: 구현 안 된 기능의 UI는 코드에서 제거. 스펙에 "Phase N에서 구현 예정" 명시. 기능 준비 시 재활성화.

## 16. 같은 행동을 유도하는 항목은 하나로 합쳐라 - automation-pattern
- **날짜**: 2026-03-15
- **교훈**: "수강권 임박"과 "수강권 만료"를 분리 표시했으나, 선생님이 해야 할 행동(수강권 재발급)은 동일. 분리하면 인지 부하만 증가하고 같은 화면으로 이동.
- **조치**: 사용자 행동(action) 기준으로 항목을 통합. "상태"가 다르더라도 "할 일"이 같으면 하나의 CTA로.

## 17. 멀티 뷰 색상 규칙은 반드시 일관성 유지 - error-pattern
- **날짜**: 2026-03-15
- **교훈**: 주간 스케줄에는 과거=회색/오늘=진한색/미래=연한색이 적용되어 있었지만, 일간 리스트 뷰에는 status 기반 색상만 사용하여 과거 레슨도 primary색 유지. 같은 데이터를 보여주는 두 뷰의 색상이 달라 사용자 혼란.
- **조치**: 새 뷰를 추가하거나 색상 로직을 변경할 때, 동일 데이터를 표시하는 모든 뷰를 grep하여 일관성 확인. `scheduleMutedBackground` 검색으로 적용 누락 감지.

## 18. 설정 값이 실제 로직에 사용되는지 반드시 추적 — "설정만 되고 미사용" 방지 - error-pattern
- **날짜**: 2026-03-15
- **교훈**: `breakTimeBetweenLessons`가 두 곳(TeacherSettings, TeacherAvailability)에서 설정 가능하지만, 슬롯 생성 로직(`_computeSlotsForDate`)에서 전혀 사용되지 않음. 사용자는 설정했다고 생각하지만 실제 예약에 반영 안 됨 → 앱 신뢰 하락.
- **조치**: 새 설정 필드를 추가할 때 반드시 "이 값을 사용하는 코드"를 함께 구현. grep으로 해당 필드가 읽히는 곳이 2곳 이상(설정 UI + 비즈니스 로직)인지 확인.

## 19. 동일 개념을 두 곳에서 설정하게 하면 안 된다 — 단일 진실 소스 원칙 - automation-pattern
- **날짜**: 2026-03-15
- **교훈**: `breakTimeBetweenLessons`와 `운영시간`이 프로필 탭(TeacherSettings)과 스케줄 탭(TeacherAvailability)에서 각각 설정 가능. 선생님은 "어느 것이 실제로 적용되나?" 혼란. 두 값이 다르면 어느 것이 우선인지 불명확.
- **조치**: 하나의 개념은 하나의 설정에서만 관리. 다른 화면에서는 참조(읽기)만 허용. 설정 화면 신규 추가 시 기존 설정과 중복되는지 반드시 확인.

## 20. add vs update 메서드 혼동 — CRUD에서 편집은 반드시 update 호출 - error-pattern
- **날짜**: 2026-03-15
- **교훈**: 기존 운영시간을 편집할 때 `addWeeklySchedule()`을 호출하여 수정 대신 중복 추가가 발생. `updateWeeklySchedule()` 메서드가 존재하지만 어디서도 호출되지 않음.
- **조치**: 편집 UI에서 저장 시 기존 ID 존재 여부 확인 → 있으면 update, 없으면 add. 새 CRUD 메서드 추가 시 "이 메서드를 호출하는 곳"이 반드시 존재하는지 grep 확인.

## 21. 새 Provider 추가 시 _invalidateProviders에 등록 필수 - error-pattern
- **날짜**: 2026-03-15
- **교훈**: `pendingRenewalProposalProvider`를 추가했지만 `SubscriptionProposalNotifier._invalidateProviders()`에 등록하지 않아, 학생이 갱신 제안을 수락/거절해도 배너가 갱신되지 않는 버그 발생. Code Review에서 HIGH로 감지됨.
- **조치**: 새 Provider를 추가할 때 관련 Notifier의 `_invalidateProviders()`에 반드시 등록. grep `invalidate.*Provider`로 누락 확인.

## 22. Hick's Law — 선택지가 많으면 사용률이 떨어진다 - automation-pattern
- **날짜**: 2026-03-15
- **교훈**: 피드백 아이콘 👍⭐💪 3개 → 선생님이 매번 "어떤 것을 누를까" 2-3초 고민. 하루 40개 과제에 누적되면 피드백 포기. YouTube처럼 👍 1개가 사용률을 극대화. 학생 응답 🙏❓도 동일 — 🙏은 정보량=0, ❓는 메모 텍스트가 적합.
- **조치**: 새 UI 요소 추가 시 "선택지 수 × 일일 사용 빈도"를 계산. 하루 10회 이상 반복되는 인터랙션은 선택지 1개가 원칙. 뉘앙스가 필요하면 텍스트 입력으로.

## 23. 이미 구현된 기능은 이슈 상태 라벨로 추적 — "한 것 또 하기" 방지 - automation-pattern
- **날짜**: 2026-03-15
- **교훈**: #158 이슈를 진행하려 했으나 Step 1이 이미 완전 구현됨(edit_student_screen + level_tuition_section). 이슈에 `status: todo` 라벨이 남아있어 미착수로 오인. 이미 완료된 작업을 다시 분석하는 데 시간 낭비.
- **조치**: 기능 구현 후 반드시 이슈 라벨을 `status: review` 또는 `status: done`으로 업데이트. 이슈 진행 전 `gh issue view`로 관련 커밋/PR 먼저 확인.
