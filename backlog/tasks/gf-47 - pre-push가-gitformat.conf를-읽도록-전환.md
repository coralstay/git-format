---
id: GF-47
title: pre-push가 gitformat.conf를 읽도록 전환
status: To Do
assignee: []
created_date: '2026-08-27 09:38'
labels: []
dependencies:
  - GF-44
ordinal: 45000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
hooks/pre-push의 언어 감지 마커 5종과 sqlfluff 기본 dialect('ansi') 인라인 리터럴을 hooks/gitformat.conf에서 읽도록 바꾼다. pre-commit과 이제 진짜로 같은 소스를 참조하게 되어 마커 목록 drift가 구조적으로 불가능해진다. has_npm_script 등 함수 로직은 그대로 유지한다.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 언어 감지 마커 5종과 sqlfluff 기본 dialect가 인라인 리터럴 대신 hooks/gitformat.conf에서 읽힌다
- [ ] #2 동작 변경 없음 — tests/robustness-dispatch.bats, tests/smoke.bats가 리팩토링 전후 동일하게 통과한다
<!-- AC:END -->
