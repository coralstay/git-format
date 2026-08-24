---
id: GF-6
title: 'post-commit 훅: --no-verify 탐지(Verify-Bypassed)'
status: To Do
assignee: []
created_date: '2026-08-24 03:12'
labels: []
dependencies:
  - GF-3
type: task
ordinal: 6000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
검증마커 유무로 --no-verify 판단, amend로 Verify-Bypassed 트레일러 삽입, 재귀가드+멱등성(decision-3)
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 --no-verify로 커밋해도 무한루프 없이 Verify-Bypassed: true가 삽입된다
- [ ] #2 정상 커밋에는 트레일러가 붙지 않는다
- [ ] #3 --amend를 반복해도 트레일러가 중복되지 않는다
<!-- AC:END -->
