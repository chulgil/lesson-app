# Code Review

$ARGUMENTS 경로의 코드를 리뷰해줘.

## 체크리스트

### 아키텍처
- [ ] Feature-First Clean Architecture 준수 (domain → data → presentation)
- [ ] 레거시 위치(`lib/models/`, `lib/providers/`)에 새 코드 없음
- [ ] 적절한 레이어 분리 (UI에 비즈니스 로직 없음)

### Riverpod 패턴
- [ ] `@riverpod` 어노테이션 사용
- [ ] `ref.watch` vs `ref.read` 올바르게 구분
- [ ] `keepAlive: true` 필요한 Provider에 적용 (빈 화면 방지)
- [ ] AutoDispose 누수 없음

### 코드 품질
- [ ] 타입 힌트 완전
- [ ] null-safety 준수 (불필요한 `!` 없음)
- [ ] 위젯 500줄 이하 (초과 시 분리 필요)
- [ ] `AppColors` 클래스만 사용 (하드코딩 색상 없음)

### 보안
- [ ] secrets 하드코딩 없음
- [ ] 사용자 입력 검증

### 성능
- [ ] 불필요한 위젯 리빌드 없음
- [ ] `const` 생성자 활용
- [ ] 큰 리스트에 `ListView.builder` 사용

### 테스트
- [ ] 핵심 Provider에 테스트 존재
- [ ] Mock Repository에 테스트 데이터 존재

## 출력

각 항목에 대해 통과/미통과/해당없음으로 표시하고,
미통과 항목은 구체적인 파일:라인 번호와 수정 제안을 포함해줘.
