#!/bin/sh
# git-format 설치 스크립트: 기존 저장소에 core.hooksPath와 commit.template을 설정한다
# (decision-2). 이 스크립트가 위치한 git-format 클론 자체를 훅 소스로 사용한다.
#
# 사용법:
#   /path/to/git-format/install.sh [target-repo-dir]
# target-repo-dir을 생략하면 현재 디렉터리를 대상으로 한다.
set -eu

SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly SELF_DIR
HOOKS_DIR="${SELF_DIR}/hooks"
readonly HOOKS_DIR
GITMESSAGE="${SELF_DIR}/.gitmessage"
readonly GITMESSAGE
TEMPLATE_DIR="${SELF_DIR}/template"
readonly TEMPLATE_DIR
CONF="${HOOKS_DIR}/gitformat.conf"
readonly CONF
# gitformat.conf 자체를 못 읽으면(파일 없음/문법 깨짐) 이후 모든 git config
# --file 읽기가 하나씩 실패하면서 원인을 알기 어려운 에러로 이어진다. 여기서
# 미리 검증해 원인을 명확히 알려준다. 이 블록은 CONF를 읽는 다른 파일들에도
# byte-identical하게 있다(tests/consistency.bats가 동일성을 보장).
if ! git config --file "$CONF" --list >/dev/null 2>&1; then
  echo "gitformat: gitformat.conf를 읽을 수 없습니다: ${CONF}" >&2
  exit 1
fi

GLOBAL_MODE="ask"
TARGET=""
for arg in "$@"; do
  case "$arg" in
    --global) GLOBAL_MODE="yes" ;;
    --no-global) GLOBAL_MODE="no" ;;
    -*) echo "install.sh: 알 수 없는 옵션: $arg" >&2; exit 1 ;;
    *) TARGET="$arg" ;;
  esac
done
TARGET="${TARGET:-$(pwd)}"
TARGET="$(cd "$TARGET" && pwd)"
readonly TARGET

if ! git -C "$TARGET" rev-parse --git-dir >/dev/null 2>&1; then
  echo "install.sh: ${TARGET}는 git 저장소가 아닙니다." >&2
  exit 1
fi

git -C "$TARGET" config core.hooksPath "$HOOKS_DIR"
git -C "$TARGET" config commit.template "$GITMESSAGE"

echo "git-format: ${TARGET} 설정 완료"
echo "  core.hooksPath  = ${HOOKS_DIR}"
echo "  commit.template = ${GITMESSAGE}"

# C/C++ 프로젝트(CMakeLists.txt/Makefile)면 pre-push가 cmake 빌드 시 만드는
# .gitformat-build/ 산출물을 실수로 커밋하지 않도록 .gitignore에 등록한다
# (마커 파일명은 gitformat.conf에서 읽어 pre-commit/pre-push와 같은 값을 쓴다).
MARKER_CPP="$(git config --file "$CONF" --get gitformat.marker.cpp)"
readonly MARKER_CPP
MARKER_CPP_MAKE="$(git config --file "$CONF" --get gitformat.marker.cppMake)"
readonly MARKER_CPP_MAKE
BUILD_DIR_NAME="$(git config --file "$CONF" --get gitformat.buildDir)"
readonly BUILD_DIR_NAME
if [ -f "${TARGET}/${MARKER_CPP}" ] || [ -f "${TARGET}/${MARKER_CPP_MAKE}" ]; then
  if ! grep -qxF "${BUILD_DIR_NAME}/" "${TARGET}/.gitignore" 2>/dev/null; then
    printf '%s\n' "${BUILD_DIR_NAME}/" >> "${TARGET}/.gitignore"
    echo "git-format: .gitignore에 ${BUILD_DIR_NAME}/ 추가함"
  fi
fi

sync_template() {
  mkdir -p "${TEMPLATE_DIR}/hooks"
  for h in "${HOOKS_DIR}"/*; do
    [ -f "$h" ] || continue
    ln -sf "$h" "${TEMPLATE_DIR}/hooks/$(basename "$h")"
  done
}

# 전역 init.templateDir(decision-2): 앞으로 git init/clone하는 모든 새 저장소에
# 자동으로 훅이 심어지게 한다. template/hooks/*는 이 클론 위치를 가리키는 절대경로
# 심볼릭 링크로 그때그때 생성한다(GF-9). --global/--no-global로 비대화형 지정 가능.
case "$GLOBAL_MODE" in
  yes)
    sync_template
    git config --global init.templateDir "$TEMPLATE_DIR"
    git config --global commit.template "$GITMESSAGE"
    echo "git-format: 전역 init.templateDir/commit.template 설정 완료 (앞으로 만드는 새 저장소에 자동 적용)"
    ;;
  no)
    echo "git-format: 전역 설정은 건너뜁니다."
    ;;
  ask)
    if [ -t 0 ]; then
      printf '전역(init.templateDir)도 설정해 앞으로 만드는 모든 새 저장소에 자동 적용할까요? [y/N] '
      read -r answer
      case "$answer" in
        y|Y|yes|YES)
          sync_template
          git config --global init.templateDir "$TEMPLATE_DIR"
          git config --global commit.template "$GITMESSAGE"
          echo "git-format: 전역 init.templateDir/commit.template 설정 완료."
          ;;
        *)
          echo "git-format: 전역 설정은 건너뜁니다. 나중에: ${SELF_DIR}/install.sh --global"
          ;;
      esac
    else
      echo "git-format: 비대화형 환경이라 전역 설정은 건너뜁니다. --global로 자동 적용 가능."
    fi
    ;;
esac

echo "git-format: 참고 - git push --no-verify는 로컬 훅으로 탐지할 수 없습니다."
echo "  push 단계까지 막는 서버사이드 백스톱은 git-format 범위 밖입니다 - 필요하면"
echo "  직접 구성하세요 (README의 '--no-verify 우회 탐지' 참고)."
