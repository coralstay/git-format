<div align="center">

# 🧬 git-format

**여러 언어 프로젝트를 위한, git 자체 기능만으로 동작하는 커밋 규칙 · 검증 · 이력 정형화 도구**

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](./LICENSE)
[![Shell: POSIX sh](https://img.shields.io/badge/shell-POSIX%20sh-89e051.svg)](./install.sh)
[![Runtime deps: none](https://img.shields.io/badge/runtime%20deps-none-brightgreen.svg)](#-무엇을-만들었는지-말씀드립니다)

npm/pip 같은 별도 런타임 없이, `core.hooksPath` · `commit.template` · `git interpret-trailers` 등
**git 자체 기능만으로** 여러 저장소가 하나의 커밋 규칙을 공유할 수 있게 만들어 사용하고
있는 도구입니다.

</div>

> ⚠️ **이 저장소의 코드는 AI(Claude Code)와 함께 작성했습니다.** 훅이 커밋을 거부하거나
> `--amend`로 내용을 바꾸는 등 실제 동작을 하므로, 적용 전에 `hooks/`의 코드를 직접 읽고
> 검토해 주시기 바랍니다.

---

## 🤔 왜 만들었는지 말씀드립니다

여러 언어(TS, C/C++, Java, Python, SQL 등)로 나뉜 프로젝트들에서 커밋 규칙과 커밋 전
검사가 저장소마다 제각각이거나 아예 없었고, `git commit --no-verify`로 검사를
우회해도 아무 흔적이 남지 않는 문제가 있었습니다. 여기에 더해, 사람이 아니라 AI
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

POSIX sh 훅 3개(`hooks/pre-commit`, `hooks/commit-msg`, `hooks/post-commit`) + 설정
파일 하나(`hooks/gitformat.conf`) + 설치 스크립트(`install.sh`)로 구성된, **git 자체
기능만으로 동작하는** 도구를 만들었습니다. `core.hooksPath` · `commit.template` ·
`init.templateDir` · `git interpret-trailers` 같은 git 내장 메커니즘만 쓰고, npm/pip
같은 별도 런타임 의존성은 두지 않았습니다 — 언어별 lint 도구(npm/ruff/clang-format/
mvn/sqlfluff 등)는 있으면 쓰고 없으면 조용히 건너뛰도록 만들었습니다.

## 🪝 훅을 생애주기별로 정리해 드립니다

> 공식 문서: [githooks(5)](https://git-scm.com/docs/githooks)

`git commit`을 실행하면 아래 순서로 훅이 개입한다는 점을 말씀드립니다.

1. **[`pre-commit`](hooks/pre-commit)** — 스테이징된 파일로 언어를 감지해(`package.json`/
   `pyproject.toml`·`requirements.txt`/`pom.xml`·`build.gradle*`/`CMakeLists.txt`·
   `Makefile`/`.sqlfluff`·추적된 `*.sql`) [`hooks/checks/<lang>.sh`](hooks/checks/)로
   lint/컴파일/포맷 검사를 돌립니다(SQL은 sqlfluff, decision-6). 통과하면 검증
   마커를 남깁니다.
2. **[`commit-msg`](hooks/commit-msg)** — 커밋 메시지가 `[type][subsystem] <description>` 형식인지, 제목
   50자/본문 줄 72자 이내인지, 본문이 있으면 빈 줄이 있는지, 브랜치명에
   Task-Id(`GF-<번호>`, decision-4)가 있는지, (non-Claude-Code AI 도구라면) `AI-Model`이
   화이트리스트에 있는지 검증합니다. 여기서 거부되면 커밋 자체가 만들어지지 않습니다.
3. **(커밋 생성)** — 둘 다 통과하면 git이 실제로 커밋을 만듭니다.
4. **[`post-commit`](hooks/post-commit)** — `pre-commit`/`commit-msg`와 달리 `--no-verify`로도 건너뛸 수
   없고, exit code가 커밋 결과에 영향을 주지도 못한다는 점을 [공식
   문서](https://git-scm.com/docs/githooks)로도 확인하실 수 있습니다 — git이 항상 실행을
   보장하는 이 훅에서, `pre-commit`이 남긴 검증 마커가 없으면(= `--no-verify`로 건너뛴
   경우) `Verify-Bypassed: true`를 `git commit --amend`로 프로그래밍적으로 삽입합니다
   (decision-3). 그리고 `Task-Id`, `Signed-off-by`(decision-10), `Hooks-Commit`과, AI
   에이전트가 커밋했다면 아래 AI 귀속/토큰 트레일러를 함께 붙입니다(decision-5).

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
기록된다는 점을 말씀드립니다 — 사유 슬러그: `no-session-id`, `jq-not-installed`,
`transcript-not-found`, `transcript-unreadable`, `transcript-parse-failed`,
`no-usage-channel`입니다.

예시를 보여드리면 다음과 같습니다.

```
[fix][login] 빈 비밀번호 입력 시 크래시 수정

Task-Id: GF-42
Signed-off-by: Jane Dev <jane@example.com>
Hooks-Commit: b5bf03a
```

git-format은 커밋 단계까지만 다룬다는 점을 말씀드립니다 — `git push`는 아무 훅도
거치지 않는 평범한 push입니다(decision-12).

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
- **설계 배경과 각 결정 이유**(decision-1~15)는 `backlog decision list`에서
  확인하실 수 있습니다.
- **작업 단위와 진행 상황**은 `backlog board`에서 확인하실 수 있습니다.
- **라이선스**는 MIT입니다(전문: [`LICENSE`](./LICENSE)) — 외부 문서를 원문 그대로
  vendoring하지 않는다는 점도 함께 말씀드립니다(decision-14).
