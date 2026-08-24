---
id: GF-25
title: post-commit 상태전이/동시성 견고성 테스트 (상태전이/결함주입)
status: To Do
assignee: []
created_date: '2026-08-24 04:48'
labels: []
dependencies:
  - GF-21
type: task
ordinal: 25000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
마커 파일 생명주기, --no-verify, 반복 amend, 트랜스크립트 손상·누락, 재귀가드를 커버
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 상태전이: 마커없음->pre-commit성공->마커있음->post-commit->마커삭제 전이 전부 테스트
- [ ] #2 결함주입: 트랜스크립트 JSON이 깨졌을 때 AI-Model만 조용히 생략되고 커밋은 막히지 않는지
- [ ] #3 결함주입: jq가 없을 때, HOME이 이상한 값일 때도 커밋이 막히지 않는지
- [ ] #4 재귀가드가 실제로 무한루프를 막는지 타임아웃 기반으로 확인
<!-- AC:END -->
