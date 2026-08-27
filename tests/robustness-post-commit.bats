#!/usr/bin/env bats
# GF-25: post-commit 상태전이/동시성 견고성 테스트 (상태전이/결함주입) - decision-8
# 표준 인증이 아니라 실제 버그 이력(GF-31, GF-33)에 근거한 실용적 테스트.

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
  run git commit -m "feat: normal commit"
  [ "$status" -eq 0 ]
  [ ! -f .git/.gitformat-verified ]
  MSG="$(git log -1 --pretty=%B)"
  [[ "$MSG" != *"Verify-Bypassed"* ]]
}

@test "[상태전이] --no-verify로 커밋하면 마커가 없어 Verify-Bypassed: true가 post-commit에서 붙는다" {
  echo hi > a.txt
  git add a.txt
  run git commit --no-verify -m "feat: bypass verification"
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
    run git commit -m "feat: broken transcript"
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
    run git commit -m "feat: no jq on PATH"
  [ "$status" -eq 0 ]
}

@test "[결함주입] HOME이 존재하지 않는 경로여도 커밋은 막히지 않는다" {
  echo hi > a.txt
  git add a.txt
  HOME="/nonexistent-gitformat-home-$$" AI_AGENT="claude-code_2-1-0" CLAUDE_CODE_SESSION_ID="fake-session" \
    run git commit -m "feat: broken HOME"
  [ "$status" -eq 0 ]
}

# ── 재귀가드: _GITFORMAT_AMEND_GUARD가 무한루프를 막는지 ─────────────

@test "[재귀가드] --no-verify + AI 트레일러가 붙는 커밋도 유한 시간 안에 끝난다" {
  echo hi > a.txt
  git add a.txt
  AI_AGENT="other-tool_1-0" run timeout 10 git commit --no-verify -m "feat: recursion guard check"
  [ "$status" -eq 0 ]
}
