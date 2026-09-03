---
id: GF-83
title: commit-msg가 subject 길이 / 본문 줄바꿈 폭을 실제로 검증하도록 만들기
status: To Do
assignee: []
created_date: '2026-09-03 01:25'
labels: []
dependencies:
  - GF-82
documentation:
  - .gitmessage
  - hooks/commit-msg
ordinal: 81000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
README '한계 및 향후 검토 과제' 항목: .gitmessage는 subject 50자 이내 권장, 본문 72자 줄바꿈 권장이라고 안내하지만, commit-msg 훅은 실제로 길이를 재지 않아 안내가 강제력이 없다. GF-82(커밋 스타일을 [type][subsystem] 프리픽스 + 리누스 토발즈 방식으로 전환)가 서브젝트 형식 자체를 바꾸는 중이므로, 이 작업은 GF-82 완료 후 새 형식을 기준으로 진행한다.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 subject 길이 초과, 본문 줄 길이 초과 상황에 대한 commit-msg의 동작(거부/경고)이 명확히 정의되고 테스트로 커버된다
- [ ] #2 정의된 동작이 .gitmessage와 README 커밋 메시지 규칙 섹션에 정확히 반영된다
- [ ] #3 README '한계 및 향후 검토 과제'에서 '실제로 길이를 재지 않는다'는 문구가 제거되거나 실제 동작으로 갱신된다
<!-- AC:END -->
