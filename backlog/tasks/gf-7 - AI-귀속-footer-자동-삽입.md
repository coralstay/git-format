---
id: GF-7
title: AI 귀속 footer 자동 삽입
status: To Do
assignee: []
created_date: '2026-08-24 03:12'
labels: []
dependencies:
  - GF-6
type: task
ordinal: 7000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
AI-Tool/AI-Tool-Version(AI_AGENT 파싱), AI-Session-Id(CLAUDE_CODE_SESSION_ID), AI-Model(세션 트랜스크립트 message.model 읽기, 비-Claude Code는 gitformat.aiModel 존재+화이트리스트+벤더 검증), Co-Authored-By 자동, Hooks-Commit(git-format 자체 커밋 해시)(decision-5)
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Claude Code 환경에서 AI-Model이 세션 트랜스크립트의 실제 model 값과 일치한다
- [ ] #2 AI 환경이 감지되지 않으면(사람 커밋) 아무 트레일러도 추가되지 않는다
- [ ] #3 트랜스크립트 파싱 실패 시 커밋을 막지 않고 AI-Model만 조용히 생략한다
<!-- AC:END -->
