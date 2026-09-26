<div align="center">

# 🧬 git-format

**git 자체 기능만으로 동작하는 커밋 메시지 규칙 · 검증 · 이력 정형화 도구**

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](./LICENSE)
[![Hooks: Python 3](https://img.shields.io/badge/hooks-Python%203-3776ab.svg)](./hooks/)
[![Installer: POSIX sh](https://img.shields.io/badge/installer-POSIX%20sh-89e051.svg)](./install.sh)
[![Requires: git + python3](https://img.shields.io/badge/requires-git%20%2B%20python3-brightgreen.svg)](#-필요조건을-말씀드립니다)

`core.hooksPath` · `commit.template` · `git interpret-trailers` 등 **git 자체 기능만으로**
여러 저장소가 하나의 커밋 규칙을 공유할 수 있게 만들어 사용하고 있는 도구입니다.
훅은 Python 3 표준 라이브러리만 쓰므로 설치할 패키지는 없지만, `python3` 자체는
필요합니다([필요조건](#-필요조건을-말씀드립니다)).

</div>

> ⚠️ **이 저장소의 코드는 AI(Claude Code)와 함께 작성했습니다.** 훅이 커밋을 거부하거나
> `--amend`로 내용을 바꾸는 등 실제 동작을 하므로, 적용 전에 `hooks/`의 코드를 직접 읽고
> 검토해 주시기 바랍니다.

---

## 🤔 왜 만들었는지 말씀드립니다

여러 저장소에서 커밋 규칙이 제각각이거나 아예 없었고, `git commit --no-verify`로
검사를 우회해도 아무 흔적이 남지 않는 문제가 있었습니다. 여기에 더해, 사람이 아니라 AI
코딩 에이전트(특히 Claude Code)가 커밋을 만드는 경우가 늘면서 이 문제가 결정적으로
중요해졌습니다.

**이 git 커밋 형식을 강제하는 궁극적인 이유는 다음 두 가지라고 말씀드릴 수 있습니다.**

1. AI 에이전트가 수많은 커밋을 남겼을 때, 나중에 그 작업 이력을 분석할 수 있게
   만드는 것입니다.
2. 그렇게 남은 기록을 여전히 사람이 이해할 수 있는지 검증하는 것입니다.

형식이 일관되면 사람도 LLM도 `git log` 한 번으로 "무엇을, 왜, 어떻게 검증하고
바꿨는지"를 바로 읽어낼 수 있습니다. 커밋별 토큰 소비량(`Tokens-Used`/`Tool-Calls`)을
남기는 것도 같은 목적의 연장선입니다 — 다만 이 측정 방법론은 아직 실험 단계라는 점을
말씀드립니다(자세한 내용은 아래 [훅 생애주기](#-훅을-생애주기별로-정리해-드립니다)를
참고해 주시기 바랍니다).

## 🛠️ 무엇을 만들었는지 말씀드립니다

Python 훅 + 설정 파일 하나(`hooks/gitformat.conf`) + POSIX sh 설치
스크립트(`install.sh`)로 구성된, **git 자체 기능만으로 동작하는** 도구를 만들었습니다.
`core.hooksPath` · `init.templateDir` · `git interpret-trailers` 같은 git 내장
메커니즘만 쓰고, 훅은 Python 3 표준 라이브러리만 씁니다(decision-16) — pip/npm으로
설치할 패키지는 없지만 `python3` 자체는 필요합니다([필요조건](#-필요조건을-말씀드립니다)).

**다루는 범위는 커밋 메시지 형식과 트레일러입니다.** 언어별 lint는 다루지 않습니다
(decision-23) — 커밋 형식을 맞추는 도구가 언어 도구를 돌릴 이유가 없고, 그 결합이
컨슈머에게 npm/ruff/clang-format/mvn/sqlfluff의 존재를 전제하게 만들었기 때문입니다.

> ⚠️ **알려진 한계**: git-format은 `core.hooksPath`를 점유하므로 그 저장소의
> `.git/hooks/*`는 무시됩니다. 언어 검사가 필요하면 CI에서 돌리시기 바랍니다 —
> git-format과 자기 훅을 함께 쓰는 지원 방법은 아직 정하지 않았습니다.

## 🪝 훅을 생애주기별로 정리해 드립니다

> 공식 문서: [githooks(5)](https://git-scm.com/docs/githooks)

git이 공식적으로 제공하는 훅은 총 28개입니다. 이 중 git-format이 실제로 구현해
연결한 것은 커밋 단계의 3개(`pre-commit`/`commit-msg`/`post-commit`)뿐이라는 점을
표로 정리해 드립니다. 훅 이름을 누르시면 실제 소스 파일로 이동합니다.

| 훅 | 실행 시점 | git-format 연결 |
| --- | --- | --- |
| `applypatch-msg` | `git am` 패치 적용 전 커밋 메시지 검증/수정 | — |
| `pre-applypatch` | `git am` 패치 적용 후 커밋 전 작업 트리 검사 | — |
| `post-applypatch` | `git am` 패치 적용·커밋 완료 후 알림 | — |
| **`pre-commit`** | `git commit` 커밋 전 코드 검사 | [`hooks/pre-commit`](hooks/pre-commit) |
| `pre-merge-commit` | `git merge` 완료 후 커밋 메시지 입력 전 | — |
| `prepare-commit-msg` | 기본 커밋 메시지 준비 후 에디터 시작 전 | — |
| **`commit-msg`** | 커밋 메시지 형식 검증/수정 | [`hooks/commit-msg`](hooks/commit-msg) |
| **`post-commit`** | 커밋 완료 후 알림(git이 항상 실행을 보장) | [`hooks/post-commit`](hooks/post-commit) |
| `pre-rebase` | `git rebase` 전, 특정 브랜치 리베이스 방지 | — |
| `post-checkout` | `git checkout`/`switch` 후 작업 트리 업데이트 후 | — |
| `post-merge` | `git merge`/`pull` 완료 후 | — |
| `pre-push` | `git push` 전, 푸시 거부 가능 | — |
| `pre-receive` | (서버측) 참조 업데이트 시작 전 | — |
| `update` | (서버측) 참조별 업데이트 전, 강제 푸시 방지 | — |
| `proc-receive` | (서버측) 특정 참조 업데이트 처리 | — |
| `post-receive` | (서버측) 모든 참조 업데이트 완료 후, 알림/배포 | — |
| `post-update` | (서버측) 모든 참조 업데이트 후, HTTP 정보 갱신 | — |
| `reference-transaction` | 참조 업데이트 트랜잭션 모니터링 | — |
| `push-to-checkout` | push가 현재 체크아웃 브랜치를 업데이트할 때 | — |
| `pre-auto-gc` | `git gc --auto` 전 | — |
| `post-rewrite` | `commit --amend`/`rebase` 등 커밋 재작성 후 | — |
| `sendemail-validate` | `git send-email` 발송 전 패치 검증 | — |
| `fsmonitor-watchman` | watchman 연동 파일 변경 모니터링 | — |
| `p4-pre-submit` | `git-p4 submit` 전 | — |
| `p4-prepare-changelist` | p4 기본 체인지리스트 준비 후 | — |
| `p4-changelist` | p4 체인지리스트 메시지 편집 후 | — |
| `p4-post-changelist` | p4 제출 완료 후 | — |
| `post-index-change` | 인덱스 write 시 | — |

git-format은 push 단계(`pre-push` 이후)와 서버측 훅은 다루지 않습니다 — 커밋
단계까지만 다룬다는 원칙(decision-11, decision-12) 때문입니다.

`git commit`을 실행하면 연결된 훅이 아래 순서로 개입한다는 점을 이어서
말씀드립니다.

1. **[`prepare-commit-msg`](hooks/prepare-commit-msg)** — 커밋 객체가 만들어지기
   **전에** 돌고, `--no-verify`로도 건너뛸 수 없습니다(실측 근거는 doc-15). 그래서
   커밋 규칙 강제가 이 훅으로 모입니다(decision-18). 지금 하는 일은 재생·병합 커밋
   면제, 에디터 경로 거부, 검증 마커 기록입니다.
   - **재생·병합 커밋 면제**: cherry-pick/rebase/revert/merge로 만들어지는 커밋은
     이미 검증된 커밋의 복제이므로 건드리지 않습니다.
   - **에디터 경로 거부**: 에디터는 이 훅보다 **뒤에** 열려서 사람이 타이핑한 최종
     메시지를 훅이 볼 수 없습니다. 그래서 `git commit -m`(또는 `-F`)만 허용합니다 —
     이렇게 하면 "통과한 커밋은 모두 검증을 거쳤다"가 성립합니다.
2. **[`commit-msg`](hooks/commit-msg)** — 커밋 메시지가 `[type][subsystem] <description>` 형식인지, 제목
   50자/본문 줄 72자 이내인지, 본문이 있으면 빈 줄이 있는지, 브랜치명에
   Task-Id(`GF-<번호>`, decision-4)가 있는지, (non-Claude-Code AI 도구라면) `AI-Model`이
   화이트리스트에 있는지 검증합니다. 여기서 거부되면 커밋 자체가 만들어지지 않습니다.
3. **(커밋 생성)** — 통과하면 git이 실제로 커밋을 만듭니다.
4. **[`post-commit`](hooks/post-commit)** — `--no-verify`로도 건너뛸 수 없고, exit code가
   커밋 결과에 영향을 주지도 못한다는 점을 [공식 문서](https://git-scm.com/docs/githooks)로도
   확인하실 수 있습니다. 검증 마커가 없으면(= 앞 훅이 돌지 않은 경우)
   `Verify-Bypassed: true`를 `git commit --amend`로 삽입하고(decision-3), `Task-Id`,
   `Signed-off-by`(decision-10), `Hooks-Commit`과, AI 에이전트가 커밋했다면 아래 AI
   귀속/토큰 트레일러를 함께 붙입니다(decision-5).

> 이 구조는 재설계 중입니다(decision-18). 검증과 트레일러 삽입을
> `prepare-commit-msg`로 옮기는 중이고, `pre-commit`은 이미 삭제됐습니다.

| 트레일러                     | 값                                                                                              | 신뢰 수준                                                    |
| ----------------------------- | -------------------------------------------------------------------------------------------------- | ----------------------------------------------------------- |
| `AI-Tool`, `AI-Tool-Version` | `AI_AGENT` 환경변수(Claude Code가 하위 프로세스에 주입)                                          | 강제 — LLM이 스스로 만든 값이 아님                           |
| `AI-Model`                   | Claude Code: 세션 트랜스크립트의 `message.model`(서버 발급) / 그 외 도구: `gitformat.aiModel` 설정값 | Claude Code는 서버 발급 사실 / 그 외는 자가신고              |
| `Tokens-Used`                | 이전 커밋 이후 세션에서 소비된 토큰 델타(누적 아님) — Claude Code 전용, 실패 시 `unavailable (사유)` | 서버 발급 사실(Claude Code 한정) / 그 외는 실측 채널 없음    |
| `Tool-Calls`                 | 같은 구간의 `tool_use` 콘텐츠 블록 개수                                                             | 위와 동일                                                    |
| `Co-Authored-By`             | `AI-Tool`이 `claude-code`일 때만 자동 삽입                                                          | 자동                                                         |
| `Hooks-Commit`               | 이 git-format 클론 자체의 `git rev-parse --short HEAD`                                             | 완전 자동, 모든 커밋에 적용                                  |
| `Signed-off-by`              | 커미터 정보(`git log -1 --format='%cn <%ce>'`)                                                     | 완전 자동, 모든 커밋에 적용                                  |

`Tokens-Used`/`Tool-Calls` 측정에 실패하면 사유 슬러그와 함께 `unavailable (사유)`로
기록된다는 점을 말씀드립니다 — 사유 슬러그: `no-session-id`, `transcript-not-found`,
`transcript-unreadable`, `transcript-parse-failed`, `no-usage-channel`입니다.

예시를 보여드리면 다음과 같습니다.

```
[fix][login] 빈 비밀번호 입력 시 크래시 수정

Task-Id: GF-42
Signed-off-by: Jane Dev <jane@example.com>
Hooks-Commit: b5bf03a
```

git-format은 커밋 단계까지만 다룬다는 점을 말씀드립니다 — `git push`는 아무 훅도
거치지 않는 평범한 push입니다(decision-12).

## ✅ 필요조건을 말씀드립니다

- **git**
- **python3** — 훅이 Python 3로 작성돼 있습니다(decision-16).
  표준 라이브러리만 쓰므로 설치할 패키지는 없지만, **훅이 실행되는 시점의 PATH에서
  `python3`가 잡혀야 합니다.**

`python3`를 못 찾을 때의 증상은 훅마다 다릅니다.

| 훅 | python3가 PATH에 없을 때 |
| --- | --- |
| `pre-commit`, `commit-msg` | 훅이 실패하고 git이 커밋을 막습니다 — 에러가 바로 보이는 안전한 실패입니다. |
| `post-commit` | 커밋이 이미 만들어진 뒤라 git이 훅의 실패를 반영하지 않습니다 — 커밋은 성공한 것처럼 보이지만 `Task-Id`/`AI-Model`/`Signed-off-by` 같은 트레일러가 조용히 누락됩니다. |

GUI git 클라이언트(SourceTree, GitHub Desktop, IDE 내장 git 패널)는 셸
프로파일(`.zshrc` 등)을 거치지 않고 OS 최소 PATH만 물려받는 경우가 흔합니다. 최신
macOS는 `/usr/bin/python3`를 기본 내장하지 않으므로, Homebrew나 pyenv로 설치한
python3는 이런 환경에서 보이지 않을 수 있습니다.

`install.sh`도 설치할 때 `python3` 존재를 확인하지만, 그건 보통 PATH가 풍부한
터미널에서 실행되는 시점만 보장합니다 — 실제 커밋이 일어나는 시점(GUI 클라이언트의
좁은 PATH)의 동작까지 보장하지는 못합니다. 이 한계는 코드로 우회하지 않고 알려진
제약으로 두기로 했습니다(decision-16).

## 🚀 설치 방법을 안내해 드립니다

### 기존 저장소에 적용하는 방법입니다

```sh
git clone https://github.com/amosQP/git-format.git ~/git-format   # 원하는 위치에 한 번만 클론
cd ~/my-project
~/git-format/install.sh
```

대상 디렉터리를 인자로 주셔도 됩니다: `~/git-format/install.sh ~/my-project`.

### 앞으로 만들 모든 새 저장소에 자동 적용하는 방법입니다

```sh
~/git-format/install.sh --global
```

`git init`/`git clone`을 실행할 때마다 훅과 커밋 템플릿이 자동으로 심어집니다
(`init.templateDir`). 대화형 터미널에서 인자 없이 실행하시면 이 적용 여부를 물어보고,
`--global`/`--no-global`로 비대화형 지정도 하실 수 있습니다.

## 📚 더 자세한 내용이 궁금하시다면

- **설치 상세, 커밋 메시지 규칙 전문, AI 귀속 트레일러 표, 커스터마이즈, 저장소 구조,
  주의점·한계**는 `backlog doc list`에서 확인하실 수 있습니다.
- **설계 배경과 각 결정 이유**(decision-1~16)는 `backlog decision list`에서
  확인하실 수 있습니다.
- **작업 단위와 진행 상황**은 `backlog board`에서 확인하실 수 있습니다.
- **라이선스**는 MIT입니다(전문: [`LICENSE`](./LICENSE)) — 외부 문서를 원문 그대로
  vendoring하지 않는다는 점도 함께 말씀드립니다(decision-14).
