#!/usr/bin/env bats
# GF-73: ts.sh(TypeScript/JavaScript 체크)에 대한 전용 테스트가 없던 공백을
# 메운다. eslint 등 특정 린터를 설치하지 않고도 package.json의 lint 스크립트
# 자체의 성공/실패로 npm run lint 연동을 검증하고, tsc는 로컬에 실제로 설치된
# 도구를 그대로 쓴다(GF-22 실도구 재검증 원칙과 동일).
#
# GF-115: tsc가 저장소 전체가 아니라 스테이징된 파일만 보게 바뀌었다. 좁히는
# 방법으로 `tsc --noEmit <파일>`을 쓰면 tsconfig.json이 무시돼 strict 전용 타입
# 에러를 놓치므로, tsconfig를 extends하는 임시 프로젝트 파일을 쓴다 - 아래
# "strict" 테스트가 그 회귀(= tsconfig 무시 형태로 되돌아감)를 잡는 감시탑이다.

load 'helpers/git-format'

setup() {
  make_isolated_repo
  # asdf 등 버전 매니저로 node를 관리하는 로컬 개발 환경에서는 격리된 임시
  # 디렉터리에 .tool-versions가 없어 node/npx/tsc 셈이 버전을 못 찾는다
  # (ts.sh 자체와는 무관한 로컬 테스트 환경 이슈). asdf가 있을 때만 필요한
  # 노드 버전을 명시적으로 지정한다 - 없는 환경(CI 등)에서는 조용히 무시된다.
  if command -v asdf >/dev/null 2>&1; then
    export ASDF_NODEJS_VERSION="lts"
  fi
}

teardown() {
  cleanup_isolated_repo
}

@test "lint 스크립트가 성공하면 커밋이 통과한다" {
  cat > package.json <<'EOF'
{ "scripts": { "lint": "exit 0" } }
EOF
  git add package.json
  run git commit -m "[feat][ts] lint script succeeds"
  [ "$status" -eq 0 ]
  [[ "$output" == *"ts: npm run lint"* ]]
}

@test "lint 스크립트가 실패하면 실제 npm이 커밋을 막는다" {
  cat > package.json <<'EOF'
{ "scripts": { "lint": "exit 1" } }
EOF
  git add package.json
  run git commit -m "[feat][ts] lint script fails"
  [ "$status" -ne 0 ]
}

@test "package.json에 lint 스크립트가 없으면 건너뛴다" {
  echo '{}' > package.json
  git add package.json
  run git commit -m "[feat][ts] no lint script"
  [ "$status" -eq 0 ]
  [[ "$output" == *"lint 스크립트가 없어 건너뜀"* ]]
}

@test "npm이 없으면 조용히 건너뛴다" {
  cat > package.json <<'EOF'
{ "scripts": { "lint": "exit 1" } }
EOF
  git add package.json
  PATH="$(path_without npm)" run git commit -m "[feat][ts] no npm on PATH"
  [ "$status" -eq 0 ]
}

@test "tsconfig.json이 있으면 실제 tsc --noEmit을 실행한다" {
  echo '{}' > package.json
  echo '{ "compilerOptions": { "strict": true } }' > tsconfig.json
  echo 'const x: number = 1;' > clean.ts
  git add package.json tsconfig.json clean.ts
  run git commit -m "[feat][ts] add tsconfig"
  [ "$status" -eq 0 ]
  [[ "$output" == *"tsc --noEmit"* ]]
}

@test "타입 에러가 있는 .ts 파일은 실제 tsc가 차단한다" {
  echo '{}' > package.json
  echo '{ "compilerOptions": { "strict": true } }' > tsconfig.json
  echo 'const x: number = "not a number";' > broken.ts
  git add package.json tsconfig.json broken.ts
  run git commit -m "[feat][ts] add type error"
  [ "$status" -ne 0 ]
}

@test "tsconfig.json은 있지만 tsc가 어디에도 없으면 조용히 건너뛴다 (GF-79)" {
  # npx --no-install tsc는 PATH가 아니라 npm/npx 자체의 조회 경로를 따로
  # 참조해서, tsc가 정말 없을 때도 npx 특유의 실패로 정상 커밋을 막았다
  # (typescript를 devDependency로만 설치하는 흔한 실사용 패턴, 그리고 이
  # 프로젝트 자체 CI도 typescript를 따로 설치하지 않아 같은 문제를 겪었다).
  echo '{}' > package.json
  echo '{ "compilerOptions": { "strict": true } }' > tsconfig.json
  echo 'const x: number = 1;' > clean.ts
  git add package.json tsconfig.json clean.ts
  PATH="$(path_without tsc)" run git commit -m "[feat][ts] no tsc anywhere"
  [ "$status" -eq 0 ]
  [[ "$output" == *"tsconfig.json은 있지만 tsc를 찾을 수 없어 건너뜀"* ]]
}

@test "strict 전용 타입 에러도 스테이징 파일에서 여전히 잡힌다 (GF-115)" {
  # noImplicitAny(strict)에서만 나는 에러다. `tsc --noEmit <파일>`처럼 파일
  # 인자를 주면 tsc가 tsconfig.json을 무시해 이 에러가 조용히 통과한다 -
  # 스코프를 좁히면서 그 형태로 되돌아가면 이 테스트가 깨진다.
  echo '{}' > package.json
  echo '{ "compilerOptions": { "strict": true } }' > tsconfig.json
  printf 'export function f(x) {\n  return x;\n}\n' > implicit.ts
  git add package.json tsconfig.json implicit.ts
  run git commit -m "[feat][ts] add implicit any"
  [ "$status" -ne 0 ]
}

@test "스테이징되지 않은 .ts의 타입 에러는 커밋을 막지 않는다 (GF-115)" {
  echo '{}' > package.json
  echo '{ "compilerOptions": { "strict": true } }' > tsconfig.json
  echo 'const bad: number = "not a number";' > legacy.ts
  echo 'const x: number = 1;' > clean.ts
  git add package.json tsconfig.json clean.ts
  run git commit -m "[feat][ts] add clean module"
  [ "$status" -eq 0 ]
}

@test "이미 커밋된 .ts의 타입 에러는 이후 커밋을 막지 않는다 (GF-115)" {
  # tsconfig.json이 없는 동안 들어온 기존 부채를 재현한다 - 검사가 좁아지기
  # 전에는 무관한 다음 커밋까지 이 에러 때문에 막혔다(false blocking).
  echo '{}' > package.json
  echo 'const bad: number = "not a number";' > legacy.ts
  git add package.json legacy.ts
  git commit -q -m "[feat][ts] pre-existing type debt"
  echo '{ "compilerOptions": { "strict": true } }' > tsconfig.json
  echo 'const x: number = 1;' > clean.ts
  git add tsconfig.json clean.ts
  run git commit -m "[feat][ts] add unrelated module"
  [ "$status" -eq 0 ]
}

@test "tsconfig의 include가 스테이징 범위를 다시 넓히지 않는다 (GF-115)" {
  # extends는 같은 이름의 키만 덮으므로, 임시 프로젝트 파일이 include를 []로
  # 덮지 않으면 원본의 include가 살아남아 스테이징되지 않은 파일까지 끌려온다.
  mkdir -p src
  echo '{}' > package.json
  echo '{ "compilerOptions": { "strict": true }, "include": ["src"] }' > tsconfig.json
  echo 'const bad: number = "not a number";' > src/legacy.ts
  echo 'const x: number = 1;' > src/clean.ts
  git add package.json tsconfig.json src/clean.ts
  run git commit -m "[feat][ts] add clean module under src"
  [ "$status" -eq 0 ]
}

@test "스테이징된 TypeScript 파일이 없으면 tsc를 건너뛴다 (GF-115)" {
  echo '{}' > package.json
  echo '{ "compilerOptions": { "strict": true } }' > tsconfig.json
  echo 'const bad: number = "not a number";' > legacy.ts
  echo "메모" > notes.txt
  git add package.json tsconfig.json notes.txt
  run git commit -m "[docs][ts] add notes"
  [ "$status" -eq 0 ]
  [[ "$output" == *"스테이징된 TypeScript 파일 없음"* ]]
}

@test "tsc가 실패해도 임시 프로젝트 파일은 남지 않는다 (GF-115)" {
  echo '{}' > package.json
  echo '{ "compilerOptions": { "strict": true } }' > tsconfig.json
  echo 'const x: number = "not a number";' > broken.ts
  git add package.json tsconfig.json broken.ts
  run git commit -m "[feat][ts] add type error"
  [ "$status" -ne 0 ]
  run ls tsconfig.gitformat-*.json
  [ "$status" -ne 0 ]
}
