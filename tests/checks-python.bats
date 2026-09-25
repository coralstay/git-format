#!/usr/bin/env bats
# GF-22: Python 체크를 실제 ruff로 검증한다(이전엔 PATH 셔밍만 했음).
# GF-115: 검사 스코프가 저장소 전체(`ruff check .`)에서 스테이징된 파일로 좁혀졌다 -
# 이번 커밋과 무관한 기존 린트 에러로 커밋이 막히지 않는지(false blocking), 그리고
# 스테이징된 파일의 에러는 여전히 막는지 양쪽을 본다.

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

@test "스테이징되지 않은 파일의 린트 에러는 커밋을 막지 않는다 (GF-115)" {
  echo "import os" > legacy.py
  echo "x = 1" > clean.py
  git add pyproject.toml clean.py
  run git commit -m "[feat][py] add clean module"
  [ "$status" -eq 0 ]
}

@test "이미 커밋된 파일의 린트 에러는 이후 커밋을 막지 않는다 (GF-115)" {
  # 기존 부채를 재현한다 - 검사가 좁아지기 전에 들어온 에러 있는 파일이
  # 무관한 다음 커밋까지 막던 게 GF-115의 false blocking이다.
  echo "import os" > legacy.py
  git add pyproject.toml legacy.py
  git commit -q --no-verify -m "[feat][py] pre-existing lint debt"
  echo "y = 2" > clean.py
  git add clean.py
  run git commit -m "[feat][py] add unrelated module"
  [ "$status" -eq 0 ]
}

@test "스테이징된 Python 파일이 없으면 건너뛴다 (GF-115)" {
  echo "import os" > legacy.py
  echo "메모" > notes.txt
  git add pyproject.toml notes.txt
  run git commit -m "[docs][py] add notes"
  [ "$status" -eq 0 ]
  [[ "$output" == *"스테이징된 Python 파일 없음"* ]]
}

@test "하위 디렉터리의 스테이징된 파일도 검사한다 (GF-115)" {
  mkdir -p pkg
  echo "import os" > pkg/unused.py
  git add pyproject.toml pkg/unused.py
  run git commit -m "[feat][py] add nested unused import"
  [ "$status" -ne 0 ]
}
