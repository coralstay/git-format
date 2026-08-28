# Pro Git vendoring

git-format 개발·문서 작업 중 git 개념(특히 훅, 커스터마이징, 내부 구조)을
오프라인으로 참고하기 위해 공식 Pro Git 책의 영문 원문을 저장해둔다.

- **원본**: https://git-scm.com/book/en/v2 (Scott Chacon, Ben Straub 저)
- **소스**: https://github.com/progit/progit2
- **라이선스**: [CC BY-NC-SA 3.0 Unported](https://creativecommons.org/licenses/by-nc-sa/3.0/)
  — 저작자 표시, 비영리, 동일조건변경허락. 전문은 `LICENSE.asc` 참고.
- **형식**: AsciiDoc(`.asc`) 원문 그대로. 빌드 산출물(이미지, 다이어그램 소스,
  콜아웃 아이콘, 표지 등 바이너리 에셋)은 제외하고 텍스트만 vendoring했다.
- **구조**: 최상위 `chNN-*.asc`/`A-*.asc`~`C-*.asc`는 각 장의 서문/요약을 담고
  `book/NN-.../sections/*.asc`를 `include::`로 끌어온다 — 원본 저장소 구조
  그대로다.
- git-format 훅과 가장 관련 깊은 절: `book/08-customizing-git/sections/hooks.asc`
  (Git Hooks), `book/08-customizing-git/sections/config.asc` (Git Configuration),
  `book/10-git-internals` (Git Internals).

이 디렉터리는 참고용 vendoring이며, git-format 자체의 코드/문서는 별도로
[backlog/decisions/](../../../backlog/decisions/)에 기록돼 있다. 비영리
라이선스이므로 이 디렉터리 내용을 상업적으로 재배포하지 않는다.
