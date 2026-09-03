---
id: GF-89
title: '코드 품질 도구 리서치: SonarQube/CodeQL 등 정적 분석·보안 스캔 도구 적용 검토'
status: To Do
assignee: []
created_date: '2026-09-03 11:31'
labels: []
milestone: m-0
dependencies: []
ordinal: 87000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
지금은 shellcheck(-s sh)와 bats-core 테스트(decision-8)만으로 코드 품질을 관리하고 있다. SonarQube, CodeQL 같은 정적 분석/보안 스캔 도구를 추가로 도입할 가치가 있는지 조사한다. 참고: CodeQL은 공식적으로 Bash/POSIX sh를 지원하지 않는다(C/C++, C#, Go, Java/Kotlin, JS/TS, Python, Ruby, Swift만 지원) - 이 프로젝트가 셸을 유지하기로 한 결정(GF-88 종료 사유)과 맞물려 실제 적용 가능 여부부터 확인해야 한다. SonarQube는 커뮤니티 셸 분석 플러그인이 있는지, 있다면 shellcheck 대비 추가 가치가 있는지를 본다.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 SonarQube가 POSIX sh/bash를 실제로 분석할 수 있는지(공식 지원 여부, 플러그인 필요 여부) 확인된다
- [ ] #2 CodeQL의 언어 지원 범위와 이 프로젝트(POSIX sh 훅)에 적용 가능한지 여부가 확인된다
- [ ] #3 두 도구가 이미 쓰고 있는 shellcheck -s sh 대비 실제로 추가 가치(잡아내는 이슈 종류, 오탐률 등)가 있는지 비교된다
- [ ] #4 무료/오픈소스 사용 범위에서 이 공개 저장소에 CI로 통합 가능한지(비용, rate limit, 설정 난이도) 확인된다
- [ ] #5 도입 여부에 대한 권고가 정리되고, 도입한다면 어떤 도구를 어느 워크플로(.github/workflows/test.yml)에 추가할지 방안이 나온다
<!-- AC:END -->
