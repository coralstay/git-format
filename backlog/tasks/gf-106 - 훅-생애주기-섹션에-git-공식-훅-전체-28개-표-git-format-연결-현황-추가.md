---
id: GF-106
title: 훅 생애주기 섹션에 git 공식 훅 전체 28개 표 + git-format 연결 현황 추가
status: In Progress
assignee: []
created_date: '2026-09-19 15:30'
updated_date: '2026-09-19 15:30'
labels: []
dependencies: []
type: docs
ordinal: 103000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
사용자가 git 공식 문서(githooks)에 정의된 모든 훅을 표로 정리하고, 그중 git-format이 실제로 구현해 연결한 훅이 어느 것인지 같은 표에서 보여달라고 요청했다. claude-rails README가 자신의 28개 Claude Code 훅을 이런 표로 정리한 것과 같은 패턴을, git-format은 git 자체의 공식 훅 목록(28개, https://git-scm.com/docs/githooks)에 대해 적용한다.

표에는 훅 이름, 실행 시점 요약, git-format 연결 여부(연결된 3개는 실제 소스 파일 링크, 나머지 25개는 미사용 표시)를 담는다. git-format은 pre-commit/commit-msg/post-commit 3개만 구현했고 pre-push는 decision-12로 제거됐으며 서버측 훅과 push 단계는 범위 밖(decision-11/12)이라는 점도 표 아래에 짧게 덧붙인다. 기존 3단계 상세 설명(AI귀속 표 포함)은 표 다음에 그대로 유지한다.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 README에 git 공식 문서 기준 28개 훅 전체를 나열한 표가 추가되고, 그중 pre-commit/commit-msg/post-commit 3개 행에만 실제 hooks/* 소스 파일 링크가 걸린다
- [ ] #2 나머지 25개 훅 행은 git-format 미연결임이 명시된다(예: —)
- [ ] #3 표 아래에 git-format이 push 단계/서버측 훅을 다루지 않는다는 점(decision-11/12)이 한 문장으로 언급된다
- [ ] #4 기존에 있던 3단계 상세 설명(pre-commit/commit-msg/post-commit 각 항목 설명, AI 귀속 트레일러 표, 사유 슬러그)은 내용 손실 없이 표 다음에 그대로 유지된다
- [ ] #5 shellcheck -s sh 전체와 bats tests/ 전체가 통과한다
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
훅 생애주기 섹션 상단에 공식 훅 28개 전체 표(git-format 연결 컬럼 포함) 추가, 표 아래 push/서버측 범위 밖 한 문장, 기존 3단계 상세 설명은 표 뒤에 유지.
<!-- SECTION:PLAN:END -->
