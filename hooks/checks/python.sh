#!/bin/sh
# Python 체크: pre-commit 디스패처가 pyproject.toml/requirements.txt 감지 시 호출한다.
# ruff를 우선 사용하고, 없으면 flake8로 대체한다. 둘 다 없으면 조용히 건너뛴다.
set -eu

REPO_ROOT="$1"
cd "$REPO_ROOT"

if command -v ruff >/dev/null 2>&1; then
  echo "[git-format] python: ruff check ."
  ruff check .
elif command -v flake8 >/dev/null 2>&1; then
  echo "[git-format] python: flake8 ."
  flake8 .
else
  echo "[git-format] python: ruff/flake8을 찾을 수 없어 건너뜀"
fi
