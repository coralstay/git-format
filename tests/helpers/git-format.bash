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
# 하드코딩하면 플랫폼마다 실제 도구 설치 위치가 달라 깨진다(GF-32 실 PR 검증 중
# 발견: macOS/Homebrew는 /opt/homebrew/bin이지만 ubuntu-latest는 clang-format/
# mvn이 /usr/bin에 있음). 처음엔 그 도구가 있는 디렉터리만 PATH에서 제거하는
# 방식을 시도했는데, git도 같은 디렉터리(/usr/bin)에 있어서 git 자체가 사라져
# 버렸다 — 디렉터리 단위 제거로는 안 된다.
#
# 대신 PATH에서 찾을 수 있는 모든 실행파일을 지정한 도구 하나만 빼고 임시
# 디렉터리에 심볼릭 링크로 모아, git/sh/grep 등 나머지는 전부 정상 동작하면서
# 그 도구만 정확히 못 찾게 만든다.
path_without() {
  target="$1"
  shadow_dir="$(mktemp -d)"
  old_ifs="$IFS"
  IFS=:
  # shellcheck disable=SC2086 # PATH를 IFS=:로 단어분리해서 순회하는 게 의도임
  set -- $PATH
  IFS="$old_ifs"
  for dir in "$@"; do
    [ -d "$dir" ] || continue
    for f in "$dir"/*; do
      [ -x "$f" ] || continue
      name="$(basename "$f")"
      [ "$name" = "$target" ] && continue
      [ -e "${shadow_dir}/${name}" ] && continue
      ln -s "$f" "${shadow_dir}/${name}" 2>/dev/null || true
    done
  done
  printf '%s' "$shadow_dir"
}
