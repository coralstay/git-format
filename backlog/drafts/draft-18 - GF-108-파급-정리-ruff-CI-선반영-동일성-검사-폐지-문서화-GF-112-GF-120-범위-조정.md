---
id: DRAFT-18
title: 'GF-108 파급 정리: ruff CI 선반영 + 동일성 검사 폐지 문서화 + GF-112/GF-120 범위 조정'
status: Draft
assignee: []
created_date: '2026-09-24 14:09'
updated_date: '2026-09-24 14:09'
labels:
  - python-migration
  - ci
  - docs
dependencies: []
references:
  - GF-108
  - decision-16
  - DRAFT-16
documentation:
  - doc-10
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
## 왜

GF-108(checks 5종 Python 포팅)이 끝나면서 세 가지 구멍이 동시에 생겼다.

1. **hooks/checks/*.py 5개가 CI에서 아무 린트도 받지 않는다.** shellcheck 대상에서는 빠졌는데 ruff 스텝은 아직 없다. ruff CI 추가는 GF-112의 AC #1이지만 GF-112는 GF-109/110/111에 막혀 있어 당장 착수할 수 없다. doc-10은 'ruff 스텝 추가만은 첫 .py가 생긴 뒤 아무 때나 병렬로 넣어도 된다'고 명시하고 있으므로 이 항목만 떼어내 먼저 반영한다. 미루면 GF-109~111에서 훅이 하나씩 Python이 될 때마다 린트 없는 파일이 늘어난다.

2. **consistency.bats의 바이트 동일성 검사 3건이 GF-108에서 삭제됐는데, 그 경위가 커밋 메시지와 태스크 노트에만 남아 있다.** 이 저장소는 '로직은 공유하지 않고 테스트로만 drift를 잡는다'를 설계 원칙으로 문서화해 왔다(decision-8/9). 그 원칙의 집행 장치였던 검사를 없앴으면서 근거를 문서로 남기지 않으면, 나중에 누군가 '동일성 검사가 왜 없지?'라며 되살리거나, 반대로 '중복을 유지할 이유가 없네'라며 공유 모듈로 합쳐버릴 수 있다. 둘 다 잘못된 복원이다.

3. **그 삭제로 기존 태스크 두 건이 무효가 됐다.** GF-112 AC #5는 '동일성 검사 대상 경로를 Python 파일로 갱신한다'인데 갱신할 검사가 없다. GF-120은 '동일성 검사 대상 목록에 python.sh/ts.sh가 빠진 게 의도인지 누락인지 확인'인데 그 목록 자체가 사라졌다. 방치하면 나중에 이미 사라진 것을 찾는 작업이 된다.

## 무엇을

세 가지를 한 PR로 처리한다. 셋 다 GF-108의 직접적인 파급이고 서로 참조하므로 나눌 실익이 없다.

ruff CI 스텝은 파일 나열이 아니라 hooks/ 디렉터리 단위로 건다 — shellcheck 쪽이 파일 나열이라 매 포팅 커밋마다 목록을 손봐야 했던 것과 반대 선택이다. ruff 설정 파일은 만들지 않는다(decision-16이 pyproject.toml 도입을 배제했고 기본 룰셋으로 이미 통과한다).

문서는 '무엇을 지웠나'가 아니라 **'대체된 행위 검증이 어디에 있는가'와 '중복 유지 원칙은 그대로라는 것'**을 남기는 게 핵심이다.

## 선행/병렬

GF-108 완료가 선행 조건이고 이미 끝났다. GF-109/110/111과 병렬로 진행해도 충돌하지 않는다 — 이 태스크가 건드리는 test.yml의 ruff 스텝은 디렉터리 단위라 훅이 추가로 Python이 돼도 수정이 필요 없다.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 .github/workflows/test.yml의 static-analysis job에 ruff 스텝이 추가되고, 이 job에는 Python/ruff 설치가 없으므로(bats job만 pip install ruff를 한다) 설치 스텝도 함께 들어간다
- [ ] #2 ruff 대상이 파일 나열이 아니라 hooks/ 디렉터리 단위로 지정되어, GF-109~111에서 훅이 하나씩 Python이 돼도 이 목록을 수정할 필요가 없다
- [ ] #3 ruff 설정 파일(pyproject.toml/ruff.toml)은 만들지 않는다 - decision-16이 패키징 도입을 배제했고 기본 룰셋으로 통과한다
- [ ] #4 PR CI에서 ruff 스텝이 실제로 hooks/checks/*.py 5개를 검사해 초록인 것이 확인된다(스텝이 조용히 0개 파일을 검사하고 통과하는 것이 아님을 출력으로 확인)
- [ ] #5 consistency.bats 바이트 동일성 검사 폐지 경위를 담은 backlog 문서가 신설된다. 삭제한 3건(resolve_self, TASK_PREFIX/BRANCH, conf 읽기 가드)과 각각을 대체하는 행위 검증 테스트의 위치, '행위 검증만 남긴다'는 유저 결정, 그리고 파일별 독립 중복 유지 원칙(decision-8/9)은 폐기된 것이 아니라 그대로라는 점을 명시한다
- [ ] #6 그 문서가 GF-112, GF-120, DRAFT-16, 그리고 이 태스크에서 --doc으로 연결된다
- [ ] #7 GF-112의 AC #1(ruff CI)과 AC #5(consistency.bats 경로 갱신)가 제거되고, 설명 본문 4번 항목과 제목에서 consistency.bats가 빠진다. AC #2(shellcheck 대상 최종 확인)는 마지막에 해야 하므로 유지한다
- [ ] #8 GF-120이 무효 사유(대상 검사 자체가 GF-108에서 삭제됨)를 final summary에 남긴 채 종료 상태로 이동한다
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 해당 AC 범위의 bats 서브셋이 통과한다
- [ ] #2 CI(shellcheck + ruff)가 초록이고, ruff 스텝이 검사한 파일이 0개가 아님을 로그로 확인한다
- [ ] #3 변경 파일이 AC 범위를 벗어나지 않는다 - 범위 밖 작업 발견 시 유저에게 먼저 확인한다
- [ ] #4 커밋이 [type][subsystem] 규칙과 Task-Id 트레일러를 만족한다
- [ ] #5 Done 전환 전 final summary에 객관적 검증 증거(CI 로그 등)를 남긴다
- [ ] #6 PR은 rebase-merge로만 머지하고(squash/merge-commit 금지), push·PR 생성·머지 각 단계 전에 git fetch로 원격 상태를 먼저 확인한다
<!-- DOD:END -->
