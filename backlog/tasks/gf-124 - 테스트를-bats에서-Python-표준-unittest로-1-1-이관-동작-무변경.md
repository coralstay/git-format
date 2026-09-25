---
id: GF-124
title: '테스트를 bats에서 Python 표준 unittest로 1:1 이관 (동작 무변경)'
status: In Progress
assignee: []
created_date: '2026-09-25 19:34'
updated_date: '2026-09-25 22:09'
labels:
  - tests
  - ci
dependencies: []
references:
  - decision-21
documentation:
  - backlog/docs/doc-13 - git-format-재설계-계획-—-커밋-규칙을-prepare-commit-msg로-통합.md
  - backlog/docs/doc-14 - 용어-정리-—-턴-트랜스크립트-귀속-마커-구분.md
  - backlog/docs/doc-16 - 토큰·툴콜-측정-방법과-한계.md
  - backlog/docs/doc-18 - 재설계-작업-순서와-의존성.md
modified_files:
  - tests/isolated_repo.py
  - .github/workflows/test.yml
priority: high
type: chore
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
훅은 이미 Python 표준 라이브러리만 쓰는데 테스트는 bats라서, CI가 bats-core를 GitHub에서 clone해 설치하는 스텝을 따로 둔다 — 훅은 '설치할 것 없음'인데 테스트만 외부 도구를 요구하는 비대칭이다. 현재 규모는 bats 1,880줄 / 17파일이다.

이 태스크를 재설계의 맨 앞에 둔다. 프레임워크 전환을 먼저 끝내면 이후 모든 훅 변경이 Python 테스트를 안전망으로 삼는다. 반대로 마지막에 두면 훅을 바꾸는 동안 bats를 계속 고쳐야 하고 마지막에 전부 다시 쓰게 되어 두 번 일하게 된다.

그래서 이 태스크는 동작을 바꾸지 않는 순수 1:1 이관이다. 구 훅 3개를 그대로 검증한다. 새 동작(에디터 거부, 귀속 측정 등)에 대한 테스트는 각 동작을 구현하는 태스크에서 함께 작성한다.

pytest가 아니라 unittest를 쓰는 이유는 설치가 필요 없어야 한다는 기존 원칙과 같다.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 기존 bats 17파일의 모든 케이스가 Python unittest로 이관되고 동일한 동작을 검증한다
- [ ] #2 bats 파일이 모두 삭제된다
- [ ] #3 tests/isolated_repo.py가 임시 저장소 생성과 환경변수 조작 헬퍼를 제공한다 (기존 tests/helpers/git-format.bash 대체)
- [ ] #4 테스트 파일명이 검증 내용을 드러낸다 (robustness 같은 성격 분류를 쓰지 않는다)
- [ ] #5 트레일러 검증이 문자열 부분 일치가 아니라 개수까지 확인한다
- [ ] #6 설정 키 일치 테스트가 설정 파일을 동적으로 읽어 대조한다 (손으로 나열한 목록을 없앤다)
- [ ] #7 python3 부재 테스트는 자식 프로세스의 환경변수만 조작하고 러너 자신은 계속 동작한다
- [ ] #8 CI에서 bats-core clone 설치 스텝이 제거되고 python3 -m unittest discover로 실행된다
- [ ] #9 CI의 shellcheck -s sh install.sh 게이트가 유지된다
- [ ] #10 CI의 언어별 실도구 설치(sqlfluff, ruff) 스텝이 유지된다
- [ ] #11 ruff 검사 대상에 tests 디렉터리가 포함된다
- [ ] #12 훅 코드는 이 태스크에서 한 줄도 바꾸지 않는다 (이관 전후로 검증하는 동작이 같다)
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 python3 -m unittest 스위트 전체 통과 (이관 전이면 bats tests/ 통과)
- [ ] #2 ruff check 통과
- [ ] #3 이 저장소 자신의 커밋이 새 훅으로 정상 생성되는지 확인
<!-- DOD:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## 이관 기준선 (2026-09-26 실측)

이관 전 `bats tests/` 결과를 기준선으로 고정한다. 1:1 이관이므로 이관 후
`python3 -m unittest`가 같은 동작을 같은 수의 케이스로 검증해야 한다.

```
1..124
ok 124개 / not ok 0개
```

파일별 줄 수(총 1,880줄): robustness-post-commit 312, robustness-commit-msg 236,
checks-ts 167, robustness-install 158, marker-semantics 112, robustness-injection 107,
robustness-python-path 104, robustness-locale 96, robustness-dispatch 86,
conf-guard 76, checks-python 74, consistency 64, checks-java 63, checks-cpp 63,
checks-sql 51, smoke 32, helpers/git-format.bash 79.

AC #12(훅 코드 무변경) 검증 방법: `git diff --stat hooks/`가 비어 있어야 한다.
<!-- SECTION:NOTES:END -->
