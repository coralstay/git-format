#!/bin/sh
# SQL 체크: pre-commit 디스패처가 .sqlfluff 설정 또는 추적된 .sql 파일 감지 시 호출한다.
# 스테이징된 .sql 파일에 대해서만 sqlfluff lint를 실행한다(decision-6).
set -eu

REPO_ROOT="$1"
cd "$REPO_ROOT"

if ! command -v sqlfluff >/dev/null 2>&1; then
  echo "[git-format] sql: sqlfluff를 찾을 수 없어 건너뜀"
  exit 0
fi

files=$(git diff --cached --name-only --diff-filter=ACM -- '*.sql' || true)

if [ -z "$files" ]; then
  echo "[git-format] sql: 스테이징된 .sql 파일 없음, 건너뜀"
  exit 0
fi

echo "[git-format] sql: sqlfluff lint"
echo "$files" | xargs sqlfluff lint
