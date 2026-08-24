#!/bin/sh
# C/C++ 체크: pre-commit 디스패처가 CMakeLists.txt/Makefile 감지 시 호출한다.
# 스테이징된 C/C++ 파일에 대해서만 clang-format 포맷 검사를 한다(빌드는 무거우므로
# pre-push(GF-5)로 미룬다).
set -eu

REPO_ROOT="$1"
cd "$REPO_ROOT"

if ! command -v clang-format >/dev/null 2>&1; then
  echo "[git-format] cpp: clang-format을 찾을 수 없어 건너뜀"
  exit 0
fi

# NUL로 구분해 공백 포함 파일명도 안전하게 다룬다(GF-36). git diff 출력을 셸
# 변수에 담으면 NUL 바이트가 잘려나가므로 임시 파일에 받는다. --diff-filter에
# R(rename)도 포함해 리네임+수정된 파일도 검사한다(GF-37).
FILELIST="$(mktemp)"
trap 'rm -f "$FILELIST"' EXIT

git diff --cached --name-only -z --diff-filter=ACMR -- \
  '*.c' '*.cc' '*.cpp' '*.cxx' '*.h' '*.hpp' '*.hh' > "$FILELIST" || true

if [ ! -s "$FILELIST" ]; then
  echo "[git-format] cpp: 스테이징된 C/C++ 파일 없음, 건너뜀"
  exit 0
fi

echo "[git-format] cpp: clang-format --dry-run -Werror"
xargs -0 clang-format --dry-run -Werror < "$FILELIST"
