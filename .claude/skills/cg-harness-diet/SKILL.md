---
name: cg-harness-diet
description: "cg-harness-legacy-scan 리포트의 low-risk 항목만 적용해 하네스를 정리. CLAUDE.md 축소·절차의 Skill 이동·긴 SKILL.md 분리·description 좁히기·삭제 후보 archive 이동. 영구삭제/hooks/MCP/권한 변경 금지. 트리거: harness diet, 하네스 다이어트 실행, 하네스 정리."
---

# cg-harness-diet — low-risk 하네스 정리 실행

**트리거 키워드**: "harness diet", "하네스 다이어트 실행", "하네스 정리", "low-risk 정리"

> 출처: 개발동생 harness-diet 패턴 흡수 (2026-06-19).
> 선행: [cg-harness-legacy-scan] 리포트 필수. 리포트 없이 실행하지 않는다.

## 선행 조건 (게이트)

1. `cg-harness-legacy-scan` 리포트가 있고, 사용자가 **low-risk 목록을 납득**했다.
2. 작업트리가 clean (`git status`) — 정리 변경을 별도 커밋으로 분리하기 위함.
3. 불확실하면 수정하지 말고 **수동 승인 목록**에 남긴다.

## 허용되는 변경 (low-risk 만)

1. CLAUDE.md 의 중복·과도하게 일반적인 지침 축소.
2. 특정 작업에만 필요한 절차를 CLAUDE.md → `.claude/skills/` 로 이동.
3. 너무 긴 SKILL.md 를 `SKILL.md` + `reference.md` + `examples.md` 로 분리.
4. Skill description 을 더 좁고 명확하게.
5. 자동 호출 범위가 넓은 Skill 에 **"사용하지 말아야 할 때"** 섹션 추가.
6. 삭제 후보는 **영구삭제 금지** — `.claude/archive/harness-diet-{YYYY-MM-DD}/` 로 이동(`git mv`/`mv`).
7. 변경 이유는 파일 주석으로 흩지 말고 **최종 요약**에 모은다.

## 금지되는 변경

1. 파일 **영구 삭제** (archive 이동만).
2. **hooks 수정**.
3. **MCP 설정 수정**.
4. **allowed-tools 권한 확대**.
5. 애플리케이션 코드 수정.
6. 테스트/빌드/배포 명령 임의 실행.
7. 불확실 항목 수정 (수동 승인 목록에만 남김).

## 정리 원칙

- 하네스는 더 붙이는 게 아니라 **필요한 순간에만 나타나야** 한다.
- 전역 지침은 **짧고 안정적인 프로젝트 원칙**만. 반복 절차는 Skill 로.
- 긴 설명·예시·체크리스트는 `reference.md`/`examples.md` 로 분리.
- 작은 작업을 느리게 만드는 규칙은 **조건부 규칙**으로.
- **안전장치는 함부로 삭제하지 않는다.**

## 절차

1. 리포트의 §8 low-risk 목록을 todo 로 전개.
2. archive 디렉토리 생성: `.claude/archive/harness-diet-{날짜}/` (날짜는 `date +%F`).
3. 항목별 변경 적용 (위 허용 범위만). 삭제 후보는 archive 이동.
4. `git diff` 로 변경 확인 — 의도 외 변경 0 인지(surgical) 검증.
5. 정리 변경을 **별도 커밋**으로 분리.

## 작업 후 보고

1. 변경한 파일 목록
2. 파일별 변경 이유
3. Before / After 요약
4. diff 요약
5. Claude 행동이 어떻게 달라지는지
6. 아직 사람이 승인해야 하는 high-risk 항목
7. 검증용 smoke-test 프롬프트 5개

> archive 이동은 복구 가능. 의심되면 이동(보존)이 삭제보다 항상 안전하다.
