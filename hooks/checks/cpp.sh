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
# gitformat.conf 자체를 못 읽으면(파일 없음/문법 깨짐) 이후 모든 git config
# --file 읽기가 하나씩 실패하면서 원인을 알기 어려운 에러로 이어진다. 여기서
# 미리 검증해 원인을 명확히 알려준다. 이 블록은 CONF를 읽는 다른 파일들에도
# byte-identical하게 있다(tests/consistency.bats가 동일성을 보장).
if ! git config --file "$CONF" --list >/dev/null 2>&1; then
  echo "gitformat: gitformat.conf를 읽을 수 없습니다: ${CONF}" >&2
  exit 1
fi

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

# gitformat.conf의 다중값 확장자 목록(*.c, *.cpp, ...)을 git diff pathspec
# 인자로 하나씩 넘긴다. 예전엔 $(...)를 따옴표 없이 그대로 펼쳤는데, 그러면
# word splitting 뒤에 셸이 pathname expansion(실제 파일시스템 글롭)까지 같이
# 수행해버린다 - 저장소 루트(cd "$REPO_ROOT" 상태)에 그 확장자와 매치되는
# 파일이 하나라도 있으면 글롭 토큰이 "그 파일명 하나"로 셸에 의해 먼저
# 치환돼, git에 넘어가는 pathspec이 트리 전체가 아니라 루트의 그 파일
# 하나로 좁아진다. 그러면 하위 디렉터리의 같은 확장자 파일은 스테이징돼
# 있어도 검사에서 통째로 빠진다(GF-81). POSIX sh엔 배열이 없으므로
# post-commit의 트레일러 누적과 동일하게 $@를 배열처럼 써서 값을 한 줄씩
# 따옴표 유지한 채 담는다 - word splitting은 되지만 각 값이 개별 인자로
# 남아 pathname expansion은 겪지 않는다.
set --
while IFS= read -r ext; do
  set -- "$@" "$ext"
done <<EOF
$(git config --file "$CONF" --get-all gitformat.cpp.ext)
EOF

git diff --cached --name-only -z --diff-filter=ACMR -- "$@" > "$FILELIST" || true

if [ ! -s "$FILELIST" ]; then
  echo "[git-format] cpp: 스테이징된 C/C++ 파일 없음, 건너뜀"
  exit 0
fi

echo "[git-format] cpp: clang-format --dry-run -Werror"
xargs -0 clang-format --dry-run -Werror < "$FILELIST"
