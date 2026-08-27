#!/bin/sh
# SQL 체크: pre-commit 디스패처가 .sqlfluff 설정 또는 추적된 .sql 파일 감지 시 호출한다.
# 스테이징된 .sql 파일에 대해서만 sqlfluff lint를 실행한다(decision-6).
set -eu

# 이 훅 스크립트가 심볼릭 링크로 호출될 가능성에 대비해 실제 위치를 해석한다.
# 이 함수는 이 파일 안에서만 쓰인다(cpp.sh 등 다른 체크 스크립트도 각자 자기
# 파일에 동일 함수를 독립적으로 갖고 있다 — 로직은 공유하지 않는다는 게
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
CONF="${HOOK_DIR}/gitformat.conf"

REPO_ROOT="$1"
cd "$REPO_ROOT"

if ! command -v sqlfluff >/dev/null 2>&1; then
  echo "[git-format] sql: sqlfluff를 찾을 수 없어 건너뜀"
  exit 0
fi

# NUL로 구분해 공백 포함 파일명도 안전하게 다룬다(GF-36, cpp.sh와 동일 이유로
# 임시 파일 사용). --diff-filter에 R(rename)도 포함한다(GF-37).
FILELIST="$(mktemp)"
trap 'rm -f "$FILELIST"' EXIT

git diff --cached --name-only -z --diff-filter=ACMR -- '*.sql' > "$FILELIST" || true

if [ ! -s "$FILELIST" ]; then
  echo "[git-format] sql: 스테이징된 .sql 파일 없음, 건너뜀"
  exit 0
fi

# sqlfluff는 dialect가 없으면(설정도, 플래그도) 린트가 아니라 사용법 에러(exit 2)로
# 실패한다(GF-22 실도구 재검증에서 발견). .sqlfluff 설정이 있으면 그 dialect를 그대로
# 쓰고, 없을 때만 범용 기본값(gitformat.conf의 sqlDialectDefault)을 명시적으로 넘긴다.
set -- lint
if [ ! -f .sqlfluff ]; then
  SQL_DIALECT_DEFAULT="$(git config --file "$CONF" --get gitformat.sqlDialectDefault)"
  set -- "$@" --dialect "$SQL_DIALECT_DEFAULT"
fi

echo "[git-format] sql: sqlfluff lint"
xargs -0 sqlfluff "$@" < "$FILELIST"
