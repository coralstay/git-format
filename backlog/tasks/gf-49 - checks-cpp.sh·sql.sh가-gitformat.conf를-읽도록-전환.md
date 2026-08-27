---
id: GF-49
title: checks/cpp.sh·sql.sh가 gitformat.conf를 읽도록 전환
status: To Do
assignee: []
created_date: '2026-08-27 09:38'
labels: []
dependencies:
  - GF-44
ordinal: 47000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
hooks/checks/cpp.sh의 C/C++ 확장자 목록과 hooks/checks/sql.sh의 기본 dialect('ansi') 인라인 리터럴을 hooks/gitformat.conf에서 읽도록 바꾼다. 두 파일 간 mktemp+trap 파일목록 수집 로직은 공유하지 않고 지금처럼 각자 독립적으로 유지한다.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 cpp.sh의 확장자 목록과 sql.sh의 기본 dialect가 인라인 리터럴 대신 hooks/gitformat.conf에서 읽힌다(두 파일 간 함수 공유는 없음)
- [ ] #2 동작 변경 없음 — tests/checks-cpp.bats, tests/checks-sql.bats가 리팩토링 전후 동일하게 통과한다
<!-- AC:END -->
