#!/bin/sh
# TypeScript/JavaScript 체크: pre-commit 디스패처가 package.json 감지 시 호출한다.
# npm이 없거나 lint 스크립트/tsconfig.json이 없으면 해당 검사만 조용히 건너뛴다.
set -eu

REPO_ROOT="$1"
cd "$REPO_ROOT"

if ! command -v npm >/dev/null 2>&1; then
  echo "[git-format] ts: npm을 찾을 수 없어 건너뜀"
  exit 0
fi

if grep -q '"lint"[[:space:]]*:' package.json 2>/dev/null; then
  echo "[git-format] ts: npm run lint"
  npm run --silent lint
else
  echo "[git-format] ts: package.json에 lint 스크립트가 없어 건너뜀"
fi

if [ -f tsconfig.json ] && command -v npx >/dev/null 2>&1; then
  echo "[git-format] ts: tsc --noEmit"
  npx --no-install tsc --noEmit
fi
