---
id: DRAFT-11
title: hooks/commit-msg → Python 포팅
status: Draft
assignee:
  - '@claude'
created_date: '2026-09-24 09:24'
updated_date: '2026-09-24 09:43'
labels:
  - python-migration
  - hooks
milestone: m-3
dependencies: []
documentation:
  - doc-9
modified_files:
  - hooks/commit-msg
  - .github/workflows/test.yml
type: enhancement
ordinal: 4
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
## 왜

commit-msg는 커밋 메시지 형식을 검증해 위반 시 커밋 자체를 거부하는 훅이다. pre-commit이나 checks 스크립트를 호출하지 않는 독립 로직이라 다른 포팅 작업과 코드 의존이 없고 병렬 진행이 가능하다.

## 무엇을

hooks/commit-msg를 #!/usr/bin/env python3 단일 파일로 포팅한다(305줄, 전환 대상 중 두 번째로 큼).

정당한 단순화: 커밋 메시지를 Path(msg_file).read_bytes().decode("utf-8", errors="replace")로 읽으면 sh 시절의 두 가지 로케일 우회가 모두 필요 없어진다 - (1) GNU grep이 리눅스에서 invalid UTF-8을 잘못 처리하는 문제를 피하려던 export LC_ALL=C(GF-80), (2) 한글이 바이트 단위로 과소 계산되지 않게 하려던 LC_ALL=C.UTF-8 + wc -m. Python의 str/len()은 코드포인트 단위라 기본적으로 유니코드를 올바르게 센다. errors="replace"는 invalid UTF-8 커밋 메시지에서 훅이 UnicodeDecodeError로 죽지 않게 하는 의도적 선택이다.

그대로 유지해야 하는 것:
- Task-Id 앵커링 정규식(GF-34) - (^|[^a-zA-Z0-9])PREFIX-[0-9]+ 형태를 유지해 부분 문자열 오매치를 막는다
- subject 50자 / body 72자 길이 검증, blank-line-after-subject 규칙
- [type][subsystem] 프리픽스 검증, 타입 목록은 gitformat.conf에서 읽음
- Fixes: 트레일러의 해시 존재 검증, AI-Model 화이트리스트 게이트
- TASK_PREFIX/BRANCH 계산 블록은 post-commit과 동일하게 유지(공유 모듈 없이 파일별 독립 중복 - 이번 전환의 확정 사항)
- 거부 시 마커 정리(sh의 trap EXIT)는 try/finally로 이식
- 모든 subprocess.run에 encoding="utf-8" 명시

CI: 같은 커밋에서 test.yml shellcheck 대상 목록에서 hooks/commit-msg를 제거한다(파일명 직접 지정이라 미루면 CI가 깨짐).

## 선행/병렬

선행 조건 없음. commit-msg는 pre-commit이나 checks 스크립트를 호출하지 않는 독립 로직이라 DRAFT-9, DRAFT-10과 병렬로 진행 가능하다.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 hooks/commit-msg가 #!/usr/bin/env python3 셔뱅의 단일 Python 파일로 포팅되고 os.path.realpath(__file__) 기반 위치 해석이 적용된다
- [ ] #2 커밋 메시지를 read_bytes().decode('utf-8', errors='replace')로 읽어 LC_ALL=C(GF-80)와 LC_ALL=C.UTF-8+wc -m 우회가 모두 제거되고, invalid UTF-8 메시지에서도 훅이 예외로 죽지 않는다
- [ ] #3 subject 50자/body 72자 길이 검증이 한글 등 멀티바이트 문자에서 코드포인트 단위로 sh 버전과 동일하게 동작한다
- [ ] #4 [type][subsystem] 프리픽스 검증, blank-line-after-subject 규칙, Fixes: 트레일러 해시 존재 검증, AI-Model 화이트리스트 게이트가 전부 동등하게 이식된다(타입 목록은 gitformat.conf에서 읽음)
- [ ] #5 Task-Id 앵커링 정규식이 (^|[^a-zA-Z0-9])PREFIX-[0-9]+ 형태로 이식돼 부분 문자열 오매치(GF-34)가 재발하지 않고, TASK_PREFIX/BRANCH 계산 블록이 post-commit과 동일하게 유지된다
- [ ] #6 거부 시 마커 정리(sh의 trap EXIT)가 try/finally로 이식되고, 모든 subprocess.run에 encoding=utf-8이 명시된다
- [ ] #7 같은 커밋에서 test.yml shellcheck 대상 목록에서 hooks/commit-msg가 제거된다
- [ ] #8 bats tests/robustness-commit-msg.bats tests/robustness-injection.bats가 전부 통과한다
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
1. hooks/commit-msg(sh, 305줄)를 읽고 검증 규칙을 목록화한다: [type][subsystem] 프리픽스, subject 50자, body 72자, blank-line-after-subject, Fixes: 해시 존재, Task-Id 브랜치 강제, AI-Model 화이트리스트
2. Python으로 재작성 - 메시지는 read_bytes().decode("utf-8", errors="replace"), 길이 검증은 len(str)로 코드포인트 단위
3. Task-Id 정규식은 re.escape(prefix)로 조립하고 (^|[^a-zA-Z0-9]) 앵커를 유지(GF-34 재발 방지)
4. TASK_PREFIX/BRANCH 계산 블록은 DRAFT-12에서 그대로 복제할 수 있는 형태로 작성한다(공유 모듈은 만들지 않기로 확정됨 - 파일별 독립 중복 유지)
5. 거부 시 마커 정리는 try/finally로 이식(sh의 trap EXIT 대체)
6. 같은 커밋에서 shellcheck 대상 목록에서 hooks/commit-msg 제거
7. bats tests/robustness-commit-msg.bats tests/robustness-injection.bats 실행 - 한글 메시지의 길이 경계값과 invalid UTF-8 입력을 특히 확인한다
<!-- SECTION:PLAN:END -->
