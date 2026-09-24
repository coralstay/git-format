#!/usr/bin/env bats
# GF-77: GF-76에서 CONF를 읽는 파일들에 추가한 "gitformat.conf 읽기 검증
# 가드"는 tests/consistency.bats로 그 파일들의 가드 블록이 텍스트로 동일한지만
# 검증되고 있었다. 실제로 conf가 깨진 상태에서 각 파일을 직접 실행해 exit
# 0이 아니고 명확한 에러 메시지가 나오는지 런타임으로도 검증한다. 진짜
# 저장소의 hooks/gitformat.conf는 절대 건드리지 않고, 매 테스트마다 hooks/를
# 임시 디렉터리에 복사해 그 사본의 conf만 깨뜨린다.

load 'helpers/git-format'

setup() {
  HOOKS_COPY="$(mktemp -d)"
  cp -r "${GITFORMAT_ROOT}/hooks/." "$HOOKS_COPY"
  printf 'this is not valid git-config syntax [[[\n' > "${HOOKS_COPY}/gitformat.conf"

  TEST_REPO="$(mktemp -d)"
  cd "$TEST_REPO" || return 1
  git init -q
  git config commit.gpgsign false
  git config user.email "bats@example.com"
  git config user.name "bats"
}

teardown() {
  cd "${GITFORMAT_ROOT}" || true
  [ -n "${HOOKS_COPY:-}" ] && rm -rf "$HOOKS_COPY"
  [ -n "${TEST_REPO:-}" ] && rm -rf "$TEST_REPO"
}

assert_conf_guard_fires() {
  [ "$status" -ne 0 ]
  [[ "$output" == *"gitformat: gitformat.conf를 읽을 수 없습니다"* ]]
}

@test "commit-msg(python): conf가 깨지면 명확한 에러로 즉시 멈춘다" {
  echo "[feat] test" > msgfile
  run python3 "${HOOKS_COPY}/commit-msg" msgfile
  assert_conf_guard_fires
}

@test "pre-commit(python): conf가 깨지면 명확한 에러로 즉시 멈춘다" {
  run python3 "${HOOKS_COPY}/pre-commit"
  assert_conf_guard_fires
}

@test "post-commit(python): conf가 깨지면 명확한 에러로 즉시 멈춘다" {
  run python3 "${HOOKS_COPY}/post-commit"
  assert_conf_guard_fires
}

@test "checks/cpp.py: conf가 깨지면 명확한 에러로 즉시 멈춘다" {
  run python3 "${HOOKS_COPY}/checks/cpp.py" "$TEST_REPO"
  assert_conf_guard_fires
}

@test "checks/java.py: conf가 깨지면 명확한 에러로 즉시 멈춘다" {
  run python3 "${HOOKS_COPY}/checks/java.py" "$TEST_REPO"
  assert_conf_guard_fires
}

@test "checks/sql.py: conf가 깨지면 명확한 에러로 즉시 멈춘다" {
  run python3 "${HOOKS_COPY}/checks/sql.py" "$TEST_REPO"
  assert_conf_guard_fires
}

@test "install.sh: conf가 깨지면 명확한 에러로 즉시 멈춘다" {
  CLONE_COPY="$(mktemp -d)"
  cp -r "${GITFORMAT_ROOT}/hooks" "${CLONE_COPY}/hooks"
  cp "${GITFORMAT_ROOT}/install.sh" "${CLONE_COPY}/install.sh"
  printf 'this is not valid git-config syntax [[[\n' > "${CLONE_COPY}/hooks/gitformat.conf"

  run sh "${CLONE_COPY}/install.sh" "$TEST_REPO"

  rm -rf "$CLONE_COPY"
  assert_conf_guard_fires
}
