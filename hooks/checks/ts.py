#!/usr/bin/env python3
# TypeScript/JavaScript 체크: pre-commit 디스패처가 package.json 감지 시 호출한다.
# npm이 없거나 lint 스크립트/tsconfig.json이 없으면 해당 검사만 조용히 건너뛴다.
import json
import os
import shutil
import subprocess
import sys

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

if has_lint:
    print("[git-format] ts: npm run lint", flush=True)
    returncode = subprocess.run(
        ["npm", "run", "--silent", "lint"], encoding="utf-8", check=False
    ).returncode
    if returncode != 0:
        sys.exit(returncode)
else:
    print("[git-format] ts: package.json에 lint 스크립트가 없어 건너뜀")

# npx --no-install은 PATH가 아니라 npm/npx 자체의 전역 설치 조회 경로를 따로
# 참조한다 - PATH에서 tsc를 찾아내도(예: 버전 매니저 shim) npx의 조회 경로가
# 다르면 "npx canceled due to missing packages"로 실패해 타입 에러가 없는 정상
# 커밋까지 막는다(실측 확인, GF-79). 그래서 npx를 거치지 않고 존재를 확인한
# tsc(로컬 devDependency 우선, 없으면 PATH의 tsc)를 직접 실행한다.
if os.path.isfile("tsconfig.json"):
    if os.access("node_modules/.bin/tsc", os.X_OK):
        tsc = "node_modules/.bin/tsc"
    elif shutil.which("tsc"):
        tsc = "tsc"
    else:
        tsc = None

    if tsc is None:
        print("[git-format] ts: tsconfig.json은 있지만 tsc를 찾을 수 없어 건너뜀")
    else:
        print("[git-format] ts: tsc --noEmit", flush=True)
        sys.exit(subprocess.run([tsc, "--noEmit"], encoding="utf-8", check=False).returncode)
