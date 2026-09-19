---
id: DRAFT-1
title: 다른 AI 코딩 도구용 Tokens-Used/Tool-Calls 실측 채널 지원 검토
status: Draft
assignee: []
created_date: '2026-09-19 01:21'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
GF-97에서 trailer_tokens_used()를 AI_TOOL_ID 케이스 분기 디스패처로 만들면서, claude-code가 아닌 감지된 AI 도구는 전부 "unavailable (no-usage-channel)"로 처리하도록 했다. decision-15(2026-09)는 당시 조사한 8개 도구(Cursor/Copilot CLI/Aider/Cline/Windsurf/Codex CLI/Gemini CLI/Amazon Q) 중 어느 것도 (1) 하위 프로세스에 주입되는 세션 상관관계 채널과 (2) 그 세션 안에서 서버가 확정한 usage 값을 동시에 제공하지 않는다고 결론지었다.

이후 어떤 도구가 이 두 조건을 만족하는 로컬 채널을 새로 노출하면, trailer_tokens_used()의 case 분기에 그 도구용 실측 함수(measure_claude_code_token_usage()와 같은 패턴)를 하나 추가하는 정도의 작업이 될 것으로 예상된다.

지금은 코드에 스텁이나 미리 준비된 함수를 두지 않는다 - 실제로 그런 도구가 나타나기 전까지는 이 draft로만 아이디어를 남겨둔다.
<!-- SECTION:DESCRIPTION:END -->
