---
id: GF-112
title: 'Python 전환 마무리: hooks readme 2종 + 전체 검증'
status: In Progress
assignee:
  - '@claude'
created_date: '2026-09-24 09:24'
updated_date: '2026-09-24 18:20'
labels:
  - python-migration
  - ci
  - docs
milestone: m-3
dependencies:
  - GF-108
  - GF-109
  - GF-110
  - GF-111
references:
  - GF-122
documentation:
  - doc-9
  - doc-5
  - doc-10
  - doc-12
modified_files:
  - .github/workflows/test.yml
  - hooks/readme.md
  - hooks/checks/readme.md
  - tests/consistency.bats
type: chore
ordinal: 6
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
## 왜

8개 파일이 전부 포팅된 뒤에만 가능한 마무리 작업들이다. readme 2종은 최종 구조가 확정돼야 정확히 쓸 수 있고, 스모크 테스트도 훅 체인 전 구간이 Python이 된 뒤라야 의미가 있다.

## 무엇을

1. shellcheck 대상 최종 확인: 각 포팅 커밋에서 하나씩 빠지므로 여기서는 install.sh 하나만 남았는지 확인만 한다.

2. hooks/readme.md 신설: 훅 생애주기 흐름(pre-commit → commit-msg → 커밋 생성 → post-commit), 각 훅 파일의 역할, 이제 Python으로 실행된다는 점과 python3 PATH 요구사항, gitformat.conf가 무엇이고 어디서 읽히는지. backlog/ 하위 7개 폴더 readme.md(GF-103)와 같은 '무엇인가/언제 쓰나/관련 명령' 스타일, 소문자 파일명.

3. hooks/checks/readme.md 신설: pre-commit이 마커 파일로 언어를 감지해 이 디렉토리 스크립트를 sys.executable로 호출하는 디스패치 메커니즘(별도 런처가 필요 없는 이유 포함), 5개 언어별 스크립트의 역할과 외부 도구 의존성(npm/tsc, ruff/flake8, sqlfluff, mvn/gradlew, clang-format).

4. 전체 검증: bats tests/ 전체 재실행, 인터프리터 기동 지연시간 실측(sh 대비 체감 지연 - 필요할 때만 -S 플래그나 지연 import 적용, 미리 최적화하지 않음), 그리고 수동 스모크 테스트. 스모크 테스트가 필수인 이유는 bats의 make_isolated_repo()가 core.hooksPath를 직접 가리키는 방식만 쓰고 install.sh의 sync_template()이 만드는 template/hooks/* 심볼릭 링크 경로는 거치지 않기 때문 - os.path.realpath(__file__) 기반 심볼릭 링크 해석은 bats만으로는 검증되지 않는다.

## 이 태스크에서 빠진 것 (GF-122)

원래 여기 있던 두 항목이 GF-122로 옮겨졌거나 무효가 됐다.

- **ruff CI 스텝**: GF-122에서 선반영됐다. doc-10이 '첫 .py가 생긴 뒤 아무 때나 병렬로 넣어도 된다'고 적고 있었고, 미루면 GF-109~111에서 린트 없는 파일이 계속 늘어나는 문제가 있었다. 그 스텝은 대상을 파일 나열이 아니라 hooks/ 디렉터리 + 셔뱅 탐색으로 잡으므로, 이 태스크에서 추가로 손댈 필요가 없다.
- **tests/consistency.bats 경로 갱신**: 대상이던 바이트 동일성 검사 3건이 GF-108에서 통째로 삭제돼 갱신할 것이 없다. 경위와 대체 행위 검증의 위치는 doc-12에 있다.

## 선행/병렬

GF-109, GF-110, GF-111이 전부 완료된 뒤에만 가능하다(GF-108은 완료). readme 2종은 최종 구조가 확정돼야 정확히 쓸 수 있다.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 shellcheck 대상이 install.sh 하나만 남았는지 최종 확인된다(각 포팅 커밋에서 이미 제거됨)
- [ ] #2 hooks/readme.md가 신설되어 훅 생애주기(pre-commit → commit-msg → 커밋 생성 → post-commit), 각 훅 역할, Python 실행 및 python3 PATH 요구사항, gitformat.conf 역할을 설명한다(backlog/ readme.md와 같은 소문자 파일명·3단 구성)
- [ ] #3 hooks/checks/readme.md가 신설되어 pre-commit의 마커 기반 언어 감지·sys.executable 호출 디스패치 메커니즘과 5개 언어별 스크립트의 역할·외부 도구 의존성을 설명한다
- [ ] #4 bats tests/ 전체가 통과하고, 인터프리터 기동 지연시간을 sh 대비 실측한다(체감 문제가 확인될 때만 -S 플래그/지연 import 적용, 선제 최적화 금지)
- [ ] #5 수동 스모크 테스트로 install.sh 템플릿 경로(template/hooks/* 심볼릭 링크)를 실제로 태워 (a) 정상 커밋 성공 (b) 형식 위반 거부 (c) --no-verify 시 Verify-Bypassed 소급 삽입 (d) AI 귀속 트레일러 삽입을 확인한다 - bats의 make_isolated_repo()는 core.hooksPath 직접 지정만 써서 심볼릭 링크 해석 경로를 검증하지 못하므로 필수
- [ ] #6 GF-111에서 이월: transcript-parse-failed를 검증하는 bats 케이스를 추가한다. GF-111 AC #4가 고정한 '한 줄이라도 파싱 실패하면 배치 전체 실패, 커서 미갱신' 동작을 지금은 스위트가 보호하지 않는다(손으로만 확인됨)
- [ ] #7 GF-111에서 이월: jq 제거로 더 이상 발생하지 않는 unavailable (jq-not-installed) 슬러그가 README.md와 backlog/docs/doc-3의 사유 목록에 남아 있다. 두 곳을 실제 사유 목록과 맞춘다(decision-5/doc-9의 과거 기록은 이력이므로 건드리지 않는다)
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 해당 AC 범위의 bats 서브셋이 통과한다
- [ ] #2 CI(shellcheck + ruff)가 초록이다
- [ ] #3 변경 파일이 AC 범위를 벗어나지 않는다 - 범위 밖 작업 발견 시 유저에게 먼저 확인한다
- [ ] #4 커밋이 [type][subsystem] 규칙과 Task-Id 트레일러를 만족한다
- [ ] #5 Done 전환 전 final summary에 객관적 검증 증거(테스트 통과 로그 등)를 남긴다
- [ ] #6 새 코드에 불필요한 주석을 넣지 않는다 - WHY가 비자명한 경우(GF-33/34/35/76/80 회귀 방지 패턴, 의도적 fail-open, 의도적 중복 유지 등)에만 한 줄 주석을 남긴다
- [ ] #7 PR은 rebase-merge로만 머지하고(squash/merge-commit 금지), push·PR 생성·머지 각 단계 전에 git fetch로 원격 상태를 먼저 확인한다(트렁크 방식이 아니라 로컬/리모트가 어긋날 수 있음)
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. .github/workflows/test.yml의 static-analysis job에 ruff 스텝 추가 - bats job은 이미 pip install ruff를 하지만 static-analysis job은 별도이므로 설치 스텝이 필요한지 확인한다
2. shellcheck 대상이 install.sh 하나만 남았는지 확인(각 포팅 커밋에서 제거됐어야 함)
3. hooks/readme.md 작성 - backlog/ 계열 readme.md의 "무엇인가/언제 쓰나/관련 명령" 구성을 따른다
4. hooks/checks/readme.md 작성 - 디스패치 메커니즘과 5개 스크립트의 외부 도구 의존성
5. tests/consistency.bats의 검사 대상 경로를 새 Python 파일로 갱신 후 실행
6. bats tests/ 전체 실행
7. 지연시간 실측 - 같은 시나리오를 sh 버전(이전 커밋 체크아웃)과 Python 버전에서 반복 측정해 비교한다. 체감 문제가 확인될 때만 -S 플래그나 지연 import를 적용하고, 그렇지 않으면 적용하지 않는다
8. 스크래치 저장소에서 install.sh를 실제로 실행해 template 경로로 (a) 정상 커밋 (b) 형식 위반 거부 (c) --no-verify 후 Verify-Bypassed 삽입 (d) AI 귀속 트레일러 삽입 4종을 수동 확인
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
GF-108 진행 중 발견(2026-09-24): hooks/gitformat.conf 헤더 주석이 'checks/cpp.sh, checks/sql.sh'를 참조한다. GF-108에서 .py로 포팅되면 죽은 참조가 되지만 conf는 GF-108의 Modified files 밖이라 손대지 않았다. 이 태스크에서 .py로 갱신할 것.
<!-- SECTION:NOTES:END -->
