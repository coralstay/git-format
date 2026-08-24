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

# sqlfluff는 dialect가 없으면(설정도, 플래그도) 린트가 아니라 사용법 에러(exit 2)로
# 실패한다(GF-22 실도구 재검증에서 발견). .sqlfluff 설정이 있으면 그 dialect를 그대로
# 쓰고, 없을 때만 범용 기본값 ansi를 명시적으로 넘긴다.
set -- lint
if [ ! -f .sqlfluff ]; then
  set -- "$@" --dialect ansi
fi

echo "[git-format] sql: sqlfluff lint"
echo "$files" | xargs sqlfluff "$@"
