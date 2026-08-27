#!/usr/bin/env bats
# GF-26: install.sh/template 이식성 테스트 (경험기반 체크리스트) - decision-8
# 표준 인증이 아니라 install.sh의 실제 분기(비대화형/--global/에러 처리)에
# 근거한 실용적 테스트. 실제 전역 git 설정(~/.gitconfig)은 절대 건드리지 않고
# HOME을 매 테스트마다 임시 디렉터리로 격리한다.

load 'helpers/git-format'

setup() {
  TARGET_REPO="$(mktemp -d)"
  git init -q "$TARGET_REPO"
}

teardown() {
  rm -rf "$TARGET_REPO" "${FAKE_HOME:-}"
}

# ── 비대화형 환경 ─────────────────────────────────────────────────

@test "[비대화형] stdin이 tty가 아니면 프롬프트 없이 로컬 설정만 적용하고 전역은 건너뛴다" {
  FAKE_HOME="$(mktemp -d)"
  run env HOME="$FAKE_HOME" "${GITFORMAT_ROOT}/install.sh" "$TARGET_REPO" </dev/null
  [ "$status" -eq 0 ]
  [[ "$output" == *"비대화형 환경이라 전역 설정은 건너뜁니다"* ]]

  # 로컬 설정은 정상 적용됐어야 한다
  [ "$(git -C "$TARGET_REPO" config --get core.hooksPath)" = "${GITFORMAT_ROOT}/hooks" ]
  [ "$(git -C "$TARGET_REPO" config --get commit.template)" = "${GITFORMAT_ROOT}/.gitmessage" ]

  # 전역(FAKE_HOME) 설정은 안 건드렸어야 한다
  run git config --file "${FAKE_HOME}/.gitconfig" --get init.templateDir
  [ "$status" -ne 0 ]
}

# ── 멱등성: --global 반복 실행 ────────────────────────────────────

@test "[멱등성] --global을 격리된 HOME에서 두 번 연속 실행해도 template/hooks 심볼릭 링크가 정상 유지된다" {
  FAKE_HOME="$(mktemp -d)"
  run env HOME="$FAKE_HOME" "${GITFORMAT_ROOT}/install.sh" --global
  [ "$status" -eq 0 ]
  first_target="$(readlink "${GITFORMAT_ROOT}/template/hooks/pre-commit")"

  run env HOME="$FAKE_HOME" "${GITFORMAT_ROOT}/install.sh" --global
  [ "$status" -eq 0 ]
  second_target="$(readlink "${GITFORMAT_ROOT}/template/hooks/pre-commit")"

  [ "$first_target" = "$second_target" ]
  [ "$first_target" = "${GITFORMAT_ROOT}/hooks/pre-commit" ]
  [ -L "${GITFORMAT_ROOT}/template/hooks/commit-msg" ]
  [ -L "${GITFORMAT_ROOT}/template/hooks/post-commit" ]
  [ -L "${GITFORMAT_ROOT}/template/hooks/pre-push" ]

  # 실제 전역 git 설정은 건드리지 않았어야 한다
  run git config --global --get init.templateDir
  # (이 값이 우연히 이미 로컬 머신에 설정돼 있을 수도 있으니, 최소한 FAKE_HOME
  # 쪽 설정이 실제로 반영됐는지를 직접 확인한다.)
  [ "$(git config --file "${FAKE_HOME}/.gitconfig" --get init.templateDir)" = "${GITFORMAT_ROOT}/template" ]
}

# ── 에러 메시지: 잘못된 인자 ──────────────────────────────────────

@test "[에러처리] 존재하지 않는 대상 디렉터리는 0이 아닌 상태로 실패한다" {
  run "${GITFORMAT_ROOT}/install.sh" "/no/such/gitformat-target-dir-$$"
  [ "$status" -ne 0 ]
  [ -n "$output" ]
}

@test "[에러처리] git 저장소가 아닌 디렉터리는 명확한 에러 메시지와 함께 실패한다" {
  NOT_A_REPO="$(mktemp -d)"
  run "${GITFORMAT_ROOT}/install.sh" "$NOT_A_REPO"
  [ "$status" -ne 0 ]
  [[ "$output" == *"git 저장소가 아닙니다"* ]]
  rm -rf "$NOT_A_REPO"
}
