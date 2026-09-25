#!/usr/bin/env python3
# Python 체크: pre-commit 디스패처가 pyproject.toml/requirements.txt 감지 시 호출한다.
# ruff를 우선 사용하고, 없으면 flake8로 대체한다. 둘 다 없으면 조용히 건너뛴다.
# 스테이징된 Python 파일에만 돌린다 - 저장소 전체(`ruff check .`)를 보면 이번
# 커밋과 무관한 기존 린트 에러까지 커밋을 막는다(false blocking, GF-115).
# ruff/flake8은 둘 다 파일 목록을 인자로 받으므로 스코프를 좁힐 수 있다.
import os
import shutil
import subprocess
import sys

os.chdir(sys.argv[1])

if shutil.which("ruff"):
    LINTER = ["ruff", "check"]
elif shutil.which("flake8"):
    LINTER = ["flake8"]
else:
    print("[git-format] python: ruff/flake8을 찾을 수 없어 건너뜀")
    sys.exit(0)

# 확장자 목록은 셸을 거치지 않고 pathspec 인자로 그대로 넘어가므로 글롭이 실제
# 파일시스템에서 먼저 펼쳐질 여지가 없다(GF-81). --diff-filter의 R은 리네임하면서
# 수정한 파일도 검사하기 위한 것이다(GF-37). .py/.pyi 둘 다 ruff/flake8의 대상이다.
diff = subprocess.run(
    ["git", "diff", "--cached", "--name-only", "-z", "--diff-filter=ACMR", "--", "*.py", "*.pyi"],
    capture_output=True,
    encoding="utf-8",
    check=False,
)
# git diff 실패는 커밋을 막지 않고 "검사할 파일 없음"으로 흘린다(cpp.py/sql.py와 동일한 fail-open).
FILES = [name for name in diff.stdout.split("\0") if name] if diff.returncode == 0 else []

if not FILES:
    print("[git-format] python: 스테이징된 Python 파일 없음, 건너뜀")
    sys.exit(0)

print(f"[git-format] python: {' '.join(LINTER)} (스테이징된 파일만)", flush=True)
sys.exit(subprocess.run([*LINTER, *FILES], encoding="utf-8", check=False).returncode)
