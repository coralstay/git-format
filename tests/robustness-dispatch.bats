#!/usr/bin/env bats
# GF-24: pre-commit 디스패처 견고성 테스트 (페어와이즈/오류추정) - decision-8
# 표준 인증이 아니라 실제 버그 이력(GF-16, GF-39)에 근거한 실용적 테스트.

load 'helpers/git-format'

setup() {
  make_isolated_repo
}

teardown() {
  cleanup_isolated_repo
}

# ── 페어와이즈: ts+python+sql 동시 존재 ──────────────────────────────

@test "[페어와이즈] ts+python+sql이 모두 클린이면 셋 다 실행되고 커밋은 통과한다" {
  echo '{}' > package.json
  touch pyproject.toml
  echo "x = 1" > clean.py
  mkdir -p migrations
  echo "SELECT 1;" > migrations/001.sql
  git add package.json pyproject.toml clean.py migrations/001.sql
  run git commit -m "[feat] multi-lang clean"
  [ "$status" -eq 0 ]
  [[ "$output" == *"ts: package.json에 lint 스크립트가 없어 건너뜀"* ]]
  [[ "$output" == *"python: ruff check ."* ]]
  [[ "$output" == *"sql: sqlfluff lint"* ]]
}

@test "[페어와이즈] python이 깨지면 (ts/sql은 클린이어도) 커밋 전체가 막힌다" {
  echo '{}' > package.json
  touch pyproject.toml
  echo "import os" > unused.py
  mkdir -p migrations
  echo "SELECT 1;" > migrations/001.sql
  git add package.json pyproject.toml unused.py migrations/001.sql
  run git commit -m "[feat] python breaks the chain"
  [ "$status" -ne 0 ]
}

@test "[페어와이즈] python은 클린이고 sql만 깨지면 sql 체크가 커밋을 막는다" {
  touch pyproject.toml
  echo "x = 1" > clean.py
  mkdir -p migrations
  printf 'select   *,,, from bad(((' > migrations/broken.sql
  git add pyproject.toml clean.py migrations/broken.sql
  run git commit -m "[feat] sql breaks alone"
  [ "$status" -ne 0 ]
  [[ "$output" == *"python: ruff check ."* ]]
}

# ── GF-16 회귀: template/(심볼릭 링크) 경유 설치에서 checks/ resolve ──

@test "[GF-16 회귀] template/ 심볼릭 링크로 설치된 새 저장소에서도 pre-commit이 checks/를 정확히 찾는다" {
  FAKE_HOME="$(mktemp -d)"
  NEW_REPO="$(mktemp -d)"
  export HOME="$FAKE_HOME"

  "${GITFORMAT_ROOT}/install.sh" --global >/dev/null

  git init -q "$NEW_REPO"
  cd "$NEW_REPO"
  git config commit.gpgsign false
  git config user.email "bats@example.com"
  git config user.name "bats"

  # init.templateDir이 .git/hooks/*를 git-format 클론을 가리키는 심볼릭 링크로
  # 채웠는지부터 확인한다 — 이게 아니면 GF-16 시나리오 자체가 재현 안 된다.
  [ -L .git/hooks/pre-commit ]

  touch pyproject.toml
  echo "import os" > unused.py
  git add pyproject.toml unused.py
  run git commit -m "[feat][py] add unused import"
  [ "$status" -ne 0 ]
  [[ "$output" == *"python: ruff check ."* ]]

  rm -rf "$FAKE_HOME" "$NEW_REPO"
}
