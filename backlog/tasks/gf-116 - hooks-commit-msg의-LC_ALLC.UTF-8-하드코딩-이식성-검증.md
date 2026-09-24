---
id: GF-116
title: hooks/commit-msg의 LC_ALL=C.UTF-8 하드코딩 이식성 검증
status: To Do
assignee: []
created_date: '2026-09-19 15:46'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
hooks/commit-msg:139에서 문자 수 계산에 LC_ALL=C.UTF-8을 사용한다. macOS/glibc 환경에서는 관대하게 동작함이 확인됐지만, musl/Alpine 같은 제한된 환경에는 이 로케일이 없을 수 있어 조용히 깨질 위험이 있다(미검증). 컨테이너/CI 환경 등에서 실측 검증하거나, 로케일 부재 시 안전한 폴백을 추가할지 검토 필요.

발견 경위: 2026-09-20 '이 프로젝트의 부족한점?' 조사(Explore agent, hooks/commit-msg:139)
<!-- SECTION:DESCRIPTION:END -->
