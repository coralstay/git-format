"""Java 체크(hooks/checks/java.py)를 실제 mvn으로 검증한다(구 checks-java.bats).

GF-22: `mvn -q -o compile`(오프라인)은 플러그인 캐시가 없는 환경에서 "Plugin ...
could not be resolved"로 항상 실패한다는 걸 실도구 테스트로 발견해 -o를 제거했다 —
이 회귀를 고정한다. 네트워크가 필요해 느릴 수 있다.
"""

import unittest

from isolated_repo import IsolatedRepoTestCase

POM = """<project xmlns="http://maven.apache.org/POM/4.0.0">
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.example</groupId>
  <artifactId>gf22-test</artifactId>
  <version>1.0</version>
  <properties>
    <maven.compiler.source>17</maven.compiler.source>
    <maven.compiler.target>17</maven.compiler.target>
  </properties>
</project>
"""

HELLO = """public class Hello {
  public static void main(String[] args) {
    System.out.println("hi");
  }
}
"""

BROKEN_HELLO = """public class Hello {
  this is not valid java
}
"""


class LintJavaTest(IsolatedRepoTestCase):
    def setUp(self):
        super().setUp()
        self.write("pom.xml", POM)

    def test_컴파일되는_Java_코드는_통과한다(self):
        """컴파일되는 Java 코드는 통과한다"""
        self.write("src/main/java/Hello.java", HELLO)
        self.git_ok("add", "pom.xml", "src")
        self.assertAccepted(self.commit("[feat][java] add hello world"))

    def test_컴파일_에러는_실제_mvn이_차단한다(self):
        """컴파일 에러가 있는 Java 코드는 실제 mvn이 차단한다"""
        self.write("src/main/java/Hello.java", BROKEN_HELLO)
        self.git_ok("add", "pom.xml", "src")
        self.assertRejected(self.commit("[feat][java] add broken hello"))

    def test_mvn이_없으면_조용히_건너뛴다(self):
        """mvn이 없으면 조용히 건너뛴다"""
        shadow = self.path_without("mvn")
        self.write("src/main/java/Hello.java", BROKEN_HELLO)
        self.git_ok("add", "pom.xml", "src")
        self.assertAccepted(
            self.commit("[feat][java] no mvn on PATH", env={"PATH": str(shadow)})
        )


if __name__ == "__main__":
    unittest.main()
