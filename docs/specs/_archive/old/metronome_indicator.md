# 고양이 발 메트로놈 UI 설계안

> 작성일: 2025-12-26
> 상태: ✅ 디자인 확정 (metronome_system.md 하위 스펙)

🐾 고양이 발 "올려놓는" 동작형 메트로놈 UI 설계안

## 컨셉 요약

성격: Quiet / Soft / Adult-friendly

인상: “고양이가 조용히 발을 올려 박자를 알려주는 느낌”

목표: 장시간 연습에도 피로 없는 시각 리듬 피드백

1️⃣ 기본 형태 (Shape Design)

구성

발바닥 큰 원 1개

젤리 패드 작은 원 3개

스타일

Fill only (stroke 없음)

완전한 원형 (각진 요소 ❌)

그림자 ❌ / 하이라이트 ❌ / 질감 ❌

색상

기본: 연보라(Pastel Purple)

비활성: 동일 색상 + opacity 40%

강박: 동일 색상 + scale 변화만 적용

2️⃣ 동작 핵심 – “툭, 올려놓기” Motion Logic
(⚠️ 튀거나 튕기지 않음 / 전자음 느낌 배제)

시작 상태

Paw는 보이지 않음

기준 위치보다 위쪽 -12px

박자 도달 시

120~160ms 동안 아래로 이동

easing: ease-out

착지

위치 고정

scale: 1.00 → 1.06 → 1.00 (총 120ms)

종료

다음 박자 전까지 그대로 유지

사라질 때는 위로 이동 ❌ → opacity fade-out (80ms)

👉 느낌 키워드
툭 / 조용히 / 얹는다 / 살짝 눌린다

3️⃣ 박자별 표현 규칙 (4/4 기준)
강박 (1박)

Paw 등장 + 살짝 큰 scale

scale peak: 1.06

위치: 기준선 정확히 중앙

시각적 강조는 크기만

중간박 (3박)

동일 모션

scale peak: 1.03

약박 (2·4박)

Paw 등장

scale 변화 없음

opacity 85%

루프(1마디)

발 위치 고정

좌/우 이동 ❌

회전 ❌

4️⃣ BPM 연동 규칙 (중요)

60–90 BPM

이동거리: 12px

easing 강조 (느린 착지)

90–120 BPM

이동거리: 8px

120 BPM 이상

이동거리: 5px

scale animation 제거 (시각 피로 방지)

5️⃣ 화면 배치 가이드

고양이 얼굴 바로 아래

숫자 BPM 바로 위

Paw는 “지표 역할”

시선 이동 최소화

박자 + 속도 동시에 인식 가능

6️⃣ 접근성 & UX 기준

애니메이션 off 옵션 제공

색상만으로 박자 구분 ❌ → 크기 변화 필수

배경 대비 최소 4.5:1 유지

진동 / 소리 없이도 리듬 인식 가능

7️⃣ 개발자용 파라미터 요약

Duration

drop: 140ms

scale: 120ms

fade-out: 80ms

Easing

cubic-bezier(0.22, 0.61, 0.36, 1)

Transform origin

center bottom

8️⃣ 다음 단계 (선택)

SVG Paw Shape 파일 제작

iOS SwiftUI / Android Compose 애니메이션 코드

Flutter 대응 AnimationController 세트

다크모드 컬러 팔레트 확장

이미지는 아래에 있음
development/app/lesson-app/assets/images/metronome/paw_minimal_symbol.svg
