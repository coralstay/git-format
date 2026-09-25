---
id: GF-125
title: prepare-commit-msg 훅 신설 — 재생 커밋 면제와 -m 강제 게이트
status: To Do
assignee: []
created_date: '2026-09-25 19:33'
updated_date: '2026-09-25 21:43'
labels:
  - hooks
dependencies:
  - GF-124
references:
  - decision-18
  - decision-22
documentation:
  - backlog/docs/doc-13 - git-format-재설계-계획-—-커밋-규칙을-prepare-commit-msg로-통합.md
  - backlog/docs/doc-14 - 용어-정리-—-턴-트랜스크립트-귀속-마커-구분.md
  - backlog/docs/doc-15 - 훅-실행-경로-실측-git-2.54.0.md
  - backlog/docs/doc-18 - 재설계-작업-순서와-의존성.md
modified_files:
  - hooks/prepare-commit-msg
priority: high
type: feature
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
git-format은 지금 커밋이 만들어진 뒤 post-commit이 --amend로 트레일러를 붙인다. 이 구조는 rebase/cherry-pick 중 amend가 불가능해 훅이 트레이스백을 내고, 재귀 가드를 필요로 하며, --no-verify로 검사와 검증을 모두 건너뛸 수 있다.

실측(git 2.54.0)으로 prepare-commit-msg는 --no-verify로도 건너뛸 수 없고 커밋 객체가 만들어지기 전에 돈다는 것을 확인했다. 이 훅을 본체로 삼으면 위 문제가 원인 단계에서 사라진다. 이 태스크는 그 골격만 세운다 — lint/검증/트레일러는 후속 태스크에서 옮긴다.

에디터 경로(source=template)에서는 훅이 사람이 타이핑하기 전에 돌아 빈 메시지를 보므로 메시지 검증이 원리적으로 불가능하다. 그래서 그 경로를 거부해 통과한 모든 커밋이 검증을 거친 것이 되게 한다.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 재생·병합 커밋에서는 아무 것도 하지 않고 종료한다 (MERGE_HEAD/CHERRY_PICK_HEAD/REBASE_HEAD/REVERT_HEAD 중 하나가 있거나 source가 merge 또는 squash)
- [ ] #2 source가 template이면 커밋을 거부하고 git commit -m 사용을 안내한다
- [ ] #3 훅 파일 위치를 os.path.realpath(__file__)로 해석해 init.templateDir 심볼릭 링크 설치에서도 lint 디렉터리와 설정 파일을 찾는다
- [ ] #4 설정 파일을 읽을 수 없으면 원인을 밝히는 메시지와 함께 즉시 중단한다
- [ ] #5 stdout/stderr 인코딩을 UTF-8로 고정해 LC_ALL=C 환경에서도 트레이스백 없이 동작한다
- [ ] #6 표준 라이브러리만 사용한다
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 python3 -m unittest 스위트 전체 통과 (이관 전이면 bats tests/ 통과)
- [ ] #2 ruff check 통과
- [ ] #3 이 저장소 자신의 커밋이 새 훅으로 정상 생성되는지 확인
<!-- DOD:END -->
