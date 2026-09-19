---
id: DRAFT-7
title: tests/consistency.bats 일관성 체크 대상에서 python.sh/ts.sh 누락 확인
status: Draft
assignee: []
created_date: '2026-09-19 15:46'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
tests/consistency.bats의 특정 일관성 체크(예: gitformat.conf 읽기 가드 동일성 체크, GF-76 관련)가 대상 파일 목록에 cpp.sh/sql.sh/java.sh만 나열하고 python.sh/ts.sh는 빠져 있다. 전체 커밋 플로우 테스트로 간접 커버는 되지만, 이 특정 체크 범위에서는 두 파일이 제외돼 있어 의도적인지 누락인지 확인 필요.

발견 경위: 2026-09-20 '이 프로젝트의 부족한점?' 조사(backlog/docs 조사 agent, tests/consistency.bats)
<!-- SECTION:DESCRIPTION:END -->
