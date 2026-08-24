---
id: GF-39
title: package.json 스크립트 존재 확인이 grep이라 scripts 밖의 동명 키와 혼동됨
status: To Do
assignee: []
created_date: '2026-08-24 08:13'
labels: []
dependencies: []
type: bug
ordinal: 39000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
grep -q 패턴은 scripts 객체 밖에 있는 동명의 키(예: devDependencies의 'test'라는 패키지명)도 매치해 npm run이 실제로 없는 스크립트를 실행하려다 실패한다. node -e로 실제 scripts 객체를 확인해야 함.
<!-- SECTION:DESCRIPTION:END -->
