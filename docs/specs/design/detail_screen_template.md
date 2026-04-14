# 상세 화면 공통 템플릿

> 레슨요청 상세, 수강권 상세 등 "프로그레스바 + 챗 + 하단 액션" 구조의 화면에 적용
> 기준 화면: `request_detail_screen.dart` (레슨요청 상세)

## 레이아웃 구조

```
Scaffold
  ├─ AppBar
  │   ├─ titleSpacing: 0
  │   ├─ title: "학원이름 학생이름 (타입)" or "학생이름 (타입)"
  │   └─ style: AppTypography.headingSmall
  ├─ Body: Column
  │   ├─ ProgressBar (고정, surfaceLight 배경 + borderLight 하단)
  │   ├─ GuideInfoBox (고정, 상황별 가이드)
  │   └─ Expanded: 스크롤 가능 영역 (챗/이벤트 히스토리)
  └─ bottomNavigationBar: ActionBar (하단 고정)
```

## AppBar 규칙

| 항목 | 규칙 |
|------|------|
| titleSpacing | 0 |
| title 포맷 | `학원이름 학생이름 (타입)` 또는 `학생이름 (타입)` |
| title 스타일 | `AppTypography.headingSmall` |
| 학원 판별 | `LessonClass.type == academy` → name이 학원 이름 |
| 타입 라벨 | 레슨요청: `request.typeDisplayLabel`, 수강권: `subscription.typeLabel` |

## 프로그레스바 규칙

| 항목 | 값 | 참조 |
|------|-----|------|
| 배경 | surfaceLight + borderLight 하단 border | Container decoration |
| 내부 패딩 | screenPadding (h), space2 (v) | 프로그레스바 위젯 내부 |
| 정렬 | `Row` + `Expanded` 커넥터 (전체 너비 분배) | LessonProgressBar |
| dot 크기 | 20px (dot), 28px (ring) | |
| 완료 상태 | `AppColors.primary` filled + checkmark (12px, white) | |
| 활성 상태 | primary filled + primaryLight outer ring (width 2) | |
| 미래 상태 | hollow circle (borderLight, width 1.5, 내부 비어있음) | |
| 커넥터 (완료) | `Container(height: 2, color: primary)` | 실선 |
| 커넥터 (미완료) | `_DashedLinePainter(borderLight, 1.5, dash 4, gap 3)` | 점선 |
| 라벨 | caption, fontSize 10, 점 아래 | |
| 라벨 색상 | completed/active=primary, future=textTertiaryLight | |
| 라벨 weight | active/selected=w600, 나머지=normal | |

## 하단 액션바 규칙

| 항목 | 값 | 참조 |
|------|-----|------|
| 컨테이너 배경 | surfaceLight | CurrentRequestBox |
| 상단 border | borderLight | |
| 패딩 | space3 사방 + SafeArea bottom | `EdgeInsets.fromLTRB` |
| 메시지 입력 | bodySmall, radiusMedium, maxLines 8, minLines 1, maxLength 200 | |
| 메시지 힌트 | bodySmall, textTertiaryLight, counterText '' | |
| 버튼 높이 | `AppSpacing.buttonHeightSmall` (40) | |
| 버튼 radius | `AppSpacing.radiusMedium` | |
| 버튼 폰트 | `AppTypography.buttonSmall` | |
| 버튼 패딩 | horizontal: space3 | |
| 버튼 간격 | space2 | |
| 주요 버튼 | ElevatedButton, primary 배경, white 텍스트 | |
| 보조 버튼 | OutlinedButton, borderLight side, textSecondaryLight 텍스트 | |

## 버튼 패턴 (2-버튼 Row)

```dart
Row(
  children: [
    Expanded(
      child: SizedBox(
        height: AppSpacing.buttonHeightSmall,
        child: OutlinedButton(  // 보조 액션
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppColors.borderLight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.space3),
          ),
          child: Text(label, style: AppTypography.buttonSmall.copyWith(
            color: AppColors.textSecondaryLight,
          )),
        ),
      ),
    ),
    SizedBox(width: AppSpacing.space2),
    Expanded(
      child: SizedBox(
        height: AppSpacing.buttonHeightSmall,
        child: ElevatedButton(  // 주요 액션
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.space3),
          ),
          child: Text(label, style: AppTypography.buttonSmall.copyWith(
            color: Colors.white,
          )),
        ),
      ),
    ),
  ],
)
```

## 화면별 차이점

| 항목 | 레슨요청 상세 | 수강권 상세 |
|------|-------------|-----------|
| 프로그레스바 | LessonProgressBar (5 phase: 신청→확정→결제→진행→완료) | SessionProgressBar (N session: 1회차~8회차) |
| AppBar 타입 | `request.typeDisplayLabel` | `subscription.typeLabel` |
| 챗 내용 | 전체 이벤트 히스토리 | 스케줄 변경 내역만 (수강권 발급 정보 X) |
| 하단 주요 버튼 | Phase별 동적 (수락/결제/레슨완료 등) | 메시지 전송 |
| 하단 보조 버튼 | Phase별 동적 (역제안/취소 등) | 일정 변경 |

## 아이콘 규칙

| 액션 | 아이콘 |
|------|--------|
| 일정 변경 | `Icons.swap_horiz_rounded` |
| 레슨 완료 | `Icons.check_circle_outline` |
| 취소 | `Icons.cancel_outlined` |
| 대기 | `Icons.hourglass_top` |
| 결제 | `Icons.card_membership` |

## 새 상세 화면 추가 시 체크리스트

- [ ] AppBar: titleSpacing 0 + headingSmall + "상대방 (타입)" 포맷
- [ ] 프로그레스바: Expanded 커넥터 + primary 색상 + 점선/실선
- [ ] 프로그레스바 배경: surfaceLight + borderLight 하단
- [ ] 하단 바: space3 패딩 + SafeArea + borderLight 상단
- [ ] 버튼: buttonHeightSmall + radiusMedium + buttonSmall 폰트
- [ ] 메시지 입력: bodySmall + radiusMedium + maxLength 200
