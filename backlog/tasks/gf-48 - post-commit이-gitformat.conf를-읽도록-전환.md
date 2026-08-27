---
id: GF-48
title: post-commit이 gitformat.conf를 읽도록 전환
status: To Do
assignee: []
created_date: '2026-08-27 09:38'
labels: []
dependencies:
  - GF-44
ordinal: 46000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
hooks/post-commit의 trailer 키 7종(Verify-Bypassed/Task-Id/AI-Tool/AI-Tool-Version/Co-Authored-By/AI-Model/Hooks-Commit), claude-code 식별자, Co-Authored-By 값 인라인 리터럴을 hooks/gitformat.conf에서 읽도록 바꾼다. 같은 파일 안에서 trailer_exists 호출부와 --trailer 삽입부가 같은 변수를 참조하게 되어 GF-33류 오타 불일치가 구조적으로 불가능해진다. trailer_exists/resolve_self 함수 로직은 그대로 유지한다.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 trailer 키 7종·claude-code 식별자·Co-Authored-By 값이 인라인 리터럴 대신 hooks/gitformat.conf에서 읽히고, 존재확인부와 삽입부가 동일 변수를 참조한다
- [ ] #2 동작 변경 없음 — tests/robustness-post-commit.bats, tests/robustness-injection.bats, tests/smoke.bats가 리팩토링 전후 동일하게 통과한다
- [ ] #3 심볼릭 링크(template/) 설치 환경에서도 conf 파일 경로를 정확히 찾는다(GF-16 회귀 없음)
<!-- AC:END -->
