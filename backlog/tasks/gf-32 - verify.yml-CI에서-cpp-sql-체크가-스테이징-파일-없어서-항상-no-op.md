---
id: GF-32
title: verify.yml CI에서 cpp/sql 체크가 스테이징 파일 없어서 항상 no-op
status: To Do
assignee: []
created_date: '2026-08-24 08:13'
labels: []
dependencies: []
priority: high
type: bug
ordinal: 32000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
verify.yml은 컨슈머 저장소를 체크아웃만 하고 git add를 안 해서, git diff --cached 기반인 cpp.sh/sql.sh가 항상 빈 목록을 보고 조용히 건너뛴다. PR에 깨진 C++/SQL이 있어도 CI 백스톱이 절대 못 잡는다.
<!-- SECTION:DESCRIPTION:END -->
