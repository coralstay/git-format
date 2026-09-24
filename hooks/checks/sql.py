#!/usr/bin/env python3
# SQL 체크: pre-commit 디스패처가 .sqlfluff 설정 또는 추적된 .sql 파일 감지 시 호출한다.
# 스테이징된 .sql 파일에 대해서만 sqlfluff lint를 실행한다(decision-6).
import os
import shutil
import subprocess
import sys

HOOK_DIR = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))
CONF = os.path.join(HOOK_DIR, "gitformat.conf")
# gitformat.conf 자체를 못 읽으면 이후 git config --file 읽기가 하나씩 실패하면서
# 원인을 알기 어려운 에러로 이어진다. 여기서 미리 검증해 원인을 명확히 알려준다.
# 이 블록은 CONF를 읽는 다른 파일들에도 byte-identical하게 있다.
if subprocess.run(
    ["git", "config", "--file", CONF, "--list"],
    stdout=subprocess.DEVNULL,
    stderr=subprocess.DEVNULL,
    encoding="utf-8",
    check=False,
).returncode != 0:
    print(f"gitformat: gitformat.conf를 읽을 수 없습니다: {CONF}", file=sys.stderr)
    sys.exit(1)

os.chdir(sys.argv[1])

if not shutil.which("sqlfluff"):
    print("[git-format] sql: sqlfluff를 찾을 수 없어 건너뜀")
    sys.exit(0)

# --diff-filter의 R은 리네임하면서 수정한 파일도 검사하기 위한 것이다(GF-37).
diff = subprocess.run(
    ["git", "diff", "--cached", "--name-only", "-z", "--diff-filter=ACMR", "--", "*.sql"],
    capture_output=True,
    encoding="utf-8",
    check=False,
)
# git diff 실패는 커밋을 막지 않고 "검사할 파일 없음"으로 흘린다(원본과 동일한 fail-open).
FILES = [name for name in diff.stdout.split("\0") if name] if diff.returncode == 0 else []

if not FILES:
    print("[git-format] sql: 스테이징된 .sql 파일 없음, 건너뜀")
    sys.exit(0)

# sqlfluff는 dialect가 없으면(설정도, 플래그도) 린트가 아니라 사용법 에러(exit 2)로
# 실패한다(GF-22). .sqlfluff 설정이 있으면 그 dialect를 그대로 쓰고, 없을 때만
# 범용 기본값(gitformat.conf의 sqlDialectDefault)을 명시적으로 넘긴다.
ARGS = ["lint"]
if not os.path.isfile(".sqlfluff"):
    # git config --get은 키가 없어도 빈 문자열로 성공할 수 있다(GF-35).
    dialect = subprocess.run(
        ["git", "config", "--file", CONF, "--get", "gitformat.sqlDialectDefault"],
        capture_output=True,
        encoding="utf-8",
        check=False,
    ).stdout.rstrip("\n")
    if dialect:
        ARGS += ["--dialect", dialect]

print("[git-format] sql: sqlfluff lint", flush=True)
sys.exit(
    subprocess.run(["sqlfluff", *ARGS, *FILES], encoding="utf-8", check=False).returncode
)
