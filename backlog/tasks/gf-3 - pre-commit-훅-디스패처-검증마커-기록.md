---
id: GF-3
title: pre-commit 훅 디스패처 + 검증마커 기록
status: To Do
assignee: []
created_date: '2026-08-24 03:12'
labels: []
dependencies:
  - GF-2
type: task
ordinal: 3000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
package.json/pyproject.toml/pom.xml/CMakeLists.txt 등으로 언어 감지 후 해당 체크 실행, 통과 시 검증마커 기록(decision-3)
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 마커 없는 언어는 아무 것도 안 하고 통과한다
- [ ] #2 체크 통과 시 .gitformat-verified 마커가 기록된다
<!-- AC:END -->
