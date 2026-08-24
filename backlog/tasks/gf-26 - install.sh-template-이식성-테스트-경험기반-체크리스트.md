---
id: GF-26
title: install.sh/template 이식성 테스트 (경험기반 체크리스트)
status: To Do
assignee: []
created_date: '2026-08-24 04:48'
labels: []
dependencies:
  - GF-21
type: task
ordinal: 26000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
비대화형/대화형 환경, --global 반복 실행 멱등성, GNU/BSD 도구 차이를 커버
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 비대화형(파이프)에서 프롬프트 없이 안전하게 기본 동작하는지
- [ ] #2 --global을 여러 번 실행해도 template/hooks 심볼릭 링크가 깨지지 않는지(멱등성)
- [ ] #3 존재하지 않는 대상 디렉터리, git 저장소가 아닌 디렉터리 등 잘못된 인자에 대한 에러 메시지가 명확한지
<!-- AC:END -->
