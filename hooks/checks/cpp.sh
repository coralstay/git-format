#!/bin/sh
# C/C++ 체크: pre-commit 디스패처가 CMakeLists.txt/Makefile 감지 시 호출한다.
# 스테이징된 C/C++ 파일에 대해서만 clang-format 포맷 검사를 한다(빌드는 무거우므로
# pre-push(GF-5)로 미룬다).
set -eu

# 이 훅 스크립트가 심볼릭 링크로 호출될 가능성에 대비해 실제 위치를 해석한다.
# 이 함수는 이 파일 안에서만 쓰인다(sql.sh 등 다른 체크 스크립트도 각자 자기
# 파일에 동일 함수를 독립적으로 갖고 있다 — 로직은 공유하지 않는다는 게
# gitformat.conf 도입(GF-44) 이후에도 유지되는 설계 원칙이다).
resolve_self() {
  p="$1"
  while [ -L "$p" ]; do
    target="$(readlink "$p")"
    case "$target" in
      /*) p="$target" ;;
      *) p="$(dirname "$p")/$target" ;;
    esac
  done
  printf '%s' "$p"
}
# checks/의 상위 디렉터리(hooks/)에 gitformat.conf가 있다.
HOOK_DIR="$(cd "$(dirname "$(dirname "$(resolve_self "$0")")")" && pwd)"
readonly HOOK_DIR
CONF="${HOOK_DIR}/gitformat.conf"
readonly CONF

REPO_ROOT="$1"
readonly REPO_ROOT
cd "$REPO_ROOT"

if ! command -v clang-format >/dev/null 2>&1; then
  echo "[git-format] cpp: clang-format을 찾을 수 없어 건너뜀"
  exit 0
fi

# NUL로 구분해 공백 포함 파일명도 안전하게 다룬다(GF-36). git diff 출력을 셸
# 변수에 담으면 NUL 바이트가 잘려나가므로 임시 파일에 받는다. --diff-filter에
# R(rename)도 포함해 리네임+수정된 파일도 검사한다(GF-37).
FILELIST="$(mktemp)"
readonly FILELIST
trap 'rm -f "$FILELIST"' EXIT

# shellcheck disable=SC2046 # gitformat.conf의 다중값 확장자 목록을 그대로 인자로 펼친다.
git diff --cached --name-only -z --diff-filter=ACMR -- \
  $(git config --file "$CONF" --get-all gitformat.cpp.ext) > "$FILELIST" || true

if [ ! -s "$FILELIST" ]; then
  echo "[git-format] cpp: 스테이징된 C/C++ 파일 없음, 건너뜀"
  exit 0
fi

echo "[git-format] cpp: clang-format --dry-run -Werror"
xargs -0 clang-format --dry-run -Werror < "$FILELIST"
