# 설정 정보 아키텍처 (IA) 스펙

> 작성일: 2026-05-18 (2026-06-12 — 5묶음 IA 상위 매핑 명시)
> 상태: 활성 (마스터 SSOT)
> 우선: 🟠 HIGH (출시 후 1개월)
> 관련: [profile_master.md §2.1](../profile/profile_master.md) (5묶음 IA 상위 진입), [event_tracking_spec.md](../analytics/event_tracking_spec.md), [crashlytics_spec.md](../architecture/crashlytics_spec.md), [account_lifecycle_spec.md](../user/account_lifecycle_spec.md), [account_recovery_spec.md](../user/account_recovery_spec.md)

> **2026-06-12 — 5묶음 IA 상위 매핑** (teacher-settings-redesign 머지)
>
> 본 IA 는 **ProfileTab 5묶음 카테고리 IA** (`profile_master.md §2.1`) 의 **§10 ⚙️ 정책·알림·지원 BottomSheet** 진입 후 세부 IA 다.
> 즉 1단계 가시 옵션 7개 (§3) 는 모두 5묶음의 §10 항목 안에서 노출되며, ProfileTab 메인에는 단일 카드 ("⚙️ 정책·알림·지원 — 기본값") 로 흡수.
> 다른 5묶음 카테고리 (운영시간/수업방식/수강권·정산/내 프로필) 는 본 IA 와 별개의 독립 화면 또는 BottomSheet 로 처리.

---

## 0. 개요

설정 화면 정보 아키텍처 통합 SSOT. 13+ 옵트아웃/프라이버시 토글이 설정 화면 곳곳에 흩어진 문제를 해결한다.

**핵심 변경**: "내 데이터 · 프라이버시" 단일 허브 도입 + 토글 통합 + 그룹 재정렬. (2026-06-12 보강: 5묶음 IA §10 BottomSheet 진입)

---

## 1. 현황 진단

| 문제 | 영향 |
|------|------|
| 옵트아웃 토글 13+개가 설정 곳곳에 분산 | 사용자 인지 부담 ↑, 어디서 끄는지 모름 |
| `event_tracking_spec` 옵트아웃 + `crashlytics_spec` 옵트아웃 별도 위치 | 동일 개념(분석 거부) 2곳 |
| 14세 미만 동의·내보내기·삭제가 별도 화면 | 데이터 권리 흐름 분산 |
| 복구 이메일 + 활성 세션이 보안 그룹 부재 | 보안 설정 발견 어려움 |

---

## 2. IA 목표

### 2.1 원칙

1. **단일 허브** — 동일 개념은 한 화면. "내 데이터 · 프라이버시"가 데이터 권리 전체 SSOT
2. **점진 노출** — 깊이 1단계(설정 → 토글)는 7개 이하. 세부 옵션은 깊이 2단계로
3. **역할별 가시성** — Pro 전용 기능은 카드로 분리 (무료 사용자에게는 업셀)
4. **CTA 통합** — 같은 행동(분석 거부)은 단일 토글

### 2.2 변화 측정

| 지표 | Before | After |
|------|--------|-------|
| 1단계 가시 옵션 | 13+ | 7 |
| 데이터 권리 진입점 | 4곳 | 1곳 ("내 데이터 · 프라이버시") |
| 토글 중복 | 4건 (analytics opt-out × 2, crash opt-out × 2) | 0건 |
| 보안 설정 그룹화 | ❌ | ✅ "로그인 보안" |

---

## 3. 설정 화면 IA (1단계)

```
┌──────────────────────────────────┐
│ 설정                              │
├──────────────────────────────────┤
│ 1. 프로필 & 계정                  │ → 이름/사진/이메일/로그아웃
│ 2. 알림                          │ → 푸시/이메일/SMS 채널별
│ 3. 로그인 보안                    │ → 복구 이메일/세션/2FA
│ 4. 내 데이터 · 프라이버시          │ → 데이터 권리 단일 허브 (§4)
│ 5. 구독 & 결제                    │ → Pro/영수증/카드
│ 6. 도움 & 지원                    │ → FAQ/문의/버전
│ 7. 정보                          │ → 약관/개인정보/라이선스
└──────────────────────────────────┘
```

상단 7개 그룹만 1단계 가시. 어떤 옵트아웃도 1단계에 노출되지 않음.

---

## 4. "내 데이터 · 프라이버시" 단일 허브 (§4)

```
┌──────────────────────────────────┐
│ 내 데이터 · 프라이버시              │
├──────────────────────────────────┤
│ [데이터 수집]                     │
│ ▸ 데이터 수집 끄기        🔘 OFF │  ← 통합 토글 (§4.1)
│ ▸ 광고/마케팅 알림 받기   🔘 OFF │
│                                  │
│ [내 데이터]                       │
│ ▸ 내 데이터 내보내기 (JSON)        │
│ ▸ 로그인 기록 보기                 │
│ ▸ 부모 동의 관리 (자녀 있을 시)    │  ← Year 2 활성화 시만 표시
│                                  │
│ [계정 종료]                       │
│ ▸ 계정 삭제                       │  ← 빨간색
│                                  │
│ [법적 고지]                       │
│ ▸ 개인정보 처리방침                │
│ ▸ 이용약관                       │
└──────────────────────────────────┘
```

### 4.1 "데이터 수집 끄기" 통합 토글

단일 토글 OFF 시 다음이 동시에 비활성:
- `event_tracking_spec` Firebase Analytics 이벤트 전송
- `crashlytics_spec` Crashlytics 자동 수집 + Sentry breadcrumb

사용자 인지 모델: "내가 한 행동을 회사가 추적하는지 여부 = 하나의 결정"

```dart
// AppPreferences에서 단일 키로 관리
@riverpod
class DataCollectionEnabled extends _$DataCollectionEnabled {
  bool build() => true;
  Future<void> toggle(bool enabled) async {
    await _firebaseAnalytics.setAnalyticsCollectionEnabled(enabled);
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(enabled);
    state = enabled;
  }
}
```

내부적으로 두 토글은 각자 존재(개별 사용자가 운영 측면에서 분리해야 할 가능성 대비)하지만 **UI는 하나만 노출**.

### 4.2 광고/마케팅 별도 분리

광고/마케팅 푸시는 분석 수집과 다른 개념(맞춤 광고 노출). 사용자가 분리해서 인지하므로 별도 토글 유지.

### 4.3 데이터 권리 → 단일 허브

다음은 모두 이 화면에서만 접근:
- 내보내기 (`account_lifecycle_spec §6` GDPR Art.20)
- 삭제 (`account_lifecycle_spec §2` GDPR Art.17)
- 동의 이력 (`account_lifecycle_spec §3.4` ParentalConsent 철회)
- 로그인 기록 (`account_lifecycle_spec §4.5` AuditLog 조회)

다른 화면(프로필, 계정 화면)에서는 이 허브로 링크만.

---

## 5. "로그인 보안" 그룹 (§5)

```
┌──────────────────────────────────┐
│ 로그인 보안                       │
├──────────────────────────────────┤
│ ▸ 복구 이메일      🟡 미설정      │  ← 미설정 시 권장 뱃지
│ ▸ 활성 세션        3대 활성       │
│ ▸ 로그인 알림      이메일 + 푸시   │
│                                  │
│ [Pro 전용]                       │
│ ▸ 백업 코드        Pro 업그레이드 │  ← 무료 사용자: 업셀
└──────────────────────────────────┘
```

`account_recovery_spec` 의 모든 항목이 이 그룹으로 집결.

---

## 6. 다른 스펙과의 진입점 매핑

| 스펙 | 본문 정의 위치 | 진입점 |
|------|-------------|--------|
| event_tracking_spec | §2.3 사용자 옵트아웃, §7 | 이 IA 스펙 §4.1 |
| crashlytics_spec | §7.1 사용자 옵트아웃 | 이 IA 스펙 §4.1 (통합) |
| account_lifecycle_spec | §2 삭제, §3.4 동의 철회, §4.5 AuditLog, §6 내보내기 | 이 IA 스펙 §4 |
| account_recovery_spec | §3 복구 이메일, §4 백업 코드, §6 세션 | 이 IA 스펙 §5 |
| customer_support_spec | §2 Zendesk 문의 | 이 IA 스펙 §1 "도움 & 지원" |

각 스펙은 본문 유지하되 "진입점은 settings_information_architecture_spec §X 참조" 한 줄 명시.

---

## 7. AppStrings 키

| 키 | 한국어 |
|----|--------|
| `settingsGroupProfile` | 프로필 & 계정 |
| `settingsGroupNotifications` | 알림 |
| `settingsGroupLoginSecurity` | 로그인 보안 |
| `settingsGroupDataPrivacy` | 내 데이터 · 프라이버시 |
| `settingsGroupSubscription` | 구독 & 결제 |
| `settingsGroupSupport` | 도움 & 지원 |
| `settingsGroupAbout` | 정보 |
| `privacyDataCollectionToggle` | 데이터 수집 끄기 |
| `privacyDataCollectionDescription` | 앱 사용 분석과 오류 진단을 위한 데이터 수집을 멈춥니다 |
| `privacyAdMarketingToggle` | 광고/마케팅 알림 받기 |
| `privacyMyDataSection` | 내 데이터 |
| `privacyAccountTerminationSection` | 계정 종료 |
| `privacyLegalSection` | 법적 고지 |
| `securityRecoveryEmailBadge` | 미설정 — 설정 권장 |

---

## 8. UX 감정 설계

| 감정 | 설계 의도 |
|------|----------|
| 🟢 안심 | "내 데이터는 한 곳에서 다 본다" — 흩어짐 불안 해소 |
| 🟢 통제 | "수집 끄기 1개만 누르면 끝" — 결정 부담 ↓ |
| 🟡 인지 | "복구 이메일 미설정" 뱃지로 잠금 사고 예방 (강제 아닌 권장) |
| 🔴 무게 | "계정 삭제"는 빨간색 + 별도 섹션 — 실수 방지 |

---

## 9. 의사결정 로그

| 일자 | 결정 | 근거 |
|------|------|------|
| 2026-05-18 | 단일 허브 "내 데이터 · 프라이버시" 채택 | 13+ 토글 분산은 사용자가 "어디서 끄는지" 모름. GDPR/PIPA 권리도 흩어져서 컴플레인 빈도 ↑ |
| 2026-05-18 | analytics + crash 옵트아웃 통합 (1 UI 토글) | 사용자 인지 모델 = "추적 여부 1개 결정". 운영상 분리는 내부 키로만 |
| 2026-05-18 | 광고/마케팅은 별도 토글 유지 | 추적과 광고는 사용자가 다른 개념으로 인지 |
| 2026-05-18 | 1단계 7개 그룹 제한 | Miller's Law (7±2). 옵트아웃은 깊이 2단계로 |
| 2026-05-18 | 백업 코드 무료 사용자에게 업셀 카드로 | Pro 전용 기능 발견 + 결제 동기 부여 |

---

## 10. 검증

### 10.1 출시 전 체크리스트

- [ ] 1단계 가시 옵션 7개 이하
- [ ] 모든 데이터 권리 진입이 "내 데이터 · 프라이버시"에서 가능
- [ ] event_tracking, crashlytics 토글 UI 1개로 통합 (내부 상태는 2개 유지)
- [ ] 보안 그룹에 복구 이메일/세션/백업 코드(Pro) 집결
- [ ] 다른 스펙들이 진입점을 본 IA 참조하도록 갱신

### 10.2 사용자 테스트

5명 사용성 테스트:
- "광고 추적을 끄려면 어디로 가요?" → 90% 정답 (이전 IA: 30%)
- "내 데이터를 다운받으려면?" → 90% 정답
- "비밀번호를 잊었을 때 어떻게 복구해요?" → 80% 정답 (복구 이메일 위치 발견)

---

## 11. 관련 문서

- [event_tracking_spec.md](../analytics/event_tracking_spec.md) — 옵트아웃 토글 본문은 §2.3 유지, 진입점은 본 IA §4.1
- [crashlytics_spec.md](../architecture/crashlytics_spec.md) — 옵트아웃 토글 본문은 §7.1 유지, 진입점은 본 IA §4.1
- [account_lifecycle_spec.md](../user/account_lifecycle_spec.md) — 데이터 권리 본문, 진입점은 본 IA §4
- [account_recovery_spec.md](../user/account_recovery_spec.md) — 보안 본문, 진입점은 본 IA §5
- [ux_guidelines.md](./ux_guidelines.md) — 토글/리스트 컴포넌트 규약
