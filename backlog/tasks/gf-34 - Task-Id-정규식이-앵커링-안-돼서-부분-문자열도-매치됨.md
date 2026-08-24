---
id: GF-34
title: Task-Id 정규식이 앵커링 안 돼서 부분 문자열도 매치됨
status: To Do
assignee: []
created_date: '2026-08-24 08:13'
labels: []
dependencies: []
type: bug
ordinal: 34000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
grep -qiE "${TASK_PREFIX}-[0-9]+"가 앵커 없이 아무 위치나 매치. 예: taskPrefix=ID일 때 브랜치명 'valid-42-fix'가 'id-4' 부분 매치로 통과함. post-commit의 Task-Id 트레일러 추출도 같은 문제.
<!-- SECTION:DESCRIPTION:END -->
