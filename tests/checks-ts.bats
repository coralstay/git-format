#!/usr/bin/env bats
# GF-73: ts.sh(TypeScript/JavaScript 체크)에 대한 전용 테스트가 없던 공백을
# 메운다. eslint 등 특정 린터를 설치하지 않고도 package.json의 lint 스크립트
# 자체의 성공/실패로 npm run lint 연동을 검증하고, tsc는 로컬에 실제로 설치된
# 도구를 그대로 쓴다(GF-22 실도구 재검증 원칙과 동일).

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
  run git commit -m "feat(ts): lint script succeeds"
  [ "$status" -eq 0 ]
  [[ "$output" == *"ts: npm run lint"* ]]
}

@test "lint 스크립트가 실패하면 실제 npm이 커밋을 막는다" {
  cat > package.json <<'EOF'
{ "scripts": { "lint": "exit 1" } }
EOF
  git add package.json
  run git commit -m "feat(ts): lint script fails"
  [ "$status" -ne 0 ]
}

@test "package.json에 lint 스크립트가 없으면 건너뛴다" {
  echo '{}' > package.json
  git add package.json
  run git commit -m "feat(ts): no lint script"
  [ "$status" -eq 0 ]
  [[ "$output" == *"lint 스크립트가 없어 건너뜀"* ]]
}

@test "npm이 없으면 조용히 건너뛴다" {
  cat > package.json <<'EOF'
{ "scripts": { "lint": "exit 1" } }
EOF
  git add package.json
  PATH="$(path_without npm)" run git commit -m "feat(ts): no npm on PATH"
  [ "$status" -eq 0 ]
}

@test "tsconfig.json이 있으면 실제 tsc --noEmit을 실행한다" {
  echo '{}' > package.json
  echo '{ "compilerOptions": { "strict": true } }' > tsconfig.json
  echo 'const x: number = 1;' > clean.ts
  git add package.json tsconfig.json clean.ts
  run git commit -m "feat(ts): add tsconfig"
  [ "$status" -eq 0 ]
  [[ "$output" == *"tsc --noEmit"* ]]
}

@test "타입 에러가 있는 .ts 파일은 실제 tsc가 차단한다" {
  echo '{}' > package.json
  echo '{ "compilerOptions": { "strict": true } }' > tsconfig.json
  echo 'const x: number = "not a number";' > broken.ts
  git add package.json tsconfig.json broken.ts
  run git commit -m "feat(ts): add type error"
  [ "$status" -ne 0 ]
}
