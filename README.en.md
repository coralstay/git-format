<div align="center">

# 🧬 git-format

**A commit rule / verification / history-formatting tool for multi-language projects, built entirely on native git features**

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](./LICENSE)
[![Shell: POSIX sh](https://img.shields.io/badge/shell-POSIX%20sh-89e051.svg)](./install.sh)
[![Runtime deps: none](https://img.shields.io/badge/runtime%20deps-none-brightgreen.svg)](#-install)

[한국어](./README.md) | **English**

No separate runtime like npm/pip. Using only **native git features** —
`core.hooksPath`, `commit.template`, `git interpret-trailers` — multiple
repositories share one commit convention.

</div>

> ⚠️ **This repo's code was written with AI (Claude Code).** The hooks
> actively reject commits and rewrite them via `--amend`, so read and
> review the code in `hooks/` yourself before adopting it.

---

## 📖 Table of Contents

- [🤔 Why this exists](#-why-this-exists)
- [🎯 Goals](#-goals)
- [🚀 Install](#-install)
- [📌 Actual usage](#-actual-usage)
- [🗂️ What this repo creates or changes](#️-what-this-repo-creates-or-changes)
- [📝 Commit message rules](#-commit-message-rules)
- [🪝 What the hooks do](#-what-the-hooks-do)
- [🏷️ Task-Id branch enforcement](#️-task-id-branch-enforcement)
- [🕵️ `--no-verify` bypass detection](#️---no-verify-bypass-detection)
- [🤖 AI attribution footer](#-ai-attribution-footer)
- [🔧 Customization](#-customization)
- [📁 Repository layout](#-repository-layout)
- [⚠️ Caveats](#️-caveats)
- [🚧 Limitations and open questions](#-limitations-and-open-questions)
- [📄 License](#-license)

---

## 🤔 Why this exists

In projects split across multiple languages (TS, C/C++, Java, Python, SQL,
etc.), commit conventions and pre-commit checks tend to be
inconsistent or missing per repository, and `git commit --no-verify` leaves
no trace when it bypasses those checks. Instead of installing a different
linter per language or maintaining a separate commit-convention doc per team,
the intent is for one repository to let multiple projects share the same
setup using **native git features** only.

## 🎯 Goals

| | Benefit |
|---|---|
| ✅ | Enforces a Linus Torvalds (Linux kernel) style commit convention (`[type][subsystem]` prefix + a body that focuses on "why" + atomic commits) the same way regardless of language. |
| 🧩 | Works with no separate runtime (Node/Python/etc.) — only `core.hooksPath`, `init.templateDir`, `commit.template`, git hooks, and `git interpret-trailers`. Per-language lint tools (npm/ruff/clang-format/mvn/sqlfluff/etc.) are used if present and silently skipped otherwise. |
| 🕵️ | Even when `git commit --no-verify` bypasses checks, a programmatic trace (`Verify-Bypassed: true`) is left in the commit history itself. |
| 🤖 | For commits made by AI coding agents, records which tool/model was involved, with a footer that distinguishes the trust level of each value. |
| 🧠 | **Structures commit/git history as semi-structured data** so it can be reused for LLM training or other learning purposes. Helps tools like Claude read `git status`/`git log` alone and accurately infer intent, verification status, and the work unit (Task-Id). |
| 👀 | For the same reason, **human readability** improves too. A consistent format lets both people and LLMs read "what changed, why, and how it was verified" from a single `git log`. |

> Design background and the reasoning behind each decision are in
> [`backlog/decisions/`](./backlog/decisions); work units are in
> [`backlog/tasks/`](./backlog/tasks). `backlog board` shows progress.

## 🚀 Install

### Apply to an existing repository

```sh
git clone https://github.com/amosQP/git-format.git ~/git-format   # clone once, anywhere
cd ~/my-project
~/git-format/install.sh
```

You can also pass a target directory: `~/git-format/install.sh ~/my-project`.

### Apply automatically to every new repository from now on

```sh
~/git-format/install.sh --global
```

Every time you run `git init`/`git clone`, the hooks and commit template are
planted automatically (`init.templateDir`). Running with no arguments in an
interactive terminal asks whether to apply this; `--global`/`--no-global`
lets you specify it non-interactively.

## 📌 Actual usage

Once installed, keep using `git checkout`/`git add`/`git commit`/`git push`
as normal. Here's a flow that was actually run once to verify it.

### 1. Start work on a branch with a Task-Id

```sh
git checkout -b GF-42-fix-login-crash
```

Unless the branch is `main`/`master`/`develop`/`release/*`, it needs a
`GF-<number>` pattern somewhere in its name (case-insensitive, prefix
changeable via `gitformat.taskPrefix`). Without it, every commit on this
branch gets rejected by `commit-msg`.

### 2. Edit code and stage it

```sh
git add src/login.ts
```

### 3. Commit — the hooks step in, in order

```sh
git commit
```

1. **`pre-commit`** detects the language from staged files and runs the
   matching check. For a TS project you'd see:
   ```
   [git-format] ts: npm run lint
   ```
2. **`commit-msg`** validates the subject line you just wrote and the
   branch name. If `commit.template` is set, the editor is pre-filled with
   the format guidance from [📝 Commit message rules](#-commit-message-rules)
   as comments. If the format is wrong:
   ```
   commit-msg: 커밋 메시지가 [type][subsystem] 형식이 아닙니다.
     형식: [type][subsystem] <description>  (subsystem 생략 가능: [type] <description>)
     허용 type: feat fix docs style refactor perf test build ci chore revert
     예: [fix][parser] 빈 입력 처리
   ```
   If the branch has no Task-Id:
   ```
   commit-msg: 브랜치명에 GF-<번호> 패턴이 없습니다 (현재 브랜치: fix-login).
     예: GF-12-install-script
     Task-Id 없이 커밋하려면 예외 브랜치(main/master/develop/release/*)에서 작업하세요.
   ```
   (The hooks' own messages are in Korean regardless of which README you're
   reading — they're not localized.)
3. Once both pass, the commit is created, and **`post-commit`** automatically
   adds trailers like `Task-Id`/`Signed-off-by`/`Hooks-Commit` (internally runs
   `git commit --amend` once — see
   [🕵️ `--no-verify` bypass detection](#️---no-verify-bypass-detection)).

### 4. Check the result

```sh
git log -1
```

```
    [fix][login] 빈 비밀번호 입력 시 크래시 수정

    Task-Id: GF-42
    Signed-off-by: Jane Dev <jane@example.com>
    Hooks-Commit: b5bf03a
```

If an AI coding agent made the commit, `AI-Tool`/`AI-Model`/`Co-Authored-By`
etc. get added too — see [🤖 AI attribution footer](#-ai-attribution-footer).

### 5. Skipping checks in a hurry with `--no-verify`

```sh
git commit --no-verify -m "[chore] 급한 핫픽스"
```

Lint/format checks are skipped, but a trace is left in the history:

```sh
git log -1
```
```
    [chore] 급한 핫픽스

    Verify-Bypassed: true
    Task-Id: GF-42
    Signed-off-by: Jane Dev <jane@example.com>
    Hooks-Commit: b5bf03a
```

git-format only covers the commit stage — `git push` goes through no hook at
all (decision-12). If you need push-stage checks, you'll have to set those up
yourself, in CI or server-side (see [⚠️ Caveats](#️-caveats)).

## 🗂️ What this repo creates or changes

**What changes in the consumer repository on install** — only git config,
never files. No source file is touched.

| Target | Command | Effect |
|---|---|---|
| Local (target repo) | `git config core.hooksPath <git-format>/hooks` | Fully replaces any existing local hooks in `.git/hooks/` |
| Local (target repo) | `git config commit.template <git-format>/.gitmessage` | Shows the skeleton in the commit editor |
| Global (`--global`) | `git config --global init.templateDir <git-format>/template` | Applied automatically to every new repo from now on |
| Global (`--global`) | `git config --global commit.template <git-format>/.gitmessage` | Same as above, as the global default |

**Files created at runtime**

| File/dir | Location | When | Notes |
|---|---|---|---|
| `.gitformat-verified` | `<target repo>/.git/` | Created when `pre-commit` passes, deleted shortly after by `post-commit` | Temporary marker, does not persist between commits |
| `template/hooks/*` | Inside this git-format clone's own `template/` | When running `install.sh --global` | Symlinks pointing at the clone's location, not committed (`.gitignore`) |

**When the commit itself changes**: `post-commit` conditionally appends
trailers to the footer of the commit you just made, via `git commit --amend`
(see [🕵️ `--no-verify` bypass detection](#️---no-verify-bypass-detection) and
[🤖 AI attribution footer](#-ai-attribution-footer) below) — in that case the
commit hash changes once more. Existing source file contents are never
touched.

## 📝 Commit message rules

Follows a Linus Torvalds (Linux kernel) style convention — only the subject
prefix was changed to bracket form; everything else (blank line, a body that
focuses on "why", trailers, atomic-commit practice) was adopted as-is
(decision: decision-10, supersedes decision-1).

```
[type][subsystem] <description>

[body]

[footer(s)]
```

- `subsystem` is optional: `[type] <description>`.
- Allowed types: `feat` `fix` `docs` `style` `refactor` `perf` `test` `build`
  `ci` `chore` `revert`.
- The subject must be 50 characters or under (Unicode character count, not
  bytes — `commit-msg` validates this).
- If there's a body, a blank line is required between it and the subject
  (`commit-msg` validates this).
- Each body line must wrap at 72 characters or under (`commit-msg` validates
  this). Lines starting with a registered footer trailer (`Task-Id`, `Fixes`,
  `BREAKING CHANGE`, etc.) are exempt.
- `Fixes: <hash> ("<title of the commit that introduced the bug>")` is not
  required, but if present, `commit-msg` verifies the hash refers to a real
  commit.
- `Signed-off-by: <name> <email>` is auto-inserted by `post-commit` from the
  committer's identity (same mechanism as `git commit -s`) — no need to
  write it yourself.
- Breaking changes are marked only via a `BREAKING CHANGE: <description>`
  footer — there's no `!` marker.

If `git config commit.template` is set, the commit editor is pre-filled with
this format and the type list as comments.

## 🪝 What the hooks do

| Hook | What it does |
|---|---|
| `commit-msg` | Validates `[type][subsystem]` format, checks subject (50 chars) / body line (72 chars) length (trailer lines exempt), requires a blank line before a body, verifies `Fixes:` hashes exist, enforces a Task-Id in the branch name, checks that AI-Model exists/is whitelisted (for non-Claude-Code AI tools) |
| `pre-commit` | Detects the language (`package.json` / `pyproject.toml`·`requirements.txt` / `pom.xml`·`build.gradle*` / `CMakeLists.txt`·`Makefile` / `.sqlfluff`·tracked `*.sql`), then runs `hooks/checks/<lang>.sh` for lint/compile/format checks |
| `post-commit` | Detects `--no-verify` bypass + auto-inserts AI attribution/Task-Id/Signed-off-by footer trailers |

If a tool a language check needs (npm, ruff/flake8, mvn/gradle,
clang-format, cmake, sqlfluff, etc.) isn't installed, that check is silently
skipped — if the project doesn't use that language at all, nothing happens.

**SQL** (decision-6): if a `.sqlfluff` config file exists or any `.sql` file
is tracked, lints staged `.sql` files with [sqlfluff](https://sqlfluff.com/)
(`pre-commit`). Dialect configuration is left to the project's own
`.sqlfluff` — git-format doesn't force one (falls back to the generic
default `ansi` if `.sqlfluff` is absent).

## 🏷️ Task-Id branch enforcement

> decision-4

If the branch name doesn't contain a `<prefix>-<number>` pattern (default
prefix `GF`, changeable via `git config gitformat.taskPrefix`), the commit is
rejected. Examples: `gf-12-install-script`, `feature/GF-9-template`.
`main`/`master`/`develop`/`release/*` (add more via
`git config --add gitformat.branchExempt <pattern>`) and detached HEAD are
exempt. On a match, `Task-Id: GF-12` is automatically added to the commit
footer.

## 🕵️ `--no-verify` bypass detection

> decision-3

`git commit --no-verify` skips `pre-commit`/`commit-msg`, but git guarantees
that `post-commit` always runs. When `pre-commit` passes, it leaves a
verification marker; if `post-commit` finds that marker missing, it inserts
a `Verify-Bypassed: true` footer **programmatically** via
`git commit --amend`. This isn't a text notice — it's a fact recorded in the
commit history itself, so bypasses can be checked with `git log` alone.

## 🤖 AI attribution footer

> decision-5

If an AI coding agent made the commit, the trailers below are added
automatically. It matters that the trust level differs per trailer.

| Trailer | Value source | Trust level |
|---|---|---|
| `AI-Tool`, `AI-Tool-Version` | `AI_AGENT` env var (injected into subprocesses by the Claude Code process) | Enforced — not a value the LLM made up itself |
| `AI-Model` | **Claude Code**: `message.model` from the session transcript (`~/.claude/projects/<slug>/<session>.jsonl`) — the value the Anthropic API actually returned, recorded as-is. **Other tools**: `git config gitformat.aiModel` (commit-msg enforces that it exists and is whitelisted) | Claude Code: a server-issued fact / Others: only presence+format enforced, truthfulness unverifiable |
| `Co-Authored-By` | Auto-inserted only when `AI-Tool` is `claude-code` | Automatic |
| `Hooks-Commit` | `git rev-parse --short HEAD` of this git-format clone itself | Fully automatic, applied to every commit regardless of AI involvement |
| `Signed-off-by` | Committer identity (`git log -1 --format='%cn <%ce>'`) | Fully automatic, applied to every commit regardless of AI involvement (same mechanism as `git commit -s`, decision-10) |

`CLAUDE_CODE_SESSION_ID` is used internally only to locate the transcript
file path for the `AI-Model` lookup — the value itself is never left in the
commit footer, so a session identifier doesn't end up permanently in a
public repository's history.

## 🔧 Customization

```sh
git config gitformat.taskPrefix PROJ                # change the Task-Id prefix (default GF)
git config --add gitformat.branchExempt 'hotfix/*'   # add an exempt branch pattern
git config gitformat.aiModel claude-opus-5           # model name for a non-Claude-Code AI tool
```

You can also add internal model IDs to `hooks/gitformat.conf`'s
`gitformat.knownModel` entries.

The `git config` overrides above are what a consumer repository uses to
change values. git-format's own internal defaults (marker filename, trailer
key names, language-detection markers, the commit type list, the AI-Model
whitelist, etc.) all live in one place: `hooks/gitformat.conf` (git config
format). Consumers aren't meant to touch this file directly — it's the
internal config file to reference when forking/customizing git-format
itself.

## 📁 Repository layout

```
git-format/
├── hooks/                  # the actual hooks core.hooksPath points at
│   ├── commit-msg
│   ├── pre-commit
│   ├── post-commit
│   ├── gitformat.conf      # internal defaults in one place (git config format)
│   └── checks/{ts,python,java,cpp,sql}.sh
├── template/                # for init.templateDir (hooks/* generated by install.sh --global)
├── .gitmessage               # commit.template
├── install.sh
├── tests/                    # bats-core tests (dev only, decision-8)
├── docs/
│   └── references/          # conventional-commits summary/translation (no verbatim vendoring, decision-14)
├── .github/workflows/        # test.yml only - this repo's own dev CI (shellcheck+bats);
│                              #   no server-side verification is shipped to consumers (decision-11)
└── backlog/                  # this repo's own dev management (decisions, tasks)
```

## ⚠️ Caveats

- **`core.hooksPath` completely replaces local hooks.** If `.git/hooks/`
  already had other hooks in use, check for conflicts before running
  install.sh.
- **Push stage isn't hooked at all.** git-format only covers the commit
  stage (`commit-msg`/`pre-commit`/`post-commit`) — `git push` goes through
  no hook (decision-12), so there's no test/build run and no `--no-verify`
  detection at push time either. Local hooks can always be bypassed entirely
  anyway (e.g. `rm -rf .git/hooks`) — so this was never a guarantee of
  "can't be bypassed," only that "normal usage leaves a trace." A
  server-side backstop that blocks at push time (e.g. a required CI status
  check, a server-side pre-receive hook) is out of scope for this project —
  git-format only ships client-side hooks (decision-11). If you need one,
  build it yourself; it can reuse `hooks/commit-msg`/`hooks/pre-commit` by
  calling them directly.
- **`post-commit` can change the commit hash via amend.** Every time a
  Verify-Bypassed or AI attribution trailer is added, the commit gets
  amended once more — be aware of this if you have external tooling that
  caches commit hashes ahead of time.
- **Non-Claude-Code AI tools can get their commit blocked without config.**
  If the `AI_AGENT` env var is detected but `gitformat.aiModel` hasn't been
  set, `commit-msg` rejects the commit (see
  [🔧 Customization](#-customization)).

## 🚧 Limitations and open questions

- **No native Windows support.** The hooks are POSIX sh, so a POSIX-compatible
  shell (WSL, Git Bash) is required.
- **Supported languages are fixed at TS/Python/Java/C·C++/SQL.** There's no
  plan to add more.
- **Push-stage checks (including tests/builds) are intentionally out of
  scope for this project** (decision-11, decision-12). git-format only
  covers the commit stage (`commit-msg`/`pre-commit`/`post-commit`) — if
  you need push-stage checks, you build them yourself, calling
  `hooks/commit-msg`/`hooks/pre-commit` from your own CI or server-side
  pre-receive hook.
- **Structuring commit history as semi-structured data is as far as this
  project's scope goes.** A tool that actually parses or turns that data
  into training data isn't included.
- **Non-Claude-Code AI tools' `AI-Model` value is self-reported.** Unlike
  Claude Code, it isn't verified against a session transcript — whatever the
  user sets in `gitformat.aiModel` is trusted as-is.

## 📄 License

MIT — full text: [`LICENSE`](./LICENSE). The whole repo is under one
license — no external documents are vendored verbatim (decision-14).
