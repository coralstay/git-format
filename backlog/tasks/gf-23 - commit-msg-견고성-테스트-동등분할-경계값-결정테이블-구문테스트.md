---
id: GF-23
title: commit-msg 견고성 테스트 (동등분할/경계값/결정테이블/구문테스트)
status: To Do
assignee: []
created_date: '2026-08-24 04:48'
labels: []
dependencies:
  - GF-21
type: task
ordinal: 23000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
type/scope 형식, Task-Id 브랜치 패턴, AI-Model 게이트를 ISO 29119-4 기법으로 커버
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 동등분할: 유효/무효 type, scope 유무, BREAKING CHANGE(!/footer) 각 클래스 대표값 테스트
- [ ] #2 경계값분석: 빈 description, 매우 긴 subject/branch명, task 번호 0/매우 큰 수
- [ ] #3 결정테이블: AI_AGENT유무 x tool=claude-code유무 x gitformat.aiModel설정유무 x 화이트리스트일치 조합 전부
- [ ] #4 구문테스트: 개행/셸 메타문자가 포함된 커밋 메시지가 정상적으로 거부/처리되는지
<!-- AC:END -->
