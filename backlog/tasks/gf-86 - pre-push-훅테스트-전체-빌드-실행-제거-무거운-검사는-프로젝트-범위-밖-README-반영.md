---
id: GF-86
title: 'pre-push 훅(테스트/전체 빌드 실행) 제거 - 무거운 검사는 프로젝트 범위 밖, README 반영'
status: To Do
assignee: []
created_date: '2026-09-03 11:10'
labels: []
dependencies: []
references:
  - decision-12
  - decision-11
documentation:
  - README.md
  - README.en.md
ordinal: 84000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
사용자 판단: pre-push가 하던 테스트/전체 빌드 실행(npm test/build, pytest, mvn verify, cmake+ctest, sqlfluff 전체 lint)은 git-format의 스코프에 맞지 않는다. decision-11은 서버사이드(GitHub Actions) 백스톱만 범위에서 뺐고 hooks/pre-push 자체는 '여전히 제공하는 것'이라 명시했었는데, 이번 결정은 그 판단을 대체해 pre-push 훅 자체를 완전히 제거한다. git-format은 이제 commit-msg/pre-commit/post-commit(커밋 단계)까지만 다루고 push 단계는 전혀 훅하지 않는다.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 hooks/pre-push 파일이 삭제된다
- [ ] #2 hooks/gitformat.conf의 buildDir 키(pre-push 전용)가 제거된다
- [ ] #3 install.sh의 .gitformat-build/ 자동 .gitignore 추가 로직(pre-push 산출물 보호용)이 제거된다
- [ ] #4 README.md/README.en.md가 pre-push 제거 상태와 일치하도록 갱신된다 (실제 사용법의 push 워크플로 섹션, 훅이 하는 일 표, SQL 섹션의 전체-lint 문구, 저장소 구조 트리, 한계 섹션의 --no-verify/push 서술, 왜 만들었나 섹션의 커밋/푸시 전 검사 문구)
- [ ] #5 decision-12(Context/Decision/Consequences)가 작성되어 decision-11의 'pre-push는 여전히 제공한다' 판단을 이 결정이 대체함을 명시한다
- [ ] #6 삭제/변경 후 tests/ 전체 bats 스위트와 shellcheck -s sh가 통과한다 (pre-push를 참조하는 conf-guard.bats/robustness-dispatch.bats/consistency.bats/robustness-install.bats의 관련 테스트 삭제·수정 포함)
<!-- AC:END -->
