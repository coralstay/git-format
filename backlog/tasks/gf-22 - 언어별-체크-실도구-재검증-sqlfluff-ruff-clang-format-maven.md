---
id: GF-22
title: 언어별 체크 실도구 재검증 (sqlfluff/ruff/clang-format/maven)
status: To Do
assignee: []
created_date: '2026-08-24 04:48'
labels: []
dependencies:
  - GF-21
type: task
ordinal: 22000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
brew로 sqlfluff/ruff/clang-format/maven 설치 후, GF-17/18(SQL)과 GF-4/10(python/cpp/java) 계열 테스트를 PATH 셔밍 대신 실제 도구로 재작성한 bats 테스트로 대체
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 sql.sh가 실제 sqlfluff로 통과/실패 케이스를 검증한다
- [ ] #2 python.sh가 실제 ruff로 통과/실패 케이스를 검증한다
- [ ] #3 cpp.sh가 실제 clang-format으로 통과/실패 케이스를 검증한다
- [ ] #4 java.sh가 실제 mvn(pom.xml 프로젝트)으로도 검증한다(기존엔 gradle만 실도구였음)
<!-- AC:END -->
