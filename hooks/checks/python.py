#!/usr/bin/env python3
# Python 체크: pre-commit 디스패처가 pyproject.toml/requirements.txt 감지 시 호출한다.
# ruff를 우선 사용하고, 없으면 flake8로 대체한다. 둘 다 없으면 조용히 건너뛴다.
import os
import shutil
import subprocess
import sys

os.chdir(sys.argv[1])

if shutil.which("ruff"):
    print("[git-format] python: ruff check .", flush=True)
    sys.exit(subprocess.run(["ruff", "check", "."], encoding="utf-8", check=False).returncode)
elif shutil.which("flake8"):
    print("[git-format] python: flake8 .", flush=True)
    sys.exit(subprocess.run(["flake8", "."], encoding="utf-8", check=False).returncode)
else:
    print("[git-format] python: ruff/flake8을 찾을 수 없어 건너뜀")
