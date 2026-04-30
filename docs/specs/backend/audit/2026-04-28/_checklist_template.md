# Audit Checklist Template

> 각 도메인 audit 문서가 이 템플릿을 따른다.

## 1. SSOT 위치

스펙 파일 vs 프론트 코드 vs 백엔드 코드 중 어느 것이 진정한 SSOT인지 명시.

## 2. 점검 기준 매트릭스

| # | 요구사항 (스펙 §) | 프론트 코드 | 백엔드 endpoint | 백엔드 model | 판정 |
|---|------------------|------------|-----------------|--------------|------|
| 1 | (스펙 인용) | (파일:라인) | (METHOD /path) | (model.field) | PASS / FAIL / MISSING |

판정 기준:
- **PASS**: 스펙 = 프론트 = 백엔드 일치
- **FAIL**: 백엔드 endpoint 존재하지만 스펙과 불일치 (필드 누락/타입 다름)
- **MISSING**: 백엔드 endpoint/model 부재
- **STALE**: 백엔드는 구현 있지만 스펙이 미반영

## 3. 갭 상세

각 FAIL/MISSING 항목에 대해:
- 영향 범위 (어느 프론트 화면이 깨지는가)
- 우선순위 (P0=데이터 손실, P1=기능 차단, P2=정합성)
- 권장 조치 (endpoint 신설 / 모델 컬럼 추가 / 마이그레이션 등)

## 4. 결론

- 총 점검 항목: N
- PASS: N
- FAIL/MISSING/STALE: N
- 후속 patch plan 권장 여부
