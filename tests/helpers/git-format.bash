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

# "도구가 없으면 건너뛴다" 시나리오를 시뮬레이션할 때 PATH="/usr/bin:/bin"처럼
# 하드코딩하면 플랫폼마다 실제 도구 설치 위치가 달라 깨진다 — 로컬 macOS/Homebrew는
# /opt/homebrew/bin이지만 GitHub Actions ubuntu-latest는 clang-format/mvn이
# /usr/bin에 이미 있어서 하드코딩된 PATH로는 실제로 도구가 안 사라진다(GF-32 실
# PR 검증 중 발견). PATH에서 해당 도구가 있는 디렉터리만 정확히 제거한다.
path_without() {
  tool_path="$(command -v "$1" 2>/dev/null || true)"
  if [ -z "$tool_path" ]; then
    printf '%s' "$PATH"
    return 0
  fi
  tool_dir="$(dirname "$tool_path")"
  printf '%s' "$PATH" | tr ':' '\n' | grep -vxF "$tool_dir" | tr '\n' ':' | sed 's/:$//'
}
