#!/bin/sh
# Java 체크: pre-commit 디스패처가 pom.xml/build.gradle* 감지 시 호출한다.
# 컴파일까지만 확인한다(테스트/verify는 무거우므로 pre-push(GF-5)로 미룬다).
set -eu

REPO_ROOT="$1"
readonly REPO_ROOT
cd "$REPO_ROOT"

if [ -f pom.xml ] && command -v mvn >/dev/null 2>&1; then
  # -o(오프라인)는 플러그인 캐시가 없는 첫 실행에서 "Plugin ... could not be
  # resolved"로 실패한다(GF-22 실도구 재검증에서 발견). 온라인으로 실행한다.
  echo "[git-format] java: mvn -q compile"
  mvn -q compile
elif ls build.gradle* >/dev/null 2>&1 && [ -x ./gradlew ]; then
  echo "[git-format] java: ./gradlew -q compileJava"
  ./gradlew -q compileJava
else
  echo "[git-format] java: mvn/gradlew를 찾을 수 없어 건너뜀"
fi
