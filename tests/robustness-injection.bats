#!/usr/bin/env bats
# GF-27: 보안/인젝션 내성 테스트 (구문테스트/네거티브 테스트) - decision-8
# 표준 인증이 아니라 hooks가 브랜치명/커밋 메시지를 항상 따옴표로 감싸 다루고
# eval을 쓰지 않는다는 실제 코드 특성을 실증하는 네거티브 테스트.
#
# tests/robustness-commit-msg.bats(GF-23)의 구문테스트가 "커밋 메시지"에 섞인
# 셸 메타문자를 이미 다루므로, 여기서는 "브랜치명"에 집중하고 커밋 메시지 쪽은
# 개행+메타문자 조합/non-UTF8/매우 긴 라인처럼 더 공격적인 조합만 추가한다.
#
# 주의: git 브랜치명은 공백을 허용하지 않는다(check-ref-format). 그래서 아래
# 페이로드는 공백 없는 형태(예: $IFS로 공백을 대신)를 쓴다 — 이건 셸 인젝션
# 페이로드에서 흔히 쓰이는 공백 우회 기법이라 오히려 더 현실적인 공격 벡터다.

load 'helpers/git-format'

setup() {
  make_isolated_repo
}

teardown() {
  cleanup_isolated_repo
}

# ── git이 애초에 거부하는 브랜치명 ────────────────────────────────

@test "[브랜치명] 공백이 섞인 브랜치명은 git 자체가 생성을 거부한다" {
  run git checkout -q -b 'GF-1 with space'
  [ "$status" -ne 0 ]
}

# ── git은 허용하지만 셸엔 위험한 브랜치명: 실행되지 않는지 검증 ──────

@test "[브랜치명] \$()+\$IFS 서브셸 패턴이 섞여도 실행되지 않고 커밋이 안전하게 처리된다" {
  git checkout -q -b 'GF-1-$(touch${IFS}pwned-a)'
  echo hi > a.txt
  git add a.txt
  run git commit -m "[feat] subshell in branch name"
  [ "$status" -eq 0 ]
  [ ! -e pwned-a ]
  MSG="$(git log -1 --pretty=%B)"
  [[ "$MSG" == *"Task-Id: GF-1"* ]]
}

@test "[브랜치명] 백틱+\$IFS 서브셸 패턴이 섞여도 실행되지 않는다" {
  git checkout -q -b 'GF-1-`touch${IFS}pwned-b`'
  echo hi > a.txt
  git add a.txt
  run git commit -m "[feat] backtick in branch name"
  [ "$status" -eq 0 ]
  [ ! -e pwned-b ]
}

@test "[브랜치명] 세미콜론/파이프/&&가 섞여도 실행되지 않는다" {
  git checkout -q -b 'GF-1-;touch-pwned-c|touch-pwned-d&&touch-pwned-e'
  echo hi > a.txt
  git add a.txt
  run git commit -m "[feat] shell operators in branch name"
  [ "$status" -eq 0 ]
  [ ! -e pwned-c ]
  [ ! -e pwned-d ]
  [ ! -e pwned-e ]
}

# ── 커밋 메시지: 개행+메타문자 조합 / non-UTF8 / 매우 긴 라인 ────────
# 트레일러가 실제로 붙는 경로(Task-Id 브랜치)에서 interpret-trailers 삽입이
# 안 깨지는지 확인한다.

@test "[커밋메시지] 개행과 셸 메타문자가 뒤섞여도 트레일러 삽입이 깨지지 않는다" {
  git checkout -q -b 'GF-2-injection'
  echo hi > a.txt
  git add a.txt
  run git commit -m "$(printf '[feat] 복합 페이로드\n\n$(touch pwned-f)\n`touch pwned-g`\n; touch pwned-h | touch pwned-i')"
  [ "$status" -eq 0 ]
  [ ! -e pwned-f ]; [ ! -e pwned-g ]; [ ! -e pwned-h ]; [ ! -e pwned-i ]
  MSG="$(git log -1 --pretty=%B)"
  [[ "$MSG" == *"Task-Id: GF-2"* ]]
}

@test "[커밋메시지] non-UTF8 바이트가 섞여도 트레일러 삽입이 깨지지 않는다" {
  git checkout -q -b 'GF-3-nonutf8'
  echo hi > a.txt
  git add a.txt
  BAD_MSG="$(mktemp)"
  printf '[feat] broken \xff\xfe bytes\n' > "$BAD_MSG"
  run git commit -F "$BAD_MSG"
  [ "$status" -eq 0 ]
  MSG="$(git log -1 --pretty=%B)"
  [[ "$MSG" == *"Task-Id: GF-3"* ]]
  rm -f "$BAD_MSG"
}

@test "[커밋메시지] 매우 긴 라인이 섞여도 트레일러 삽입이 깨지지 않는다" {
  # 이 테스트의 목적은 post-commit의 interpret-trailers 삽입이 매우 긴 라인
  # 앞에서 깨지지 않는지 확인하는 것이지, GF-83의 본문 줄 길이(72자) 검증
  # 자체를 테스트하는 게 아니다 - 20000자 라인은 그 검증에 걸리므로
  # --no-verify로 commit-msg/pre-commit을 건너뛰고 post-commit(항상 실행됨)
  # 경로만 검증한다.
  git checkout -q -b 'GF-4-longline'
  echo hi > a.txt
  git add a.txt
  long_body="$(printf 'y%.0s' $(seq 1 20000))"
  run git commit --no-verify -m "$(printf '[feat] 긴 본문\n\n%s' "$long_body")"
  [ "$status" -eq 0 ]
  MSG="$(git log -1 --pretty=%B)"
  [[ "$MSG" == *"Task-Id: GF-4"* ]]
  [[ "$MSG" == *"$long_body"* ]]
}
