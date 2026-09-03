---
id: GF-87
title: 'POSIX sh 컨벤션 확립: Google Shell Style Guide 참조 + 함수 분해로 화면 크기 준수'
status: In Progress
assignee: []
created_date: '2026-09-03 11:25'
updated_date: '2026-09-03 12:11'
labels: []
milestone: m-0
dependencies: []
references:
  - decision-13
ordinal: 85000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
훅 파일은 유지하되(훅 1개 = 파일 1개, decision-9의 '훅 간 로직 비공유' 원칙 유지) 화면 크기를 넘는 commit-msg(211줄)/post-commit(224줄)을 함수 단위로 분해해 리뷰어가 한 화면 안에서 각 검증/트레일러 단위를 이해할 수 있게 한다. 컨벤션 판단 기준으로 Google Shell Style Guide(CC BY 3.0)를 오프라인 참조용으로 vendoring한다.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 docs/references/google-shellguide/에 Google Shell Style Guide가 vendoring되고 VENDORING.md로 출처/라이선스(CC BY 3.0)가 문서화된다
- [ ] #2 hooks/commit-msg가 validate_format/validate_fixes_trailer/enforce_task_id_branch/enforce_ai_model_gate 등 이름 있는 함수로 분해되고, 각 함수가 한 화면(약 50줄) 안에 들어온다
- [ ] #3 hooks/post-commit이 detect_verify_bypass/trailer_task_id/trailer_ai_attribution/trailer_signed_off_by 등 이름 있는 함수로 분해되고, 각 함수가 한 화면 안에 들어온다
- [ ] #4 리팩터 후에도 파일당 정확히 1개 훅이라는 배포 단위는 그대로 유지된다(멀티파일 분리 없음)
- [ ] #5 리팩터 후 tests/ 전체 bats 스위트와 shellcheck -s sh가 통과한다
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Google Shell Style Guide를 docs/references/google-shellguide/에 vendoring (완료)
   - decision-9의 "외부 자료 vendoring/출처 URL 금지" 조항과 충돌 발견 -> 사용자 확인 후
     decision-13으로 그 항목만 대체(POSIX 문법 제약은 그대로 유효)
2. hooks/commit-msg를 validate_format/validate_fixes_trailer/enforce_task_id_branch/
   enforce_ai_model_gate 함수로 분해. resolve_self/CONF 가드/TASK_PREFIX-BRANCH 블록은
   post-commit과 텍스트 동일성이 tests/consistency.bats로 보장되므로 함수로 감싸더라도
   들여쓰기까지 정확히 동일하게 유지.
3. hooks/post-commit을 detect_verify_bypass/trailer_task_id/trailer_ai_attribution/
   trailer_signed_off_by 함수로 분해. 같은 이유로 TASK_PREFIX-BRANCH 블록 들여쓰기를
   commit-msg와 동일하게.
4. tests/consistency.bats의 TASK_PREFIX/BRANCH 블록 추출 awk 패턴을 새 들여쓰기에 맞게 조정
   (텍스트 동일성이라는 불변조건 자체는 유지, 추출 방식만 갱신).
5. shellcheck -s sh + bats tests/ 전체 통과 확인.
6. AC별 커밋.
<!-- SECTION:PLAN:END -->
