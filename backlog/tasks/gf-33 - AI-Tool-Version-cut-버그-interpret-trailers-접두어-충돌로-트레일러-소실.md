---
id: GF-33
title: AI-Tool-Version cut 버그 + interpret-trailers 접두어 충돌로 트레일러 소실
status: To Do
assignee: []
created_date: '2026-08-24 08:13'
labels: []
dependencies: []
priority: high
type: bug
ordinal: 33000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
AI_AGENT에 밑줄이 없으면 cut -d_ -f2가 전체 문자열을 그대로 반환해 AI_TOOL_VERSION=AI_TOOL_ID가 됨. 이 상태에서 addIfDifferent가 AI-Tool과 AI-Tool-Version을 같은 트레일러로 오인(접두어 매칭)해 값이 같으면 AI-Tool-Version을 아예 안 붙인다. GF-7에서 doNothing->addIfDifferent로 바꾼 것만으론 이 접두어 충돌을 완전히 못 피함 - 자체 정확 일치 검사로 바꿔야 함.
<!-- SECTION:DESCRIPTION:END -->
