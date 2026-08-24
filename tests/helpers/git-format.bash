# bats 테스트 공용 헬퍼(GF-21): 격리된 git 저장소를 만들고 git-format 훅을 연결한다.
# `load 'helpers/git-format'`로 각 .bats 파일에서 불러 쓴다.

GITFORMAT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

make_isolated_repo() {
  TEST_REPO="$(mktemp -d)"
  cd "$TEST_REPO" || return 1
  git init -q
  git config commit.gpgsign false
  git config user.email "bats@example.com"
  git config user.name "bats"
  git config core.hooksPath "${GITFORMAT_ROOT}/hooks"
}

cleanup_isolated_repo() {
  if [ -n "${TEST_REPO:-}" ]; then
    cd "${GITFORMAT_ROOT}" || true
    rm -rf "$TEST_REPO"
  fi
}
