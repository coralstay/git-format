---
id: GF-115
title: 언어별 pre-commit 검사 스코프 불일치 (저장소 전체 vs 스테이징) 해소 검토
status: To Do
assignee: []
created_date: '2026-09-19 15:46'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
checks/ts.sh, checks/python.sh, checks/java.sh는 저장소 전체를 검사하고, checks/cpp.sh, checks/sql.sh는 git diff --cached로 스테이징된 파일만 검사한다. TS/Python/Java 프로젝트는 이번 커밋과 무관한 기존 lint/컴파일 에러 때문에도 커밋이 막힐 수 있다(false blocking) — 언어 간 검사 스코프를 일관되게 맞출지, 아니면 스코프 차이를 의도된 것으로 문서화만 할지 검토 필요.

발견 경위: 2026-09-20 '이 프로젝트의 부족한점?' 조사(Explore agent, hooks/checks/ts.sh:25, python.sh:12, java.sh:48/51 vs cpp.sh:70, sql.sh:50)
<!-- SECTION:DESCRIPTION:END -->
