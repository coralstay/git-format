#!/usr/bin/env bats
# GF-25: post-commit 상태전이/동시성 견고성 테스트 (상태전이/결함주입) - decision-8
# 표준 인증이 아니라 실제 버그 이력(GF-31, GF-33)에 근거한 실용적 테스트.
# GF-82: 서브젝트를 [type][subsystem] 프리픽스로 전환하면서 관련 테스트도 갱신.

load 'helpers/git-format'

setup() {
  make_isolated_repo
}

teardown() {
  cleanup_isolated_repo
}

# ── 상태전이: 마커없음 -> pre-commit성공 -> 마커있음 -> post-commit -> 마커삭제 ──

@test "[상태전이] 정상 커밋(pre-commit 통과)은 마커가 결과적으로 남지 않고 Verify-Bypassed가 안 붙는다" {
  [ ! -f .git/.gitformat-verified ]
  echo hi > a.txt
  git add a.txt
  run git commit -m "[feat] normal commit"
  [ "$status" -eq 0 ]
  [ ! -f .git/.gitformat-verified ]
  MSG="$(git log -1 --pretty=%B)"
  [[ "$MSG" != *"Verify-Bypassed"* ]]
}

@test "[GF-82] 정상 커밋에 Signed-off-by가 커미터 정보로 자동 삽입된다" {
  echo hi > a.txt
  git add a.txt
  run git commit -m "[feat] signed off commit"
  [ "$status" -eq 0 ]
  MSG="$(git log -1 --pretty=%B)"
  [[ "$MSG" == *"Signed-off-by: bats <bats@example.com>"* ]]
}

@test "[상태전이] --no-verify로 커밋하면 마커가 없어 Verify-Bypassed: true가 post-commit에서 붙는다" {
  echo hi > a.txt
  git add a.txt
  run git commit --no-verify -m "[feat] bypass verification"
  [ "$status" -eq 0 ]
  [ ! -f .git/.gitformat-verified ]
  MSG="$(git log -1 --pretty=%B)"
  [[ "$MSG" == *"Verify-Bypassed: true"* ]]
}

# ── 결함주입: 트랜스크립트 손상, jq 없음, HOME 이상값 ────────────────

@test "[결함주입] Claude Code 트랜스크립트 JSON이 깨져도 AI-Model만 생략되고 커밋은 막히지 않는다" {
  if ! command -v jq >/dev/null 2>&1; then
    skip "jq가 로컬에 없어 이 케이스를 검증할 수 없음"
  fi
  FAKE_HOME="$(mktemp -d)"
  SLUG="$(printf '%s' "$PWD" | tr '/' '-')"
  mkdir -p "${FAKE_HOME}/.claude/projects/${SLUG}"
  printf 'this is not valid json at all\n{ also not valid' \
    > "${FAKE_HOME}/.claude/projects/${SLUG}/fake-session.jsonl"

  echo hi > a.txt
  git add a.txt
  HOME="$FAKE_HOME" AI_AGENT="claude-code_2-1-0" CLAUDE_CODE_SESSION_ID="fake-session" \
    run git commit -m "[feat] broken transcript"
  [ "$status" -eq 0 ]
  MSG="$(git log -1 --pretty=%B)"
  [[ "$MSG" != *"AI-Model:"* ]]
  [[ "$MSG" == *"AI-Tool: claude-code"* ]]

  rm -rf "$FAKE_HOME"
}

@test "[결함주입] jq가 PATH에 없어도 Claude Code 커밋은 막히지 않는다" {
  echo hi > a.txt
  git add a.txt
  PATH="$(path_without jq)" AI_AGENT="claude-code_2-1-0" CLAUDE_CODE_SESSION_ID="fake-session" \
    run git commit -m "[feat] no jq on PATH"
  [ "$status" -eq 0 ]
}

@test "[결함주입] HOME이 존재하지 않는 경로여도 커밋은 막히지 않는다" {
  echo hi > a.txt
  git add a.txt
  HOME="/nonexistent-gitformat-home-$$" AI_AGENT="claude-code_2-1-0" CLAUDE_CODE_SESSION_ID="fake-session" \
    run git commit -m "[feat] broken HOME"
  [ "$status" -eq 0 ]
}

# ── Tokens-Used/Tool-Calls: 트랜스크립트 델타 집계(GF-96) ─────────────

@test "[GF-96] 알려진 usage 값을 가진 트랜스크립트로 커밋하면 Tokens-Used/Tool-Calls가 정확히 합산된다" {
  if ! command -v jq >/dev/null 2>&1; then
    skip "jq가 로컬에 없어 이 케이스를 검증할 수 없음"
  fi
  FAKE_HOME="$(mktemp -d)"
  SLUG="$(printf '%s' "$PWD" | tr '/' '-')"
  mkdir -p "${FAKE_HOME}/.claude/projects/${SLUG}"
  TRANSCRIPT="${FAKE_HOME}/.claude/projects/${SLUG}/fake-session.jsonl"

  {
    printf '%s\n' '{"type":"assistant","message":{"usage":{"input_tokens":10,"output_tokens":5},"content":[{"type":"text","text":"hi"}]}}'
    printf '%s\n' '{"type":"assistant","message":{"usage":{"input_tokens":20,"output_tokens":10},"content":[{"type":"tool_use","name":"bash"},{"type":"tool_use","name":"grep"}]}}'
    printf '%s\n' '{"type":"user","message":{"content":"hello"}}'
  } > "$TRANSCRIPT"

  echo hi > a.txt
  git add a.txt
  HOME="$FAKE_HOME" AI_AGENT="claude-code_2-1-0" CLAUDE_CODE_SESSION_ID="fake-session" \
    run git commit -m "[feat] token usage first commit"
  [ "$status" -eq 0 ]
  MSG="$(git log -1 --pretty=%B)"
  [[ "$MSG" == *"Tokens-Used: 45"* ]]
  [[ "$MSG" == *"Tool-Calls: 2"* ]]
  [ -f .git/.gitformat-token-cursor ]
  [ "$(cat .git/.gitformat-token-cursor)" = "3" ]

  rm -rf "$FAKE_HOME"
}

@test "[GF-96] 같은 세션의 두 번째 커밋은 첫 커밋 이후 새로 추가된 줄만 델타로 집계한다" {
  if ! command -v jq >/dev/null 2>&1; then
    skip "jq가 로컬에 없어 이 케이스를 검증할 수 없음"
  fi
  FAKE_HOME="$(mktemp -d)"
  SLUG="$(printf '%s' "$PWD" | tr '/' '-')"
  mkdir -p "${FAKE_HOME}/.claude/projects/${SLUG}"
  TRANSCRIPT="${FAKE_HOME}/.claude/projects/${SLUG}/fake-session.jsonl"

  printf '%s\n' '{"type":"assistant","message":{"usage":{"input_tokens":10,"output_tokens":5},"content":[]}}' \
    > "$TRANSCRIPT"

  echo hi > a.txt
  git add a.txt
  HOME="$FAKE_HOME" AI_AGENT="claude-code_2-1-0" CLAUDE_CODE_SESSION_ID="fake-session" \
    run git commit -m "[feat] token usage commit one"
  [ "$status" -eq 0 ]
  MSG1="$(git log -1 --pretty=%B)"
  [[ "$MSG1" == *"Tokens-Used: 15"* ]]

  {
    printf '%s\n' '{"type":"assistant","message":{"usage":{"input_tokens":1,"output_tokens":1},"content":[]}}'
    printf '%s\n' '{"type":"assistant","message":{"usage":{"input_tokens":2,"output_tokens":2},"content":[{"type":"tool_use","name":"bash"}]}}'
  } >> "$TRANSCRIPT"

  echo bye > b.txt
  git add b.txt
  HOME="$FAKE_HOME" AI_AGENT="claude-code_2-1-0" CLAUDE_CODE_SESSION_ID="fake-session" \
    run git commit -m "[feat] token usage commit two"
  [ "$status" -eq 0 ]
  MSG2="$(git log -1 --pretty=%B)"
  [[ "$MSG2" == *"Tokens-Used: 6"* ]]
  [[ "$MSG2" == *"Tool-Calls: 1"* ]]
  [[ "$MSG2" != *"Tokens-Used: 21"* ]]
  [ "$(cat .git/.gitformat-token-cursor)" = "3" ]

  rm -rf "$FAKE_HOME"
}

@test "[GF-96] 트랜스크립트 파일이 없으면 Tokens-Used/Tool-Calls가 조용히 생략되고 커밋은 막히지 않는다" {
  FAKE_HOME="$(mktemp -d)"
  echo hi > a.txt
  git add a.txt
  HOME="$FAKE_HOME" AI_AGENT="claude-code_2-1-0" CLAUDE_CODE_SESSION_ID="nonexistent-session" \
    run git commit -m "[feat] no transcript file"
  [ "$status" -eq 0 ]
  MSG="$(git log -1 --pretty=%B)"
  [[ "$MSG" != *"Tokens-Used:"* ]]
  [[ "$MSG" != *"Tool-Calls:"* ]]
  [ ! -f .git/.gitformat-token-cursor ]

  rm -rf "$FAKE_HOME"
}

@test "[GF-96] jq가 PATH에 없으면 Tokens-Used/Tool-Calls가 조용히 생략되고 커밋은 막히지 않는다" {
  FAKE_HOME="$(mktemp -d)"
  SLUG="$(printf '%s' "$PWD" | tr '/' '-')"
  mkdir -p "${FAKE_HOME}/.claude/projects/${SLUG}"
  printf '%s\n' '{"type":"assistant","message":{"usage":{"input_tokens":10,"output_tokens":5},"content":[]}}' \
    > "${FAKE_HOME}/.claude/projects/${SLUG}/fake-session.jsonl"

  echo hi > a.txt
  git add a.txt
  HOME="$FAKE_HOME" PATH="$(path_without jq)" AI_AGENT="claude-code_2-1-0" \
    CLAUDE_CODE_SESSION_ID="fake-session" run git commit -m "[feat] no jq for tokens"
  [ "$status" -eq 0 ]
  MSG="$(git log -1 --pretty=%B)"
  [[ "$MSG" != *"Tokens-Used:"* ]]
  [ ! -f .git/.gitformat-token-cursor ]

  rm -rf "$FAKE_HOME"
}

# ── 재귀가드: _GITFORMAT_AMEND_GUARD가 무한루프를 막는지 ─────────────

@test "[재귀가드] --no-verify + AI 트레일러가 붙는 커밋도 유한 시간 안에 끝난다" {
  echo hi > a.txt
  git add a.txt
  AI_AGENT="other-tool_1-0" run timeout 10 git commit --no-verify -m "[feat] recursion guard check"
  [ "$status" -eq 0 ]
}
