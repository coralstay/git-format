#!/usr/bin/env bats
# GF-113: 훅이 실행되는 시점의 PATH에 python3이 없을 때의 동작 검증(decision-16).
# sh 시절에는 없던 실패 모드라 "sh/Python 동일성 재검증"이 아니라 신규 동작 검증이다.
# 훅마다 결과가 비대칭이라는 README의 서술(pre-commit/commit-msg는 커밋 차단,
# post-commit은 트레일러 조용한 누락)이 실제로 그런지 확인하는 것이 목적이다.
#
# 여기서는 HOME을 바꾸지 않으므로 asdf_pin_python()을 부르지 않는다 - 이 파일이
# 필요로 하는 건 python3을 실행 가능하게 만드는 게 아니라 정확히 그 반대다.

load 'helpers/git-format'

setup() {
  make_isolated_repo
  SHADOW_PATH="$(path_without python3)"
  # 섀도 PATH가 python3만 정확히 가렸는지 먼저 고정한다. 이 단언이 없으면 아래
  # 케이스들은 PATH가 통째로 망가져 git 자체가 죽는 경우에도 똑같이 통과한다.
  [ ! -e "${SHADOW_PATH}/python3" ]
  PATH="$SHADOW_PATH" run git --version
  [ "$status" -eq 0 ]
}

teardown() {
  rm -rf "${SHADOW_PATH:-}" "${TRIMMED_HOOKS:-}"
  cleanup_isolated_repo
}

# 특정 훅만 남긴 hooks/ 사본을 만들어 core.hooksPath를 그쪽으로 돌린다. git은
# 앞선 훅이 실패하면 뒤의 훅을 아예 실행하지 않으므로, pre-commit을 지워야
# commit-msg가, 둘 다 지워야 post-commit이 실제로 검증 대상이 된다.
use_hooks_without() {
  TRIMMED_HOOKS="$(mktemp -d)"
  cp -R "${GITFORMAT_ROOT}/hooks/." "${TRIMMED_HOOKS}/"
  for h in "$@"; do
    rm -f "${TRIMMED_HOOKS}/${h}"
  done
  git config core.hooksPath "$TRIMMED_HOOKS"
}

# ── pre-commit/commit-msg: 커밋이 실제로 막힌다 ───────────────────

@test "[GF-113] python3이 없으면 pre-commit이 실패해 커밋 객체가 만들어지지 않는다" {
  echo base > base.txt
  git add base.txt
  run git commit -m "[feat] baseline commit"
  [ "$status" -eq 0 ]
  before="$(git rev-parse HEAD)"

  echo hi > a.txt
  git add a.txt
  PATH="$SHADOW_PATH" run git commit -m "[feat] blocked by missing python3"
  [ "$status" -ne 0 ]
  [[ "$output" == *"python3"* ]]

  # 종료 코드만 보면 안 된다 - 커밋 객체가 정말 안 생겼는지까지 확인한다.
  [ "$(git rev-parse HEAD)" = "$before" ]
  [ "$(git rev-list --count HEAD)" -eq 1 ]
}

@test "[GF-113] python3이 없으면 commit-msg가 실패해 커밋 객체가 만들어지지 않는다" {
  use_hooks_without pre-commit

  echo base > base.txt
  git add base.txt
  run git commit -m "[feat] baseline commit"
  [ "$status" -eq 0 ]
  before="$(git rev-parse HEAD)"

  echo hi > a.txt
  git add a.txt
  PATH="$SHADOW_PATH" run git commit -m "[feat] blocked by missing python3"
  [ "$status" -ne 0 ]
  [[ "$output" == *"python3"* ]]
  [ "$(git rev-parse HEAD)" = "$before" ]
  [ "$(git rev-list --count HEAD)" -eq 1 ]
}

# ── post-commit: 커밋은 남고 트레일러만 조용히 빠진다 ─────────────

@test "[GF-113] python3이 없으면 post-commit만 실패해 커밋은 남고 트레일러가 누락된다" {
  use_hooks_without pre-commit commit-msg

  # 같은 설정에서 python3이 보이면 트레일러가 붙는다는 것부터 확인한다 - 이게
  # 없으면 아래 누락이 python3 부재 때문인지 훅 연결이 애초에 안 된 탓인지
  # 구분할 수 없다.
  echo base > base.txt
  git add base.txt
  run git commit -m "[feat] baseline commit"
  [ "$status" -eq 0 ]
  [[ "$(git log -1 --pretty=%B)" == *"Signed-off-by: bats <bats@example.com>"* ]]

  echo hi > a.txt
  git add a.txt
  PATH="$SHADOW_PATH" run git commit -m "[feat] trailerless commit"

  # --no-verify도 아니고 에러도 아니다 - 커밋은 평범하게 성공한 것처럼 보인다.
  [ "$status" -eq 0 ]
  [ "$(git rev-list --count HEAD)" -eq 2 ]
  [ "$(git log -1 --pretty=%s)" = "[feat] trailerless commit" ]

  MSG="$(git log -1 --pretty=%B)"
  [[ "$MSG" != *"Signed-off-by"* ]]
  [[ "$MSG" != *"Hooks-Commit"* ]]
  [[ "$MSG" != *"Task-Id"* ]]
}
