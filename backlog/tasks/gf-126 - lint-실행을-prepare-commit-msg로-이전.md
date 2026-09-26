---
id: GF-126
title: lint 실행을 prepare-commit-msg로 이전
status: In Progress
assignee: []
created_date: '2026-09-25 19:33'
updated_date: '2026-09-26 02:57'
labels:
  - hooks
  - lint
dependencies:
  - GF-125
references:
  - decision-18
documentation:
  - backlog/docs/doc-13 - git-format-재설계-계획-—-커밋-규칙을-prepare-commit-msg로-통합.md
  - backlog/docs/doc-14 - 용어-정리-—-턴-트랜스크립트-귀속-마커-구분.md
  - backlog/docs/doc-18 - 재설계-작업-순서와-의존성.md
modified_files:
  - hooks/prepare-commit-msg
  - hooks/pre-commit
priority: high
type: feature
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
언어별 검사는 지금 pre-commit이 담당하는데, pre-commit은 --no-verify로 건너뛸 수 있다. prepare-commit-msg는 건너뛸 수 없으므로 검사를 그쪽으로 옮기면 우회가 불가능해진다.

판정 로직은 그대로 옮긴다 — 저장소 루트의 언어 감지 마커 파일로 언어를 고르고, 해당 검사 스크립트를 실행해 실패 시 종료 코드를 전파한다. 언어 마커가 없으면 무해하게 통과한다.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 저장소 루트의 언어 감지 마커 파일로 언어를 판정하고 해당 검사 스크립트를 실행한다
- [ ] #2 검사가 실패하면 그 종료 코드를 전파해 커밋을 막는다
- [ ] #3 언어 마커가 하나도 없으면 아무 검사도 하지 않고 통과한다
- [ ] #4 git commit --no-verify로도 검사가 실행되어 실패 시 커밋이 막힌다
- [ ] #5 검사 전에 저장소 루트로 작업 디렉터리를 옮긴다 (마커 파일을 루트에서 찾기 때문)
- [ ] #6 리터럴 경로 마커와 글롭 마커의 해석 차이가 기존과 동일하게 유지된다
- [ ] #7 같은 커밋에서 hooks/pre-commit을 삭제한다 — 기능을 옮기고 구 훅을 남기면 lint가 두 번 실행된다
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 python3 -m unittest 스위트 전체 통과 (이관 전이면 bats tests/ 통과)
- [ ] #2 ruff check 통과
- [ ] #3 이 저장소 자신의 커밋이 새 훅으로 정상 생성되는지 확인
<!-- DOD:END -->

## Comments

<!-- COMMENTS:BEGIN -->
author: claude
created: 2026-09-26 02:57
---
착수 전 확인한 연쇄 문제와 처리 방침 (2026-09-26).

## pre-commit 삭제가 Verify-Bypassed를 오작동시킨다

현재 사슬: pre-commit이 lint 통과 후 $GIT_DIR/.gitformat-verified를 쓰고,
post-commit이 그 **부재**를 --no-verify 우회로 판정해 Verify-Bypassed: true를 붙인다.
commit-msg는 거부 시 스테일 마커를 지운다(GF-31).

AC #7대로 pre-commit을 지우면 마커를 쓰는 곳이 없어져, 아직 살아 있는 post-commit이
**모든 커밋에 Verify-Bypassed: true를 붙인다.** 이 저장소는 자기 훅으로 커밋하므로
잘못된 footer가 실제 이력에 남는다 — doc-18이 경고한 바로 그 문제다.

**처리: prepare-commit-msg가 lint 통과 후 마커를 쓴다(임시 가교).** 형식은 기존 계약
그대로 "<epoch> <pid>" 한 줄이다. GF-128에서 post-commit과 함께 제거한다.
마커를 쓰는 시점은 pre-commit과 같다 — 모든 검사가 통과한 뒤. 실패하면 exit로
빠져나가므로 마커가 남지 않는다.

## 이 태스크가 만드는 1개 태스크짜리 과도기

lint가 prepare-commit-msg로 오면 --no-verify로 건너뛸 수 없으므로 마커가 항상 써지고,
따라서 **Verify-Bypassed가 도달 불가능해진다.** 그런데 이 시점에는 commit-msg가 아직
살아 있고 --no-verify가 여전히 그것을 건너뛴다 — 즉 '메시지 검증 우회'는 남아 있는데
그것을 기록할 신호가 없다.

GF-127이 검증을 옮기면 해소된다. 한 태스크짜리 과도기이므로 수용하되, 기존 테스트
tests/test_verify_bypass_detection.py가 '--no-verify면 Verify-Bypassed가 붙는다'를
단정하므로 이 태스크에서 새 동작으로 고쳐야 한다. 그게 AC #4(--no-verify로도 검사가
실행되어 실패 시 커밋이 막힌다)의 이면이다.
---
<!-- COMMENTS:END -->
