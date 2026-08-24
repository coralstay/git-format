---
id: GF-37
title: cpp.sh/sql.sh diff-filter가 rename(R)을 제외함
status: To Do
assignee: []
created_date: '2026-08-24 08:13'
labels: []
dependencies: []
type: bug
ordinal: 37000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
--diff-filter=ACM은 rename 상태(R)를 포함 안 함. 파일을 리네임하면서 동시에 수정한 경우 clang-format/sqlfluff 체크를 건너뛴다. ACMR로 바꿔야 함.
<!-- SECTION:DESCRIPTION:END -->
