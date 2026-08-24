# git-format

TS, C/C++, Java, Python 등 언어가 달라도 동일한 git 커밋 규칙과 커밋/푸시 전 검사를
쓸 수 있게 하는 저장소다. 별도 런타임(Node/Python 등) 의존성 없이 **git 자체 기능**
(`core.hooksPath`, `init.templateDir`, `commit.template`, git hooks, `git interpret-trailers`)
만으로 동작한다.

설계 배경과 각 결정의 이유는 `backlog/decisions/`(decision-1~5)에, 작업 단위는
`backlog/tasks/`(GF-1~GF-12)에 기록돼 있다. `backlog board`로 진행 상황을 볼 수 있다.

## 설치

### 기존 저장소에 적용

```sh
git clone <이 저장소 URL> ~/git-format   # 원하는 위치에 한 번만 클론
cd ~/my-project
~/git-format/install.sh
```

`core.hooksPath`와 `commit.template`이 대상 저장소에 설정된다. 대상 디렉터리를 인자로
줘도 된다: `~/git-format/install.sh ~/my-project`.

### 앞으로 만들 모든 새 저장소에 자동 적용

```sh
~/git-format/install.sh --global
```

`git init`/`git clone`을 실행할 때마다 훅과 커밋 템플릿이 자동으로 심어진다
(`init.templateDir`). 대화형 터미널에서 인자 없이 실행하면 이 적용 여부를 물어본다.

> `core.hooksPath`가 설정된 저장소는 `.git/hooks/`의 로컬 훅을 완전히 무시한다.
> 기존에 다른 훅을 쓰고 있었다면 충돌 여부를 확인할 것.

## 커밋 메시지 규칙

[Conventional Commits v1.0.0](https://www.conventionalcommits.org/ko/v1.0.0/)을 따른다
(요약: `docs/references/conventional-commits-ko.md`, 결정: decision-1).

```
<type>[(scope)][!]: <description>

[body]

[footer(s)]
```

허용 type: `feat` `fix` `docs` `style` `refactor` `perf` `test` `build` `ci` `chore` `revert`.
`git config commit.template`이 설정돼 있으면 커밋 시 에디터에 이 형식과 type 목록이
주석으로 채워진다.

## 훅이 하는 일

| 훅 | 하는 일 |
|---|---|
| `commit-msg` | Conventional Commits 형식 검증, 브랜치명 Task-Id 강제, (non-Claude-Code AI 도구의) AI-Model 존재/화이트리스트 검증 |
| `pre-commit` | 언어 감지(`package.json`/`pyproject.toml`·`requirements.txt`/`pom.xml`·`build.gradle*`/`CMakeLists.txt`·`Makefile`/`.sqlfluff`·추적된 `*.sql`) 후 `hooks/checks/<lang>.sh`로 lint/컴파일/포맷 검사 |
| `pre-push` | 같은 언어 감지로 테스트/전체 빌드(무거운 검사는 여기로 미룸) |
| `post-commit` | `--no-verify` 우회 탐지 + AI 귀속/Task-Id footer 트레일러 자동 삽입 |

언어별 체크에 필요한 도구(npm, ruff/flake8, mvn/gradle, clang-format, cmake, sqlfluff 등)가
없으면 해당 검사만 조용히 건너뛴다 — 프로젝트에 해당 언어가 없으면 아무 일도 하지 않는다.

SQL(decision-6): `.sqlfluff` 설정 파일이 있거나 `.sql` 파일이 추적돼 있으면
[sqlfluff](https://sqlfluff.com/)로 lint한다. `pre-commit`은 스테이징된 `.sql`만,
`pre-push`는 저장소 전체를 검사한다. dialect 설정은 프로젝트의 `.sqlfluff`에 맡기고
git-format은 강제하지 않는다.

## Task-Id 브랜치 강제 (decision-4)

브랜치명에 `<prefix>-<번호>` 패턴(기본 접두어 `GF`, `git config gitformat.taskPrefix`로
변경 가능)이 없으면 커밋이 거부된다. 예: `gf-12-install-script`, `feature/GF-9-template`.
`main`/`master`/`develop`/`release/*`(`git config --add gitformat.branchExempt <패턴>`으로
추가 가능)와 detached HEAD는 예외다. 매치되면 커밋 footer에 `Task-Id: GF-12`가 자동으로
붙는다.

## `--no-verify` 우회 탐지 (decision-3)

`git commit --no-verify`를 쓰면 `pre-commit`/`commit-msg`는 건너뛰지만, git은
`post-commit`만은 항상 실행한다는 걸 보장한다. `pre-commit`이 통과하면 검증마커를
남기고, `post-commit`이 이 마커가 없는 걸 확인하면 `git commit --amend`로
`Verify-Bypassed: true` footer를 **프로그래밍적으로** 삽입한다. 텍스트 안내가 아니라
커밋 이력 자체에 남는 사실이라 `git log`만으로 우회 여부를 확인할 수 있다.

**한계**: `git push --no-verify`는 `pre-push`만 건너뛰고, git에는 push 이후 무조건
실행되는 로컬 훅이 없어서 이 트릭을 push 단계에는 쓸 수 없다. 로컬 훅은 애초에
`rm -rf .git/hooks` 같은 방법으로도 완전히 우회 가능하므로, 이건 "우회 불가능"이
아니라 "정상적인 사용에서 흔적을 남긴다"는 보장이다. push 단계까지 막고 싶으면
GitHub 브랜치 보호 + 필수 status check(GF-12, opt-in)를 함께 쓸 것.

### opt-in: GitHub Actions 백스톱 설정

`docs/examples/github-actions-caller.yml`을 컨슈머 저장소의
`.github/workflows/`로 복사하면 `git-format`의 재사용 워크플로
(`.github/workflows/verify.yml`)가 PR마다 commit-msg 형식 검증 +
언어별 lint/빌드/테스트를 다시 실행한다. 그다음 저장소 설정의
Branch protection rules에서 이 워크플로를 **필수 status check**로
지정해야 실제로 병합을 막는 효과가 생긴다(단순히 워크플로만 추가하면
결과가 표시만 되고 강제되지는 않는다).

## AI 귀속 footer (decision-5)

AI 코딩 에이전트가 커밋했다면 아래 트레일러가 자동으로 붙는다. 신뢰 수준이 트레일러마다
다르다는 걸 알아두는 게 중요하다.

| 트레일러 | 값 출처 | 신뢰 수준 |
|---|---|---|
| `AI-Tool`, `AI-Tool-Version` | `AI_AGENT` 환경변수(Claude Code 프로세스가 하위 프로세스에 주입) | 강제 — LLM이 스스로 만든 값이 아님 |
| `AI-Model` | **Claude Code**: 세션 트랜스크립트(`~/.claude/projects/<slug>/<session>.jsonl`)의 `message.model` — Anthropic API 응답을 그대로 기록한 값. **그 외 도구**: `git config gitformat.aiModel`(commit-msg가 존재/화이트리스트를 강제) | Claude Code는 서버 발급 사실 / 그 외는 존재+형식만 강제, 진실성은 검증 불가 |
| `Co-Authored-By` | `AI-Tool`이 `claude-code`일 때만 자동 삽입 | 자동 |
| `Hooks-Commit` | 이 git-format 클론 자체의 `git rev-parse --short HEAD` | 완전 자동, 모든 커밋에 적용(AI 여부 무관) |

비-Claude-Code AI 도구를 쓰면서 `gitformat.aiModel`을 설정하지 않으면 `commit-msg`가
커밋을 거부한다. 모델 ID는 `hooks/checks/known-models.txt` 화이트리스트에 있어야 한다.

`CLAUDE_CODE_SESSION_ID`는 `AI-Model` 조회를 위해 트랜스크립트 파일 경로를 찾는 데만
내부적으로 쓰이고, 값 자체가 커밋 footer에 남지는 않는다 — 세션 식별자를 공개 저장소
히스토리에 영구히 남기지 않기 위함이다.

## 커스터마이즈

```sh
git config gitformat.taskPrefix PROJ          # Task-Id 접두어 변경 (기본 GF)
git config --add gitformat.branchExempt 'hotfix/*'  # 예외 브랜치 패턴 추가
git config gitformat.aiModel claude-opus-5    # Claude Code가 아닌 AI 도구의 모델명
```

`hooks/checks/known-models.txt`에 조직 내부 모델 ID를 추가해도 된다.

## 저장소 구조

```
git-format/
├── hooks/                  # core.hooksPath가 가리키는 실제 훅
│   ├── commit-msg
│   ├── pre-commit
│   ├── pre-push
│   ├── post-commit
│   └── checks/{ts,python,java,cpp,sql}.sh, known-models.txt
├── template/                # init.templateDir용 (hooks/*는 install.sh --global이 생성)
├── .gitmessage               # commit.template
├── install.sh
├── docs/references/          # 외부 스펙 vendoring
└── backlog/                  # 이 저장소 자체 개발 관리(decision, task)
```

## 라이선스

[MIT](LICENSE)
