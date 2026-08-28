#!/bin/sh
# Java 체크: pre-commit 디스패처가 pom.xml/build.gradle* 감지 시 호출한다.
# 컴파일까지만 확인한다(테스트/verify는 무거우므로 pre-push(GF-5)로 미룬다).
set -eu

# 이 훅 스크립트가 심볼릭 링크로 호출될 가능성에 대비해 실제 위치를 해석한다.
# 이 함수는 이 파일 안에서만 쓰인다(다른 체크 스크립트도 각자 자기 파일에
# 동일 함수를 독립적으로 갖고 있다 - 로직은 공유하지 않는다는 게
# gitformat.conf 도입(GF-44) 이후에도 유지되는 설계 원칙이다).
resolve_self() {
  p="$1"
  while [ -L "$p" ]; do
    target="$(readlink "$p")"
    case "$target" in
      /*) p="$target" ;;
      *) p="$(dirname "$p")/$target" ;;
    esac
  done
  printf '%s' "$p"
}
# checks/의 상위 디렉터리(hooks/)에 gitformat.conf가 있다.
HOOK_DIR="$(cd "$(dirname "$(dirname "$(resolve_self "$0")")")" && pwd)"
readonly HOOK_DIR
CONF="${HOOK_DIR}/gitformat.conf"
readonly CONF
MARKER_JAVA="$(git config --file "$CONF" --get gitformat.marker.java)"
readonly MARKER_JAVA
MARKER_JAVA_GRADLE="$(git config --file "$CONF" --get gitformat.marker.javaGradle)"
readonly MARKER_JAVA_GRADLE

REPO_ROOT="$1"
readonly REPO_ROOT
cd "$REPO_ROOT"

# shellcheck disable=SC2086 # 의도적 글롭 확장(예: build.gradle*). 따옴표로 감싸면 리터럴 비교가 되어 깨진다.
if [ -f "$MARKER_JAVA" ] && command -v mvn >/dev/null 2>&1; then
  # -o(오프라인)는 플러그인 캐시가 없는 첫 실행에서 "Plugin ... could not be
  # resolved"로 실패한다(GF-22 실도구 재검증에서 발견). 온라인으로 실행한다.
  echo "[git-format] java: mvn -q compile"
  mvn -q compile
elif ls ${MARKER_JAVA_GRADLE} >/dev/null 2>&1 && [ -x ./gradlew ]; then
  echo "[git-format] java: ./gradlew -q compileJava"
  ./gradlew -q compileJava
else
  echo "[git-format] java: mvn/gradlew를 찾을 수 없어 건너뜀"
fi
