# Spec — notebook-surface-ssot

> 날짜: 2026-05-04 | 상태: locked

## 1. 목표

Notebook × Score의 전체 화면, 상세 화면, 다이얼로그, 바텀시트 표면 계약을 하나의 SSOT로 고정한다.

## 2. 성공 기준

- [ ] 일반 화면은 `NotebookScreenScaffold`로 paper 배경을 보장한다.
- [ ] 상세 화면은 `NotebookDetailScaffold`로 paper 배경, `titleSpacing: 0`, Playfair AppBar title을 보장한다.
- [ ] 다이얼로그는 `NotebookAlertDialog`로 paper 배경, 투명 surface tint, 각진 ink 테두리, Playfair title을 보장한다.
- [ ] 커스텀 `Dialog`가 필요한 경우에도 `backgroundColor: AppColors.paper`, `surfaceTintColor: Colors.transparent`, `shape: const RoundedRectangleBorder()`를 직접 명시한다.
- [ ] 로딩/처리중 팝업은 투명 route 위 `CircularProgressIndicator`만 띄우지 않고 `showNotebookDialog` 또는 `NotebookAlertDialog` 표면 안에 표시한다.
- [ ] 바텀시트 내부 content는 `NotebookBottomSheet`로 paper 배경, 각진 표면, 공통 handle, SafeArea를 보장한다.
- [ ] `docs/specs/design/detail_screen_template.md`는 레거시 `surfaceLight/primary/white/radiusMedium` 기준을 제거하고 Notebook 토큰만 사용한다.

## 3. 범위

- 공통 래퍼 추가
- 래퍼 위젯 테스트 추가
- 디자인 SSOT 문서 정리

## 4. 범위 외

- 기존 100개 이상 화면의 즉시 전수 교체
- Dialog 98건, BottomSheet 89건의 즉시 전수 교체
- Card 456건 전수 제거

## 5. 후속 이행 순서

1. 상세/신규 화면부터 `NotebookDetailScaffold`로 교체한다.
2. 자주 쓰는 팝업부터 `NotebookAlertDialog`로 교체한다.
3. 업무용 바텀시트를 `NotebookBottomSheet`로 교체한다.
4. `Card` 사용을 도메인별로 `Container` + `Border` 종이 조각 패턴으로 축소한다.
