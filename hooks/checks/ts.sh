#!/bin/sh
# TypeScript/JavaScript 체크: pre-commit 디스패처가 package.json 감지 시 호출한다.
# npm이 없거나 lint 스크립트/tsconfig.json이 없으면 해당 검사만 조용히 건너뛴다.
set -eu

REPO_ROOT="$1"
readonly REPO_ROOT
cd "$REPO_ROOT"

if ! command -v npm >/dev/null 2>&1; then
  echo "[git-format] ts: npm을 찾을 수 없어 건너뜀"
  exit 0
fi

# grep으로 "lint": 문자열을 찾으면 scripts 밖(예: devDependencies의 "lint"라는
# 패키지명)도 오탐한다(GF-39). package.json이 이미 npm이 이해하는 형식이므로
# node로 실제 scripts 객체를 확인한다. $1은 항상 이 파일 안에서 "lint" 같은
# 고정 리터럴로만 호출되므로(외부/사용자 입력 아님) 문자열 삽입이 안전하다.
has_npm_script() {
  node -e "process.exit((require('./package.json').scripts || {})['$1'] ? 0 : 1)" 2>/dev/null
}

if has_npm_script lint; then
  echo "[git-format] ts: npm run lint"
  npm run --silent lint
else
  echo "[git-format] ts: package.json에 lint 스크립트가 없어 건너뜀"
fi

if [ -f tsconfig.json ] && command -v npx >/dev/null 2>&1; then
  echo "[git-format] ts: tsc --noEmit"
  npx --no-install tsc --noEmit
fi
