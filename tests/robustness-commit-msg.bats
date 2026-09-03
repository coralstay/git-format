#!/usr/bin/env bats
# GF-23: commit-msg 견고성 테스트 (동등분할/경계값/결정테이블/구문테스트) - decision-8
# 표준 인증이 아니라 실제 버그 이력(GF-30, GF-34, GF-35)에 근거한 실용적 테스트.
# GF-82: 서브젝트를 [type][subsystem] 프리픽스로 전환하면서 관련 테스트도 갱신.

load 'helpers/git-format'

setup() {
  make_isolated_repo
  echo hi > a.txt
  git add a.txt
}

teardown() {
  cleanup_isolated_repo
}

# ── 동등분할: type/subsystem/BREAKING CHANGE 대표값 ──────────────────

@test "[동등분할] 유효한 type + subsystem 없음은 통과한다" {
  run git commit -m "[fix] 버그 수정"
  [ "$status" -eq 0 ]
}

@test "[동등분할] 유효한 type + subsystem 있음은 통과한다" {
  run git commit -m "[fix][parser] 버그 수정"
  [ "$status" -eq 0 ]
}

@test "[동등분할] 목록에 없는 type은 거부된다" {
  run git commit -m "[wip] 진행중"
  [ "$status" -ne 0 ]
}

@test "[동등분할] BREAKING CHANGE(subject의 !)는 더 이상 지원하지 않아 거부된다 (GF-82)" {
  run git commit -m "[feat!] 하위호환 깨는 변경"
  [ "$status" -ne 0 ]
}

@test "[동등분할] BREAKING CHANGE(footer)는 통과한다" {
  run git commit -m "$(printf '[feat] 변경\n\nBREAKING CHANGE: 하위호환 깨짐')"
  [ "$status" -eq 0 ]
}

# ── 경계값분석: 빈 description / 매우 긴 값 / task 번호 0·거대값 ──────

@test "[경계값] description이 빈 문자열이면 거부된다" {
  run git commit -m "[feat] "
  [ "$status" -ne 0 ]
}

@test "[GF-83] 매우 긴 subject는 형식이 맞아도 길이 제한(50자)으로 거부된다" {
  long_desc="$(printf 'x%.0s' $(seq 1 5000))"
  run git commit -m "[feat] ${long_desc}"
  [ "$status" -ne 0 ]
}

@test "[경계값] Task-Id 번호가 0이어도 브랜치 패턴은 통과한다" {
  git checkout -q -b "GF-0-zero"
  run git commit -m "[feat] zero task id"
  [ "$status" -eq 0 ]
}

@test "[경계값] Task-Id 번호가 매우 커도 브랜치 패턴은 통과한다" {
  git checkout -q -b "GF-99999999999999999999-huge"
  run git commit -m "[feat] huge task id"
  [ "$status" -eq 0 ]
}

@test "[경계값] 매우 긴 브랜치명도 Task-Id 패턴만 있으면 통과한다" {
  long_suffix="$(printf 'x%.0s' $(seq 1 200))"
  git checkout -q -b "GF-1-${long_suffix}"
  run git commit -m "[feat] long branch"
  [ "$status" -eq 0 ]
}

@test "[경계값] Task-Id 없는 non-exempt 브랜치는 거부된다" {
  git checkout -q -b "no-task-id-here"
  run git commit -m "[feat] missing task id"
  [ "$status" -ne 0 ]
}

# ── branchExempt --add 시 기본 예외 유실 회귀 방지 (GF-78) ──────────────

@test "[GF-78] branchExempt를 --add해도 기본 예외 브랜치(main)는 유지된다" {
  git config --add gitformat.branchExempt 'hotfix/*'
  # -B: 이미 main 브랜치일 수도(git init 기본값에 따라 다름) 있어 -b 대신
  # 강제 생성/전환으로 환경에 상관없이 동작하게 한다.
  git checkout -q -B main
  run git commit -m "[feat] main after add"
  [ "$status" -eq 0 ]
}

@test "[GF-78] branchExempt로 --add한 패턴도 예외로 동작한다" {
  git config --add gitformat.branchExempt 'hotfix/*'
  git checkout -q -b hotfix/urgent
  run git commit -m "[feat] added exempt pattern"
  [ "$status" -eq 0 ]
}

@test "[GF-78] branchExempt를 --add해도 Task-Id 없는 다른 브랜치는 여전히 거부된다" {
  git config --add gitformat.branchExempt 'hotfix/*'
  git checkout -q -b unrelated-branch
  run git commit -m "[feat] still rejected"
  [ "$status" -ne 0 ]
}

# ── 결정테이블: AI_AGENT유무 x claude-code여부 x aiModel설정 x 화이트리스트 ──

@test "[결정테이블] AI_AGENT 미설정이면 AI-Model 게이트를 건너뛴다" {
  AI_AGENT="" run git commit -m "[feat] no ai agent"
  [ "$status" -eq 0 ]
}

@test "[결정테이블] AI_AGENT=claude-code면 aiModel 미설정이어도 통과한다" {
  AI_AGENT="claude-code_2-1-0" run git commit -m "[feat] claude code agent"
  [ "$status" -eq 0 ]
}

@test "[결정테이블] 비-claude-code 도구 + aiModel 미설정이면 거부된다" {
  AI_AGENT="other-tool_1-0" run git commit -m "[feat] other tool no model"
  [ "$status" -ne 0 ]
}

@test "[결정테이블] 비-claude-code 도구 + aiModel 설정했지만 화이트리스트에 없으면 거부된다" {
  git config gitformat.aiModel "not-a-real-model"
  AI_AGENT="other-tool_1-0" run git commit -m "[feat] unknown model"
  [ "$status" -ne 0 ]
}

@test "[결정테이블] 비-claude-code 도구 + aiModel이 화이트리스트에 있으면 통과한다" {
  git config gitformat.aiModel "gpt-5"
  AI_AGENT="other-tool_1-0" run git commit -m "[feat] known model"
  [ "$status" -eq 0 ]
}

# ── 구문테스트: 셸 메타문자 / 개행 / 제어문자 ─────────────────────────

@test "[구문테스트] 커밋 메시지에 셸 메타문자가 있어도 실행되지 않고 안전하게 처리된다" {
  # subject 길이 제한(GF-83, 50자)에 걸리지 않도록 짧은 파일명을 쓴다 -
  # 이 테스트의 목적은 셸 인젝션 방지 확인이지 길이 검증이 아니다.
  run git commit -m '[feat] $(touch p1) `touch p2`;touch p3|touch p4'
  [ "$status" -eq 0 ]
  [ ! -e p1 ]
  [ ! -e p2 ]
  [ ! -e p3 ]
  [ ! -e p4 ]
}

@test "[구문테스트] 커밋 메시지 본문에 개행이 있어도 정상 처리된다" {
  run git commit -m "$(printf '[feat] 여러줄\n\n첫 줄\n둘째 줄\n\nFooter: value')"
  [ "$status" -eq 0 ]
}

@test "[구문테스트] type 앞에 제어문자(탭)가 섞이면 거부된다" {
  run git commit -m "$(printf '\t[feat] 탭으로 시작')"
  [ "$status" -ne 0 ]
}

# ── 빈 줄 강제 / Fixes: 검증 (GF-82, 리누스 스타일) ───────────────────

@test "[GF-82] 본문이 있는데 제목과의 사이에 빈 줄이 없으면 거부된다" {
  run git commit -m "$(printf '[feat] 제목\n본문이 빈 줄 없이 바로 이어짐')"
  [ "$status" -ne 0 ]
}

@test "[GF-82] 본문이 있고 빈 줄로 구분돼 있으면 통과한다" {
  run git commit -m "$(printf '[feat] 제목\n\n본문')"
  [ "$status" -eq 0 ]
}

@test "[GF-82] Fixes: 트레일러가 실재하는 커밋을 가리키면 통과한다" {
  git commit -q -m "[fix] baseline"
  FIRST_HASH="$(git rev-parse HEAD)"
  echo more >> a.txt
  git add a.txt
  run git commit -m "$(printf '[fix] 후속 수정\n\nFixes: %s' "$FIRST_HASH")"
  [ "$status" -eq 0 ]
}

@test "[GF-82] Fixes: 트레일러가 존재하지 않는 해시를 가리키면 거부된다" {
  git commit -q -m "[fix] baseline"
  echo more >> a.txt
  git add a.txt
  run git commit -m "$(printf '[fix] 후속 수정\n\nFixes: 0000000000000000000000000000000000dead')"
  [ "$status" -ne 0 ]
}

@test "[GF-82] Fixes: 트레일러가 없어도 통과한다 (강제 아님)" {
  run git commit -m "[fix] no fixes trailer"
  [ "$status" -eq 0 ]
}

# ── subject 길이 / 본문 줄 길이 검증 (GF-83) ──────────────────────────

@test "[GF-83] subject가 정확히 50자면 통과한다 (경계값)" {
  desc="$(printf 'x%.0s' $(seq 1 43))"
  run git commit -m "[feat] ${desc}"
  [ "$status" -eq 0 ]
}

@test "[GF-83] subject가 51자면 거부된다 (경계값)" {
  desc="$(printf 'x%.0s' $(seq 1 44))"
  run git commit -m "[feat] ${desc}"
  [ "$status" -ne 0 ]
}

@test "[GF-83] 글자 수는 바이트가 아니라 유니코드 문자 단위로 센다 - 한글 27자(67바이트)는 통과한다" {
  desc="$(printf '가%.0s' $(seq 1 20))"
  run git commit -m "[feat] ${desc}"
  [ "$status" -eq 0 ]
}

@test "[GF-83] 한글이어도 문자 수 자체가 50자를 넘으면 거부된다 (52자)" {
  desc="$(printf '가%.0s' $(seq 1 45))"
  run git commit -m "[feat] ${desc}"
  [ "$status" -ne 0 ]
}

@test "[GF-83] 본문 줄이 정확히 72자면 통과한다 (경계값)" {
  body="$(printf 'x%.0s' $(seq 1 72))"
  run git commit -m "$(printf '[feat] 제목\n\n%s' "$body")"
  [ "$status" -eq 0 ]
}

@test "[GF-83] 본문 줄이 73자면 거부된다 (경계값)" {
  body="$(printf 'x%.0s' $(seq 1 73))"
  run git commit -m "$(printf '[feat] 제목\n\n%s' "$body")"
  [ "$status" -ne 0 ]
}

@test "[GF-83] 등록된 트레일러 토큰으로 시작하는 줄은 72자를 넘어도 통과한다" {
  long_desc="$(printf 'y%.0s' $(seq 1 70))"
  run git commit -m "$(printf '[feat] 제목\n\nBREAKING CHANGE: %s' "$long_desc")"
  [ "$status" -eq 0 ]
}
