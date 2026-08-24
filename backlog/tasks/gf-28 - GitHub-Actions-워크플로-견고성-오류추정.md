---
id: GF-28
title: GitHub Actions 워크플로 견고성 (오류추정)
status: To Do
assignee: []
created_date: '2026-08-24 04:48'
labels: []
dependencies:
  - GF-21
type: task
ordinal: 28000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
얕은 클론(fetch-depth 기본값)일 때 PR 커밋 범위 검증이 어떻게 동작하는지, 권한 최소화 검토
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 fetch-depth를 지정 안 한 캐ller 워크플로에서도 verify.yml이 명확하게 실패하거나 우회하는지(현재 fetch-depth:0 전제라 미지정 시 동작 확인 필요)
- [ ] #2 GITHUB_TOKEN 권한이 최소한(contents:read 등)으로 충분한지 점검
<!-- AC:END -->
