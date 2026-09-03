#!/usr/bin/env bats
# GF-21 스모크 테스트: 하네스가 실제로 동작하는지 최소 확인.
# 세부 견고성 테스트는 GF-22~28에서 각 훅별로 확장한다.

load 'helpers/git-format'

setup() {
  make_isolated_repo
}

teardown() {
  cleanup_isolated_repo
}

@test "[type][subsystem] 형식의 커밋은 통과한다" {
  echo hi > a.txt
  git add a.txt
  run git commit -m "[feat] smoke test"
  [ "$status" -eq 0 ]
}

@test "형식에 안 맞는 커밋 메시지는 거부된다" {
  echo hi > a.txt
  git add a.txt
  run git commit -m "이상한 메시지"
  [ "$status" -ne 0 ]
}

@test "언어 마커가 없는 저장소는 pre-commit이 무해하게 통과시킨다" {
  run sh "${GITFORMAT_ROOT}/hooks/pre-commit"
  [ "$status" -eq 0 ]
}
