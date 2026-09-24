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
  rm -rf "$TARGET_REPO" "${FAKE_HOME:-}" "${FAKE_ROOT:-}"
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
  # --global은 전역 설정만 하는 플래그가 아니다 - install.sh는 타깃(기본값 CWD)에
  # 대한 로컬 설치도 함께 수행한다. 타깃을 생략하면 bats의 CWD인 이 저장소 자신이
  # 대상이 되므로 반드시 격리된 TARGET_REPO를 넘긴다(GF-123).
  run env HOME="$FAKE_HOME" "${GITFORMAT_ROOT}/install.sh" --global "$TARGET_REPO"
  [ "$status" -eq 0 ]
  first_target="$(readlink "${GITFORMAT_ROOT}/template/hooks/pre-commit")"

  run env HOME="$FAKE_HOME" "${GITFORMAT_ROOT}/install.sh" --global "$TARGET_REPO"
  [ "$status" -eq 0 ]
  second_target="$(readlink "${GITFORMAT_ROOT}/template/hooks/pre-commit")"

  [ "$first_target" = "$second_target" ]
  [ "$first_target" = "${GITFORMAT_ROOT}/hooks/pre-commit" ]
  [ -L "${GITFORMAT_ROOT}/template/hooks/commit-msg" ]
  [ -L "${GITFORMAT_ROOT}/template/hooks/post-commit" ]

  # 실제 전역 git 설정은 건드리지 않았어야 한다
  run git config --global --get init.templateDir
  # (이 값이 우연히 이미 로컬 머신에 설정돼 있을 수도 있으니, 최소한 FAKE_HOME
  # 쪽 설정이 실제로 반영됐는지를 직접 확인한다.)
  [ "$(git config --file "${FAKE_HOME}/.gitconfig" --get init.templateDir)" = "${GITFORMAT_ROOT}/template" ]
}

# ── 정리: 삭제된 훅의 template/hooks 심볼릭 링크 정리 (GF-92) ──────
# GF-86(decision-12)에서 hooks/pre-push를 삭제했지만 template/hooks/pre-push
# 심볼릭 링크는 지워지지 않고 대상 없는 채로 남았다(sync_template()이 새로
# 생기는 파일만 링크하고, 없어진 파일의 예전 링크는 정리하지 않았기 때문).
# 실제 hooks/ 파일을 지우는 테스트이므로, 이 저장소 자신이 아니라 격리된
# GITFORMAT_ROOT 사본(FAKE_ROOT)에서 진행한다. 격리해야 하는 것이 훅 소스만은
# 아니다 - install.sh는 타깃(기본값 CWD)에 로컬 설치도 하므로 타깃도 함께
# 격리해야 한다. 예전엔 타깃을 생략해서, 이 테스트를 돌릴 때마다 실제 저장소의
# core.hooksPath가 곧 삭제될 FAKE_ROOT를 가리키게 되고 이후 모든 커밋에서 훅이
# 조용히 죽었다(GF-123).
@test "[정리] hooks/에서 파일이 삭제된 뒤 --global을 재실행하면 template/hooks의 대응 심볼릭 링크도 삭제된다" {
  FAKE_HOME="$(mktemp -d)"
  FAKE_ROOT="$(mktemp -d)"
  cp -R "${GITFORMAT_ROOT}/hooks" "${FAKE_ROOT}/hooks"
  cp "${GITFORMAT_ROOT}/install.sh" "${FAKE_ROOT}/install.sh"
  cp "${GITFORMAT_ROOT}/.gitmessage" "${FAKE_ROOT}/.gitmessage"

  run env HOME="$FAKE_HOME" "${FAKE_ROOT}/install.sh" --global "$TARGET_REPO"
  [ "$status" -eq 0 ]
  [ -L "${FAKE_ROOT}/template/hooks/pre-commit" ]
  [ -L "${FAKE_ROOT}/template/hooks/commit-msg" ]

  # hooks/에서 파일 하나를 지운다 (GF-86의 hooks/pre-push 삭제 상황 재현)
  rm "${FAKE_ROOT}/hooks/pre-commit"

  run env HOME="$FAKE_HOME" "${FAKE_ROOT}/install.sh" --global "$TARGET_REPO"
  [ "$status" -eq 0 ]

  # 삭제된 파일에 대응하는 심볼릭 링크는 사라져야 한다 (깨진 링크로도 남으면 안 됨)
  [ ! -e "${FAKE_ROOT}/template/hooks/pre-commit" ]
  [ ! -L "${FAKE_ROOT}/template/hooks/pre-commit" ]

  # 여전히 존재하는 훅의 심볼릭 링크는 그대로 유지된다
  [ -L "${FAKE_ROOT}/template/hooks/commit-msg" ]
  [ -L "${FAKE_ROOT}/template/hooks/post-commit" ]
}

# ── 회귀: 테스트가 이 저장소 자신의 설정을 오염시키지 않는다 ──────

# GF-123: --global 케이스들이 타깃 인자를 생략해, install.sh의 기본 타깃인
# CWD(=이 저장소)에 로컬 설치가 함께 일어났다. 그 결과 스위트를 한 번 돌릴
# 때마다 이 저장소의 core.hooksPath가 곧 삭제될 임시 경로를 가리키게 되고,
# 이후 모든 커밋에서 훅이 조용히 실행되지 않았다(에러 없이 트레일러만 사라짐).
# --global이 "전역 설정만 한다"는 뜻이 아니라는 점을 고정한다.
@test "[GF-123 회귀] --global 실행이 이 저장소 자신의 core.hooksPath를 바꾸지 않는다" {
  FAKE_HOME="$(mktemp -d)"
  FAKE_ROOT="$(mktemp -d)"
  cp -R "${GITFORMAT_ROOT}/hooks" "${FAKE_ROOT}/hooks"
  cp "${GITFORMAT_ROOT}/install.sh" "${FAKE_ROOT}/install.sh"
  cp "${GITFORMAT_ROOT}/.gitmessage" "${FAKE_ROOT}/.gitmessage"

  before="$(git -C "$GITFORMAT_ROOT" config --get core.hooksPath || true)"

  run env HOME="$FAKE_HOME" "${FAKE_ROOT}/install.sh" --global "$TARGET_REPO"
  [ "$status" -eq 0 ]

  after="$(git -C "$GITFORMAT_ROOT" config --get core.hooksPath || true)"
  [ "$before" = "$after" ]

  # 타깃 쪽에는 정상적으로 설치됐어야 한다(설치 자체가 안 된 것으로 통과하면 안 됨).
  [ "$(git -C "$TARGET_REPO" config --get core.hooksPath)" = "${FAKE_ROOT}/hooks" ]
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
