#!/usr/bin/env python3
# C/C++ 체크: pre-commit 디스패처가 CMakeLists.txt/Makefile 감지 시 호출한다.
# 스테이징된 C/C++ 파일에 대해서만 clang-format 포맷 검사를 한다(빌드/테스트는
# git-format 범위 밖이다, decision-12).
import os
import shutil
import subprocess
import sys

# 로케일이 UTF-8을 제공하지 않는 환경에서는 Python의 stdout 인코딩이 ascii로 떨어져,
# 이 파일의 한국어 메시지를 출력하는 순간 UnicodeEncodeError로 훅이 죽는다 — "도구가
# 없어 건너뜀"처럼 무해해야 하는 경로에서도 커밋이 트레이스백과 함께 막힌다(GF-116
# 실측: LC_ALL=C에 C.UTF-8이 없는 조건을 재현해 확인). sh 시절의 LC_ALL=C.UTF-8
# 하드코딩(GF-83)은 Python 전환으로 사라졌지만, 같은 위험이 출력 인코딩으로 옮겨온
# 것이다. 메시지는 UTF-8로 쓰여 있으니 출력 인코딩도 UTF-8로 고정한다 — 터미널이
# UTF-8을 못 읽으면 글자가 깨져 보이지만, 죽어서 커밋을 막는 것보다 낫다.
# errors="replace"는 서로게이트 등 인코딩 불가 문자에서도 죽지 않게 하는 보험이다.
for _stream in (sys.stdout, sys.stderr):
    try:
        _stream.reconfigure(encoding="utf-8", errors="replace")
    except (AttributeError, ValueError, OSError):
        pass

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

EXTENSIONS = [
    line
    for line in subprocess.run(
        ["git", "config", "--file", CONF, "--get-all", "gitformat.cpp.ext"],
        capture_output=True,
        encoding="utf-8",
        check=False,
    ).stdout.splitlines()
    if line
]

os.chdir(sys.argv[1])

if not shutil.which("clang-format"):
    print("[git-format] cpp: clang-format을 찾을 수 없어 건너뜀")
    sys.exit(0)

# 확장자 목록은 셸을 거치지 않고 pathspec 인자로 그대로 넘어가므로 글롭이
# 실제 파일시스템에서 먼저 펼쳐질 여지가 없다(GF-81). --diff-filter의 R은
# 리네임하면서 수정한 파일도 검사하기 위한 것이다(GF-37).
diff = subprocess.run(
    ["git", "diff", "--cached", "--name-only", "-z", "--diff-filter=ACMR", "--", *EXTENSIONS],
    capture_output=True,
    encoding="utf-8",
    check=False,
)
# git diff 실패는 커밋을 막지 않고 "검사할 파일 없음"으로 흘린다(원본과 동일한 fail-open).
FILES = [name for name in diff.stdout.split("\0") if name] if diff.returncode == 0 else []

if not FILES:
    print("[git-format] cpp: 스테이징된 C/C++ 파일 없음, 건너뜀")
    sys.exit(0)

print("[git-format] cpp: clang-format --dry-run -Werror", flush=True)
sys.exit(
    subprocess.run(
        ["clang-format", "--dry-run", "-Werror", *FILES], encoding="utf-8", check=False
    ).returncode
)
