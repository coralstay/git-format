---
id: doc-3
title: AI 귀속 트레일러 레퍼런스
type: guide
created_date: '2026-09-19 05:27'
updated_date: '2026-09-19 05:27'
---
## 🤖 AI 귀속 footer

> decision-5

AI 코딩 에이전트가 커밋했다면 아래 트레일러가 자동으로 붙습니다. 신뢰 수준이 트레일러마다
다르다는 걸 알아두는 게 중요합니다.

| 트레일러                     | 값 출처                                                                                                                                                                                                                          | 신뢰 수준                                                                           |
| ---------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| `AI-Tool`, `AI-Tool-Version` | `AI_AGENT` 환경변수(Claude Code 프로세스가 하위 프로세스에 주입)                                                                                                                                                                 | 강제 — LLM이 스스로 만든 값이 아님                                                  |
| `AI-Model`                   | **Claude Code**: 세션 트랜스크립트(`~/.claude/projects/<slug>/<session>.jsonl`)의 `message.model` — Anthropic API 응답을 그대로 기록한 값. **그 외 도구**: `git config gitformat.aiModel`(commit-msg가 존재/화이트리스트를 강제) | Claude Code는 서버 발급 사실 / 그 외는 존재+형식만 강제, 진실성은 검증 불가         |
| `Tokens-Used`                | AI-Tool이 감지된 모든 커밋에 붙습니다. **Claude Code**: 같은 세션 트랜스크립트에서 `message.usage`(input/output/cache 토큰) 합계 — 이전 커밋 이후 새로 추가된 구간만(누적 아님, 아래 참고). **그 외 도구/실패 시**: `unavailable (사유)` (아래 참고)                          | 서버 발급 사실(자가신고 아님, Claude Code 한정) / 그 외는 실측 채널 없음            |
| `Tool-Calls`                 | 같은 구간에서 assistant 메시지의 `tool_use` 콘텐츠 블록 개수 — 출처/한계는 `Tokens-Used`와 동일                                                                                                                                  | 서버 발급 사실(자가신고 아님, Claude Code 한정) / 그 외는 실측 채널 없음            |
| `Co-Authored-By`             | `AI-Tool`이 `claude-code`일 때만 자동 삽입                                                                                                                                                                                       | 자동                                                                                |
| `Hooks-Commit`               | 이 git-format 클론 자체의 `git rev-parse --short HEAD`                                                                                                                                                                           | 완전 자동, 모든 커밋에 적용(AI 여부 무관)                                           |
| `Signed-off-by`              | 커미터 정보(`git log -1 --format='%cn <%ce>'`)                                                                                                                                                                                   | 완전 자동, 모든 커밋에 적용(AI 여부 무관, `git commit -s`와 동일 방식, decision-10) |

`CLAUDE_CODE_SESSION_ID`는 `AI-Model`/`Tokens-Used`/`Tool-Calls` 조회를 위해 트랜스크립트
파일 경로를 찾는 데만 내부적으로 쓰이고, 값 자체가 커밋 footer에 남지는 않습니다 — 세션
식별자를 공개 저장소 히스토리에 영구히 남기지 않기 위함입니다.

`Tokens-Used`/`Tool-Calls`는 한 세션에서 커밋이 여러 번 나올 수 있다는 점을 감안해
**세션 누적치가 아니라 이전 커밋 이후의 델타**만 집계합니다. `<대상 저장소>/.git/.gitformat-token-cursor`
파일에 "이미 처리한 트랜스크립트 줄 수"를 기억해뒀다가 다음 커밋에서 그 이후 줄만
다시 읽습니다.

측정에 실패하면 `unavailable (사유 슬러그)`로 명시 기록합니다(사유:
`no-session-id`/`jq-not-installed`/`transcript-not-found`/`transcript-unreadable`/
`transcript-parse-failed`/`no-usage-channel`). 커서는 실측 성공 시에만 갱신하고, 실제로
읽어서 합산한 값이 0이면 `0`으로 그대로 기록합니다(생략하지 않음). **주의**: 이 값은
"이 커밋에 정확히 필요했던 토큰"이 아니라 "직전 커밋 이후 세션에서 소비된 토큰"의
근사치입니다 — 측정 방법론 자체가 아직 실험적이며 계속 개선할 예정입니다.
