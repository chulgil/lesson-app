# Bundled signature fonts (SIL OFL 1.1)

Notebook × Score 시그니처 타이포그래피용 폰트를 오프라인-퍼스트 렌더링을 위해
로컬 번들로 포함한다. google_fonts 패키지가 런타임 페치 대신 이 에셋에서 로드한다
(app_bootstrap.dart: `GoogleFonts.config.allowRuntimeFetching = false`).

| 패밀리 | weight/style | 파일 |
|---|---|---|
| Playfair Display | 400·400i·500i·600·600i·700 | PlayfairDisplay-*.ttf |
| Gaegu | 400·700 | Gaegu-*.ttf |
| IBM Plex Mono | 400·500·600 | IBMPlexMono-*.ttf |

- 라이선스: SIL Open Font License 1.1 (OFL-*.txt).
- 출처: Google Fonts (fonts.gstatic.com static instances).
- 파일명 규약: google_fonts 8.x `{Family}-{Variant}.ttf` endsWith 매칭.
