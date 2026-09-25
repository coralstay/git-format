#!/usr/bin/env python3
# Java 체크: pre-commit 디스패처가 pom.xml/build.gradle* 감지 시 호출한다.
# 컴파일까지만 확인한다(테스트/verify는 git-format 범위 밖이다, decision-12).
#
# 다른 체크(python.py/ts.py/cpp.py/sql.py)와 달리 여기만 스테이징 범위가 아니라
# 프로젝트 전체를 본다(GF-115). mvn/gradle에는 "이 파일들만 컴파일" 모드가 없다 -
# 자바 컴파일은 같은 소스 트리의 다른 클래스를 참조해야 성립하므로 파일 목록만
# 떼어내 컴파일하는 게 애초에 의미가 없다. 그래서 이번 커밋과 무관한 기존 컴파일
# 에러도 커밋을 막을 수 있다는 한계를 그대로 남긴다(checks/readme.md의 스코프 표).
import glob
import os
import shutil
import subprocess
import sys

HOOK_DIR = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))
CONF = os.path.join(HOOK_DIR, "gitformat.conf")
# gitformat.conf 자체를 못 읽으면 이후 git config --file 읽기가 하나씩 실패하면서
# 원인을 알기 어려운 에러로 이어진다. 여기서 미리 검증해 원인을 명확히 알려준다.
# 이 블록은 CONF를 읽는 다른 파일들에도 byte-identical하게 있다.
if (
    subprocess.run(
        ["git", "config", "--file", CONF, "--list"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        encoding="utf-8",
        check=False,
    ).returncode
    != 0
):
    print(f"gitformat: gitformat.conf를 읽을 수 없습니다: {CONF}", file=sys.stderr)
    sys.exit(1)


def conf_get(key):
    # git config --get은 키가 없어도 빈 문자열로 성공할 수 있다(GF-35).
    return subprocess.run(
        ["git", "config", "--file", CONF, "--get", key],
        capture_output=True,
        encoding="utf-8",
        check=False,
    ).stdout.rstrip("\n")


MARKER_JAVA = conf_get("gitformat.marker.java")
MARKER_JAVA_GRADLE = conf_get("gitformat.marker.javaGradle")

os.chdir(sys.argv[1])

if MARKER_JAVA and os.path.isfile(MARKER_JAVA) and shutil.which("mvn"):
    # -o(오프라인)는 플러그인 캐시가 없는 첫 실행에서 "Plugin ... could not be
    # resolved"로 실패한다(GF-22). 온라인으로 실행한다.
    print("[git-format] java: mvn -q compile", flush=True)
    sys.exit(
        subprocess.run(
            ["mvn", "-q", "compile"], encoding="utf-8", check=False
        ).returncode
    )
elif (
    MARKER_JAVA_GRADLE
    and glob.glob(MARKER_JAVA_GRADLE)
    and os.access("./gradlew", os.X_OK)
):
    print("[git-format] java: ./gradlew -q compileJava", flush=True)
    sys.exit(
        subprocess.run(
            ["./gradlew", "-q", "compileJava"], encoding="utf-8", check=False
        ).returncode
    )
else:
    print("[git-format] java: mvn/gradlew를 찾을 수 없어 건너뜀")
