---
id: GF-17
title: hooks/checks/sql.sh 언어 체크 추가 (pre-commit lint)
status: To Do
assignee: []
created_date: '2026-08-24 04:29'
labels: []
dependencies: []
type: task
ordinal: 17000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
pre-commit 디스패처에 SQL 감지(.sqlfluff 설정 또는 추적된 .sql 파일) 추가, 스테이징된 .sql 파일에 sqlfluff lint 실행
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 sqlfluff 없으면 조용히 건너뜀
- [ ] #2 .sql 파일도 .sqlfluff도 없으면 건너뜀
- [ ] #3 스테이징된 .sql만 대상으로 lint, 실패 시 커밋 차단
<!-- AC:END -->
