---
id: GF-82
title: 'commit-msg 서브젝트를 [type][subsystem] 프리픽스로 전환 + 토발즈 스타일 트레일러/빈줄 규칙 도입'
status: In Progress
assignee: []
created_date: '2026-09-03 01:13'
updated_date: '2026-09-03 01:15'
labels: []
dependencies: []
references:
  - backlog/decisions/decision-1 - Conventional-Commits-채택.md
documentation:
  - .gitmessage
  - README.md
  - README.en.md
  - hooks/commit-msg
  - hooks/post-commit
ordinal: 80000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Conventional Commits의 `type(scope)!:` 서브젝트 형식을 `[type][subsystem]` 대괄호 프리픽스로 바꾸고, BREAKING CHANGE `!` 마커를 제거한다. 본문이 있으면 제목-본문 사이 빈 줄을 훅에서 강제한다. post-commit이 모든 커밋에 Signed-off-by 트레일러를 커미터 정보로 자동 삽입한다(git commit -s와 동일한 방식, DCO 스타일). Fixes: <hash> 트레일러는 강제하지 않되, 존재하면 참조 해시가 실제 커밋인지 검증한다. decision-1(Conventional Commits 채택)을 대체하는 새 decision을 기록한다.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 commit-msg가 [type][subsystem] description 형식(subsystem 대괄호는 선택)을 검증하고, 기존 type(scope): 콜론 형식과 ! breaking-change 마커는 더 이상 허용하지 않는다
- [ ] #2 본문(3번째 이후 내용)이 있는데 2번째 줄이 빈 줄이 아니면 commit-msg가 거부한다
- [ ] #3 Fixes: 트레일러가 있으면 참조 해시가 저장소에 실재하는 커밋인지 검증하고, 존재하지 않으면 거부한다 - 트레일러 자체는 강제하지 않는다
- [ ] #4 post-commit이 모든 커밋에 Signed-off-by 트레일러를 커미터 정보(git log -1 --format='%cn <%ce>')로 자동 삽입한다(이미 있으면 건너뜀)
- [ ] #5 .gitmessage, README.md, README.en.md가 새 서브젝트 형식/Fixes/Signed-off-by 규칙을 반영한다
- [ ] #6 decision-1을 대체하는 새 decision이 기록되고 decision-1 파일 자체는 직접 수정하지 않는다
- [ ] #7 tests/robustness-commit-msg.bats, tests/consistency.bats가 새 형식에 맞게 갱신되고 전체 bats 스위트와 shellcheck -s sh가 통과한다
<!-- AC:END -->
