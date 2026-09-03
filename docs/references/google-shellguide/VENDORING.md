# Google Shell Style Guide vendoring

훅 스크립트를 POSIX sh로 유지하기로 한 결정(decision-9)에 따라, 셸
스크립트를 어떻게 구조화할지(함수 분해, 화면 크기 준수 등) 판단할 때 참조할
관례를 오프라인으로도 정확히 대조할 수 있게 원문을 저장해둔다(decision-13 —
decision-9의 "외부 자료 원문 vendoring/출처 URL 금지" 항목을 대체함).

- **원본**: https://google.github.io/styleguide/shellguide.html
- **소스**: https://github.com/google/styleguide (`gh-pages` 브랜치의
  `shellguide.md`)
- **라이선스**: [CC BY 3.0 Unported](https://creativecommons.org/licenses/by/3.0/)
  — 저작자 표시만 요구, 비영리 제한 없음(Pro Git과 달리 상업적 재배포도
  허용된다). 전문은 `LICENSE` 참고.
- **저작권자**: Google Inc.
- **형식**: 원문 GitHub-flavored Markdown(`shellguide.md`) 그대로. 변형 없음.
- git-format 훅과 가장 관련 깊은 절: [Formatting](https://google.github.io/styleguide/shellguide.html#s5-formatting)
  (특히 함수/제어흐름 구조), [Naming Conventions](https://google.github.io/styleguide/shellguide.html#s7-naming-conventions),
  [Function Comments](https://google.github.io/styleguide/shellguide.html#s4.2-function-comments).

이 저장소는 decision-9에 따라 셸을 POSIX sh로 한정하므로, 원문이 권장하는
일부 항목 중 POSIX와 충돌하는 bash 전용 기능(예: `local` 키워드, `[[ ]]`
조건문, 배열, 확장 산술 비교, 정규식 매칭 연산자)은 그대로 채택하지 않는다
— 함수 분해·네이밍·주석 관례처럼 POSIX sh와 충돌하지 않는 부분만 참고한다.

git-format 자체의 코드/문서는 별도로 [backlog/decisions/](../../../backlog/decisions/)에
기록돼 있다.
