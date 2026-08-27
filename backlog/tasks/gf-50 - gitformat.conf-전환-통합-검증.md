---
id: GF-50
title: gitformat.conf 전환 통합 검증
status: To Do
assignee: []
created_date: '2026-08-27 09:38'
labels: []
dependencies:
  - GF-45
  - GF-46
  - GF-47
  - GF-48
  - GF-49
ordinal: 48000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
GF-45~49(각 훅의 gitformat.conf 전환)가 모두 끝난 뒤, 전체 bats 스위트와 shellcheck를 다시 돌려 회귀가 없는지 통합 확인한다. hooks/gitformat.conf에 남아 있는 값과 실제 훅 동작이 일치하는지도 최종 점검한다.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 bats tests/ 전체가 통과한다
- [ ] #2 shellcheck -s sh hooks/commit-msg hooks/pre-commit hooks/pre-push hooks/post-commit hooks/checks/*.sh install.sh 가 경고 없이 통과한다
<!-- AC:END -->
