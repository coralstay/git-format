---
id: DRAFT-16
title: '[보류] bats 테스트 스위트 재설계'
status: Draft
assignee: []
created_date: '2026-09-24 09:28'
updated_date: '2026-09-24 09:43'
labels:
  - parked
  - post-migration
  - tests
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
## 배경

현재 테스트는 bats-core 기반 13개 파일 103개 케이스다. 이 테스트들은 훅을 블랙박스(서브프로세스)로 호출해 종료 코드/출력/결과 트레일러만 확인하므로 훅이 sh든 Python이든 언어에 무관하게 동작한다 - 그래서 Python 전환의 안전망으로 그대로 재사용할 수 있다.

유저가 "추후에 bats 테스트도 다시 짤 생각이 있다"고 밝혔으나, 전환 작업 중에 테스트까지 바꾸면 안전망 자체가 흔들려 동작 동일성을 보장할 수 없다.

## 보류 사유

이번 전환에서는 기존 103개를 그대로 쓰고, 언어 변경에 따라 꼭 필요한 경로 수정(hooks/checks/*.sh → *.py 하드코딩 등)만 반영한다. 스위트 자체의 재설계는 범위 밖.

## 재개 조건

Python 전환 완료 후. 검토할 선택지: bats 유지 vs pytest 전환(훅이 Python이 되므로 내부 함수 단위 테스트가 가능해짐), 블랙박스/화이트박스 비중 재조정, consistency.bats의 바이트 동일성 검사를 계속 유지할지 여부(파일별 독립 중복 원칙과 연동).
<!-- SECTION:DESCRIPTION:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
보류 상태이므로 구현 계획이 아니라 재개 시 착수 순서를 기록한다.

1. Python 전환(DRAFT-8~14) 완료를 확인한다
2. 현재 103개 케이스를 성격별로 분류한다 - 블랙박스 커밋 플로우 / 단위 검증 / 파일 간 일관성 검사
3. pytest 전환 시 이득이 큰 것만 선별한다. 훅이 Python이 되면 내부 함수 단위 테스트가 가능해지므로 단위 검증 성격의 케이스가 후보
4. bats를 남길 범위를 결정한다 - 실제 git commit을 태우는 end-to-end 검증은 bats가 여전히 적합하다
5. consistency.bats의 바이트 동일성 검사를 유지할지 결정한다(파일별 독립 중복 원칙을 계속 지킬지와 연동된 결정)
<!-- SECTION:PLAN:END -->
