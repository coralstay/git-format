"""gitformat.conf의 marker 값 해석 규약을 고정한다(구 marker-semantics.bats, GF-118).

sh 시절 pre-commit/checks/java.sh는 `ls ${MARKER_JAVA_GRADLE}`처럼 일부러 unquoted
glob 확장을 썼고(shellcheck disable=SC2086), 마커 값에 공백이 섞이면 단어 분리 때문에
의도하지 않은 파일이 매칭될 수 있었다. Python 전환(decision-16) 후에는 값이
glob.glob()/os.path.isfile()에 단일 인자로 넘어가 단어 분리가 원리적으로 일어나지
않는다 — 그 사실을 회귀로 고정한다.

동시에 "어떤 키가 글롭이고 어떤 키가 리터럴인가"라는 비대칭도 고정한다. 리터럴 키에
글롭을 넣으면 에러가 아니라 조용한 미매칭이 되므로, 이 동작이 의도된 것임을 테스트로
남겨둔다(gitformat.conf 주석 및 doc-4와 같은 내용).

진짜 저장소의 hooks/gitformat.conf는 건드리지 않는다 — 매 테스트마다 hooks/를 임시
디렉터리에 복사해 그 사본의 마커 값만 바꾼다.

java.py는 mvn/gradlew가 없으면 "건너뜀"을 출력하고 끝낸다 — 이 출력이 곧 "pre-commit이
java를 감지해 체크를 실행했다"는 신호다. 감지 여부만 보고 싶으므로 mvn이 설치된
환경에서 실제 빌드가 돌지 않도록 PATH에서 mvn을 뺀 채 커밋한다(gradlew는 저장소에
없으니 따로 뺄 필요가 없다).
"""

import unittest

from isolated_repo import IsolatedRepoTestCase

JAVA_RAN = "java: mvn/gradlew를 찾을 수 없어 건너뜀"


class LanguageDetectionTest(IsolatedRepoTestCase):
    def setUp(self):
        self.hooks_copy = self.copy_hooks()
        self.repo = self.make_repo(hooks_path=self.hooks_copy)
        self.shadow_path = self.path_without("mvn")

    def set_marker(self, key, value):
        self.git_ok(
            "config",
            "--file",
            self.hooks_copy / "gitformat.conf",
            f"gitformat.marker.{key}",
            value,
        )

    def commit_without_mvn(self, message):
        return self.commit(message, env={"PATH": str(self.shadow_path)})

    # ── 단어 분리가 일어나지 않는다 (GF-118 원래 위험) ──────────────

    def test_공백이_든_글롭_마커는_한_경로로_취급된다(self):
        """[GF-118] 공백이 든 글롭 마커 값은 한 경로로 취급된다 - 그 이름의 파일이 있으면 감지된다"""
        self.set_marker("javaGradle", "a b")
        self.write("a b", "")
        self.git_ok("add", "a b")
        result = self.commit_without_mvn("[feat] space marker matches whole path")
        self.assertAccepted(result)
        self.assertIn(JAVA_RAN, result.output)

    def test_공백이_든_글롭_마커는_단어_분리되지_않는다(self):
        """[GF-118] 공백이 든 글롭 마커 값은 단어 분리되지 않는다 - 'a'와 'b'가 따로 있어도 감지되지 않는다"""
        # sh의 `ls ${VAR}`였다면 'a'가 매칭돼 java 체크가 실행됐을 입력이다.
        self.set_marker("javaGradle", "a b")
        self.write("a", "")
        self.write("b", "")
        self.git_ok("add", "a", "b")
        result = self.commit_without_mvn("[feat] split words must not match")
        self.assertAccepted(result)
        self.assertNotIn(JAVA_RAN, result.output)

    def test_글롭_마커의_메타문자는_glob으로_확장된다(self):
        """[GF-118] 글롭 마커 값의 메타문자는 셸이 아니라 glob으로 확장된다"""
        self.set_marker("javaGradle", "build.gradle*")
        self.write("build.gradle.kts", "")
        self.git_ok("add", "build.gradle.kts")
        result = self.commit_without_mvn("[feat] glob metachar expands")
        self.assertAccepted(result)
        self.assertIn(JAVA_RAN, result.output)

    # ── 리터럴 키 vs 글롭 키 비대칭 ─────────────────────────────────

    def test_리터럴_마커_키에_글롭을_넣으면_조용히_미매칭된다(self):
        """[GF-118] 리터럴 마커 키에 글롭을 넣으면 확장되지 않고 조용히 미매칭된다"""
        # marker.java는 os.path.isfile()로 보는 리터럴 경로다. javaGradle은 이 저장소에
        # build.gradle*이 없어 매칭되지 않으므로, 감지 여부는 marker.java만으로 결정된다.
        self.set_marker("java", "pom*.xml")
        self.write("pom.xml", "")
        self.git_ok("add", "pom.xml")
        result = self.commit_without_mvn("[feat] literal key does not glob")
        self.assertAccepted(result)
        self.assertNotIn(JAVA_RAN, result.output)

    def test_리터럴_마커_키에_정확한_파일명은_감지된다(self):
        """[GF-118] 리터럴 마커 키에 정확한 파일명을 넣으면 감지된다 (위 테스트의 대조군)"""
        self.set_marker("java", "pom.xml")
        self.write("pom.xml", "")
        self.git_ok("add", "pom.xml")
        result = self.commit_without_mvn("[feat] literal key matches exact name")
        self.assertAccepted(result)
        self.assertIn(JAVA_RAN, result.output)

    def test_글롭_키에_리터럴_파일명도_동작한다(self):
        """[GF-118] 글롭 키에는 리터럴 파일명을 넣어도 동작한다 (글롭은 리터럴의 상위 집합)"""
        self.set_marker("javaGradle", "build.gradle")
        self.write("build.gradle", "")
        self.git_ok("add", "build.gradle")
        result = self.commit_without_mvn("[feat] glob key accepts literal name")
        self.assertAccepted(result)
        self.assertIn(JAVA_RAN, result.output)


if __name__ == "__main__":
    unittest.main()
