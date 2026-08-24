#!/usr/bin/env bats
# GF-22: Java 체크를 실제 mvn(Maven)으로 검증한다(이전엔 gradle만 실도구였음).
# mvn -q -o compile(오프라인)는 플러그인 캐시가 없는 환경에서 "Plugin ... could
# not be resolved"로 항상 실패한다는 걸 실도구 테스트로 발견해 -o를 제거했다 —
# 이 회귀를 고정한다. 네트워크가 필요해 느릴 수 있다.

load 'helpers/git-format'

setup() {
  make_isolated_repo
  cat > pom.xml <<'EOF'
<project xmlns="http://maven.apache.org/POM/4.0.0">
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.example</groupId>
  <artifactId>gf22-test</artifactId>
  <version>1.0</version>
  <properties>
    <maven.compiler.source>17</maven.compiler.source>
    <maven.compiler.target>17</maven.compiler.target>
  </properties>
</project>
EOF
  mkdir -p src/main/java
}

teardown() {
  cleanup_isolated_repo
}

@test "컴파일되는 Java 코드는 통과한다" {
  cat > src/main/java/Hello.java <<'EOF'
public class Hello {
  public static void main(String[] args) {
    System.out.println("hi");
  }
}
EOF
  git add pom.xml src
  run git commit -m "feat(java): add hello world"
  [ "$status" -eq 0 ]
}

@test "컴파일 에러가 있는 Java 코드는 실제 mvn이 차단한다" {
  cat > src/main/java/Hello.java <<'EOF'
public class Hello {
  this is not valid java
}
EOF
  git add pom.xml src
  run git commit -m "feat(java): add broken hello"
  [ "$status" -ne 0 ]
}

@test "mvn이 없으면 조용히 건너뛴다" {
  cat > src/main/java/Hello.java <<'EOF'
public class Hello {
  this is not valid java
}
EOF
  git add pom.xml src
  PATH="/usr/bin:/bin" run git commit -m "feat(java): no mvn on PATH"
  [ "$status" -eq 0 ]
}
