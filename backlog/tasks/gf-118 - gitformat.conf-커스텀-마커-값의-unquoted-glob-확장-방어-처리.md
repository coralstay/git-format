---
id: GF-118
title: gitformat.conf 커스텀 마커 값의 unquoted glob 확장 방어 처리
status: To Do
assignee: []
created_date: '2026-09-19 15:46'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
hooks/pre-commit:86, hooks/checks/java.sh:49가 ls ${MARKER_JAVA_GRADLE}처럼 unquoted glob 확장을 의도적으로 사용한다(shellcheck disable=SC2086 명시). 현재는 gitformat.conf가 유일한 신뢰된 값 출처라 실질 위험은 낮지만, marker.javaGradle 등 커스텀 값에 공백/특수문자가 섞이면 예기치 않은 파일 매칭이 될 수 있다. 방어적으로 quoting하거나 값 검증을 추가할지 검토.

발견 경위: 2026-09-20 '이 프로젝트의 부족한점?' 조사(Explore agent, hooks/pre-commit:86, hooks/checks/java.sh:49)
<!-- SECTION:DESCRIPTION:END -->
