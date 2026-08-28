
<!-- BACKLOG.MD GUIDELINES START -->
<!-- backlog.md-instructions-version: 1.50.1 -->
<CRITICAL_INSTRUCTION>

## Backlog.md Workflow

This project uses Backlog.md for task and project management.

**For every user request in this project, run `backlog instructions overview` before answering or taking action.**

Use the overview to decide whether to search, read, create, or update Backlog tasks.

Before task lifecycle actions, read the matching detailed guide:
- `backlog instructions task-creation` before creating or splitting tasks
- `backlog instructions task-execution` before planning, changing status or assignee, adding a plan or implementation notes, or implementing task work
- `backlog instructions task-finalization` before checking acceptance criteria, writing final summaries, or moving tasks to terminal statuses

Use `backlog <command> --help` before running unfamiliar commands. Help shows options, fields, and examples.

Do not edit Backlog task, draft, document, decision, or milestone markdown files directly. Use the `backlog` CLI so metadata, relationships, and history stay consistent.

</CRITICAL_INSTRUCTION>
<!-- BACKLOG.MD GUIDELINES END -->

## Backlog Decision 상태 확인 관례

`backlog decision` CLI에는 `create`/`list`만 있고 상태(status)를 바꾸는 명령이
없다. 그래서 어떤 decision이 나중 decision으로 대체(superseded)돼도
`backlog decision list`에는 여전히 `accepted`로 표시된다(예: decision-7은
decision-8로 대체됐지만 목록상 상태는 그대로다).

**decision을 참고할 때는 `backlog decision list`의 상태 표시만 보지 말고,
`backlog/decisions/`의 해당 파일 본문(Context/Decision/Consequences)에 "OO으로
대체됨/superseded" 같은 언급이 있는지 항상 확인할 것.** (`backlog decision`
CLI에는 `view`가 없어 파일을 직접 읽어야 한다.) 가장 번호가 큰 decision이
같은 주제를 다루고 있으면 그게 최신 결정이다.

## `hooks/*`, `install.sh`에서 `readonly VAR="$(cmd)"`를 한 줄로 합치지 말 것

`VAR="$(cmd)"` 다음 줄에 `readonly VAR`를 쓰는 두 줄짜리 패턴이 hooks/*,
install.sh 전체에 반복된다. "한 줄로 합칠 수 있지 않나" 싶어도(POSIX 문법상
`readonly VAR="$(cmd)"`도 유효하다) **절대 합치지 말 것** — 실측 확인 결과,
`set -eu` 아래에서 `cmd`가 실패해도 `readonly VAR="$(cmd)"` 형태는 여러 셸
(bash의 sh 모드, dash, zsh의 sh 에뮬레이션)에서 그 실패를 **조용히 삼켜버리고**
빈 문자열로 계속 진행한다. 반면 `VAR="$(cmd)"; readonly VAR`처럼 대입과
readonly를 분리하면 대입 실패 시점에 정상적으로 `set -e`가 걸려 스크립트가
즉시 중단된다. 즉 지금의 "장황해 보이는" 두 줄 패턴은 스타일이 아니라
안전장치이며, 한 줄로 "정리"하면 조용한 실패를 유발하는 회귀가 생긴다.
