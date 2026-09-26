---
id: GF-136
title: README를 최종 커밋 포맷 중심으로 재구성한다
status: To Do
assignee: []
created_date: '2026-09-26 07:55'
updated_date: '2026-09-26 07:57'
labels:
  - docs
dependencies: []
documentation:
  - backlog/docs/doc-13 - git-format-재설계-계획-—-커밋-규칙을-prepare-commit-msg로-통합.md
modified_files:
  - README.md
priority: medium
type: docs
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
README가 구현 서술 중심이다 — "왜 만들었는지 / 무엇을 만들었는지 / 훅을 생애주기별로" 순서라, 읽는 사람이 정작 알고 싶은 "그래서 커밋이 어떤 모양이 되는가"에 도달하기까지 훅 설명을 먼저 통과해야 한다.

유저 지시: 최종적으로 완성되는 포맷을 보여주고, 각 필드의 의미를 표로 정리하고, 언제 만들어지는지와 왜 만들어지는지를 함께 정리할 것.

또 GF-135에서 거짓 서술을 걷어내면서 오히려 분량을 늘렸다(언어 lint 범위 설명 두 문단, 컨슈머 한계 인용 블록, prepare-commit-msg 중첩 불릿, 재설계 진행 알림 블록). 재구성하면서 함께 압축한다 — 새 설명을 보태지 않고 기존 내용을 재배치한다.

주의: 현재 구조는 재설계 중이다. 트레일러 삽입은 아직 post-commit이 하고 메시지 검증은 아직 commit-msg가 한다. '언제 만들어지는지' 열은 지금 사실대로 쓰고, GF-127/GF-128이 그 시점을 옮기면 갱신해야 한다. hooks/README.md와 최종 아키텍처 반영은 GF-134가 계속 맡는다.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 최종적으로 완성되는 커밋 메시지 전문을 문서 앞부분에 제시한다 — 제목·본문·footer가 모두 채워진 실제 예시 하나
- [ ] #2 각 필드를 표로 정리한다: 제목 구성요소(type, subsystem, 설명)와 트레일러 전체
- [ ] #3 표에 각 필드의 의미, 언제(어느 훅의 어느 시점) 만들어지는지, 왜 필요한지를 함께 담는다
- [ ] #4 사람이 직접 쓰는 필드와 훅이 자동으로 붙이는 필드를 구분해 표시한다
- [ ] #5 값의 신뢰 수준(강제/서버 발급/자가신고/자동)을 표에 유지한다 — 기존 트레일러 표의 핵심 정보다
- [ ] #6 GF-135가 늘린 분량을 압축한다: 언어 lint 범위 설명, 컨슈머 한계 인용 블록, prepare-commit-msg 중첩 불릿, 재설계 진행 알림 블록
- [ ] #7 새 설명을 보태지 않는다 — 기존 내용의 재배치와 압축만 한다
- [ ] #8 '언제 만들어지는지'는 현재 사실대로 쓴다 (트레일러 삽입은 post-commit, 메시지 검증은 commit-msg). GF-127/128이 옮기면 갱신해야 한다는 점을 태스크 노트에 남긴다
- [ ] #9 README 순증 줄 수가 0 이하다 (GF-135 이전 대비)
- [ ] #10 필드 표에 그 필드를 만드는 git 훅 이름을 명시한다 (prepare-commit-msg / commit-msg / post-commit 중 어느 것인지)
- [ ] #11 git 커밋 훅 라이프사이클을 문서에 함께 정리한다 — 커밋 한 번에 훅이 도는 순서와 각 단계에서 커밋 객체가 존재하는지 여부
- [ ] #12 라이프사이클에서 --no-verify가 어느 훅을 건너뛰는지 표시한다 — 어떤 필드가 우회 가능하고 어떤 필드가 불가능한지가 여기서 갈린다
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 python3 -m unittest 스위트 전체 통과
- [ ] #2 문서에 적힌 커밋 예시가 실제로 생성되는 footer와 일치하는지 확인
<!-- DOD:END -->
