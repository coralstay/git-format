---
id: DRAFT-18
title: 언어별 lint 제거 — git-format은 커밋 형식만 다룬다
status: Draft
assignee: []
created_date: '2026-09-26 03:32'
updated_date: '2026-09-26 03:32'
labels:
  - hooks
  - scope
dependencies: []
references:
  - decision-23
documentation:
  - backlog/docs/doc-13 - git-format-재설계-계획-—-커밋-규칙을-prepare-commit-msg로-통합.md
  - backlog/docs/doc-18 - 재설계-작업-순서와-의존성.md
modified_files:
  - hooks/prepare-commit-msg
  - hooks/gitformat.conf
  - .github/workflows/test.yml
  - README.md
  - hooks/readme.md
priority: high
type: chore
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
git-format은 커밋 메시지 형식과 트레일러를 강제하는 도구인데, hooks/checks/에 TS·Python·Java·C/C++·SQL 5종의 언어별 lint 실행기(496줄)를 두고 커밋 전에 그 도구들을 돌려왔다. 커밋 형식을 맞추는 도구가 언어 lint를 돌릴 이유가 없다 — 결이 다른 기능이 한 도구에 섞여 있다(decision-23).

이 결합이 만든 비용: 컨슈머 저장소에 npm/ruff/clang-format/mvn/sqlfluff 존재를 전제하고, 그 '없으면 조용히 건너뜀'이 GF-22에서 실제 사고를 냈다. CI가 테스트를 위해 sqlfluff를 설치해야 하고, 언어 감지 마커의 리터럴/글롭 의미론(GF-118)과 C/C++ 확장자 목록, SQL dialect 기본값이 conf의 절반을 차지한다.

주의: 검증 마커(.gitformat-verified)는 gate할 대상이 없어지지만 post-commit이 살아 있는 동안은 조건 없이 계속 써야 한다. 안 쓰면 post-commit이 모든 커밋에 Verify-Bypassed를 붙인다(GF-126에서 실측). GF-128에서 post-commit과 함께 사라진다.

컨슈머가 언어 검사를 원하면 자기 pre-commit이나 CI에서 하면 된다 — 단 git-format이 core.hooksPath를 점유하므로 자기 훅을 함께 쓰는 방법을 문서에 안내해야 한다(GF-134).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 hooks/checks/ 디렉터리 전체를 삭제한다 (검사기 5개 + readme)
- [ ] #2 prepare-commit-msg에서 언어 감지와 검사 호출을 전부 제거한다 (CHECKS_DIR, 언어 MARKER_* 변수, run_check, has_tracked, run_language_checks, REPO_ROOT와 chdir)
- [ ] #3 gitformat.conf에서 marker 섹션, cpp 섹션, sqlDialectDefault를 제거한다
- [ ] #4 검증 마커 기록은 조건 없이 유지한다 — post-commit이 살아 있는 동안 Verify-Bypassed 오작동을 막는 임시 가교이고 GF-128에서 사라진다
- [ ] #5 언어별 lint 테스트를 삭제한다 (test_lint_typescript/python/java/c_cpp/sql, test_lint_dispatch, test_language_detection)
- [ ] #6 CI에서 sqlfluff 설치를 제거한다. ruff와 shellcheck는 유지한다 — 이 저장소 자신의 코드를 검사하는 개발 도구다
- [ ] #7 README와 hooks/readme.md에서 언어 지원 서술과 lint 생애주기 설명을 제거한다
- [ ] #8 제거 후에도 커밋 형식 강제와 트레일러 삽입이 그대로 동작한다 (남은 테스트 전부 통과)
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 python3 -m unittest 스위트 전체 통과
- [ ] #2 ruff check 통과
- [ ] #3 이 저장소 자신의 커밋이 정상 생성되는지 확인
<!-- DOD:END -->
