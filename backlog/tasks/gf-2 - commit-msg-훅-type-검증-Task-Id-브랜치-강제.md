---
id: GF-2
title: 'commit-msg 훅: type 검증 + Task-Id 브랜치 강제'
status: To Do
assignee: []
created_date: '2026-08-24 03:12'
labels: []
dependencies:
  - GF-1
type: task
ordinal: 2000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Conventional Commits 형식 정규식 검증과, 브랜치명의 GF-<n> 패턴 강제(decision-1, decision-4)
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 형식에 안 맞는 메시지는 커밋을 거부하고 허용 type 목록을 출력한다
- [ ] #2 예외 브랜치(main/develop/release/*) 외에는 브랜치명에 Task-Id 패턴이 없으면 커밋을 거부한다
<!-- AC:END -->
