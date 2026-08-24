#!/usr/bin/env bats
# GF-22: SQL 체크를 실제 sqlfluff로 검증한다(이전엔 PATH 셔밍만 했음).
# sqlfluff는 dialect 미지정 시 사용법 에러(exit 2)를 낸다는 걸 실도구 테스트로
# 발견해 hooks/checks/sql.sh가 .sqlfluff 없을 때 --dialect ansi를 기본값으로
# 넘기도록 고쳤다 — 이 회귀를 고정한다.

load 'helpers/git-format'

setup() {
  make_isolated_repo
}

teardown() {
  cleanup_isolated_repo
}

@test ".sqlfluff 없이도 유효한 SQL은 통과한다 (ansi 폴백)" {
  mkdir -p migrations
  echo "SELECT 1;" > migrations/001.sql
  git add migrations/001.sql
  run git commit -m "feat(db): add migration"
  [ "$status" -eq 0 ]
}

@test "문법이 깨진 SQL은 실제 sqlfluff가 차단한다" {
  mkdir -p migrations
  printf 'select   *,,, from bad(((' > migrations/broken.sql
  git add migrations/broken.sql
  run git commit -m "feat(db): add broken migration"
  [ "$status" -ne 0 ]
}

@test ".sqlfluff 설정이 있으면 그 dialect를 존중한다" {
  cat > .sqlfluff <<'EOF'
[sqlfluff]
dialect = postgres
EOF
  mkdir -p migrations
  echo "SELECT 1;" > migrations/001.sql
  git add .sqlfluff migrations/001.sql
  run git commit -m "feat(db): postgres dialect"
  [ "$status" -eq 0 ]
}

@test "sqlfluff가 없으면 조용히 건너뛴다" {
  mkdir -p migrations
  echo "SELECT 1;" > migrations/001.sql
  git add migrations/001.sql
  PATH="/usr/bin:/bin" run git commit -m "feat(db): no sqlfluff on PATH"
  [ "$status" -eq 0 ]
}
