---
id: GF-84
title: 비-Claude-Code AI 도구의 AI-Model 값 자가신고 한계 조사/개선
status: To Do
assignee: []
created_date: '2026-09-03 01:26'
labels: []
dependencies: []
references:
  - backlog/decisions/decision-5 - AI-귀속-footer-정책-트랜스크립트-기반-AI-Model-포함.md
documentation:
  - hooks/commit-msg
  - hooks/post-commit
  - hooks/gitformat.conf
ordinal: 82000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
decision-5에 따라 Claude Code는 세션 트랜스크립트(message.model)로 AI-Model을 검증하지만, 그 외 AI 도구는 사용자가 gitformat.aiModel에 설정한 값을 존재/화이트리스트 여부만 확인하고 그대로 신뢰한다(자가신고 수준). README '한계 및 향후 검토 과제'에 명시된 항목. 다른 주요 AI 코딩 도구들이 로컬에 검증 가능한 세션 로그/트랜스크립트를 남기는지 조사하고, 가능하면 Claude Code와 유사한 방식으로 검증을 강화하거나, 불가능하면 그 근거를 decision-5를 갱신하는 새 decision으로 명시적으로 남긴다.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 비-Claude-Code AI 도구(예: 주요 AI 코딩 CLI/에이전트) 중 로컬에서 검증 가능한 세션 로그/트랜스크립트를 남기는 도구가 있는지 조사 결과가 태스크 노트에 기록된다
- [ ] #2 검증 가능한 도구가 있으면 해당 도구에 대해 트랜스크립트 기반 AI-Model 검증이 구현되고 테스트로 커버된다
- [ ] #3 검증이 불가능하다는 결론이면 그 근거가 decision-5를 대체하거나 보완하는 새 decision으로 기록된다(decision-5 파일 자체는 직접 수정하지 않는다)
- [ ] #4 README '한계 및 향후 검토 과제' 문구가 조사/구현 결과에 맞게 갱신된다
<!-- AC:END -->
