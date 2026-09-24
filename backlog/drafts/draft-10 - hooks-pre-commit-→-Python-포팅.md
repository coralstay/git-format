---
id: DRAFT-10
title: hooks/pre-commit → Python 포팅
status: Draft
assignee:
  - '@claude'
created_date: '2026-09-24 09:23'
updated_date: '2026-09-24 09:57'
labels:
  - python-migration
  - hooks
milestone: m-3
dependencies:
  - DRAFT-9
documentation:
  - doc-9
  - doc-10
modified_files:
  - hooks/pre-commit
  - .github/workflows/test.yml
type: enhancement
ordinal: 4
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
## 왜

pre-commit은 git이 직접 실행하는 3개 진입점 중 하나이자, 언어 감지 후 checks 스크립트를 호출하는 디스패처다. checks/*.py가 먼저 존재해야 디스패치 경로를 갱신할 수 있으므로 DRAFT-9 완료가 선행 조건이다.

## 무엇을

hooks/pre-commit을 #!/usr/bin/env python3 셔뱅을 가진 단일 Python 파일로 포팅한다(sh 런처 없음 - python3을 필요조건으로 받아들이는 결정에 따름).
- template/hooks/*가 심볼릭 링크라 자기 실제 위치를 알아야 하는데, sh의 수동 resolve_self() 루프 대신 os.path.realpath(__file__)로 대체(심볼릭 링크 체인을 기본으로 따라감 - 정당한 단순화)
- 마커 파일 기반 언어 감지 로직 이식(마커 목록은 기존대로 gitformat.conf에서 git config --file 셸아웃으로 읽음 - ini 파서 직접 구현하지 않음)
- 5개 체크 스크립트를 sys.executable로 호출(이미 확보된 인터프리터 경로 재사용)
- 성공 시 .gitformat-verified 마커 기록(post-commit이 --no-verify 우회 탐지에 쓰는 포맷 계약이므로 형식 불변)

중요: CI의 shellcheck 대상이 글롭이 아니라 파일명 직접 지정이라, 이 파일이 Python이 되는 커밋에서 .github/workflows/test.yml의 대상 목록에서 hooks/pre-commit을 같이 빼야 한다. 미루면 그 사이 커밋들에서 CI가 Python 파일을 sh로 린트하려다 깨진다.

## 선행/병렬

DRAFT-9(checks 5개) 완료가 선행 조건. DRAFT-11(commit-msg)과는 코드 의존이 없어 병렬 가능하다.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 hooks/pre-commit이 #!/usr/bin/env python3 셔뱅의 단일 Python 파일로 포팅되고 실행 권한이 유지된다
- [ ] #2 os.path.realpath(__file__)로 자기 실제 위치를 찾아 template/hooks/의 심볼릭 링크를 경유해 실행돼도 hooks/ 경로를 올바르게 해석한다(sh의 수동 resolve_self 루프 대체)
- [ ] #3 마커 파일 기반 언어 감지가 sh 버전과 동일하게 동작하고 마커 목록은 기존대로 git config --file로 gitformat.conf에서 읽는다(ini 파서 직접 구현 금지)
- [ ] #4 감지된 언어의 체크 스크립트를 sys.executable로 호출하고, 체크 실패 시 해당 종료 코드로 커밋을 막는다
- [ ] #5 성공 시 .gitformat-verified 마커를 post-commit이 읽는 기존 형식 그대로 기록한다
- [ ] #6 같은 커밋에서 .github/workflows/test.yml의 shellcheck 대상 목록에서 hooks/pre-commit이 제거된다(파일명 직접 지정이라 미루면 CI가 Python 파일을 sh로 린트하려다 깨짐)
- [ ] #7 bats tests/robustness-dispatch.bats tests/smoke.bats tests/conf-guard.bats가 전부 통과한다
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
1. 현재 hooks/pre-commit(sh, 100줄)을 읽고 로직 블록을 분해한다: resolve_self, gitformat.conf 읽기 가드, 마커 기반 언어 감지, 체크 스크립트 호출, 검증 마커 기록
2. Python으로 재작성 - HOOK_DIR은 os.path.realpath(__file__) 기반, conf는 git config --file 셸아웃, 체크 호출은 sys.executable 사용
3. 실행 권한 확인(chmod +x) - git은 실행 가능한 파일만 훅으로 실행한다
4. 같은 커밋에서 .github/workflows/test.yml의 shellcheck 대상 목록에서 hooks/pre-commit 제거
5. bats tests/robustness-dispatch.bats tests/smoke.bats tests/conf-guard.bats 실행
6. 스크래치 저장소에서 install.sh --global로 template/hooks/ 심볼릭 링크 경로를 만들고, 그 경로로 실행됐을 때도 realpath 해석이 올바른지 수동 확인(bats가 검증하지 못하는 경로)
<!-- SECTION:PLAN:END -->
