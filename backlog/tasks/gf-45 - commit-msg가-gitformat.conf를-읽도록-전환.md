---
id: GF-45
title: commit-msg가 gitformat.conf를 읽도록 전환
status: To Do
assignee: []
created_date: '2026-08-27 09:38'
labels: []
dependencies:
  - GF-44
ordinal: 43000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
hooks/commit-msg의 마커 파일명(.gitformat-verified), TASK_PREFIX/EXEMPT 기본값, AI 도구 식별자(claude-code) 인라인 리터럴을 hooks/gitformat.conf(git config --file)에서 읽도록 바꾼다. resolve_self/cleanup_marker_on_reject 등 함수 로직은 그대로 유지한다(합치지 않음). 컨슈머 저장소의 gitformat.taskPrefix/gitformat.branchExempt 오버라이드 우선순위(설정 있으면 그 값, 없으면 conf의 기본값)는 유지한다.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 마커 파일명·TASK_PREFIX/EXEMPT 기본값·claude-code 식별자가 인라인 리터럴 대신 hooks/gitformat.conf에서 읽힌다
- [ ] #2 동작 변경 없음 — tests/robustness-commit-msg.bats, tests/smoke.bats가 리팩토링 전후 동일하게 통과한다
- [ ] #3 심볼릭 링크(template/) 설치 환경에서도 conf 파일 경로를 정확히 찾는다(GF-16 회귀 없음)
<!-- AC:END -->
