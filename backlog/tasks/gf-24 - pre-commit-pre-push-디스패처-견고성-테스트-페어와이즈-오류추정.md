---
id: GF-24
title: pre-commit/pre-push 디스패처 견고성 테스트 (페어와이즈/오류추정)
status: To Do
assignee: []
created_date: '2026-08-24 04:48'
labels: []
dependencies:
  - GF-21
type: task
ordinal: 24000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
다중 언어 동시 존재, 도구 부재, 손상된 매니페스트 파일, 심볼릭 링크 설치 경로(GF-16 재확인)를 커버
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 페어와이즈: ts+python+sql처럼 2개 이상 언어가 한 저장소에 동시에 있을 때 전부 개별 실행되는지
- [ ] #2 오류추정: package.json이 손상된 JSON일 때, CMakeLists.txt가 있지만 cmake 없을 때 등
- [ ] #3 template/(심볼릭 링크) 경로로 설치된 저장소에서 checks/가 정확히 resolve되는지 회귀 테스트로 고정
<!-- AC:END -->
