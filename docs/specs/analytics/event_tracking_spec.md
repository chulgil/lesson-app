# 이벤트 트래킹 스펙

> 작성일: 2026-05-18
> 상태: 활성 (마스터 SSOT)
> 우선: 🟠 HIGH (출시 후 3개월)
> 관련: `pubspec.yaml`, [analytics_dashboard_spec.md](./analytics_dashboard_spec.md)

---

## 0. 개요

사용자 행동 데이터 수집 + 분석 인프라. **"왜 이탈하는지" 질문에 답하기 위한 기반.**

기술 스택: `firebase_analytics` (이미 `firebase_core` 설치됨 — 추가 설정만 필요).

---

## 1. 현황 진단 (2026-05-18)

| 항목 | 상태 |
|------|------|
| `firebase_core` | ✅ 설치 |
| `firebase_messaging` | ✅ 설치 |
| `firebase_analytics` | ❌ 미설치 |
| 이벤트 스키마 | ❌ 미정의 |
| GA4 Property | ❌ 미생성 |
| BigQuery export | ❌ |
| 분석 대시보드 | 🟡 부분 (`analytics_dashboard_spec.md` — 학생 진도 한정) |

---

## 2. 도입

### 2.1 패키지 추가

```yaml
# pubspec.yaml
dependencies:
  firebase_analytics: ^11.0.0
```

### 2.2 초기화 (`main.dart`)

```dart
await Firebase.initializeApp();
FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(
  !kDebugMode,  // dev 빌드는 수집 안 함
);
```

### 2.3 동의 관리

옵트인이 아닌 **옵트아웃** (한국 사용자 관행):
- 첫 실행 시 개인정보처리방침 동의 시 묵시 동의
- 진입점: 설정 → "내 데이터 · 프라이버시" → "데이터 수집 끄기" (통합 토글)
- OFF 시 `setAnalyticsCollectionEnabled(false)`

> **UI 진입점은 [settings_information_architecture_spec.md §4.1](../design/settings_information_architecture_spec.md) 참조.**
> 토글 본문은 본 스펙에서 정의, 진입점/UI는 IA 스펙이 SSOT. analytics + crashlytics 옵트아웃이 단일 UI 토글로 통합되어 사용자에게 노출된다.

GDPR 적용 사용자(IP 기준 EU)는 별도 옵트인 모달. 출시 후 1년 내 자동 감지 미구현은 무방.

---

## 3. 핵심 이벤트 스키마 (10개)

### 3.1 이벤트 목록

| 이벤트 | 속성 | 의미 | 발화 위치 |
|--------|------|------|----------|
| `onboarding_completed` | `step: int`, `duration_sec: int`, `role: string` | 온보딩 끝 | `onboarding_provider.dart` |
| `student_added` | `is_demo: bool`, `method: string` (qr/manual/invite) | 학생 추가 | `student_repository.dart` |
| `lesson_completed` | `duration_min: int`, `has_note: bool`, `has_recording: bool` | 레슨 완료 | `lesson_provider.dart` |
| `practice_started` | `tool: string` (metronome/tuner/record/free) | 연습 시작 | `practice_provider.dart` |
| `subscription_upgraded` | `plan: string`, `was_trial: bool`, `mrr_delta: int` | 유료 전환 | `billing_provider.dart` |
| `invite_shared` | `channel: string` (kakao/url/qr/referral) | 초대 공유 | `invite_provider.dart` |
| `feature_used` | `name: string` | 기능 사용 | 각 feature 진입 시 |
| `app_opened` | `session_count: int`, `source: string` (icon/notification/deeplink) | 앱 열기 | `app.dart` |
| `review_prompted` | `result: string` (yes/no/dismiss) | 인앱 리뷰 | `review_prompt.dart` |
| `churn_risk_detected` | `days_inactive: int`, `last_action: string`, `engagement_score: int` | 이탈 위험 | 백엔드 → 푸시 시 |

### 3.2 표준 속성 (모든 이벤트)

| 속성 | 값 |
|------|-----|
| `user_role` | teacher / student / parent / academy_owner |
| `app_version` | semver |
| `platform` | ios / android |
| `locale` | ko / en / ja |

### 3.3 PII 차단 원칙

이벤트 속성에 절대 포함하지 않는 값:
- 사용자 이름, 이메일, 전화번호
- 학생 이름, 학부모 정보
- 레슨 노트 본문
- 결제 카드 정보

대신 ID + 익명 메타데이터만:
- `student_id: hash` (해시값)
- `lesson_duration_min` (값)
- `has_note: bool` (존재 여부만)

---

## 4. 이벤트 구현 가이드

### 4.1 공통 헬퍼

`core/analytics/event_tracker.dart` 신규:

```dart
class EventTracker {
  static Future<void> log(String name, {Map<String, Object>? params}) async {
    if (kDebugMode) return;  // dev 차단
    await FirebaseAnalytics.instance.logEvent(
      name: name,
      parameters: {
        'user_role': _currentRole,
        'app_version': _appVersion,
        'platform': defaultTargetPlatform.name,
        'locale': _currentLocale,
        ...?params,
      },
    );
  }
}
```

### 4.2 호출 컨벤션

- 비동기 fire-and-forget (await 안 함)
- 실패해도 앱 로직 영향 없음 (try/catch silent)
- 백엔드와 중복 발화 금지 (서버 사이드는 백엔드 분석)

### 4.3 디버그 모드

`kDebugMode`에서는 콘솔 로그만:
```
[Analytics] lesson_completed {duration_min: 30, has_note: true}
```

---

## 5. 대시보드 / 측정 항목

### 5.1 GA4 Custom Reports

| 리포트 | 메트릭 |
|--------|--------|
| Funnel: 가입 → 첫 레슨 | `app_opened` → `onboarding_completed` → `student_added` → `lesson_completed` |
| Funnel: 무료 → Pro | `app_opened` → `subscription_upgraded` (plan=pro) |
| Retention | D1 / D7 / D30 retention by `user_role` |
| Engagement | 평균 세션 길이, 일일 활성 사용자 (DAU) |
| Churn | `churn_risk_detected` 발화율, 복귀율 |

### 5.2 BigQuery Export

GA4 → BigQuery 일일 export 활성화. SQL로 커스텀 분석.

### 5.3 알림

- D30 retention < 20% → Slack 알림 (출시 후 1개월부터)
- `churn_risk_detected` 일간 증가율 > 30% → 알림

---

## 6. 백엔드 보강 (`churn_risk_detected`)

리인게이지먼트 워커(`reengagement_spec.md`)와 연동:

```python
# inactivity_detector.py
def detect_and_dispatch():
    for user in at_risk_users:
        analytics_client.log(
            event="churn_risk_detected",
            user_id=hash(user.id),
            params={
                "days_inactive": (now - user.last_active_at).days,
                "last_action": user.last_action_type,
                "engagement_score": user.engagement_score,
            },
        )
```

Firebase Analytics는 서버 사이드 SDK 미지원 → **GA4 Measurement Protocol** 직접 호출 또는 BigQuery 직접 적재.

---

## 7. 사용자 권리

| 권리 | 구현 |
|------|------|
| 데이터 수집 거부 | 설정 → "내 데이터 · 프라이버시" → 데이터 수집 끄기 ([IA spec §4.1](../design/settings_information_architecture_spec.md) 참조) |
| 수집된 데이터 조회 | `account_lifecycle_spec.md §6` 데이터 내보내기 포함 |
| 데이터 삭제 | 계정 삭제 시 GA4 User Property 익명화 + 30일 후 영구 |

---

## 8. AppStrings 키

| 키 | 한국어 |
|----|--------|
| `analyticsOptOutTitle` | 사용 데이터 수집 |
| `analyticsOptOutSubtitle` | 앱 개선을 위한 익명화된 사용 통계를 수집해요. 개인정보는 포함되지 않아요. |
| `analyticsOptedOut` | 데이터 수집을 끄셨어요 |

---

## 9. 검증

| 시점 | 검증 |
|------|------|
| 도입 PR | DebugView에서 이벤트 실시간 확인 |
| QA | 10개 이벤트 모두 1회씩 발화 시나리오 작성 |
| 출시 후 1주 | GA4 대시보드에서 이벤트 발화량 정상 확인 |
| 분기별 | PII 누출 감사 (BigQuery sample 100건 review) |

---

## 10. 의사결정 로그

| 일자 | 결정 | 근거 |
|------|------|------|
| 2026-05-18 | firebase_analytics 채택 (Mixpanel/Amplitude 대신) | 이미 firebase_core 설치, 무료 무제한, BigQuery export |
| 2026-05-18 | 옵트아웃 방식 채택 (한국) | EU 사용자 옵트인 별도 처리는 EU 진출 시점에 |
| 2026-05-18 | PII 차단을 코드 레벨로 강제 | EventTracker helper에서 화이트리스트 강제 |
| 2026-05-18 | 10개 핵심 이벤트로 시작 | 과도한 이벤트 = 분석 노이즈 (industry best practice) |

---

## 11. 관련 문서

- [analytics_dashboard_spec.md](./analytics_dashboard_spec.md) — 인앱 대시보드 (학생 진도)
- [reengagement_spec.md](../notification/reengagement_spec.md) — `churn_risk_detected` 연동
- [account_lifecycle_spec.md](../user/account_lifecycle_spec.md) — 데이터 권리
- [paywall_spec.md](../subscription/paywall_spec.md) — `subscription_upgraded` 발화점
