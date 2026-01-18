# 메트로놈 구현 가이드

## 중요: 실제 사용되는 모달

**`PracticeToolsModal`이 메트로놈/튜너의 실제 진입점입니다.**

```
lib/features/practice/presentation/widgets/practice_tools_modal.dart
```

### 사용되지 않는 파일 (레거시)

`MetronomeFullScreenModal`은 **사용되지 않습니다**:
```
lib/features/practice/presentation/widgets/metronome/metronome_full_screen_modal.dart
```
- 이 파일은 레거시로, 실제 앱에서 호출되지 않음
- 메트로놈 관련 수정은 반드시 `PracticeToolsModal` 내의 `_MetronomePanel`에서 진행

## 모달 구조

### PracticeToolsModal
- 위치: `lib/features/practice/presentation/widgets/practice_tools_modal.dart`
- 탭 구조: 메트로놈 탭 (index 0) | 튜너 탭 (index 1)
- 진입점: `MetronomeControllerBar`의 `onExpand` 콜백 → `PracticeToolsModal.show(context)`

### _MetronomePanel (메트로놈 탭 내용)
현재 UI 구성:
1. 고양이 탭 템포 (CatBeatIndicator)
2. BPM 슬라이더 (_LogarithmicBpmSlider)
3. 재생/일시정지 버튼
4. 박자표 (TimeSignature)
5. 서브디비전 (Subdivision) - 기본, 8분음표, 셋잇단음, 16분음표, 5연음, 6연음
6. 박자 패턴 (AccentPattern)

### _TunerPanel (튜너 탭 내용)
- CircularTunerIndicator
- TunerCatIndicator
- TunerStaff
- TunerInfoBar

## 메트로놈 컨트롤러 바

```
lib/features/practice/presentation/widgets/metronome/metronome_controller_bar.dart
```
- 연습 화면 하단에 표시되는 컴팩트 메트로놈 바
- 전체 화면 버튼 클릭 시 `PracticeToolsModal` 열림

## 메트로놈 관련 파일 정리

| 파일 | 용도 | 상태 |
|------|------|------|
| `practice_tools_modal.dart` | 메트로놈/튜너 통합 모달 | ✅ 활성 |
| `metronome_controller_bar.dart` | 하단 컨트롤러 바 | ✅ 활성 |
| `cat_beat_indicator.dart` | 고양이 비트 인디케이터 | ✅ 활성 |
| `metronome_full_screen_modal.dart` | 단독 메트로놈 모달 | ❌ 미사용 (레거시) |

## 메트로놈 수정 시 체크리스트

1. [ ] `practice_tools_modal.dart`의 `_MetronomePanel` 수정
2. [ ] 필요시 `metronome_controller_bar.dart` 수정
3. [ ] `metronome_full_screen_modal.dart`는 수정하지 않음 (미사용)
