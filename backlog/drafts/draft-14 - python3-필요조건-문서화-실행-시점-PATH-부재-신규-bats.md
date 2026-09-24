---
id: DRAFT-14
title: python3 필요조건 문서화 + 실행 시점 PATH 부재 신규 bats
status: Draft
assignee:
  - '@claude'
created_date: '2026-09-24 09:25'
updated_date: '2026-09-24 09:43'
labels:
  - python-migration
  - docs
  - tests
milestone: m-4
dependencies:
  - DRAFT-8
  - DRAFT-10
  - DRAFT-11
  - DRAFT-12
documentation:
  - doc-9
  - doc-6
modified_files:
  - README.md
  - hooks/readme.md
  - tests/robustness-install.bats
type: enhancement
ordinal: 7
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
## 왜

이번 전환의 유일한 실질적 트레이드오프는 python3 의존성이다. 그런데 "설치돼 있음"만으로는 부족하고 훅이 실행되는 시점의 PATH에도 잡혀야 한다. GUI git 클라이언트(SourceTree, GitHub Desktop, IDE 내장 git 패널)는 셸 프로파일(.zshrc 등)을 거치지 않고 OS 최소 PATH(macOS는 launchd가 물려주는 /usr/bin:/bin:/usr/sbin:/sbin 수준)만 물려받는 경우가 흔해, Homebrew/pyenv로만 설치된 python3(/opt/homebrew/bin/python3 등)을 못 찾을 수 있다. 최신 macOS는 /usr/bin/python3를 기본 내장하지도 않는다.

이 문제를 코드로 우회하지 않고(sh 런처 + git config로 경로를 저장하는 방식을 검토했으나 채택하지 않음) 명시적 필요조건으로 고지하기로 했으므로, 고지 자체가 제품의 일부다. 그리고 sh에는 없던 이 새 실패 모드가 문서에 적은 대로 실제로 동작하는지 객관적으로 검증해야 한다 - 문서만 써두고 검증하지 않으면 안 된다.

## 무엇을

1. README.md: "Runtime deps: none" 문구를 명시적 필요조건 섹션으로 교체한다. "Requirements: git, python3 (PATH에서 실행 가능해야 함)"을 설치 안내보다 먼저 보이는 자리에 둔다. 그 아래에 GUI 클라이언트 PATH 한계를 세부 설명으로 붙이되, 훅별 영향이 비대칭이라는 점을 강조한다:
   - pre-commit/commit-msg: python3을 못 찾으면 훅이 실패하고 git이 커밋을 막는다(눈에 띄는 안전한 실패)
   - post-commit: 이미 커밋이 완료된 뒤라 git이 신경 쓰지 않는다 - Task-Id/AI-Model/Signed-off-by 트레일러가 조용히 누락된 채 커밋은 성공한 것처럼 보인다(가장 날카로운 지점)
   - install.sh의 확인은 설치 시점(터미널, 풍부한 PATH)만 검증하므로 실제 커밋 시점(GUI, 좁은 PATH) 동작을 보장하지 못한다

2. hooks/readme.md에도 이 python3 PATH 요구사항을 한 줄 반영한다.

3. tests/robustness-install.bats: python3이 없는 설치 환경 케이스를 추가한다(기존 path_without() 헬퍼 재사용). DRAFT-8에서 만든 install.sh 가드가 명확한 에러로 설치를 막는지 확인.

4. 신규 bats: 훅 실행 시점(설치 시점 아님) PATH에 python3이 없을 때의 동작을 검증한다. path_without()으로 python3을 숨긴 환경에서 (a) pre-commit/commit-msg가 nonzero로 실패해 커밋이 실제로 막히는지, (b) post-commit이 실패해도 커밋 자체는 유지되고 트레일러만 누락되는지 직접 확인한다. 이건 sh 버전에 없던 동작이라 "동일성 재검증"이 아니라 "신규 동작 검증"이다.

## 선행/병렬

항목마다 다르다. README 필요조건 문구는 코드 상태와 무관해 아무 때나(마일스톤 1을 기다리지 않고) 쓸 수 있다. install.sh 부재 케이스 bats는 DRAFT-8 완료 후면 언제든 가능하다. 실행 시점 PATH 부재 bats는 해당 훅이 실제로 Python으로 포팅된 뒤에만 의미가 있으므로, DRAFT-10/11/12가 하나씩 끝날 때마다 그 훅의 케이스부터 병렬로 추가하면 된다(전부 기다릴 필요 없음).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 README.md의 'Runtime deps: none' 문구가 설치 안내보다 먼저 보이는 명시적 필요조건 섹션(Requirements: git, python3 - PATH에서 실행 가능해야 함)으로 교체된다
- [ ] #2 README에 GUI git 클라이언트 최소 PATH 한계가 문서화되고, 훅별 영향 비대칭(pre-commit/commit-msg는 커밋 차단이라 눈에 띄는 실패 / post-commit은 트레일러가 조용히 누락된 채 커밋이 성공한 것처럼 보임)이 명시된다
- [ ] #3 README에 install.sh의 python3 확인이 설치 시점(터미널, 풍부한 PATH)만 검증하므로 실제 커밋 시점(GUI, 좁은 PATH) 동작을 보장하지 못한다는 점이 명시된다
- [ ] #4 hooks/readme.md에도 python3 PATH 요구사항이 반영된다
- [ ] #5 tests/robustness-install.bats에 python3 없는 설치 환경 케이스가 path_without() 헬퍼를 재사용해 추가되고, install.sh 가드가 명확한 에러로 설치를 막는 것이 확인된다
- [ ] #6 신규 bats로 훅 실행 시점 PATH에 python3이 없을 때 pre-commit/commit-msg가 nonzero로 실패해 커밋이 실제로 막히는 것이 확인된다
- [ ] #7 신규 bats로 같은 조건에서 post-commit이 실패해도 커밋 자체는 유지되고 트레일러만 누락되는 것이 확인된다(README에 문서화한 비대칭 동작의 객관적 증거)
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
1. README.md에서 "Runtime deps: none" 문구의 현재 위치를 확인하고, 설치 안내보다 앞서는 Requirements 섹션으로 교체한다
2. 그 아래에 GUI 클라이언트 PATH 한계, 훅별 비대칭 영향(pre-commit/commit-msg는 커밋 차단 / post-commit은 트레일러 조용한 누락), install.sh 검증의 시점 한계를 하위 항목으로 작성
3. hooks/readme.md에 python3 PATH 요구사항 한 줄 반영
4. tests/robustness-install.bats에 python3 부재 설치 케이스 추가 - 기존 path_without() 헬퍼 재사용
5. 신규 bats 파일 작성 - 실행 시점 PATH 부재 시나리오. pre-commit/commit-msg는 커밋이 실제로 막히는지, post-commit은 커밋이 유지되고 트레일러만 빠지는지를 각각 단언한다
6. 실측 동작이 README에 쓴 문구와 다르면 **README를 실측에 맞춰 고친다** - 문서가 아니라 실제 동작이 기준이다
<!-- SECTION:PLAN:END -->
