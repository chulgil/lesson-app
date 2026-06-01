# 학생 인터랙티브 튜토리얼 v2 — 실행 스펙

> 상태: 구현 완료 (2026-06-01)
> 작성: 2026-06-01
> 마스터: [onboarding_quest_v2.md §1.2, §3.2, §5.2.1](onboarding_quest_v2.md)

## 1. 목표

회원가입(role=student) 직후 진입하는 `StudentTutorialScreen`을 정적 4-슬라이드에서 **인터랙티브 워크스루**로 교체. 학생이 매일 쓸 핵심 4기능(메트로놈/튜너/녹음/피드백)을 한 화면 내 미니 시뮬레이션으로 직접 체험.

## 2. 성공 기준

- [x] `student_tutorial_screen.dart` 4단계 인터랙티브 페이지 구조 (PageView + NeverScrollable)
- [x] 각 단계 인터랙션 미완료 시 "다음" 버튼 비활성화 (_canContinue == false)
- [x] 4개 step widget 파일 (`metronome_step.dart`, `tuner_step.dart`, `recording_step.dart`, `feedback_step.dart`) 신규
- [x] `student_tutorial_step.dart` enum + 진행 모델
- [x] 진행률 표시 (선생님 튜토리얼과 동일 `_ProgressStep` 3단 패턴: 휴대폰 / 프로필 / 튜토리얼)
- [x] "건너뛰기"/"이전"/"다음"/"시작하기" 네비게이션 동일 패턴
- [x] 라우터 진입 후 마지막 단계에서 `AppRoutes.studentHome` 으로 이동
- [x] Smoke test: 4단계 모두 통과 + `tester.takeException() == null`
- [x] `flutter analyze` 위반 0건
- [x] AppColors/AppSpacing/AppTypography/AppStrings 사용 (진행 표시 라벨 상수화)

## 3. 비목표 (이번 범위 제외)

- 실제 메트로놈/튜너/녹음 엔진 호출 — **시뮬레이션 위젯**으로 처리. 권한 요청 없음.
- 코치마크 시스템 (별도 phase)
- 셀레브레이션 바텀시트 (별도 phase, 인라인 텍스트로만)
- 백엔드 quest API 호출
- 정적 5페이지 도움말 등 v1 잔재 제거

## 4. 인터페이스 계약 (병렬 분리 기준)

### 4.1 모델 — `presentation/models/student_tutorial_step.dart`

```dart
enum StudentTutorialStep { metronome, tuner, recording, feedback }

class StudentTutorialStepContent {
  final StudentTutorialStep step;
  final int index;          // 1..4
  final String title;       // 미션 제목
  final String description; // 미션 설명
}
```

> 아이콘은 모델 필드가 아닌 `_getIconForStep(step)` switch 로 매핑 (선생님 튜토리얼과 동일 패턴).

### 4.2 Step Widget 인터페이스 (모든 step widget 공통)

각 step widget은 다음 시그니처를 따른다:

```dart
class XxxStep extends StatelessWidget {
  final bool completed;
  final VoidCallback onComplete;
  const XxxStep({super.key, required this.completed, required this.onComplete});
}
```

- `completed`: 부모(컨테이너)가 보유한 완료 플래그 전달
- `onComplete`: 인터랙션 완료 시 부모에게 알림 (한 번만 호출)
- 부모는 4개 플래그(`_metronomeDone, _tunerDone, _recordingDone, _feedbackDone`) 관리

### 4.3 컨테이너 동작

- `_canContinue` 는 현재 step의 완료 플래그를 검사
- 마지막 step 완료 후 "시작하기" → `_completeTutorial()` → `AppRoutes.studentHome`
- "건너뛰기" → `_skipTutorial()` → 동일 라우트 (auth.completeOnboarding 호출 유지)

## 5. Step별 시뮬레이션 사양

### Step 1: 메트로놈 (`metronome_step.dart`)
- BPM 슬라이더 (60~180, 기본 100)
- "재생" 버튼 탭 → 3초 카운트다운 (1초마다 setState로 ●○○ → ●●○ → ●●●)
- 완료 조건: 슬라이더를 한 번이라도 조정 + 재생 완료 시 `onComplete()` 호출
- Key: `student_tutorial_metronome_play`

### Step 2: 튜너 (`tuner_step.dart`)
- 4개 음 칩 (라 A4, 도 C4, 미 E4, 솔 G4) Wrap
- 하나 선택 시 "✓ 정확히 맞췄어요!" 표시 + `onComplete()`
- 완료 조건: 칩 1개 선택
- Key: `student_tutorial_tuner_chip_<note>`

### Step 3: 녹음 (`recording_step.dart`)
- "길게 눌러서 녹음" 원형 버튼
- `GestureDetector.onLongPressStart` → 2초 LinearProgressIndicator 채움
- `onLongPressEnd` 시 2초 이상이면 "자동 트리밍: 0.3초 ~ 1.8초" 결과 카드 + `onComplete()`
- 2초 미만이면 "조금 더 길게 눌러보세요" 안내
- Key: `student_tutorial_recording_button`

### Step 4: 피드백 (`feedback_step.dart`)
- 샘플 피드백 카드 1개 (collapsed: 제목 + 미리보기 1줄)
- 탭 시 ExpansionTile 펼쳐짐 → 본문 + 과제 + 다음 레슨 일정 표시 + `onComplete()`
- 완료 조건: 카드 한 번 펼치기
- Key: `student_tutorial_feedback_card`

## 6. 병렬 worktree 분리

| Worktree | 브랜치 | 담당 파일 | 의존 |
|----------|--------|----------|------|
| `student-tut-A` | `feat/student-tut-container-<n>` | `student_tutorial_screen.dart` (교체) | 모델 (main에 선행 커밋) |
| `student-tut-B` | `feat/student-tut-step1-<n>` | `widgets/student_tutorial/metronome_step.dart` | 모델 |
| `student-tut-C` | `feat/student-tut-step2-<n>` | `widgets/student_tutorial/tuner_step.dart` | 모델 |
| `student-tut-D` | `feat/student-tut-step3-<n>` | `widgets/student_tutorial/recording_step.dart` | 모델 |
| `student-tut-E` | `feat/student-tut-step4-<n>` | `widgets/student_tutorial/feedback_step.dart` | 모델 |

**충돌 방지**: 모델/enum은 main 에 먼저 커밋. 각 worktree는 신규 파일만 생성 (A는 기존 `student_tutorial_screen.dart` 단독 덮어쓰기).

## 7. 통합 단계 (main에서)

1. 모든 worktree 머지 (`git merge --no-ff <branch>`)
2. `cd frontend && flutter analyze` (0 errors)
3. `flutter test test/features/onboarding/` 통과
4. Smoke test 신규: `student_tutorial_screen_test.dart` (4단계 인터랙션 검증)
5. 통합 커밋 → push → 이슈 close

## 8. 품질 모드

**balanced** (feature/3+ 파일, 보안/마이그레이션 없음). adaptive-quality §6번 적용.

## 9. 변경 이력

| 날짜 | 내용 |
|------|------|
| 2026-06-01 | 본 실행 스펙 작성 (마스터 v2 §3.2 구현 1차) |
| 2026-06-01 | 병렬 worktree 5개 통합 완료 + 일관성 보정 (선생님 패턴 정렬: `_ProgressStep` 3단, `_getIconForStep` switch, `IconData` 필드 제거) |
