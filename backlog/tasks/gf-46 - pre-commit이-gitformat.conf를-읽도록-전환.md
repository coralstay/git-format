---
id: GF-46
title: pre-commit이 gitformat.conf를 읽도록 전환
status: To Do
assignee: []
created_date: '2026-08-27 09:38'
labels: []
dependencies:
  - GF-44
ordinal: 44000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
hooks/pre-commit의 언어 감지 마커 5종(package.json 등) 인라인 리터럴을 hooks/gitformat.conf에서 읽도록 바꾼다. resolve_self/run_check 함수 로직은 그대로 유지한다.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 언어 감지 마커 5종이 인라인 리터럴 대신 hooks/gitformat.conf에서 읽힌다
- [ ] #2 동작 변경 없음 — tests/robustness-dispatch.bats, tests/checks-*.bats, tests/smoke.bats가 리팩토링 전후 동일하게 통과한다
- [ ] #3 심볼릭 링크(template/) 설치 환경에서도 conf 파일 경로를 정확히 찾는다(GF-16 회귀 없음)
<!-- AC:END -->
