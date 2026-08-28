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

# npx --no-install은 PATH가 아니라 npm/npx 자체의 전역 설치 조회 경로를
# 따로 참조한다 - `command -v tsc`가 PATH에서 tsc를 찾아내도(예: 버전
# 매니저 shim), npx의 조회 경로가 다르면 `npx --no-install tsc`가 여전히
# "npx canceled due to missing packages"로 실패해 타입 에러가 없는 정상
# 커밋까지 막을 수 있다(실측 확인, GF-79). 그래서 npx를 거치지 않고, 이미
# 존재를 확인한 tsc(로컬 devDependency 우선, 없으면 PATH의 tsc)를 직접
# 실행한다. 다른 언어 체크와 같은 원칙(도구 없으면 조용히 건너뜀)을 지킨다.
if [ -f tsconfig.json ]; then
  if [ -x node_modules/.bin/tsc ]; then
    echo "[git-format] ts: tsc --noEmit"
    node_modules/.bin/tsc --noEmit
  elif command -v tsc >/dev/null 2>&1; then
    echo "[git-format] ts: tsc --noEmit"
    tsc --noEmit
  else
    echo "[git-format] ts: tsconfig.json은 있지만 tsc를 찾을 수 없어 건너뜀"
  fi
fi
