#!/usr/bin/env bats
# GF-22: Python 체크를 실제 ruff로 검증한다(이전엔 PATH 셔밍만 했음).

load 'helpers/git-format'

setup() {
  make_isolated_repo
  touch pyproject.toml
}

teardown() {
  cleanup_isolated_repo
}

@test "린트 문제 없는 코드는 통과한다" {
  echo "x = 1" > clean.py
  git add pyproject.toml clean.py
  run git commit -m "[feat][py] add clean module"
  [ "$status" -eq 0 ]
}

@test "실제 ruff가 미사용 import를 잡아 커밋을 막는다" {
  echo "import os" > unused.py
  git add pyproject.toml unused.py
  run git commit -m "[feat][py] add unused import"
  [ "$status" -ne 0 ]
}

@test "ruff가 없으면 조용히 건너뛴다" {
  echo "import os" > unused.py
  git add pyproject.toml unused.py
  PATH="$(path_without ruff)" run git commit -m "[feat][py] no ruff on PATH"
  [ "$status" -eq 0 ]
}
