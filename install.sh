#!/bin/sh
# git-format 설치 스크립트: 기존 저장소에 core.hooksPath와 commit.template을 설정한다
# (decision-2). 이 스크립트가 위치한 git-format 클론 자체를 훅 소스로 사용한다.
#
# 사용법:
#   /path/to/git-format/install.sh [target-repo-dir]
# target-repo-dir을 생략하면 현재 디렉터리를 대상으로 한다.
set -eu

SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOKS_DIR="${SELF_DIR}/hooks"
GITMESSAGE="${SELF_DIR}/.gitmessage"

TARGET=""
for arg in "$@"; do
  case "$arg" in
    -*) ;;
    *) TARGET="$arg" ;;
  esac
done
TARGET="${TARGET:-$(pwd)}"
TARGET="$(cd "$TARGET" && pwd)"

if ! git -C "$TARGET" rev-parse --git-dir >/dev/null 2>&1; then
  echo "install.sh: ${TARGET}는 git 저장소가 아닙니다." >&2
  exit 1
fi

git -C "$TARGET" config core.hooksPath "$HOOKS_DIR"
git -C "$TARGET" config commit.template "$GITMESSAGE"

echo "git-format: ${TARGET} 설정 완료"
echo "  core.hooksPath  = ${HOOKS_DIR}"
echo "  commit.template = ${GITMESSAGE}"
