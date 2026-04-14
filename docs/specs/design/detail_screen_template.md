# 상세 화면 공통 템플릿

> 레슨요청 상세, 수강권 상세 등 "프로그레스바 + 챗 + 하단 액션" 구조의 화면에 적용

## 레이아웃 구조

```
Scaffold
  ├─ AppBar (상대방 정보, centerTitle: true)
  ├─ Body: Column
  │   ├─ ProgressBar (고정, AppBar 바로 아래)
  │   ├─ GuideBox (선택, 고정)
  │   └─ Expanded: 스크롤 가능 영역 (챗/이벤트 히스토리)
  └─ bottomNavigationBar: ActionBar (하단 고정)
```

## 프로그레스바 규칙

| 항목 | 규칙 | 참조 컴포넌트 |
|------|------|--------------|
| 정렬 | `MainAxisAlignment.center` | LessonProgressBar |
| 커넥터 | 완료=실선(primary), 미완료=점선(borderLight) | _DashedLinePainter |
| 점 크기 | dot=20, ring=28 | _PhaseDot, _SessionDot |
| 완료 상태 | filled circle + checkmark (white) | |
| 활성 상태 | filled circle + outer ring (primaryLight border) | |
| 미래 상태 | hollow circle (borderLight border) | |
| 라벨 | caption, fontSize: 10, 점 아래 | |
| 패딩 | screenPadding (horizontal), space2 (vertical) | |

## 하단 액션바 규칙

| 항목 | 규칙 | 참조 컴포넌트 |
|------|------|--------------|
| 컨테이너 | surfaceLight + borderLight top border | CurrentRequestBox |
| 패딩 | space3 + SafeArea bottom | |
| 메시지 입력 | bodySmall, radiusMedium, maxLength: 200 | |
| 버튼 높이 | buttonHeightSmall (40) | |
| 버튼 스타일 | outlined(보조) + filled(주요), radiusMedium | |
| 버튼 폰트 | buttonSmall | |
| 버튼 간격 | space2 | |
| 아이콘 크기 | 16 (버튼 내부) | |

## 버튼 패턴

### 2-버튼 레이아웃 (기본)

```
Row
  ├─ Expanded: OutlinedButton.icon (보조 액션)
  ├─ SizedBox(width: space2)
  └─ Expanded: ElevatedButton.icon (주요 액션)
```

### 메시지 + 버튼 레이아웃

```
Column
  ├─ TextField (메시지 입력)
  ├─ SizedBox(height: space2)
  └─ Row (2-버튼 레이아웃)
```

## 아이콘 규칙

| 액션 | 아이콘 |
|------|--------|
| 일정 변경 | `Icons.swap_horiz_rounded` |
| 레슨 완료 | `Icons.check_circle_outline` |
| 취소 | `Icons.cancel_outlined` |
| 수락 | `Icons.check` |
| 역제안 | (텍스트만) |
| 결제 | `Icons.card_membership` |
| 대기 | `Icons.hourglass_top` |

## 적용 대상 화면

| 화면 | 파일 | 프로그레스바 |
|------|------|-------------|
| 레슨요청 상세 | `request_detail_screen.dart` | LessonProgressBar (5 phase) |
| 수강권 상세 | `subscription_detail_screen.dart` | SessionProgressBar (N session) |

## 새 상세 화면 추가 시 체크리스트

- [ ] 프로그레스바: 점선 커넥터 + 가운데 정렬
- [ ] 하단 액션바: CurrentRequestBox 패딩/스타일 준수
- [ ] 버튼: buttonHeightSmall + radiusMedium + buttonSmall 폰트
- [ ] 아이콘: 위 아이콘 규칙 참조
- [ ] AppBar: centerTitle: true
