# UX 규칙 — 반복 위반 방지

> lessons-learned.md에서 UX 관련 교훈을 분리. 에이전트가 구현 시 자동 참조.
> 상세 디자인 토큰/컴포넌트: `docs/specs/design/ux_guidelines.md`

## 코딩 전 필수 조회 (HARD-GATE)

1. `AppColors` 클래스 → 색상 확인 (없으면 상수 추가)
2. `core/utils/` → 기존 유틸 사용 (NameUtils, date_format_utils 등)
3. `core/widgets/` → 기존 공통 위젯 확인

**공통 유틸 필수 사용:**
- 이름: `NameUtils.givenName()` | 날짜: `formatDateYMD()` | 악기색상: `InstrumentColors.getColor()`
- 스케줄 뮤트: `AppColors.scheduleMutedBackground`, `AppColors.scheduleMutedAccent`

**원샷 UX**: 한 번 탭으로 모든 연관 작업 완료 → [UX 가이드라인](docs/specs/design/ux_guidelines.md)

## 색상 규칙

- **AppColors만 사용** — `Color(0x...)` 하드코딩 절대 금지 (#6)
- **3색 이하 원칙** — 한 화면에서 semantic color(success/warning/error) 3종 이상 동시 사용 금지. stat 카드는 primary 단색 통일 (#14)
- **멀티 뷰 색상 일관성** — 같은 데이터를 보여주는 뷰(주간/일간)에서 색상 규칙이 동일해야 함. 새 뷰 추가 시 기존 뷰 grep 필수 (#17)

## 위젯 재사용

- **공통 위젯 우선** — `core/widgets/` 에 유사 위젯이 있으면 반드시 재사용. 새로 만들기 전 기존 확인 필수
- **AppTypography만 사용** — `fontSize: N` 직접 사용 금지
- **AppSpacing만 사용** — `EdgeInsets.all(16)` 대신 `EdgeInsets.all(AppSpacing.space4)`

## 메뉴/진입점 규칙

- **중복 메뉴 금지** — 프로필 탭에 수정 + 메뉴 안에 또 수정 = 중복. 하나로 통합 (#9, #19)
- **같은 행동 → 하나의 CTA** — "수강권 임박"과 "수강권 만료"처럼 상태는 다르지만 행동(재발급)이 같으면 통합 (#16)
- **관련 정보 한곳 관리** — 설정이 3개 이상 화면에 분산되면 단일 스크롤로 통합 검토 (#9)

## 인터랙션 규칙

- **얕은 뎁스** — 모든 기능 2탭 이내 도달
- **원클릭** — 핵심 작업은 한 번 탭으로 완료
- **Hick's Law** — 하루 10회+ 반복 인터랙션은 선택지 1개. 뉘앙스 필요 시 텍스트 입력 (#22)
- **플레이스홀더 UI 금지** — 미구현 기능의 UI 요소는 코드에서 제거. "Phase N에서 구현 예정"은 스펙에만 명시 (#15)
- **NO-OP 버튼 금지** — 탭해도 아무 일도 안 일어나는 버튼은 앱 신뢰 하락 (#4, #15)

## 레이아웃 규칙

- **Row 카드 수 고정** — 조건부 카드가 Row를 깨트리면 별도 배너로 분리 (#13)
- **BoxDecoration border** — 0.5px OVERFLOW 유발하므로 별도 Container(height: 0.5)로 분리 (#5)

## 검증 grep 패턴

```bash
# 하드코딩 색상 검출
grep -rn "Color(0x" --include="*.dart" features/

# fontSize 직접 사용
grep -rn "fontSize:" --include="*.dart" features/ | grep -v "AppTypography"

# EdgeInsets 숫자 직접
grep -rn "EdgeInsets\." --include="*.dart" features/ | grep -v "AppSpacing"

# 빈 상태 위젯 미사용
grep -rn "Text('데이터가 없습니다')" --include="*.dart" features/

# NO-OP 콜백
grep -rn "onTap: () {}" --include="*.dart" features/
grep -rn "onPressed: null" --include="*.dart" features/
```
