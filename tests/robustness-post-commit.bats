#!/usr/bin/env bats
# GF-25: post-commit 상태전이/동시성 견고성 테스트 (상태전이/결함주입) - decision-8
# 표준 인증이 아니라 실제 버그 이력(GF-31, GF-33)에 근거한 실용적 테스트.
# GF-82: 서브젝트를 [type][subsystem] 프리픽스로 전환하면서 관련 테스트도 갱신.
# GF-97: Tokens-Used/Tool-Calls가 실패 시 조용히 생략되지 않고 unavailable
# (사유)로 명시되도록, 그리고 claude-code 외 AI 도구/사람 커밋/실측 0까지
# 다루도록 케이스를 갱신·확장.

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

# ── Tokens-Used/Tool-Calls: 측정 실패 사유 명시(GF-97) ────────────────

@test "[GF-97] 트랜스크립트 파일이 없으면 Tokens-Used/Tool-Calls가 unavailable (transcript-not-found)로 명시된다" {
  FAKE_HOME="$(mktemp -d)"
  echo hi > a.txt
  git add a.txt
  HOME="$FAKE_HOME" AI_AGENT="claude-code_2-1-0" CLAUDE_CODE_SESSION_ID="nonexistent-session" \
    run git commit -m "[feat] no transcript file"
  [ "$status" -eq 0 ]
  MSG="$(git log -1 --pretty=%B)"
  [[ "$MSG" == *"Tokens-Used: unavailable (transcript-not-found)"* ]]
  [[ "$MSG" == *"Tool-Calls: unavailable (transcript-not-found)"* ]]
  [ ! -f .git/.gitformat-token-cursor ]

  rm -rf "$FAKE_HOME"
}

@test "[GF-97] jq가 PATH에 없으면 Tokens-Used/Tool-Calls가 unavailable (jq-not-installed)로 명시된다" {
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
  [[ "$MSG" == *"Tokens-Used: unavailable (jq-not-installed)"* ]]
  [[ "$MSG" == *"Tool-Calls: unavailable (jq-not-installed)"* ]]
  [ ! -f .git/.gitformat-token-cursor ]

  rm -rf "$FAKE_HOME"
}

@test "[GF-97] 사람 커밋(AI 도구 미감지)에는 Tokens-Used/Tool-Calls가 전혀 붙지 않는다" {
  echo hi > a.txt
  git add a.txt
  # 이 저장소에서 bats 자체를 Claude Code로 구동 중이면 AI_AGENT/
  # CLAUDE_CODE_SESSION_ID가 이미 셸 환경에 노출돼 있을 수 있으므로(GF-97
  # 검증 중 실제로 발견), "사람 커밋"을 흉내내려면 명시적으로 지워야 한다.
  run env -u AI_AGENT -u CLAUDE_CODE_SESSION_ID git commit -m "[feat] human commit no ai"
  [ "$status" -eq 0 ]
  MSG="$(git log -1 --pretty=%B)"
  [[ "$MSG" != *"AI-Tool:"* ]]
  [[ "$MSG" != *"Tokens-Used:"* ]]
  [[ "$MSG" != *"Tool-Calls:"* ]]
}

@test "[GF-97] claude-code 외 AI 도구가 감지되면 unavailable (no-usage-channel)로 명시된다" {
  echo hi > a.txt
  git add a.txt
  # commit-msg 게이트(decision-5)는 claude-code 외 AI 도구가 감지되면
  # gitformat.aiModel이 설정돼 있을 것을 요구한다 - 이 테스트의 관심사는
  # 그 게이트 통과 이후 post-commit의 Tokens-Used/Tool-Calls 분기이므로
  # 먼저 채워둔다.
  git config gitformat.aiModel "gpt-5"
  AI_AGENT="other-tool_1-0" run git commit -m "[feat] other ai tool"
  [ "$status" -eq 0 ]
  MSG="$(git log -1 --pretty=%B)"
  [[ "$MSG" == *"AI-Tool: other-tool"* ]]
  [[ "$MSG" == *"Tokens-Used: unavailable (no-usage-channel)"* ]]
  [[ "$MSG" == *"Tool-Calls: unavailable (no-usage-channel)"* ]]
}

@test "[GF-97] 실측 결과가 정말 0이면 unavailable이 아니라 Tokens-Used: 0/Tool-Calls: 0으로 명시된다" {
  if ! command -v jq >/dev/null 2>&1; then
    skip "jq가 로컬에 없어 이 케이스를 검증할 수 없음"
  fi
  FAKE_HOME="$(mktemp -d)"
  SLUG="$(printf '%s' "$PWD" | tr '/' '-')"
  mkdir -p "${FAKE_HOME}/.claude/projects/${SLUG}"
  printf '%s\n' '{"type":"assistant","message":{"usage":{"input_tokens":0,"output_tokens":0},"content":[]}}' \
    > "${FAKE_HOME}/.claude/projects/${SLUG}/fake-session.jsonl"

  echo hi > a.txt
  git add a.txt
  HOME="$FAKE_HOME" AI_AGENT="claude-code_2-1-0" CLAUDE_CODE_SESSION_ID="fake-session" \
    run git commit -m "[feat] genuine zero token delta"
  [ "$status" -eq 0 ]
  MSG="$(git log -1 --pretty=%B)"
  [[ "$MSG" == *"Tokens-Used: 0"* ]]
  [[ "$MSG" == *"Tool-Calls: 0"* ]]
  [[ "$MSG" != *"unavailable"* ]]
  [ "$(cat .git/.gitformat-token-cursor)" = "1" ]

  rm -rf "$FAKE_HOME"
}

# ── PROJECT_SLUG: Claude Code 실제 세션 슬러그 규칙(GF-98) ────────────
# Claude Code가 ~/.claude/projects/ 아래 세션 디렉터리를 만들 때 쓰는 실제
# 규칙은 "영숫자가 아닌 모든 문자를 하이픈으로 치환"(tr -c 'A-Za-z0-9' '-')
# 이다. 기존 GF-96/GF-97 테스트들은 SLUG를 tr '/' '-'로 계산해 훅의 버그를
# 그대로 흉내내고 있어(둘 다 틀렸으니 우연히 일치) 이 버그를 못 잡는다.
# 이 테스트는 저장소 최상위 디렉터리 이름 자체에 밑줄/점을 넣어(하위
# 디렉터리에 넣어도 소용없다 - git hook은 항상 worktree 최상위를 PWD로
# 실행된다는 것을 실측 확인함) 두 알고리즘이 반드시 갈리게 만든다.
@test "[GF-98] 저장소 경로에 밑줄/점이 있어도 Claude Code 실제 슬러그 규칙으로 트랜스크립트를 찾아 AI-Model/Tokens-Used/Tool-Calls가 채워진다" {
  if ! command -v jq >/dev/null 2>&1; then
    skip "jq가 로컬에 없어 이 케이스를 검증할 수 없음"
  fi

  NESTED_REPO="${TEST_REPO}/repo_with.dot_and_underscore"
  mkdir -p "$NESTED_REPO"
  cd "$NESTED_REPO" || return 1
  git init -q
  git config commit.gpgsign false
  git config user.email "bats@example.com"
  git config user.name "bats"
  git config core.hooksPath "${GITFORMAT_ROOT}/hooks"

  FAKE_HOME="$(mktemp -d)"
  SLUG="$(printf '%s' "$PWD" | tr -c 'A-Za-z0-9' '-')"
  mkdir -p "${FAKE_HOME}/.claude/projects/${SLUG}"
  TRANSCRIPT="${FAKE_HOME}/.claude/projects/${SLUG}/fake-session.jsonl"
  printf '%s\n' '{"type":"assistant","message":{"model":"claude-slug-fix-test","usage":{"input_tokens":10,"output_tokens":5},"content":[{"type":"tool_use","name":"bash"}]}}' \
    > "$TRANSCRIPT"

  echo hi > a.txt
  git add a.txt
  HOME="$FAKE_HOME" AI_AGENT="claude-code_2-1-0" CLAUDE_CODE_SESSION_ID="fake-session" \
    run git commit -m "[feat] underscore dot path slug"
  [ "$status" -eq 0 ]
  MSG="$(git log -1 --pretty=%B)"
  [[ "$MSG" == *"AI-Model: claude-slug-fix-test"* ]]
  [[ "$MSG" == *"Tokens-Used: 15"* ]]
  [[ "$MSG" == *"Tool-Calls: 1"* ]]

  rm -rf "$FAKE_HOME"
}

# ── 재귀가드: _GITFORMAT_AMEND_GUARD가 무한루프를 막는지 ─────────────

@test "[재귀가드] --no-verify + AI 트레일러가 붙는 커밋도 유한 시간 안에 끝난다" {
  echo hi > a.txt
  git add a.txt
  # GF-97 이후 이 커밋도 AI-Tool: other-tool과 함께
  # Tokens-Used/Tool-Calls: unavailable (no-usage-channel)이 붙지만, 이
  # 테스트의 관심사는 재귀 가드가 유한 시간 안에 끝나는지이지 트레일러
  # 값 자체가 아니므로 별도로 단언하지 않는다.
  AI_AGENT="other-tool_1-0" run timeout 10 git commit --no-verify -m "[feat] recursion guard check"
  [ "$status" -eq 0 ]
}
