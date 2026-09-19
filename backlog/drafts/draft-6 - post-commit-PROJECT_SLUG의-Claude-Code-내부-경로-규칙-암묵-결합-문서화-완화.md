---
id: DRAFT-6
title: post-commit PROJECT_SLUG의 Claude Code 내부 경로 규칙 암묵 결합 문서화/완화
status: Draft
assignee: []
created_date: '2026-09-19 15:46'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
hooks/post-commit:225의 PROJECT_SLUG=$(printf '%s' "$PWD" | tr -c 'A-Za-z0-9' '-')가 Claude Code 트랜스크립트 경로를 재구성하는 데 쓰이는데, 이는 Claude Code 내부 slug 알고리즘과 암묵적으로 결합돼 있다. Claude Code가 알고리즘을 바꾸면 AI-Model/Tokens-Used 측정이 에러 없이 조용히 실패한다. 이 결합 지점을 코드 주석/문서로 명시하거나, 실패를 감지 가능하게 만들지 검토.

발견 경위: 2026-09-20 '이 프로젝트의 부족한점?' 조사(Explore agent, hooks/post-commit:225)
<!-- SECTION:DESCRIPTION:END -->
