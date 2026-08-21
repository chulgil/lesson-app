# i18n / l10n 마이그레이션 스펙

> 작성일: 2026-05-18
> 상태: 활성 (마스터 SSOT)
> 마일스톤: M2 (단계 1-2), Year 2 (단계 3-4)
> 관련: [i18n-l10n.md](../../../.claude/rules/i18n-l10n.md) 규칙

---

## 0. 현황 진단 (2026-05-18 기준)

### 인프라 ✅ 부분 구축

```
frontend/lib/core/l10n/
├── app_strings.dart              # 6,965줄, 2,311 static const (한국어 하드코딩)
├── arb/
│   ├── app_en.arb                # 기본 영어 (시작됨)
│   └── app_ko.arb                # 한국어 (시작됨)
└── generated/
    ├── app_localizations.dart    # ARB 코드 생성 완료
    ├── app_localizations_en.dart
    └── app_localizations_ko.dart
```

| 항목 | 상태 |
|------|------|
| `intl` 패키지 도입 | ✅ 완료 |
| `flutter_localizations` SDK | ✅ 완료 |
| ARB 코드 생성 (`flutter gen-l10n`) | ✅ 완료 |
| AppStrings → AppLocalizations 이관 | ❌ 0% (ARB에 핵심 키 일부만 있음) |
| 하드코딩 잔재 정리 | ❌ 미정리 |

### 잔재 부채

- **AppStrings 2,311개** — 영구 SSOT가 되었으나 ARB로 이관 필요
- **하드코딩 한글 잔재** — `Text('...')`는 0건이나 `title:`, `subtitle:`, `label:` 등에 잔존
  - 주요 위치: `features/settings/`, `features/schedule/`, `features/student_home/`
  - 표본 측정: `title: '한글'` 패턴 20+ 건 (전체 grep 시 더 늘어남)

---

## 1. 목표

| 단계 | 목표 | 마일스톤 |
|------|------|---------|
| **0. 신규 유입 차단** | 신규 문자열은 ARB+AppLocalizations 로만 추가 — AppStrings 라체트 게이트 | **도입 완료 (2026-08-21)** |
| **1. 하드코딩 박멸** | `title:`, `subtitle:`, `label:`, `hint:` 잔재를 AppStrings 또는 AppLocalizations로 흡수 | M2 |
| **2. ARB 이관** | AppStrings 2,311개 → `app_ko.arb` 키 + AppLocalizations 사용 | M2~M3 |
| **3. 영어 번역** | `app_en.arb` 전체 키 영문 번역 | Year 2 |
| **4. 일본어 추가** | `app_ja.arb` 신규 + locale 분기 UI | Year 2+ |

---

## 1.5 단계 0 — 신규 유입 차단 게이트 (도입 완료, 2026-08-21)

글로벌 확장 전략(옵시디언 56번)의 "지금 당장 할 일": 이관(단계 1~2)이 끝나기 전에도
**부채가 더 늘지 않게** 신규 문자열의 진입점을 ARB 로 고정한다.

- **정책**: 신규 사용자-facing 문자열 = `app_ko.arb` 키(+ `app_en.arb` 병기) + `AppLocalizations`.
  `AppStrings` 신규 상수 추가 금지. 기존 상수는 이관 전까지 사용 유지.
- **기계 강제**: `test/architecture/app_strings_ratchet_test.dart` — `AppStrings` 멤버 수를
  baseline(도입 시점 실측 4,646 = static const 4,108 + static String 538) 이하로 잠근다.
  이관으로 실측이 줄면 baseline 을 하향해 래칫을 조인다.
- **편집 시 리마인더**: `.claude/hooks/scripts/i18n-l10n-guard.py` 가 `app_strings.dart`
  편집 시 stderr advisory 를 낸다 (차단은 라체트 테스트 담당).
- **규칙**: `.claude/rules/i18n-l10n.md` §신규 문자열 = ARB 필수.

---

## 2. 단계 1 — 하드코딩 박멸 (M2)

### 2.1 검출 grep 패턴

```bash
# 직접 한글 문자열이 위젯 파라미터에 박힌 경우
grep -rn "Text('[가-힣]" --include="*.dart" frontend/lib/features/
grep -rn "title: '[가-힣]" --include="*.dart" frontend/lib/features/
grep -rn "subtitle: '[가-힣]" --include="*.dart" frontend/lib/features/
grep -rn "label: '[가-힣]" --include="*.dart" frontend/lib/features/
grep -rn "hint.*'[가-힣]" --include="*.dart" frontend/lib/features/
grep -rn "tooltip: '[가-힣]" --include="*.dart" frontend/lib/features/
```

#### 2.1.1 "ARB 키 존재 미사용" 케이스 (특수 위반)

ARB(`app_ko.arb`)에 키가 정의되어 있는데도 코드에서 직접 한글 문자열을 박는 패턴이 발견됨. 예:

| 위치 | 위반 코드 | 올바른 코드 |
|------|----------|------------|
| `student_home_screen.dart:109` | `Text('레슨')` | `Text(AppStrings.navLessons)` 또는 `Text(loc.navLessons)` |
| `parent_home_screen.dart:70~74` | `Text('홈'), Text('스케줄'), ...` | ARB 키 `navHome`/`navSchedule` 사용 |

검출 절차:

```bash
# 1. ARB 키 추출
jq -r 'keys[]' frontend/lib/core/l10n/arb/app_ko.arb | grep -v "^@" > /tmp/arb_keys.txt
jq -r '. as $arb | keys[] | select(test("^[a-z]") and ($arb[.] | type == "string")) | "\(.)\t\($arb[.])"' frontend/lib/core/l10n/arb/app_ko.arb > /tmp/arb_values.tsv

# 2. ARB에 있는 한글 값이 코드에 그대로 박혀 있는지 검사
awk -F'\t' '{print $2}' /tmp/arb_values.tsv | while read -r value; do
  grep -rn "'${value}'" --include="*.dart" frontend/lib/features/ && echo "↑ ARB 키 존재. AppStrings/AppLocalizations 사용 필요"
done
```

이 케이스가 가장 회피 쉬움 — 키만 바꾸면 끝. 단계 1 작업 시 우선 처리.

### 2.2 정리 규칙 (2026-08-21 단계 0 도입 후 개정)

| 종류 | 이관 대상 |
|------|----------|
| UI 문구 (재사용·1회성 모두) | **ARB 키(app_ko+app_en) + AppLocalizations** — 단계 0 라체트가 AppStrings 신규 상수를 차단. 동일 의미의 **기존 AppStrings 상수/포매터가 있으면 재사용** (C4) |
| 데이터(샘플 데이터 `local_app_release_repository.dart` 등) | seed/asset로 분리 |
| 디버그/로그 문자열 | 이관 제외 (개발자 전용) — 예외 목록: `hardcoded_korean_guard_test.dart`·`i18n-l10n-guard.py` 의 DEBUG_ONLY_FILES |

### 2.3 검수

- `flutter analyze` 통과
- **기계 게이트**: `test/architecture/hardcoded_korean_guard_test.dart` 0건 (2026-08-21 도입 — 검출 범위 lib 전체, features 한정이던 §2.1 grep 을 대체·강화)
- 변경 없는 화면 회귀: `flutter test` + 스크린샷 회귀 (Playwright/golden)

### 2.4 단계 1 실행 기록 (2026-08-21)

- 실측 위반 29건(생산 21파일) 박멸: ARB 신규 22키(ko/en 병기) + 기존 AppStrings 포매터 재사용 2건(`practiceCountTimes`·`usageCountShort`)
- 디버그 전용 2파일(`debug_role_switcher`·`recording_diagnostic_screen`) 은 §2.2 규칙으로 예외 등록
- data 계층의 AppStrings 의존 2건(backup 서비스 onProgress) — #1299 에서 BackupStage/BackupFailure 값 기반으로 해소

### 2.5 리뷰 0821 정정 — 멀티라인 잔존과 라체트 봉인

초기 게이트는 "같은 줄" 정규식이라 dart-format 이 줄바꿈한 멀티라인 호출을 놓쳤다.
전문(full-content) 스캔으로 강화한 결과 **멀티라인 형태 잔존 253건 실측** — 이는
단계 1 스코프(단일행 검출분) 밖의 기존 부채로, 게이트를 baseline 라체트로 전환해
봉인했다 (`hardcodedKoreanBaseline = 253`, 증가=FAIL·감소=라체트 조임). 253건과
`suffixText: '회'` 류 접미사, 커스텀 위젯 named param(`title:`·`unit:` 등)의 한글은
**단계 2 이관 대상**이다.

---

## 3. 단계 2 — ARB 이관 (M2~M3)

### 3.1 키 네이밍 컨벤션

```
<feature><Subject><Action>
```

| 한국어 | ARB key | 영어 |
|--------|---------|------|
| 레슨 요청 | `lessonRequest` | Request lesson |
| 일정 비교 | `scheduleCompare` | Compare schedule |
| 입금 확인 | `paymentConfirm` | Confirm payment |
| 학생 5명 한도에 도달했어요 | `paywallFreeLimitTitle` | You've reached the 5-student limit |

### 3.2 변환 절차

```
1. app_strings.dart 의 const → ARB 키로 매핑 (1:1)
2. app_ko.arb 에 키 + description 추가
3. flutter gen-l10n 실행 → generated/ 갱신
4. 사용처 변경: AppStrings.foo → AppLocalizations.of(context)!.foo
5. AppStrings 상수 제거
```

### 3.3 자동화 옵션

`scripts/i18n_migrate.dart` 스크립트로 AppStrings → ARB 일괄 이관:
```bash
dart run scripts/i18n_migrate.dart \
  --source frontend/lib/core/l10n/app_strings.dart \
  --target frontend/lib/core/l10n/arb/app_ko.arb \
  --dry-run
```

(스크립트 자체는 후속 PR에서 구현)

---

## 4. 단계 3-4 — 영어/일본어 (Year 2)

### 4.1 영어 (M5 이후)

- `app_en.arb` 키 전체 번역
- locale 분기: 기기 언어가 `en`이면 영어 노출
- 화폐: KRW → USD 변환 표시 (Pro 월간 $7.99 등)
- 날짜: `intl` `DateFormat.yMd()` 사용 — `2026.05.18` (ko) / `5/18/2026` (en)

### 4.2 일본어 (Year 2+)

- `app_ja.arb` 신규
- 한국 시장 검증 후 진출 시점 결정

---

## 5. 계층별 정책

> [i18n-l10n.md](../../../.claude/rules/i18n-l10n.md) 강제 규칙 요약

| 계층 | i18n 정책 |
|------|-----------|
| `presentation/` (screens, widgets) | AppStrings/AppLocalizations 사용 ✅ |
| `presentation/extensions/` | enum → 표시 문구 변환 ✅ |
| `presentation/providers/` | UI state는 i18n key 보유 가능 ✅ |
| `domain/` (entities, services) | ❌ AppStrings 직접 import 금지 |
| `data/` (repositories) | ❌ AppStrings 직접 import 금지 |

**예외**: domain enum에 `displayLabel` getter는 [flutter-architecture.md](../../../.claude/rules/flutter-architecture.md) 위반. presentation/extensions/ 로 이동.

---

## 6. n8n / 자동화 메시지

n8n 워크플로우가 앱에 메시지를 전달할 때는 **사람이 읽는 문장 대신 stable key + payload** 로:

```json
// BAD
{ "title": "곧 레슨이 시작됩니다" }

// GOOD
{ "messageKey": "lessonStartingSoon", "params": { "minutes": 10 } }
```

앱에서 key → AppLocalizations 로 해석.

---

## 7. 검증

| 시점 | 검증 |
|------|------|
| 코드 작성 시 | hook `.claude/hooks/scripts/i18n-l10n-guard.py` (자동 경고) |
| PR 생성 시 | grep 패턴 0건 + `flutter gen-l10n` 성공 |
| 단계 1 완료 | 모든 features/*.dart 에서 한글 박힘 0건 |
| 단계 2 완료 | AppStrings 클래스 삭제 또는 < 100줄 |
| 단계 3 완료 | locale=en 으로 앱 실행 시 모든 화면 영문 표시 |

---

## 8. 의사결정 로그

| 일자 | 결정 | 근거 |
|------|------|------|
| 2026-05-18 | AppStrings 즉시 삭제 안 함, ARB 이관 후 단계적 제거 | 6,965줄 → 일시 변환 시 회귀 위험 |
| 2026-05-18 | ARB 키 네이밍: `<feature><Subject><Action>` camelCase | Flutter `gen-l10n` 컨벤션 |
| 2026-05-18 | 영어 우선, 일본어는 Year 2 시장 검증 후 | 일본 진출 확정 전 번역 비용 절감 |
| 2026-05-18 | 단계 1-2는 M2 안에 완료, 더 미루지 않음 | 부채 누적 방지 (현재 6,965줄 → 추가 늘어남) |

---

## 9. 관련 문서

- [.claude/rules/i18n-l10n.md](../../../.claude/rules/i18n-l10n.md) — 작성 규칙 (강제)
- [.claude/rules/flutter-architecture.md](../../../.claude/rules/flutter-architecture.md) — 계층별 import 정책
- [paywall_spec.md](../subscription/paywall_spec.md) — paywall 문구 ARB 키 후보
- [.claude/hooks/scripts/i18n-l10n-guard.py](../../../.claude/hooks/scripts/i18n-l10n-guard.py) — 검증 hook
