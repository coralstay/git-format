# hooks

**무엇인가**: git이 커밋마다 직접 실행하는 훅 코드와 그 설정 파일을 담는다.
`install.sh`가 대상 저장소의 `core.hooksPath`를 이 디렉터리로 맞추거나(로컬 설치),
`init.templateDir` 경유로 새 저장소의 `.git/hooks/`에 이 디렉터리를 가리키는
심볼릭 링크를 심는다(전역 설치, decision-2). 어느 쪽이든 실행되는 파일은 여기 있는
바로 이 파일들이다.

**훅 생애주기**: 커밋 한 번에 세 훅이 이 순서로 돈다.

```
pre-commit → commit-msg → (커밋 객체 생성) → post-commit
```

- `pre-commit` — 저장소 루트의 마커 파일로 언어를 감지해 `checks/`의 해당 스크립트를
  실행한다. 하나라도 실패하면 그 종료 코드를 그대로 전파해 커밋을 막는다. 전부
  통과하면 마지막에 `$GIT_DIR/.gitformat-verified`에 `<epoch> <pid>` 한 줄을
  기록한다(decision-3). 언어 마커가 하나도 없으면 아무 것도 하지 않고 통과한다.
- `commit-msg` — 커밋 메시지를 검증한다. `[type][subsystem] <설명>` 형식, 제목
  50자·본문 줄 72자 제한, `Fixes:` 해시의 실재 여부, 브랜치명의 `<prefix>-<번호>`
  패턴(decision-4), Claude Code 외 AI 도구의 `gitformat.aiModel` 게이트(decision-5).
  병합 중(`MERGE_HEAD` 존재)에는 전부 면제한다. 거부할 때는 `pre-commit`이 남긴
  검증 마커를 반드시 지운다 — 안 지우면 뒤따르는 무관한 `--no-verify` 커밋이 그
  스테일 마커를 "검증됨"으로 잘못 소비한다(GF-31).
- `post-commit` — 검증 마커의 유무로 `--no-verify` 우회를 판정해 `Verify-Bypassed`를
  소급 삽입하고(decision-3), `Task-Id`/`AI-Tool`/`AI-Tool-Version`/`AI-Model`/
  `Tokens-Used`/`Tool-Calls`/`Co-Authored-By`/`Hooks-Commit`/`Signed-off-by`를
  `git commit --amend`로 붙인다. amend가 `post-commit`을 다시 발동시키므로 파일
  맨 앞의 `_GITFORMAT_AMEND_GUARD` 확인이 재귀를 끊는다.

**Python 실행 요구사항**: 이 디렉터리의 8개 파일(훅 3개 + `checks/*.py`)은 전부
Python 3이고 표준 라이브러리만 쓴다(decision-16). 셔뱅은
`#!/usr/bin/env python3`이므로 **설치 시점이 아니라 훅이 실행되는 시점의 PATH에서**
`python3`가 잡혀야 한다. `install.sh`의 확인은 설치 시점만 보장한다 — GUI git
클라이언트는 셸 프로파일을 거치지 않고 OS 최소 PATH만 물려받는 경우가 흔해
Homebrew/pyenv로 깐 python3를 못 찾을 수 있다. 코드로 우회하지 않고 알려진 한계로
둔다. 실패 양상도 훅마다 다르다 — `pre-commit`/`commit-msg`는 커밋이 막혀 바로
드러나지만, `post-commit`은 커밋이 이미 만들어진 뒤라 트레일러만 조용히 빠진다.

훅끼리 겹치는 블록(자기 위치 해석, conf 읽기 가드, `TASK_PREFIX`/`BRANCH` 계산)은
공유 모듈로 빼지 않고 파일마다 중복을 유지한다 — 파일 하나만 읽으면 그 훅의 동작을
전부 알 수 있어야 한다는 감사 가능성 요구사항이다(decision-16).

**gitformat.conf**: git config 포맷으로 쓴 내부 기본값 상수 파일이다. 마커 파일명,
커밋 type 목록, 트레일러 키 이름, 길이 제한, 알려진 모델 ID가 들어 있고 훅 3개와
`checks/cpp.py`, `checks/sql.py`가 `git config --file`로 읽는다. 공유하는 건 값뿐이고
그 값을 쓰는 로직은 파일마다 독립이다. ini를 직접 파싱하지 않고 `git config`에
맡기는 이유는 다중값(`--get-all`)과 따옴표 처리 같은 git 자신의 파싱 의미론과
조용히 갈라지는 걸 막기 위해서다. 읽기가 실패하면 각 파일 앞부분의 동일한 가드가
즉시 멈춘다 — 빈 값으로 진행하면 원인을 알 수 없는 거부가 된다(GF-76).

컨슈머 저장소가 자기 git config에 두는 `gitformat.taskPrefix`/`gitformat.branchExempt`/
`gitformat.aiModel` 오버라이드가 있으면 그쪽이 이긴다.

**언제 쓰나**: 커밋 검증 규칙이나 트레일러 동작을 바꿀 때. 값만 바뀌면
`gitformat.conf`에서 끝내고, 판단 로직이 바뀌면 해당 훅 파일을 고친다. 언어별 검사는
`checks/readme.md`를 참고한다. 고친 뒤에는 `bats tests/`를 돌린다 — 이 저장소 자신도
같은 훅으로 커밋하므로 깨진 훅은 곧바로 자기 커밋을 막는다.

**관련 명령**:

- `./install.sh <대상 저장소>` — 대상 저장소의 `core.hooksPath`/`commit.template` 설정
- `./install.sh --global <대상 저장소>` — 위에 더해 `template/hooks/` 심볼릭 링크 생성과 전역 `init.templateDir` 설정
- `git config --get core.hooksPath` — 어떤 훅이 실제로 연결돼 있는지 확인
- `git config --file hooks/gitformat.conf --list` — 내부 기본값 전체 조회
- `git commit --no-verify` — `pre-commit`/`commit-msg`를 건너뛴다(그 사실이 `Verify-Bypassed`로 커밋에 남는다)
- `bats tests/` — 훅 전체 동작 검증
