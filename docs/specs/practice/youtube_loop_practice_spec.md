# YouTube 구간 반복 연습 — 스펙 (통합본 v2)

> 작성일: 2026-06-04
> 상태: 구현 준비 (D1-D9 + 진입점/카운트인/속도5/메트로놈통합 모두 반영)
> 의사결정 문서: `mybrain/10 Projects/레슨앱/27-유튜브-구간반복-연습-의사결정.md`, `28-유튜브-구간반복-메트로놈통합-결정.md`
> 관련 마스터: `docs/specs/practice/practice_master.md` §3 (레퍼토리), §4 (녹음)
> 디자인 SSOT: `docs/specs/design/notebook/README.md`, `docs/specs/design/detail_screen_template.md`
> 메트로놈 분석: `metronome_controller_bar.dart:14-107`, `audio_session_manager.dart` (mixWithOthers + defaultToSpeaker)

## 1. 개요

### 1.1 목적

학생이 유튜브 영상으로 어려운 구간을 반복 연습할 수 있게 한다. 선생님은 PracticeSection 에 영상 URL + 구간을 미리 마킹 (이미 구현됨), 학생은 그대로 또는 자기 구간으로 조정해서 목표 횟수만큼 반복. 메트로놈과 동일한 컨셉으로 녹음과 동시 진행 가능 (best effort + 헤드폰 권장).

### 1.2 사용자

- **선생님**: PracticeSection 에 영상 URL + 구간 입력 (이미 구현됨, 본 스펙 범위 밖)
- **학생**: 5개 진입점 (홈/리스트/상세/녹음/결과) 에서 자연스럽게 영상 도달, 반복+녹음+메트로놈 동시 가능

### 1.3 차별점

- 학생이 선생님 디폴트 구간을 그대로 또는 자기 구간으로 조정 (로컬 오버라이드)
- 영상+녹음 동시 모드 (`headphoneOnly` 권장 + 가이드)
- 영상+메트로놈+녹음 3중 동시 (mixWithOthers + 사용자 책임)
- 속도 5단계 (0.25x/0.5x/0.75x/1.0x/1.25x) — 정밀 연습부터 훑기까지
- 카운트인 (3-2-1) — 음악 연습 표준 패턴
- 반복 목표 횟수 + 진행률 시각화 (뱃지 시스템 연동 가능)

## 2. 사용자 시나리오

### 2.1 시나리오 A — 선생님 과제 시범 따라치기

```
1. 학생 홈 → 영상 있는 섹션 카드 (NotebookGlyph play + 라벨)
2. 섹션 상세 → 선생님 마킹 영상 + 구간 자동 로드
3. [반복 ON] + [속도 0.5x] → 천천히 따라침
4. 충분히 익혔다 → [연습 시작] → 연습 녹음 화면
```

### 2.2 시나리오 B — 영상 보면서 메트로놈 + 녹음 (3중 동시)

```
1. 학생 → 연습 녹음 화면 (상단 영상 미니 플레이어 + 메트로놈 컨트롤 + 녹음 컨트롤)
2. [메트로놈 ON] (BPM 90) → 헤드폰으로 메트로놈 들음
3. [영상 재생] (구간 반복 + 0.75x) → 헤드폰으로 영상 음성도 들음
4. [녹음 시작] → 첫 사용 시 가이드: "헤드폰 권장 — 메트로놈/영상 소리가 녹음에 섞일 수 있어요"
5. 학생 선택: 그대로 / 영상 음소거 / 헤드폰 연결 안내
6. 녹음 진행 → 메트로놈 + 영상 계속 재생
7. 녹음 종료 → 결과 화면 (영상 자동 일시정지)
```

### 2.3 시나리오 C — 학생 구간 조정

```
1. 선생님 구간 00:42-01:15 가 너무 김
2. 학생 → 마커 드래그 → 00:50-01:05 로 축소
3. [리셋] 버튼 → 선생님 디폴트 복원 가능
4. 학생 조정값은 로컬 Hive 사용자별 scoped 저장 (선생님 데이터 변경 X)
```

### 2.4 시나리오 D — 카운트인으로 정확한 시작

```
1. 학생 [카운트인 ON] + [소리 ON]
2. [▶] 탭 → 영상 일시정지 상태에서 화면 중앙 큰 "3" → "2" → "1" → 재생
3. 메트로놈 단발 클릭 3회 (소리 ON 시)
4. 반복 모드 ON 시 매 반복 시작 전 동일 카운트인
```

## 3. 데이터 모델

### 3.1 재사용 (변경 없음)

`PracticeSection` (기존):
```dart
final String? youtubeUrl;
final String? youtubeVideoId;
final int? youtubeStartSeconds;
final int? youtubeEndSeconds;
```

### 3.2 신규 entity

`PracticeLoopOverride`:
```dart
class PracticeLoopOverride {
  final String sectionId;
  final String studentUserId;
  final int? overrideStartSeconds;        // null = 선생님 디폴트
  final int? overrideEndSeconds;
  final double playbackSpeed;              // 0.25/0.5/0.75/1.0/1.25
  final int targetRepeatCount;             // 목표 횟수 (기본 5)
  final int completedRepeatCount;          // 완료 횟수 (런타임)
  final bool countInEnabled;               // 카운트인 ON/OFF (기본 false)
  final bool countInSoundEnabled;          // 카운트인 소리 ON/OFF (기본 true)
  final AudioMixMode audioMixMode;         // 영상+녹음 모드
  final DateTime lastPlayedAt;
}
```

### 3.3 신규 enum

`AudioMixMode`:
```dart
enum AudioMixMode {
  videoOnly,         // 녹음 없음
  recordOnly,        // 영상 일시정지, 녹음만
  mixed,             // 영상 + 마이크 동시 (믹스 녹음 — 의도)
  videoMuted,        // 영상 음량 0 + 녹음
  headphoneOnly,     // 헤드폰 출력 강제 + 녹음 (권장)
  metronomeMixed,    // 영상 + 메트로놈 + 녹음 3중 (사용자 책임)
}
```

### 3.4 상수

`PracticeLoopSpeeds`:
```dart
class PracticeLoopSpeeds {
  static const List<double> allowed = [0.25, 0.5, 0.75, 1.0, 1.25];
  static const double defaultSpeed = 1.0;
}
```

## 4. UX 명세

### 4.1 학생 진입점 5단계 흐름 (필수 wiring)

> 위젯 클래스만 만들고 화면 통합을 미루면 안 됨. 모든 진입점에 시각 affordance + wiring 필수.

```
[1] 학생 홈 (student_practice_tab)
    └─ 영상 있는 섹션 카드:
       · 우측 상단 NotebookGlyph play + tempoMono 라벨 "구간 00:42-01:15"
       · paperAccent (#9B1B12) 강조
       · 영상 없으면 기존 카드 그대로 (regression 0)

[2] 레퍼토리 상세 (repertoire_detail)
    └─ 섹션 카드 리스트:
       · 좌측 60x60 YouTube 썸네일 (각진 모서리, paper 테두리)
       · 우측 상단 mono 라벨 [구간: 00:42-01:15]
       · 카드 탭 → 섹션 상세

[3] 섹션 상세 (section_detail)
    └─ youtubeUrl 있으면 영상 영역 자동 표시 (조건부 렌더)
       · 자동 로드, 자동 재생 X
       · 컨트롤 패널 (paper 배경, 각진, 평면)
       · 하단 [연습 시작] → 연습 녹음 화면

[4] 연습 녹음 화면 (practice_recording_screen)
    └─ 직전 섹션이 영상 → 상단 미니 플레이어 자동 유지 (재생 위치 + 반복 상태)
    └─ youtubeUrl 없으면 미니 플레이어 미렌더
    └─ 메트로놈 컨트롤 (기존) + 미니 플레이어 + 녹음 컨트롤 3중 통합
    └─ [녹음 시작] 첫 탭 시 AudioMixMode 가이드 다이얼로그

[5] 결과 화면 (recording_result_screen)
    └─ 영상 자동 일시정지
    └─ 녹음 결과 + 영상 ABLoop 정보 표시
```

### 4.2 섹션 상세 화면 — 영상 영역

```
+-----------------------------------------------+
| NotebookMasthead (eyebrow + title)            |
+-----------------------------------------------+
| 영상 캔버스 (16:9, YouTube 검정 배경 — 예외)  |
|  ▶ YouTube iframe + 카운트인 오버레이         |
+-----------------------------------------------+
| 타임라인 (paper, _DashedLinePainter)          |
|  --[A]====구간====[B]----                     |
|   ▲드래그            ▲드래그                   |
+-----------------------------------------------+
| 컨트롤 (paper, 각진, 평면)                    |
| [반복 ON] [속도 0.75x▼] [리셋]                |
| [카운트인 ON] [소리 ON] · 3-2-1 후 재생       |
| 반복: 3 / 5  ████████░░ 60%                   |
+-----------------------------------------------+
| 노트 / 챕터 리스트 (기존 §2.4 통합)           |
+-----------------------------------------------+
| 하단 액션바: [연습 시작 →]                    |
+-----------------------------------------------+
```

- 영상 캔버스만 검정 배경 (미디어 예외)
- 모든 컨트롤 `AppColors.paper` 강제
- 마커: `_DashedLinePainter` + `paperAccent`
- 시간 라벨: `IBM Plex Mono` ("00:42 -- 01:15")
- 반복 카운터: Playfair Display 큰 숫자

### 4.3 연습 녹음 화면 — 3중 통합

```
+-----------------------------------------------+
| 영상 미니 플레이어 (180px, youtubeUrl 있을때) |
|  ▶ YouTube + 반복 토글 + 속도 + [▲풀스크린]  |
+-----------------------------------------------+
| 메트로놈 컨트롤 바 (기존 — MetronomeControllerBar)|
|  BPM 90 · ♩=90 · [▶ 메트로놈]                  |
+-----------------------------------------------+
| 녹음 컨트롤 (기존 — _RecordingSection)         |
|  파형 / 시간 MM:SS / [● 녹음]                  |
+-----------------------------------------------+
```

- 직전 섹션 상세에서 영상 본 상태면 미니 플레이어 자동 유지
- 미니 플레이어 탭 → 풀스크린 (재생 위치 유지)
- 메트로놈 + 영상 + 녹음 모두 동시 가능 (`metronomeMixed` 모드)

### 4.4 카운트인 (count-in)

```
[카운트인 ON 시 동작]
  첫 [▶] 탭 또는 반복 끝 도달
    ↓
  영상 일시정지
    ↓
  화면 중앙 큰 숫자 오버레이:
    "3"  →  300ms 페이드  →  "2"  →  300ms  →  "1"  →  영상 재생
    (각 숫자 사이 1초 간격, Timer.periodic)
    ↓
  소리 ON 시: 메트로놈 단발 클릭 3회 (1초 간격)
    ↓
  카운트 종료 → 영상 재생 + 반복 카운터 +1
```

오버레이 디자인:
- 크기: Playfair Display 60-72pt w700
- 색: `AppColors.paperAccent` (#9B1B12)
- 배경: paper 60% opacity 반투명 사각형
- 모서리: `BorderRadius.zero`
- 그림자: `elevation: 0`
- 애니메이션: AnimatedOpacity 300ms 페이드 인/아웃

### 4.5 마커 드래그 인터랙션

```
1. 학생 A 마커 길게 누름 → 햅틱 피드백
2. 드래그 → 영상 실시간 seek (미리보기)
3. 드래그 종료 → PracticeLoopOverride 저장
4. [리셋] → 선생님 디폴트 복원 (override 삭제)
```

### 4.6 반복 카운터

```
정상: 구간 끝 → 카운트인 (선택) → seekTo(start) → 카운터 +1
목표 도달: 알림 + 뱃지 trigger (#490 onPracticeRepeat — #508 완료)
수동 리셋: 카운터 0
```

뱃지 연동 (#508):
- 목표 횟수 도달 시 `BadgeChecker.onPracticeRepeat({sectionId, completedCount})` 호출
- 누적 카운트 (학생별 scoped, Hive `practice_repeat_totals` box) 10/50/100 회 도달 시 신규 뱃지 (`practiceRepeat10/50/100`) 획득
- `BadgePopupListener` 가 자동 popup

### 4.7 시각 affordance 톤

- 영상 글리프: `NotebookGlyph` play (▶ 또는 chevronRight ›) — Material `Icons.play_arrow` 는 컨트롤 패널 내부에서만
- 라벨: `NotebookTypography.tempoMono` — "구간 00:42 -- 01:15"
- 색: `AppColors.paperAccent` (#9B1B12)
- 빈 상태: 영상 없는 섹션은 변경 0 (regression 금지)

## 5. 기술 명세

### 5.1 의존성

- 패키지: `youtube_player_iframe: ^5.2.2` (이미 있음)
- 영상 URL → videoId 파싱: `YoutubePlayerController.convertUrlToId()`
- 학생 오버라이드 저장: Hive box `practice_loop_overrides` (사용자별 scoped key: `{studentUserId}:{sectionId}`)
- 헤드폰 감지: `audio_session` 패키지 또는 iOS `AVAudioSession.routeChangeEvent` 채널

### 5.2 메트로놈+녹음 패턴 답습

현재 메트로놈+녹음 동시 동작 (분석 결과):
- iOS `.playAndRecord` + `mixWithOthers` + `defaultToSpeaker`
- 메트로놈 = AVAudioEngine 별도 player node → 마이크 분리
- 헤드폰 사용 시 자동 라우팅 분리

YouTube 적용 (옵션 A + E 채택):
- 동일 audio session 설정 그대로 활용 (`AudioSessionManager.enableRecordingMode()` 호출)
- YouTube iframe 의 audio 도 `mixWithOthers` 글로벌 옵션에 의해 메트로놈처럼 mixing
- **한계**: WebView 의 audio 가 마이크 입력에 들어가는지 보장 불가 → 헤드폰 권장 가이드
- **검증 항목** (실기기 수동 테스트 후 결정):
  1. 헤드폰 연결 상태에서 마이크에 YouTube 음성 들어가는지
  2. 스피커 상태에서 마이크 픽업 여부
  3. iOS / Android 차이
- 검증 결과에 따라 헤드폰 권장 / 강제 / 자유 결정

### 5.3 AudioMixMode 별 동작

| 모드 | 메트로놈 | YouTube | 녹음 | UX |
|------|---------|---------|------|-----|
| `videoOnly` | OFF | ON | OFF | 영상만 보기 |
| `recordOnly` | 선택 | OFF (일시정지) | ON | 녹음만 |
| `mixed` | 선택 | ON | ON | 동시 (사용자 의도) |
| `videoMuted` | 선택 | ON (`setVolume(0)`) | ON | 시각만 + 녹음 |
| `headphoneOnly` | 선택 | ON | ON | 헤드폰 출력 강제 — 권장 |
| `metronomeMixed` | ON | ON | ON | 3중 동시 (사용자 책임) |

### 5.4 헤드폰 감지 + 가이드 (D8 권장)

```
신규 service: domain/services/audio_routing_service.dart
  Stream<bool> headphoneConnectedStream
  bool get isHeadphoneConnected
  Future<void> requestHeadphoneIfMissing()
```

녹음 시작 시:
1. 헤드폰 미감지 → AudioMixGuideDialog 표시
2. 선택지: [그대로 진행 / 영상 음소거 / 헤드폰 연결 안내]
3. 선택 결과 → AudioMixMode 갱신 + 녹음 시작

### 5.5 백그라운드 재생 차단

- `YoutubePlayerParam.playInline = true`
- 화면 잠금 → 영상 자동 일시정지 (연습 집중)

### 5.6 데이터 사용량

- 기본 화질 `medium` (360p) — `setPlaybackQuality('medium')`
- Wi-Fi 환경에서 [고화질] 토글 가능

## 6. 노트 X 악보 토큰 강제

| 요소 | 토큰 | 위반 시 |
|------|------|---------|
| 컨트롤 패널 배경 | `AppColors.paper` (#F2ECDD) | BLOCK |
| 모서리 | `BorderRadius.zero` | BLOCK |
| 그림자 | `elevation: 0` | BLOCK |
| 구간 마커 | `_DashedLinePainter` + `paperAccent` (#9B1B12) | BLOCK |
| 시간 라벨 | `NotebookTypography.tempoMono` (IBM Plex Mono) | BLOCK |
| 반복 카운터 숫자 | Playfair Display | FLAG |
| 카운트인 오버레이 숫자 | Playfair Display 60-72pt w700 | FLAG |
| 시스템 상태 라벨 | `indicatorLabel` (Pretendard italic) | FLAG |
| 자유 메모 | Gaegu (Tier 1 hand) | 권장 |
| 재생/일시정지 아이콘 | Material `Icons.play_arrow` 허용 | OK (affordance 예외) |
| 영상 캔버스 자체 | YouTube 검정 | OK (미디어 예외) |
| 진입점 글리프 | NotebookGlyph play (▶) | OK |

## 7. 수용 기준

### 7.1 학생 진입점 (5단계)

- [ ] 학생 홈 — 영상 있는 섹션 카드 NotebookGlyph + mono 라벨 표시
- [ ] 학생 홈 — 영상 없는 섹션은 기존 UI 그대로 (regression 0)
- [ ] 레퍼토리 상세 — 섹션 카드 좌측 60x60 썸네일 표시
- [ ] 섹션 상세 — youtubeUrl 있으면 영상 영역 자동 렌더, 없으면 미렌더
- [ ] 연습 녹음 화면 — 직전 섹션이 영상이면 미니 플레이어 자동 유지
- [ ] 결과 화면 — 영상 자동 일시정지

### 7.2 학생 진입 + 재생

- [ ] 선생님 디폴트 구간 자동 로드
- [ ] 반복 토글 → 구간만 반복 재생
- [ ] 속도 5단계 (0.25x/0.5x/0.75x/1.0x/1.25x) 토글
- [ ] 속도 선택 → YouTube iframe `setPlaybackRate` 호출

### 7.3 학생 오버라이드

- [ ] 마커 드래그 → 실시간 영상 seek
- [ ] 드래그 종료 → Hive 사용자별 scoped 저장
- [ ] 리셋 → 선생님 디폴트 복원
- [ ] 다른 학생/디바이스 격리

### 7.4 반복 카운터

- [ ] 구간 끝 도달 → 카운터 +1
- [ ] 목표 횟수 설정 (1-20, 기본 5)
- [ ] 목표 도달 알림

### 7.5 카운트인

- [ ] 토글 [카운트인 ON/OFF] 동작 (loop_controls)
- [ ] 토글 [소리 ON/OFF] 동작 (카운트인 ON 일 때만 enabled)
- [ ] ON 시 첫 재생 [▶] → 3-2-1 후 영상 재생
- [ ] ON 시 반복 끝 → seekTo(start) 전 3-2-1 → 재생
- [ ] OFF 시 기존 동작 (즉시 재생)
- [ ] Hive 사용자별 scoped 저장
- [ ] 시각: Playfair Display 60-72pt + paperAccent + paper 60% 배경
- [ ] 소리 ON 시 메트로놈 단발 클릭 3회

### 7.6 녹음 + 영상 + 메트로놈 동시 (옵션)

- [ ] 연습 녹음 화면 상단 미니 플레이어
- [ ] 메트로놈 컨트롤 + 미니 플레이어 + 녹음 컨트롤 3중 UI
- [ ] 녹음 시작 시 첫 사용 → AudioMixGuideDialog
- [ ] 6개 모드 정상 동작
- [ ] 헤드폰 연결 감지 → 자동 `headphoneOnly` 제안
- [ ] 헤드폰 미감지 시 가이드 다이얼로그 (그대로 / 음소거 / 헤드폰 연결)

### 7.7 디자인 일관성 (노트 X 악보)

- [ ] 모든 컨트롤 paper 배경 + BorderRadius.zero + elevation 0
- [ ] 시간 라벨 mono font
- [ ] 구간 마커 점선 + paperAccent
- [ ] 카운트인 오버레이 Playfair Display + paperAccent
- [ ] 진입점 글리프 NotebookGlyph (Material 아님)
- [ ] notebook 시그니처 영역 위반 0건

### 7.8 에러 처리

- [ ] 영상 비공개/삭제 → 빈 상태 + "선생님에게 알리기"
- [ ] 네트워크 끊김 → 재시도 버튼
- [ ] iframe 로드 실패 → 외부 YouTube 앱 fallback

## 8. 테스트 계획

### 8.1 단위 테스트

- `PracticeLoopOverride` 직렬화/역직렬화 + 카운트인 필드 + audioMixMode
- `PlaybackLooper` 알고리즘 (shouldSeekBack + countInTrigger + countCompleted)
- `AudioRoutingService` 헤드폰 감지 mock
- `PracticeAudioMixService` 6 모드별 audio session 설정 변환
- Hive 저장소 (오버라이드 / 리셋 / 사용자별 분리)
- `PracticeLoopSpeeds.allowed` 검증

### 8.2 위젯 smoke test

- `PracticeYoutubePlayer` (정상 / 영상 없음 / 영상 오류)
- `LoopTimeline` 마커 드래그 (좁은 폭 회귀 포함)
- `LoopControls` (5속도 옵션 + 카운트인 토글 + 리셋)
- `RepeatCounter` (0/3/5/목표 도달)
- `CountInOverlay` (3→2→1→onComplete 콜백)
- `AudioMixGuideDialog` (헤드폰 감지 시 / 미감지 시)
- `PracticeYoutubeMiniPlayer` (재생 위치 유지 + 풀스크린 전환)

### 8.3 화면 smoke test

- `student_practice_tab` — 영상 있는 섹션 카드 affordance + 영상 없는 섹션 변경 0
- `section_detail` — youtubeUrl 있으면 영상 영역 보임, 없으면 미렌더
- `practice_recording_screen` — 직전 섹션 영상이면 미니 플레이어 보임 + 메트로놈/녹음 컨트롤 공존
- `repertoire_card` — 영상 섹션 포함 시 mono 라벨

### 8.4 통합 테스트 (수동, 실기기)

- iOS / Android 실기기에서 YouTube + 마이크 녹음 동시 동작
- 헤드폰 연결 시 마이크에 YouTube 음성 들어가는지 측정
- 스피커 상태에서 마이크 픽업 여부
- 화면 회전 시 미니 플레이어 ↔ 풀스크린 자동 전환
- 백그라운드 진입 시 영상 일시정지
- 카운트인 정확한 타이밍 (1초 간격)
- 메트로놈 + YouTube + 녹음 3중 동시 검증

## 9. 후속 작업 (별도 이슈)

- 멀티 마커 (북마크 N구간)
- 뱃지 시스템 #490 `onPracticeRepeat` trigger 연동 (#508 완료)
- 선생님 측 학생별 반복 통계
- 영상 메모 (구간별 손글씨)
- 다른 비디오 플랫폼 (Vimeo, 직접 업로드)
- 실기기 검증 결과에 따른 헤드폰 강제 모드 (D8 후속)

## 10. 위험 + 완화

| 위험 | 영향 | 완화 |
|------|------|------|
| YouTube iframe seekTo 1초 오차 | 정확도 ↓ | 정수 초 + 100ms 마진 |
| 영상 광고 (skippable) | 흐름 끊김 | 광고 검출 → 일시정지 |
| 영상 삭제/비공개 | 에러 | 빈 상태 + 선생님 알림 |
| 마이크에 영상/메트로놈 음성 혼입 | 녹음 품질 ↓ | 헤드폰 권장 + 가이드 다이얼로그 |
| 데이터 사용량 | LTE 부담 | 360p 기본 + Wi-Fi 시 고화질 |
| YouTube 정책 변경 | break | 버전 고정 |
| 카운트인 timing drift | UX | Timer.periodic + 1초 보정 |
| WebView audio session 충돌 | iOS/Android 차이 | 실기기 검증 + best effort 명시 |

## 11. 구현 파일 매핑

| 계층 | 파일 | 상태 |
|------|------|------|
| Entity | `domain/entities/practice_loop_override.dart` | 생성 |
| Enum | `domain/value_objects/audio_mix_mode.dart` | 생성 (6종) |
| 상수 | `domain/value_objects/practice_loop_speeds.dart` | 생성 |
| Repository (인터페이스) | `domain/repositories/practice_loop_override_repository.dart` | 생성 |
| Repository (Hive 구현) | `data/repositories/hive_practice_loop_override_repository.dart` | 생성 |
| Service | `domain/services/playback_looper.dart` (순수 알고리즘) | 생성 |
| Service | `domain/services/practice_audio_mix_service.dart` (audio session) | 생성 |
| Service | `domain/services/audio_routing_service.dart` (헤드폰 감지) | 생성 |
| Provider | `presentation/providers/practice_loop_provider.dart` | 생성 |
| Widget | `presentation/widgets/youtube/practice_youtube_player.dart` (메인) | 생성 |
| Widget | `presentation/widgets/youtube/loop_timeline.dart` (마커 드래그) | 생성 |
| Widget | `presentation/widgets/youtube/loop_controls.dart` (속도5/반복/카운트인/리셋) | 생성 |
| Widget | `presentation/widgets/youtube/repeat_counter.dart` (목표 횟수) | 생성 |
| Widget | `presentation/widgets/youtube/count_in_overlay.dart` (3-2-1 오버레이) | 생성 |
| Widget | `presentation/widgets/youtube/audio_mix_guide_dialog.dart` (헤드폰 가이드) | 생성 |
| Widget | `presentation/widgets/youtube/practice_youtube_mini_player.dart` (녹음 화면) | 생성 |
| Widget | `presentation/widgets/youtube/section_video_affordance.dart` (진입점 글리프+라벨) | 생성 |
| Extension | `presentation/extensions/audio_mix_visuals.dart` (enum 라벨 변환) | 생성 |
| Screen 통합 | `student_home/.../student_practice_tab.dart` (진입점 1) | 갱신 |
| Screen 통합 | `practice/.../repertoire_detail_screen.dart` (진입점 2) — 정확한 파일명 grep | 갱신 |
| Screen 통합 | `practice/.../section_detail_screen.dart` (진입점 3) — 정확한 파일명 grep | 갱신 |
| Screen 통합 | `practice/.../practice_recording_screen.dart` (진입점 4) | 갱신 |
| Screen 통합 | `practice/.../recording_result_screen.dart` (진입점 5 — 영상 일시정지) | 갱신 |
| Card | `practice/.../section_card.dart` 또는 동급 (진입점 1/2 affordance) | 갱신 |
| Strings | `core/l10n/app_strings.dart` (35-40 키) | 갱신 |
| Entity (#508) | `features/practice/domain/entities/badge.dart` (+ `practiceRepeat10/50/100`) | 갱신 |
| Service (#508) | `features/practice/domain/services/badge_checker.dart` (+ `onPracticeRepeat` + `cumulativeRepeatCount`) | 갱신 |
| Repository (#508) | `features/practice/domain/repositories/practice_repeat_total_repository.dart` | 생성 |
| Repository (#508) | `features/practice/data/repositories/hive_practice_repeat_total_repository.dart` (box `practice_repeat_totals`) | 생성 |
| Provider (#508) | `presentation/providers/practice_loop_provider.dart` — `incrementCompletedCount` 목표 도달 시 badge trigger | 갱신 |
| Extension (#508) | `presentation/extensions/badge_visuals.dart` (+ 3 visual) | 갱신 |
| Strings (#508) | `core/l10n/app_strings.dart` (+ `badgePracticeRepeat10/50/100Name` + `badgePracticeRepeatDescription`) | 갱신 |

## 12. 변경 이력

- 2026-06-04 v1: D1-D6 초안
- 2026-06-04 v2: D7-D9 + 진입점 5단계 + 카운트인 + 속도 5단계 + 메트로놈 통합 패턴 통합
- 2026-06-04 v3 (#508): 뱃지 onPracticeRepeat trigger 연동 — 10/50/100 회 뱃지 + 누적 카운트 storage
