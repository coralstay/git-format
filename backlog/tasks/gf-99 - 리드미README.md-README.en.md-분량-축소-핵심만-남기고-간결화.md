---
id: GF-99
title: 리드미(README.md/README.en.md) 분량 축소 - 핵심만 남기고 간결화
status: In Progress
assignee: []
created_date: '2026-09-19 04:46'
updated_date: '2026-09-19 04:48'
labels: []
dependencies: []
type: docs
ordinal: 96000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
README.md가 394줄/23개 섹션, README.en.md가 440줄로 늘어나 있다(GF-96/97/98 등 AI 귀속·토큰 측정 기능이 추가되면서 특히 "AI 귀속 footer"/"한계 및 향후 검토 과제" 섹션이 크게 불어났다). 사용자가 리드미를 짧게 만들어달라고 요청했다 - 정보를 빠뜨리는 게 아니라, 같은 내용을 더 간결하게 전달하는 게 목표다.

줄여야 할 부분 예시: "실제 사용법" 섹션의 단계별 예시 출력(git log -1 결과 등)이 여러 번 반복되는 것, "한계 및 향후 검토 과제"의 decision-15 조사 내용(8개 도구 나열)이 본문에 그대로 풀려있는 것(요약 한두 문장 + decision-15 링크로 대체 가능), 같은 설명이 여러 섹션에 걸쳐 살짝 다른 말로 반복되는 부분(예: Tokens-Used 델타/근사치 설명이 "왜 만들었나"와 "AI 귀속 footer" 양쪽에 비슷하게 나옴).

유지해야 할 것: 설치 방법, 커밋 메시지 형식 스펙, 훅 목록/역할, Task-Id 강제, AI 귀속 트레일러 표(사유 슬러그 포함), 커스터마이즈 방법, 주의점, 한계, 라이선스 - 즉 정보 자체를 삭제하지 말고 표현을 압축한다. 목차(#📖-목차) 앵커 링크가 깨지지 않게 섹션 제목을 유지하거나 목차도 함께 갱신한다. README.md/README.en.md 두 언어판의 섹션 구성이 계속 1:1로 대응해야 한다(기존 관례, GF-75).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 README.md 전체 분량이 현재(394줄) 대비 눈에 띄게(대략 40% 이상) 줄어들되, 기존에 있던 정보 항목(설치/커밋규칙/훅목록/Task-Id/AI귀속표/사유슬러그/커스터마이즈/저장소구조/주의점/한계/라이선스) 중 어느 것도 통째로 빠지지 않는다
- [ ] #2 README.en.md도 같은 방식으로 축소되고, README.md와 섹션 제목/순서가 1:1로 대응한다
- [ ] #3 목차(📖 목차)의 앵커 링크가 실제 섹션 제목과 어긋나지 않는다(깨진 링크 없음)
- [ ] #4 decision-N/GF-N 참조 링크와 문구가 축약 과정에서 잘못 바뀌지 않는다(예: decision-15 조사 내용은 요약 후 링크로 대체하되 링크 자체는 유지)
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. README.md/README.en.md 전체를 다시 읽고 23개 섹션 구조 파악
2. 사용법 섹션: 5단계 예시 출력 3회 반복을 압축된 하나의 흐름으로 병합
3. 한계 섹션: 8개 도구 나열을 decision-15 링크 참조 한두 문장으로 축약
4. Tokens-Used 근사치 캐비어트: AI귀속 섹션에만 상세 서술, Why 섹션은 짧게 참조
5. 목적 표: 7행 문구를 각 행 의미 유지하며 간결화
6. 저장소 변경사항 섹션: 표-프로즈 중복 제거
7. 두 파일 모두 목차-헤딩 1:1 대응 유지, decision-N/GF-N 링크 불변 확인
8. wc -l 전후 비교, shellcheck+bats 실행, AC 검증 후 Done 전환
<!-- SECTION:PLAN:END -->
