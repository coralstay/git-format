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

files=$(git diff --cached --name-only --diff-filter=ACM -- '*.c' '*.cc' '*.cpp' '*.cxx' '*.h' '*.hpp' '*.hh' || true)

if [ -z "$files" ]; then
  echo "[git-format] cpp: 스테이징된 C/C++ 파일 없음, 건너뜀"
  exit 0
fi

echo "[git-format] cpp: clang-format --dry-run -Werror"
echo "$files" | xargs clang-format --dry-run -Werror
