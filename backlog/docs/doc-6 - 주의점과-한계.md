---
id: doc-6
title: 주의점과 한계
type: guide
created_date: '2026-09-19 05:27'
updated_date: '2026-09-19 09:33'
---
## ⚠️ 주의점

- **`core.hooksPath`는 로컬 훅을 완전히 대체합니다.** 기존에 `.git/hooks/`에 다른 훅을
  쓰고 있었다면 install.sh 실행 전에 충돌 여부를 확인하세요.
- **push 단계는 아예 훅하지 않습니다.** git-format은 `commit-msg`/`pre-commit`/
  `post-commit`(커밋 단계)까지만 다루고, `git push`는 평범한 push입니다(decision-12) —
  테스트/빌드 실행이나 `--no-verify` 탐지 같은 것도 없습니다. 로컬 훅은 애초에
  `rm -rf .git/hooks`로도 완전히 우회 가능하므로, git-format의 보장은 "우회
  불가능"이 아니라 "정상적인 사용에서 흔적을 남긴다"는 것뿐입니다. push 단계까지
  막는 서버사이드 백스톱(예: CI 필수 status check, 서버 pre-receive 훅)은 이
  프로젝트 범위 밖입니다 — git-format은 클라이언트측 훅만 제공합니다(decision-11).
  필요하면 컨슈머가 직접 구성해야 하고, `hooks/commit-msg`/`hooks/pre-commit`을
  그대로 호출하는 방식으로 재사용할 수 있습니다.
- **`post-commit`이 커밋 해시를 amend로 바꿀 수 있습니다.** Verify-Bypassed나 AI 귀속
  트레일러가 붙을 때마다 커밋이 한 번 더 amend됩니다 — 커밋 해시를 미리 캐싱하는
  외부 도구가 있다면 이 점을 인지해야 합니다.
- **비-Claude-Code AI 도구는 설정 없이 커밋이 막힐 수 있습니다.** `AI_AGENT` 환경변수가
  감지되는데 `gitformat.aiModel`을 안 정했다면 `commit-msg`가 거부합니다(doc-4
  "커스터마이즈 가이드" 참고).

## 🚧 한계 및 향후 검토 과제

- **Windows를 네이티브로 지원하지 않습니다.** 훅이 POSIX sh로 작성돼 있어 WSL이나
  Git Bash 같은 POSIX 호환 셸이 필요합니다.
- **지원 언어는 TS/Python/Java/C·C++/SQL 5종으로 고정돼 있습니다.** 확대 계획은
  없습니다.
- **push 단계 검증(테스트/빌드 포함)은 의도적으로 이 프로젝트 범위 밖입니다**
  (decision-11, decision-12). git-format은 커밋 단계(`commit-msg`/`pre-commit`/
  `post-commit`)까지만 다룹니다 — 필요하면 컨슈머가 자체 CI나 서버 pre-receive
  훅에서 `hooks/commit-msg`/`hooks/pre-commit`을 직접 호출해 구성해야 합니다.
- **커밋 이력을 반정형 데이터로 남기는 것까지가 이 프로젝트의 범위입니다.** 그
  데이터를 실제로 파싱하거나 학습용으로 가공하는 도구는 포함돼 있지 않습니다.
- **비-Claude-Code AI 도구의 `AI-Model` 값은 자가신고 수준입니다.** Claude Code처럼
  세션 트랜스크립트로 검증하지 않고, 사용자가 `gitformat.aiModel`에 설정한 값을
  그대로 신뢰합니다. Cursor/GitHub Copilot CLI/Aider/Cline/Windsurf/OpenAI Codex
  CLI/Google Gemini CLI/Amazon Q Developer CLI를 조사했지만, Claude Code처럼
  "앱이 직접 주입하는 세션 상관관계 채널 + API 응답이 확정한 model 값"을 동시에
  제공하는 도구는 찾지 못했습니다(decision-15). 가장 근접한 OpenAI Codex CLI도
  세션 로그의 model 필드가 로컬 설정값을 그대로 옮겨 적은 것으로 보여 자가신고와
  신뢰 수준이 같았습니다.
