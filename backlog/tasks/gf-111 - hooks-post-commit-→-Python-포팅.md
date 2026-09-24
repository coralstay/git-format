---
id: GF-111
title: hooks/post-commit → Python 포팅
status: To Do
assignee:
  - '@claude'
created_date: '2026-09-24 09:24'
updated_date: '2026-09-24 10:08'
labels:
  - python-migration
  - hooks
milestone: m-3
dependencies:
  - GF-110
documentation:
  - doc-9
  - doc-10
modified_files:
  - hooks/post-commit
  - .github/workflows/test.yml
type: enhancement
ordinal: 5
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
## 왜

post-commit은 423줄로 전환 대상 중 가장 크고, 트레일러 삽입/우회 탐지/AI 귀속 측정이 얽혀 있어 마지막에 포팅한다. pre-commit이 쓰는 .gitformat-verified 마커를 읽는 역할이라 코드 의존은 없지만(마커는 포맷 기반 계약이라 sh/Python 상관없이 상호운용됨) 마커를 쓰는 쪽을 먼저 포팅한 뒤 읽는 쪽을 포팅하는 순서가 원인 추적에 유리하다.

## 무엇을

hooks/post-commit을 #!/usr/bin/env python3 단일 파일로 포팅한다.

그대로 유지해야 하는 것(단순화 금지 대상):
- amend 재귀 방지 가드(_GITFORMAT_AMEND_GUARD 환경변수 확인)가 반드시 맨 먼저 실행돼야 한다. post-commit이 git commit --amend로 트레일러를 삽입하므로 이 가드가 없거나 늦으면 무한 재귀한다
- git interpret-trailers --if-exists는 키를 정확 일치가 아니라 접두어로 매칭한다(GF-33) - 이 때문에 지금 코드는 --if-exists에 기대지 않고 "key: value" 줄을 직접 파싱한다. Python으로 옮길 때 interpret-trailers를 믿고 단순화하면 안 된다
- Verify-Bypassed(마커 부재 = --no-verify 우회), Task-Id, AI-Tool/AI-Tool-Version/AI-Model, Co-Authored-By, Tokens-Used/Tool-Calls, Hooks-Commit, Signed-off-by 트레일러 삽입 로직 전부
- TASK_PREFIX/BRANCH 계산은 commit-msg와 동일 유지(파일별 독립 중복)

정당한 개선: jq 서브프로세스 호출을 json.loads()로 대체한다 - Claude Code 트랜스크립트 파싱에 쓰던 jq 의존성이 사라진다. 단 현재의 fail-open 단위를 바꾸면 안 된다: 지금은 jq -s로 한 줄이라도 파싱 실패하면 배치 전체가 실패해 MEASUREMENT_REASON="transcript-parse-failed"로 기록된다. 개별 불량 줄만 조용히 건너뛰는 식으로 바꾸면 동작 변경이다.

의도적 예외 유지: AI-Model 트랜스크립트 조회는 실패 시 조용히 트레일러를 생략하는 fail-open이 의도된 동작이다(decision-5). 이 한 곳만 좁은 try/except로 감싸고, 나머지 subprocess 호출은 실패 시 예외를 던지게 한다(GF-76의 조용한 실패 전파 방지).

CI: 같은 커밋에서 test.yml shellcheck 대상에서 hooks/post-commit 제거 - 이 시점에 install.sh만 남는다.

## 선행/병렬

코드 의존은 없다(마커는 포맷 기반 계약이라 pre-commit이 sh든 Python이든 상호운용된다). 다만 마커를 쓰는 쪽(pre-commit, GF-110)을 먼저 포팅한 뒤 읽는 쪽을 포팅하는 순서가 문제 발생 시 원인 추적에 유리하므로 GF-110 이후를 권장한다(강제 아님).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 hooks/post-commit이 #!/usr/bin/env python3 셔뱅의 단일 Python 파일로 포팅되고, amend 재귀 방지 가드가 다른 어떤 작업보다 먼저 실행된다
- [ ] #2 Verify-Bypassed(마커 부재 = --no-verify 우회), Task-Id, AI-Tool/AI-Tool-Version/AI-Model, Co-Authored-By, Tokens-Used/Tool-Calls, Hooks-Commit, Signed-off-by 트레일러 삽입이 sh 버전과 동일하게 동작한다
- [ ] #3 git interpret-trailers --if-exists의 접두어 매칭 문제(GF-33)를 피하기 위해 기존처럼 'key: value' 줄을 직접 파싱하는 방식이 유지된다(interpret-trailers를 믿고 단순화하지 않음)
- [ ] #4 jq 서브프로세스 호출이 json.loads()로 대체되어 jq 의존성이 제거되되, 한 줄이라도 파싱 실패 시 배치 전체를 실패 처리해 MEASUREMENT_REASON=transcript-parse-failed로 기록하는 현재의 fail-open 단위가 그대로 유지된다
- [ ] #5 AI-Model 트랜스크립트 조회만 좁은 try/except로 감싸 실패 시 트레일러를 생략하는 의도된 fail-open(decision-5)을 유지하고, 나머지 subprocess 호출은 실패 시 예외를 던진다(GF-76 조용한 실패 전파 방지)
- [ ] #6 TASK_PREFIX/BRANCH 계산 블록이 commit-msg와 동일하게 유지되고(파일별 독립 중복), 모든 subprocess.run에 encoding=utf-8이 명시된다
- [ ] #7 같은 커밋에서 test.yml shellcheck 대상에서 hooks/post-commit이 제거되어 install.sh만 남는다
- [ ] #8 bats tests/robustness-post-commit.bats 통과 후 bats tests/ 전체를 1회 재실행해 교차 파일 정합성을 확인한다
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 해당 AC 범위의 bats 서브셋이 통과한다
- [ ] #2 CI(shellcheck + ruff)가 초록이다
- [ ] #3 변경 파일이 AC 범위를 벗어나지 않는다 - 범위 밖 작업 발견 시 유저에게 먼저 확인한다
- [ ] #4 커밋이 [type][subsystem] 규칙과 Task-Id 트레일러를 만족한다
- [ ] #5 Done 전환 전 final summary에 객관적 검증 증거(테스트 통과 로그 등)를 남긴다
- [ ] #6 새 코드에 불필요한 주석을 넣지 않는다 - WHY가 비자명한 경우(GF-33/34/35/76/80 회귀 방지 패턴, 의도적 fail-open, 의도적 중복 유지 등)에만 한 줄 주석을 남긴다
- [ ] #7 PR은 rebase-merge로만 머지하고(squash/merge-commit 금지), push·PR 생성·머지 각 단계 전에 git fetch로 원격 상태를 먼저 확인한다(트렁크 방식이 아니라 로컬/리모트가 어긋날 수 있음)
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. hooks/post-commit(sh, 423줄)을 읽고 트레일러별 로직을 분해한다
2. amend 재귀 방지 가드를 main() 최상단에 배치 - 환경변수 확인 후 즉시 종료. post-commit이 git commit --amend를 호출하므로 이 가드가 늦으면 무한 재귀한다
3. 트레일러 존재 확인은 git interpret-trailers --parse 출력을 "key: value"로 직접 파싱(--if-exists의 접두어 매칭에 의존 금지 - GF-33)
4. 트랜스크립트 파싱을 jq에서 json.loads()로 전환하되, jq -s의 all-or-nothing 실패 단위를 유지한다(한 줄이라도 실패하면 전체를 transcript-parse-failed로 기록)
5. AI-Model 조회만 좁은 try/except로 감싸고(decision-5의 의도된 fail-open), 나머지 subprocess는 실패 시 예외를 던지게 한다
6. TASK_PREFIX/BRANCH 블록은 GF-109의 commit-msg와 동일하게 유지
7. 같은 커밋에서 shellcheck 대상에서 hooks/post-commit 제거 → install.sh만 남는다
8. bats tests/robustness-post-commit.bats 실행 후 bats tests/ 전체를 1회 더 실행
<!-- SECTION:PLAN:END -->
