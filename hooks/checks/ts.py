#!/usr/bin/env python3
# TypeScript/JavaScript 체크: pre-commit 디스패처가 package.json 감지 시 호출한다.
# npm이 없거나 lint 스크립트/tsconfig.json이 없으면 해당 검사만 조용히 건너뛴다.
# tsc는 스테이징된 파일만 검사한다(GF-115) — 저장소 전체를 보면 이번 커밋과 무관한
# 기존 타입 에러까지 커밋을 막는다(false blocking). npm run lint은 이유가 있어
# 저장소 전체로 남는다(아래 주석 참고).
import json
import os
import shutil
import subprocess
import sys

# tsc에 넘길 스테이징 파일을 고르는 pathspec. .js/.jsx는 넣지 않는다 - allowJs가
# 아닌 프로젝트에서 .js를 파일 목록에 넣으면 타입 에러와 무관한 사용법 에러로
# 커밋이 막힌다.
EXTENSIONS = ["*.ts", "*.tsx", "*.mts", "*.cts"]

os.chdir(sys.argv[1])

if not shutil.which("npm"):
    print("[git-format] ts: npm을 찾을 수 없어 건너뜀")
    sys.exit(0)

# "lint": 문자열을 grep하면 scripts 밖(예: devDependencies의 lint 패키지명)도
# 오탐한다(GF-39). package.json을 실제로 파싱해 scripts.lint만 본다.
# 파일이 없거나 JSON이 깨졌으면 lint 스크립트가 없는 것으로 취급한다.
try:
    with open("package.json", encoding="utf-8") as f:
        has_lint = bool(json.load(f).get("scripts", {}).get("lint"))
except (OSError, ValueError, AttributeError):
    has_lint = False

# lint만은 저장소 전체 스코프로 남긴다(GF-115) - 이건 컨슈머가 직접 쓴 package.json
# 스크립트라서 파일 인자를 덧붙였을 때의 계약을 알 수 없다: `eslint .`처럼 경로를
# 이미 박아둔 스크립트는 인자를 받아도 좁혀지지 않고, 인자를 예상하지 않는 스크립트는
# 오히려 깨진다.
if has_lint:
    print("[git-format] ts: npm run lint", flush=True)
    returncode = subprocess.run(
        ["npm", "run", "--silent", "lint"], encoding="utf-8", check=False
    ).returncode
    if returncode != 0:
        sys.exit(returncode)
else:
    print("[git-format] ts: package.json에 lint 스크립트가 없어 건너뜀")

if not os.path.isfile("tsconfig.json"):
    sys.exit(0)

# npx --no-install은 PATH가 아니라 npm/npx 자체의 전역 설치 조회 경로를 따로
# 참조한다 - PATH에서 tsc를 찾아내도(예: 버전 매니저 shim) npx의 조회 경로가
# 다르면 "npx canceled due to missing packages"로 실패해 타입 에러가 없는 정상
# 커밋까지 막는다(실측 확인, GF-79). 그래서 npx를 거치지 않고 존재를 확인한
# tsc(로컬 devDependency 우선, 없으면 PATH의 tsc)를 직접 실행한다.
if os.access("node_modules/.bin/tsc", os.X_OK):
    TSC = "node_modules/.bin/tsc"
elif shutil.which("tsc"):
    TSC = "tsc"
else:
    print("[git-format] ts: tsconfig.json은 있지만 tsc를 찾을 수 없어 건너뜀")
    sys.exit(0)

# 확장자 목록은 셸을 거치지 않고 pathspec 인자로 그대로 넘어가므로 글롭이 실제
# 파일시스템에서 먼저 펼쳐질 여지가 없다(GF-81). --diff-filter의 R은 리네임하면서
# 수정한 파일도 검사하기 위한 것이다(GF-37).
diff = subprocess.run(
    [
        "git",
        "diff",
        "--cached",
        "--name-only",
        "-z",
        "--diff-filter=ACMR",
        "--",
        *EXTENSIONS,
    ],
    capture_output=True,
    encoding="utf-8",
    check=False,
)
# git diff 실패는 커밋을 막지 않고 "검사할 파일 없음"으로 흘린다(cpp.py/sql.py와 같은 fail-open).
FILES = (
    [name for name in diff.stdout.split("\0") if name] if diff.returncode == 0 else []
)

if not FILES:
    print("[git-format] ts: 스테이징된 TypeScript 파일 없음, tsc 건너뜀")
    sys.exit(0)

# 스테이징 범위로 좁히되 `tsc --noEmit <파일>` 형태는 절대 쓰지 않는다(GF-115) - 파일
# 인자를 주면 tsc가 tsconfig.json을 아예 무시해서 strict에서만 잡히는 타입 에러가
# 조용히 통과한다(실측 확인: 파일 인자는 exit 0, `tsc --noEmit`은 exit 2). 대신
# 프로젝트 tsconfig.json 옆에 그걸 extends하는 임시 프로젝트 파일을 써서
# compilerOptions는 그대로 물려받고 검사 대상만 스테이징 파일로 바꾼다.
# - files의 상대 경로는 이 파일이 놓인 디렉터리(= 저장소 루트) 기준이고 git diff가
#   주는 경로도 저장소 루트 기준이라 그대로 맞는다.
# - include는 []로 덮어써야 한다 - extends는 같은 이름의 키만 덮으므로 원본의
#   include가 그대로 남아 스테이징되지 않은 파일까지 다시 끌려온다(실측 확인).
TMP_PROJECT = f"tsconfig.gitformat-{os.getpid()}.json"
with open(TMP_PROJECT, "w", encoding="utf-8") as f:
    json.dump({"extends": "./tsconfig.json", "files": FILES, "include": []}, f)

print("[git-format] ts: tsc --noEmit (스테이징된 파일만)", flush=True)
try:
    returncode = subprocess.run(
        [TSC, "-p", TMP_PROJECT, "--noEmit"], encoding="utf-8", check=False
    ).returncode
finally:
    # 임시 프로젝트 파일은 tsc가 실패해도 반드시 지운다.
    try:
        os.remove(TMP_PROJECT)
    except OSError:
        pass
sys.exit(returncode)
