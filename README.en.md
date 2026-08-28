<div align="center">

# 🧬 git-format

**A commit rule / verification / history-formatting tool for multi-language projects, built entirely on native git features**

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](./LICENSE)
[![Shell: POSIX sh](https://img.shields.io/badge/shell-POSIX%20sh-89e051.svg)](./install.sh)
[![Runtime deps: none](https://img.shields.io/badge/runtime%20deps-none-brightgreen.svg)](#-install)
[![Conventional Commits](https://img.shields.io/badge/commits-Conventional%20Commits-fe5196.svg)](https://www.conventionalcommits.org/en/v1.0.0/)

[한국어](./README.md) | **English**

No separate runtime like npm/pip. Using only **native git features** —
`core.hooksPath`, `commit.template`, `git interpret-trailers` — multiple
repositories share one commit convention.

</div>

---

## 📖 Table of Contents

- [🤔 Why this exists](#-why-this-exists)
- [🎯 Goals](#-goals)
- [🚀 Install](#-install)
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
etc.), commit conventions and pre-commit/pre-push checks tend to be
inconsistent or missing per repository, and `git commit --no-verify` leaves
no trace when it bypasses those checks. Instead of installing a different
linter per language or maintaining a separate commit-convention doc per team,
the intent is for one repository to let multiple projects share the same
setup using **native git features** only.

## 🎯 Goals

| | Benefit |
|---|---|
| ✅ | Enforces [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) the same way regardless of language. |
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
| `.gitformat-build/` | Consumer repo root | When C/C++ `pre-push` runs a cmake build | Not meant to be committed; add to `.gitignore` |
| `template/hooks/*` | Inside this git-format clone's own `template/` | When running `install.sh --global` | Symlinks pointing at the clone's location, not committed (`.gitignore`) |

**When the commit itself changes**: `post-commit` conditionally appends
trailers to the footer of the commit you just made, via `git commit --amend`
(see [🕵️ `--no-verify` bypass detection](#️---no-verify-bypass-detection) and
[🤖 AI attribution footer](#-ai-attribution-footer) below) — in that case the
commit hash changes once more. Existing source file contents are never
touched.

## 📝 Commit message rules

Follows [Conventional Commits v1.0.0](https://www.conventionalcommits.org/en/v1.0.0/)
(summary: [`docs/references/conventional-commits-ko.md`](./docs/references/conventional-commits-ko.md), decision: decision-1).

```
<type>[(scope)][!]: <description>

[body]

[footer(s)]
```

Allowed types: `feat` `fix` `docs` `style` `refactor` `perf` `test` `build`
`ci` `chore` `revert`. If `git config commit.template` is set, the commit
editor is pre-filled with this format and the type list as comments.

## 🪝 What the hooks do

| Hook | What it does |
|---|---|
| `commit-msg` | Validates Conventional Commits format, enforces a Task-Id in the branch name, checks that AI-Model exists/is whitelisted (for non-Claude-Code AI tools) |
| `pre-commit` | Detects the language (`package.json` / `pyproject.toml`·`requirements.txt` / `pom.xml`·`build.gradle*` / `CMakeLists.txt`·`Makefile` / `.sqlfluff`·tracked `*.sql`), then runs `hooks/checks/<lang>.sh` for lint/compile/format checks |
| `pre-push` | Same language detection, for tests/full builds (heavier checks deferred here) |
| `post-commit` | Detects `--no-verify` bypass + auto-inserts AI attribution/Task-Id footer trailers |

If a tool a language check needs (npm, ruff/flake8, mvn/gradle,
clang-format, cmake, sqlfluff, etc.) isn't installed, that check is silently
skipped — if the project doesn't use that language at all, nothing happens.

**SQL** (decision-6): if a `.sqlfluff` config file exists or any `.sql` file
is tracked, lints with [sqlfluff](https://sqlfluff.com/). `pre-commit` only
checks staged `.sql` files; `pre-push` checks the whole repository. Dialect
configuration is left to the project's own `.sqlfluff` — git-format doesn't
force one (falls back to the generic default `ansi` if `.sqlfluff` is
absent).

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

### opt-in: setting up the GitHub Actions backstop

Copying [`docs/examples/github-actions-caller.yml`](./docs/examples/github-actions-caller.yml)
into the consumer repo's `.github/workflows/` makes git-format's reusable
workflow (`.github/workflows/verify.yml`) re-run commit-msg format
validation and per-language lint/build/test checks on every PR. You then
need to set this workflow as a **required status check** under Branch
protection rules in the repo settings for it to actually block merges
(adding the workflow alone only shows the result, it doesn't enforce
anything) — see [⚠️ Caveats](#️-caveats).

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
│   ├── pre-push
│   ├── post-commit
│   ├── gitformat.conf      # internal defaults in one place (git config format)
│   └── checks/{ts,python,java,cpp,sql}.sh
├── template/                # for init.templateDir (hooks/* generated by install.sh --global)
├── .gitmessage               # commit.template
├── install.sh
├── tests/                    # bats-core tests (dev only, decision-8)
├── docs/
│   ├── references/          # vendored external specs (conventional-commits, Pro Git)
│   └── examples/            # examples meant to be copied into a consumer repo (GitHub Actions backstop, etc.)
├── .github/workflows/        # verify.yml (reusable workflow for consumers), test.yml/self-verify.yml (dev only)
└── backlog/                  # this repo's own dev management (decisions, tasks)
```

## ⚠️ Caveats

- **`core.hooksPath` completely replaces local hooks.** If `.git/hooks/`
  already had other hooks in use, check for conflicts before running
  install.sh.
- **`git push --no-verify` can't be detected.** Git has no local hook that
  unconditionally runs after push (unlike `commit`), so the `--no-verify`
  trick used for commit-msg/pre-commit doesn't apply at push time. Local
  hooks can always be bypassed entirely anyway (e.g. `rm -rf .git/hooks`) —
  so this was never a guarantee of "can't be bypassed," only that "normal
  usage leaves a trace." To block push too, set up the opt-in GitHub Actions
  backstop above as a required branch-protection status check.
- **`post-commit` can change the commit hash via amend.** Every time a
  Verify-Bypassed or AI attribution trailer is added, the commit gets
  amended once more — be aware of this if you have external tooling that
  caches commit hashes ahead of time.
- **Non-Claude-Code AI tools can get their commit blocked without config.**
  If the `AI_AGENT` env var is detected but `gitformat.aiModel` hasn't been
  set, `commit-msg` rejects the commit (see
  [🔧 Customization](#-customization)).
- **There are two licenses.** git-format itself is MIT, but the vendored
  Pro Git text in `docs/references/pro-git/` is
  **CC BY-NC-SA 3.0 (non-commercial)** and must not be redistributed
  commercially — see
  [`docs/references/pro-git/VENDORING.md`](./docs/references/pro-git/VENDORING.md).
- **Don't commit `.gitformat-build/`.** For C/C++ projects, add
  `.gitformat-build/` to the consumer repo's `.gitignore`.

## 🚧 Limitations and open questions

- **Subject length / body line-wrap width aren't validated.** The "keep it
  under 50 chars", "wrap around 72 chars" text in `.gitmessage` is guidance
  only — `commit-msg` doesn't actually measure length.
- **No native Windows support.** The hooks are POSIX sh, so a POSIX-compatible
  shell (WSL, Git Bash) is required.
- **Supported languages are fixed at TS/Python/Java/C·C++/SQL.** There's no
  plan to add more.
- **The server-side backstop only ships a GitHub Actions example.** There's
  no example for other platforms like GitLab CI.
- **Structuring commit history as semi-structured data is as far as this
  project's scope goes.** A tool that actually parses or turns that data
  into training data isn't included.
- **Non-Claude-Code AI tools' `AI-Model` value is self-reported.** Unlike
  Claude Code, it isn't verified against a session transcript — whatever the
  user sets in `gitformat.aiModel` is trusted as-is.

## 📄 License

MIT — full text: [`LICENSE`](./LICENSE)

> ⚠️ `docs/references/pro-git/` is the one exception, under CC BY-NC-SA 3.0
> (non-commercial) — see
> [`VENDORING.md`](./docs/references/pro-git/VENDORING.md).
