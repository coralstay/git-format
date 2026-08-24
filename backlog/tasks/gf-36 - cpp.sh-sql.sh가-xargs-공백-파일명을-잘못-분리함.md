---
id: GF-36
title: cpp.sh/sql.sh가 xargs 공백 파일명을 잘못 분리함
status: To Do
assignee: []
created_date: '2026-08-24 08:13'
labels: []
dependencies: []
type: bug
ordinal: 36000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
git diff --cached --name-only 결과를 echo | xargs로 넘기면 공백 포함 파일명이 여러 인자로 쪼개진다. -z/-0으로 NUL 구분해야 함.
<!-- SECTION:DESCRIPTION:END -->
