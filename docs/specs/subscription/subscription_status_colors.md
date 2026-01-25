# 수강권 상태별 색상 체계

> 작성일: 2026-01-25
> 최종 수정: 2026-01-25
> 상태: ✅ 구현 완료

---

## 개요

수강권의 상태별 시각적 표현 가이드. 브랜드 색상과 UX 원칙에 기반한 설계.

**핵심 원칙**: 3+1 색상 시스템으로 단순하고 명확한 상태 전달

---

## 3+1 색상 시스템

| 상태 | 색상 | 코드 | 의미 |
|------|------|------|------|
| **이용중** | 녹색 | #2E8B57 | 정상 사용 중 |
| **갱신 필요** | 주황 | #F4A460 | 행동 유도 (D-7 이하 OR 1회 남음) |
| **비활성** | 회색 | #999999 | 만료됨, 일시정지 |
| **사용 완료** | 보라 | #9A8BC4 | 성취 (브랜드 강조) |

---

## 상태 정의 (5단계)

| 상태 | 조건 | 색상 |
|------|------|------|
| **이용중** | 정상 사용 중 | 녹색 |
| **갱신 필요** | D-7 이하 OR 잔여 1회 | 주황 |
| **사용 완료** | 잔여 = 0 | 보라 |
| **일시정지** | 수동 정지 | 회색 |
| **만료됨** | 유효기간 경과 | 회색 |

---

## 상태별 시각 디자인

```
┌─────────────────────────────────────────────────────────────────┐
│  3+1 Color System 시각 디자인                                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ✅ 이용중 (Active)                                             │
│  ┌─────────────────────────────────────────┐                   │
│  │ 배지: [이용중] 녹색 배경                  │                   │
│  │ 텍스트: "3/4회 남음 (D-25)"               │                   │
│  │ 본문 색상: 기본 (검정)                    │                   │
│  │ 테두리: 기본 1px                         │                   │
│  └─────────────────────────────────────────┘                   │
│                                                                 │
│  ⚠️ 갱신 필요 (Expiring Soon)                                   │
│  ┌─────────────────────────────────────────┐                   │
│  │ 배지: [갱신 필요] 주황 배경               │                   │
│  │ 텍스트: "1/4회 남음 (D-5)"                │                   │
│  │ 본문 색상: 주황 (warning)                 │                   │
│  │ 테두리: 주황 2px                         │                   │
│  │ 메시지: "갱신이 필요합니다"               │                   │
│  └─────────────────────────────────────────┘                   │
│                                                                 │
│  🎉 사용 완료 (Depleted)                                        │
│  ┌─────────────────────────────────────────┐                   │
│  │ 배지: [사용 완료] 연보라 배경             │                   │
│  │ 텍스트: "4회 모두 사용"                   │                   │
│  │ 본문 색상: 연보라 (primaryLight)          │                   │
│  │ 테두리: 연보라 2px                        │                   │
│  └─────────────────────────────────────────┘                   │
│                                                                 │
│  ⏸️ 일시정지 (Paused)                                           │
│  ┌─────────────────────────────────────────┐                   │
│  │ 배지: [일시정지] 회색 배경                │                   │
│  │ 본문 색상: 회색                          │                   │
│  │ 테두리: 기본 1px                         │                   │
│  │ Opacity: 80%                            │                   │
│  └─────────────────────────────────────────┘                   │
│                                                                 │
│  ❌ 만료됨 (Expired)                                            │
│  ┌─────────────────────────────────────────┐                   │
│  │ 배지: [만료됨] 회색 배경                  │                   │
│  │ 텍스트: "2회 미사용 (만료됨)"             │                   │
│  │ 본문 색상: 회색 (tertiary)                │                   │
│  │ 테두리: 연한 회색 1px                    │                   │
│  │ Opacity: 70%                            │                   │
│  └─────────────────────────────────────────┘                   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## UX 설계 원칙

### 1. 색상 최소화

> "Too many colors greatly reduces the user's ability to learn and properly use the application." - Carbon Design System

```
❌ 기존 (6개 상태, 4가지 색상):
   이용중(녹색), 갱신안내(파랑), 갱신필요(주황),
   사용완료(보라), 일시정지(회색), 만료됨(회색)

✅ 개선 (5개 상태, 3+1색):
   이용중(녹색), 갱신필요(주황),
   비활성(회색), 사용완료(보라)
```

### 2. 성취 = 브랜드 컬러

"사용 완료"는 목표 달성 → Primary 보라로 긍정 강조

```
❌ 빨강/주황: "문제가 있다"는 부정적 인상
✅ 보라: "완료했다"는 성취감, 브랜드 일관성
```

### 3. 비활성 = 페이드아웃

만료/일시정지 카드는 opacity 낮춰 시각적 우선순위 ↓

```
활성 수강권: 100% opacity
일시정지: 80% opacity
만료 수강권: 70% opacity
→ 현재 사용 가능한 것에 집중 유도
```

### 4. 빨강 미사용 이유

```
❌ 빨강 사용 시 문제:
   - "내가 뭔가 잘못했다"는 부정적 인상
   - 앱에 대한 거부감 증가
   - 음악 앱의 따뜻한 분위기 훼손

✅ 회색 사용 시 장점:
   - "지나간 것"이라는 중립적 표현
   - 현재 활성 수강권에 집중 유도
   - 부담 없이 갱신 고려 가능
```

---

## 구현 세부사항

### 공통 유틸리티 클래스

```dart
// lib/features/subscription/presentation/utils/subscription_status_colors.dart
class SubscriptionStatusColors {
  static Color getColor(Subscription subscription);
  static Color getProgressColor(Subscription subscription);
  static Color getBadgeBackground(Subscription subscription);
  static Color getBorderColor(Subscription subscription);
  static Color getSummaryTextColor(Subscription subscription);
  static String getLabel(Subscription subscription);
  static IconData getIcon(Subscription subscription);
  static String getMessage(Subscription subscription);
  static double getBorderWidth(Subscription subscription);
  static double getCardOpacity(Subscription subscription);
}
```

### 판정 우선순위

```dart
// 상태 판정 순서
if (subscription.isDepleted) {
  // 사용 완료 (보라)
} else if (subscription.isExpired) {
  // 기간 만료 (회색)
} else if (subscription.isExpiringSoon) {
  // 갱신 필요 - D-7 이하 OR 1회 (주황)
} else if (subscription.status == SubscriptionStatus.paused) {
  // 일시정지 (회색)
} else {
  // 이용중 (녹색)
}
```

### 관련 속성

| 속성 | 타입 | 설명 |
|------|------|------|
| `isDepleted` | bool | 잔여 횟수 ≤ 0 |
| `isExpired` | bool | 유효기간 경과 |
| `isExpiringSoon` | bool | D-7 이하 OR 잔여 1회 |

---

## 관련 파일

| 파일 | 역할 |
|------|------|
| `subscription.dart` | isDepleted, isExpiringSoon 등 computed properties |
| `subscription_status_colors.dart` | 공통 색상/라벨/아이콘 유틸리티 |
| `subscription_card.dart` | 카드 UI (유틸리티 사용) |
| `subscription_detail_screen.dart` | 상세 화면 UI (유틸리티 사용) |

---

## 변경 이력

| 날짜 | 변경 내용 |
|------|----------|
| 2026-01-25 | 초안 작성, 6단계 색상 시스템 |
| 2026-01-25 | 3+1 색상 시스템으로 단순화 (파랑 제거) |
| 2026-01-25 | 공통 유틸리티 클래스 추출 |
