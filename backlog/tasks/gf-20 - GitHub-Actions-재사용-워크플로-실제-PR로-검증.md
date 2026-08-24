---
id: GF-20
title: GitHub Actions 재사용 워크플로 실제 PR로 검증
status: To Do
assignee: []
created_date: '2026-08-24 04:29'
labels: []
dependencies: []
type: task
ordinal: 20000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
GF-12에서 문법 검증만 했던 .github/workflows/verify.yml을 실제 amosQP/git-format 저장소에 진짜 PR을 열어 Actions 러너에서 실행되는지 검증한다.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 테스트용 브랜치+PR 생성 후 워크플로가 트리거되는지 확인
- [ ] #2 commit-msg 형식 검증 스텝이 PR 커밋에 대해 정상 동작하는지 확인
- [ ] #3 pre-commit/pre-push 스텝이 정상 실행되는지 확인(git-format 자체엔 lint 대상 언어 파일이 없어 스킵되는 게 정상인지 확인)
- [ ] #4 테스트 완료 후 브랜치/PR 정리(머지 또는 삭제)
<!-- AC:END -->
