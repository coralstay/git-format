---
id: GF-98
title: >-
  PROJECT_SLUG 계산이 Claude Code의 실제 세션 슬러그 규칙과 달라
  AI-Model/Tokens-Used/Tool-Calls가 밑줄/점 포함 경로에서 항상 실패함
status: In Progress
assignee: []
created_date: '2026-09-18 16:21'
updated_date: '2026-09-19 01:25'
labels: []
milestone: m-2
dependencies: []
references:
  - GF-97
type: bug
ordinal: 95000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
hooks/post-commit의 trailer_ai_model()과 trailer_tokens_used()(각각 독립 사본, decision-9 관례)가 세션 트랜스크립트 경로를 PROJECT_SLUG="$(printf '%s' "$PWD" | tr '/' '-')"로 계산한다 - 슬래시만 하이픈으로 치환.

그런데 Claude Code가 실제로 ~/.claude/projects/ 아래 세션 디렉터리를 만들 때 쓰는 규칙은 "영숫자가 아닌 모든 문자를 하이픈으로 치환"이다(직접 재현: printf '%s' "$PWD" | tr -c 'A-Za-z0-9' '-' 가 실제 디렉터리명과 정확히 일치함을 확인). $HOME이나 작업 경로에 밑줄/점 등이 들어가면(예: 이 저장소를 쓰는 사용자의 $HOME=/Users/flynn_macpro, 밑줄 포함) 훅이 계산한 슬러그가 실제 디렉터리와 어긋나 트랜스크립트를 영영 찾지 못한다.

실제로 git log로 확인한 결과 이 저장소 자체의 GF-96 관련 커밋들(0cd8aff/3cbb904/a5ec61f/568af76)은 전부 AI-Model/Tokens-Used/Tool-Calls가 붙지 않았다 - "조회 실패 시 조용히 생략"으로 설계돼 있어 지금까지 에러 없이 숨어 있던 버그다.

GF-97(같은 함수를 다루는 unavailable+사유 명시 기능)과 밀접하게 관련되지만, 사용자 확인 결과 별도 버그로 분리해 처리한다. 같은 코드를 건드리므로 실행 순서/충돌에 주의(먼저 병합되는 쪽 기준으로 나머지를 rebase).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 trailer_ai_model()과 (GF-97 반영 이후) measure_claude_code_token_usage() 양쪽의 PROJECT_SLUG 계산이 Claude Code의 실제 규칙(영숫자가 아닌 모든 문자를 하이픈으로 치환, 예: tr -c A-Za-z0-9 -)과 일치하도록 수정된다
- [ ] #2 밑줄/점이 포함된 경로(FAKE_HOME)에서도 트랜스크립트 파일을 정확히 찾아낸다는 것을 검증하는 bats 테스트가 tests/robustness-post-commit.bats에 추가된다
- [ ] #3 이 저장소 자신에서 실커밋을 하나 만들어 AI-Model/Tokens-Used/Tool-Calls가 실제로 채워지는지 수동 확인하고 구현 노트에 근거를 남긴다
- [ ] #4 shellcheck -s sh hooks/post-commit 와 bats tests/ 전체가 경고/실패 없이 통과한다
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. tests/robustness-post-commit.bats에 실패하는 테스트 추가: 저장소 최상위 디렉터리 이름 자체에 밑줄/점을 포함시켜(하위 디렉터리는 훅 PWD에 영향 없음 - 훅은 항상 worktree root에서 실행됨을 실측 확인) tr -c A-Za-z0-9 - 로 계산한 SLUG로 FAKE_HOME 트랜스크립트를 배치하고 AI-Model/Tokens-Used/Tool-Calls가 실값으로 채워지는지 검증. bats로 RED 확인.
2. hooks/post-commit의 trailer_ai_model()과 measure_claude_code_token_usage() 두 PROJECT_SLUG 라인을 tr -c A-Za-z0-9 - 로 수정.
3. 같은 테스트 재실행해 GREEN 확인, bats tests/ 전체 재실행해 회귀 없는지 확인.
4. 이 저장소 자신에서 실커밋 하나 만들어 AI-Model/Tokens-Used/Tool-Calls가 실제로 채워지는지 수동 확인, 근거를 구현 노트에 남김.
5. shellcheck -s sh hooks/post-commit 클린 확인.
<!-- SECTION:PLAN:END -->
