<div align="center">

# 🧬 git-format

**여러 언어 프로젝트를 위한, git 자체 기능만으로 동작하는 커밋 규칙 · 검증 · 이력 정형화 도구**

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](./LICENSE)
[![Shell: POSIX sh](https://img.shields.io/badge/shell-POSIX%20sh-89e051.svg)](./install.sh)
[![Runtime deps: none](https://img.shields.io/badge/runtime%20deps-none-brightgreen.svg)](#--설치)
[![Conventional Commits](https://img.shields.io/badge/commits-Conventional%20Commits-fe5196.svg)](https://www.conventionalcommits.org/ko/v1.0.0/)

npm/pip 같은 별도 런타임 없이, `core.hooksPath` · `commit.template` · `git interpret-trailers` 등
**git 자체 기능만으로** 여러 저장소가 하나의 커밋 규칙을 공유하게 합니다.

</div>

---

## 📖 목차

- [🤔 왜 만들었나](#-왜-만들었나)
- [🎯 목적](#-목적)
- [🚀 설치](#-설치)
- [🗂️ 이 저장소가 만들거나 바꾸는 것](#️-이-저장소가-만들거나-바꾸는-것)
- [📝 커밋 메시지 규칙](#-커밋-메시지-규칙)
- [🪝 훅이 하는 일](#-훅이-하는-일)
- [🏷️ Task-Id 브랜치 강제](#️-task-id-브랜치-강제)
- [🕵️ `--no-verify` 우회 탐지](#️---no-verify-우회-탐지)
- [🤖 AI 귀속 footer](#-ai-귀속-footer)
- [🔧 커스터마이즈](#-커스터마이즈)
- [📁 저장소 구조](#-저장소-구조)
- [⚠️ 주의점](#️-주의점)
- [📄 라이선스](#-라이선스)

---

## 🤔 왜 만들었나

여러 언어(TS, C/C++, Java, Python, SQL 등)로 나뉜 프로젝트들에서 커밋 규칙과
커밋/푸시 전 검사가 저장소마다 제각각이거나 아예 없는 문제, 그리고 `git commit --no-verify`로
검사를 우회해도 아무 흔적이 안 남는 문제를 해결하려고 만들었습니다. 언어별로 다른 린터를
설치하게 하거나 팀마다 커밋 컨벤션 문서를 따로 유지하는 대신, **git 자체 기능**만으로
하나의 저장소를 여러 프로젝트가 공유해서 쓸 수 있게 하는 것이 의도입니다.

## 🎯 목적

| | 이점 |
|---|---|
| ✅ | [Conventional Commits](https://www.conventionalcommits.org/ko/v1.0.0/)를 언어와 무관하게 동일하게 강제합니다. |
| 🧩 | 별도 런타임(Node/Python 등) 의존성 없이 `core.hooksPath`, `init.templateDir`, `commit.template`, git hooks, `git interpret-trailers` 같은 **git 자체 기능**만으로 동작합니다 — 언어별 lint 도구(npm/ruff/clang-format/mvn/sqlfluff 등)는 있으면 쓰고 없으면 조용히 건너뜁니다. |
| 🕵️ | `git commit --no-verify`로 검사를 우회해도 커밋 이력 자체에 프로그래밍적으로 흔적(`Verify-Bypassed: true`)이 남게 합니다. |
| 🤖 | AI 코딩 에이전트가 만든 커밋에 어떤 도구/모델이 관여했는지, 신뢰 수준을 구분해서 footer에 남깁니다. |
| 🧠 | **커밋/git 이력을 반정형(semi-structured) 데이터로 구조화**해, 이 데이터를 LLM 학습이나 그 밖의 학습 용도로 재사용할 수 있게 합니다. Claude 같은 도구가 `git status`·`git log`만 보고도 변경 의도·검증 여부·작업 단위(Task-Id)까지 정확히 문맥을 파악할 수 있도록 돕습니다. |
| 👀 | 위와 같은 이유로, **사람이 읽을 때의 가독성**도 함께 좋아집니다. 형식이 일관되면 사람도 LLM도 `git log` 한 번으로 "무엇을, 왜, 어떻게 검증하고 바꿨는지"를 바로 읽어낼 수 있습니다. |

> 설계 배경과 각 결정의 이유는 [`backlog/decisions/`](./backlog/decisions)에, 작업 단위는
> [`backlog/tasks/`](./backlog/tasks)에 기록돼 있습니다. `backlog board`로 진행 상황을 볼 수 있습니다.

## 🚀 설치

### 기존 저장소에 적용

```sh
git clone https://github.com/amosQP/git-format.git ~/git-format   # 원하는 위치에 한 번만 클론
cd ~/my-project
~/git-format/install.sh
```

대상 디렉터리를 인자로 줘도 됩니다: `~/git-format/install.sh ~/my-project`.

### 앞으로 만들 모든 새 저장소에 자동 적용

```sh
~/git-format/install.sh --global
```

`git init`/`git clone`을 실행할 때마다 훅과 커밋 템플릿이 자동으로 심어집니다
(`init.templateDir`). 대화형 터미널에서 인자 없이 실행하면 이 적용 여부를 물어보고,
`--global`/`--no-global`로 비대화형 지정도 가능합니다.

## 🗂️ 이 저장소가 만들거나 바꾸는 것

**설치 시 컨슈머 저장소에서 바뀌는 것** — 파일이 아니라 git 설정뿐입니다. 어떤 소스
파일도 건드리지 않습니다.

| 대상 | 명령 | 효과 |
|---|---|---|
| 로컬(대상 저장소) | `git config core.hooksPath <git-format>/hooks` | `.git/hooks/`의 기존 로컬 훅을 완전히 대체 |
| 로컬(대상 저장소) | `git config commit.template <git-format>/.gitmessage` | 커밋 에디터에 스켈레톤 표시 |
| 전역(`--global`) | `git config --global init.templateDir <git-format>/template` | 이후 모든 신규 저장소에 자동 적용 |
| 전역(`--global`) | `git config --global commit.template <git-format>/.gitmessage` | 위와 동일, 전역 기본값 |

**실행 중 새로 생기는 파일**

| 파일/디렉터리 | 위치 | 언제 | 비고 |
|---|---|---|---|
| `.gitformat-verified` | `<대상 저장소>/.git/` | `pre-commit` 통과 시 생성, `post-commit`이 곧 삭제 | 커밋 사이에 남지 않는 임시 마커 |
| `.gitformat-build/` | 컨슈머 저장소 루트 | C/C++ `pre-push`가 cmake 빌드 시 | 커밋 대상 아님, `.gitignore`에 추가 권장 |
| `template/hooks/*` | 이 git-format 클론 자신의 `template/` 안 | `install.sh --global` 실행 시 | 클론 위치를 가리키는 심볼릭 링크, 커밋 안 됨(`.gitignore`) |

**커밋 자체가 바뀌는 경우**: `post-commit`이 조건에 따라 `git commit --amend`로
방금 만든 커밋의 footer에 트레일러를 추가합니다(아래 [🕵️ `--no-verify` 우회 탐지](#️---no-verify-우회-탐지),
[🤖 AI 귀속 footer](#-ai-귀속-footer) 참고) — 이 경우 커밋 해시가 한 번 더 바뀝니다. 기존 소스 파일
내용은 건드리지 않습니다.

## 📝 커밋 메시지 규칙

[Conventional Commits v1.0.0](https://www.conventionalcommits.org/ko/v1.0.0/)을 따릅니다
(요약: [`docs/references/conventional-commits-ko.md`](./docs/references/conventional-commits-ko.md), 결정: decision-1).

```
<type>[(scope)][!]: <description>

[body]

[footer(s)]
```

허용 type: `feat` `fix` `docs` `style` `refactor` `perf` `test` `build` `ci` `chore` `revert`.
`git config commit.template`이 설정돼 있으면 커밋 시 에디터에 이 형식과 type 목록이
주석으로 채워집니다.

## 🪝 훅이 하는 일

| 훅 | 하는 일 |
|---|---|
| `commit-msg` | Conventional Commits 형식 검증, 브랜치명 Task-Id 강제, (non-Claude-Code AI 도구의) AI-Model 존재/화이트리스트 검증 |
| `pre-commit` | 언어 감지(`package.json`/`pyproject.toml`·`requirements.txt`/`pom.xml`·`build.gradle*`/`CMakeLists.txt`·`Makefile`/`.sqlfluff`·추적된 `*.sql`) 후 `hooks/checks/<lang>.sh`로 lint/컴파일/포맷 검사 |
| `pre-push` | 같은 언어 감지로 테스트/전체 빌드(무거운 검사는 여기로 미룸) |
| `post-commit` | `--no-verify` 우회 탐지 + AI 귀속/Task-Id footer 트레일러 자동 삽입 |

언어별 체크에 필요한 도구(npm, ruff/flake8, mvn/gradle, clang-format, cmake, sqlfluff 등)가
없으면 해당 검사만 조용히 건너뜁니다 — 프로젝트에 해당 언어가 없으면 아무 일도 하지 않습니다.

**SQL**(decision-6): `.sqlfluff` 설정 파일이 있거나 `.sql` 파일이 추적돼 있으면
[sqlfluff](https://sqlfluff.com/)로 lint합니다. `pre-commit`은 스테이징된 `.sql`만,
`pre-push`는 저장소 전체를 검사합니다. dialect 설정은 프로젝트의 `.sqlfluff`에 맡기고
git-format은 강제하지 않습니다(`.sqlfluff`가 없으면 범용 기본값 `ansi`로 대체).

## 🏷️ Task-Id 브랜치 강제

> decision-4

브랜치명에 `<prefix>-<번호>` 패턴(기본 접두어 `GF`, `git config gitformat.taskPrefix`로
변경 가능)이 없으면 커밋이 거부됩니다. 예: `gf-12-install-script`, `feature/GF-9-template`.
`main`/`master`/`develop`/`release/*`(`git config --add gitformat.branchExempt <패턴>`으로
추가 가능)와 detached HEAD는 예외입니다. 매치되면 커밋 footer에 `Task-Id: GF-12`가 자동으로
붙습니다.

## 🕵️ `--no-verify` 우회 탐지

> decision-3

`git commit --no-verify`를 쓰면 `pre-commit`/`commit-msg`는 건너뛰지만, git은
`post-commit`만은 항상 실행한다는 걸 보장합니다. `pre-commit`이 통과하면 검증 마커를
남기고, `post-commit`이 이 마커가 없는 걸 확인하면 `git commit --amend`로
`Verify-Bypassed: true` footer를 **프로그래밍적으로** 삽입합니다. 텍스트 안내가 아니라
커밋 이력 자체에 남는 사실이라 `git log`만으로 우회 여부를 확인할 수 있습니다.

### opt-in: GitHub Actions 백스톱 설정

[`docs/examples/github-actions-caller.yml`](./docs/examples/github-actions-caller.yml)을 컨슈머 저장소의
`.github/workflows/`로 복사하면 git-format의 재사용 워크플로
(`.github/workflows/verify.yml`)가 PR마다 commit-msg 형식 검증 +
언어별 lint/빌드/테스트를 다시 실행합니다. 그다음 저장소 설정의
Branch protection rules에서 이 워크플로를 **필수 status check**로
지정해야 실제로 병합을 막는 효과가 생깁니다(단순히 워크플로만 추가하면
결과가 표시만 되고 강제되지는 않습니다) — [⚠️ 주의점](#️-주의점) 참고.

## 🤖 AI 귀속 footer

> decision-5

AI 코딩 에이전트가 커밋했다면 아래 트레일러가 자동으로 붙습니다. 신뢰 수준이 트레일러마다
다르다는 걸 알아두는 게 중요합니다.

| 트레일러 | 값 출처 | 신뢰 수준 |
|---|---|---|
| `AI-Tool`, `AI-Tool-Version` | `AI_AGENT` 환경변수(Claude Code 프로세스가 하위 프로세스에 주입) | 강제 — LLM이 스스로 만든 값이 아님 |
| `AI-Model` | **Claude Code**: 세션 트랜스크립트(`~/.claude/projects/<slug>/<session>.jsonl`)의 `message.model` — Anthropic API 응답을 그대로 기록한 값. **그 외 도구**: `git config gitformat.aiModel`(commit-msg가 존재/화이트리스트를 강제) | Claude Code는 서버 발급 사실 / 그 외는 존재+형식만 강제, 진실성은 검증 불가 |
| `Co-Authored-By` | `AI-Tool`이 `claude-code`일 때만 자동 삽입 | 자동 |
| `Hooks-Commit` | 이 git-format 클론 자체의 `git rev-parse --short HEAD` | 완전 자동, 모든 커밋에 적용(AI 여부 무관) |

`CLAUDE_CODE_SESSION_ID`는 `AI-Model` 조회를 위해 트랜스크립트 파일 경로를 찾는 데만
내부적으로 쓰이고, 값 자체가 커밋 footer에 남지는 않습니다 — 세션 식별자를 공개 저장소
히스토리에 영구히 남기지 않기 위함입니다.

## 🔧 커스터마이즈

```sh
git config gitformat.taskPrefix PROJ                # Task-Id 접두어 변경 (기본 GF)
git config --add gitformat.branchExempt 'hotfix/*'   # 예외 브랜치 패턴 추가
git config gitformat.aiModel claude-opus-5           # Claude Code가 아닌 AI 도구의 모델명
```

`hooks/gitformat.conf`의 `gitformat.knownModel` 항목에 조직 내부 모델 ID를 추가해도 됩니다.

위 `git config` 오버라이드는 컨슈머 저장소가 값을 바꿀 때 쓰는 것이고, 이
git-format 저장소 자체의 내부 기본값(마커 파일명, trailer 키 이름, 언어 감지
마커, 커밋 타입 목록, AI-Model 화이트리스트 등)은 전부 `hooks/gitformat.conf`
(git config 포맷) 한 곳에 모여 있습니다. 컨슈머가 직접 건드릴 파일은 아니고,
git-format을 포크/커스터마이즈할 때 참고하는 내부 설정 파일입니다.

## 📁 저장소 구조

```
git-format/
├── hooks/                  # core.hooksPath가 가리키는 실제 훅
│   ├── commit-msg
│   ├── pre-commit
│   ├── pre-push
│   ├── post-commit
│   ├── gitformat.conf      # 내부 기본값 한 곳에 모음(git config 포맷)
│   └── checks/{ts,python,java,cpp,sql}.sh
├── template/                # init.templateDir용 (hooks/*는 install.sh --global이 생성)
├── .gitmessage               # commit.template
├── install.sh
├── tests/                    # bats-core 테스트(dev 전용, decision-8)
├── docs/references/          # 외부 스펙 vendoring(conventional-commits, Pro Git)
└── backlog/                  # 이 저장소 자체 개발 관리(decision, task)
```

## ⚠️ 주의점

- **`core.hooksPath`는 로컬 훅을 완전히 대체합니다.** 기존에 `.git/hooks/`에 다른 훅을
  쓰고 있었다면 install.sh 실행 전에 충돌 여부를 확인하세요.
- **`git push --no-verify`는 탐지할 수 없습니다.** git에는 push 이후 무조건 실행되는
  로컬 훅이 없어서(`commit`과 다름) `--no-verify` 트릭을 push 단계엔 못 씁니다. 로컬
  훅은 애초에 `rm -rf .git/hooks`로도 완전히 우회 가능하므로, 이건 "우회 불가능"이
  아니라 "정상적인 사용에서 흔적을 남긴다"는 보장입니다. push까지 막고 싶으면 위
  opt-in GitHub Actions 백스톱을 브랜치 보호 필수 status check로 걸어야 합니다.
- **`post-commit`이 커밋 해시를 amend로 바꿀 수 있습니다.** Verify-Bypassed나 AI 귀속
  트레일러가 붙을 때마다 커밋이 한 번 더 amend됩니다 — 커밋 해시를 미리 캐싱하는
  외부 도구가 있다면 이 점을 인지해야 합니다.
- **비-Claude-Code AI 도구는 설정 없이 커밋이 막힐 수 있습니다.** `AI_AGENT` 환경변수가
  감지되는데 `gitformat.aiModel`을 안 정했다면 `commit-msg`가 거부합니다([🔧 커스터마이즈](#-커스터마이즈)
  참고).
- **라이선스가 두 가지입니다.** git-format 자체는 MIT지만, `docs/references/pro-git/`에
  vendoring한 Pro Git 원문은 **CC BY-NC-SA 3.0(비영리)**이라 상업적으로 재배포하면
  안 됩니다 — [`docs/references/pro-git/VENDORING.md`](./docs/references/pro-git/VENDORING.md) 참고.
- **`.gitformat-build/`는 커밋하지 말 것.** C/C++ 프로젝트라면 컨슈머 저장소의
  `.gitignore`에 `.gitformat-build/`를 추가하세요.

## 📄 라이선스

MIT — 전문: [`LICENSE`](./LICENSE)
