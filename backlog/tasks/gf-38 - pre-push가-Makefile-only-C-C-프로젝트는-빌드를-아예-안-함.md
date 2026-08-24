---
id: GF-38
title: pre-push가 Makefile-only C/C++ 프로젝트는 빌드를 아예 안 함
status: To Do
assignee: []
created_date: '2026-08-24 08:13'
labels: []
dependencies: []
type: bug
ordinal: 38000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
pre-commit의 cpp.sh는 CMakeLists.txt 또는 Makefile로 감지하지만 pre-push는 CMakeLists.txt만 확인한다. Makefile만 있는 프로젝트는 pre-push 단계에서 빌드 검증이 전혀 없다.
<!-- SECTION:DESCRIPTION:END -->
