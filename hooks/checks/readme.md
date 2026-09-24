# checks

**무엇인가**: `pre-commit`이 언어를 감지했을 때 호출하는 커밋 전 검사 스크립트 5개를
담는다. 각 스크립트는 저장소 루트 경로를 인자 하나로 받아 그 디렉터리에서 자기
검사만 하고, 결과를 종료 코드로 알린다. 0이 아니면 `pre-commit`이 그 코드를 그대로
전파해 커밋이 막히고 검증 마커도 기록되지 않는다.

**디스패치 메커니즘**: `pre-commit`이 `gitformat.conf`의 `[gitformat "marker"]`
값을 읽어 저장소 루트에 해당 마커 파일이 있는지 보고, 있는 언어의 스크립트만
실행한다.

| 스크립트    | 마커                                       | 외부 도구         |
| ----------- | ------------------------------------------ | ----------------- |
| `ts.py`     | `package.json`                             | npm, tsc          |
| `python.py` | `pyproject.toml` 또는 `requirements.txt`   | ruff, 없으면 flake8 |
| `java.py`   | `pom.xml` 또는 `build.gradle*`             | mvn 또는 `./gradlew` |
| `cpp.py`    | `CMakeLists.txt` 또는 `Makefile`           | clang-format      |
| `sql.py`    | `.sqlfluff` 또는 추적되는 `*.sql`          | sqlfluff          |

마커가 하나도 없으면 아무 것도 실행하지 않고 통과한다. `build.gradle*`와 `*.sql`은
리터럴 파일명이 아니라 글롭이라 각각 글롭 확장과 `git ls-files`로 확인한다.

호출은 `sys.executable`로 한다 — 지금 `pre-commit`을 돌리고 있는 바로 그 인터프리터를
재사용하므로 셔뱅 해석도, 실행 권한도, 별도 런처도 필요 없고, PATH의 `python3`가
`pre-commit`을 띄운 `python3`와 갈라질 여지도 없다. sh 시절에는 실행 권한(`-x`)까지
확인했지만 지금은 파일 존재만 본다.

**각 스크립트가 하는 일**:

- `ts.py` — `package.json`의 `scripts.lint`가 있으면 `npm run lint`. `"lint"`를
  grep하면 `devDependencies`의 패키지명까지 오탐하므로 JSON을 실제로 파싱해
  `scripts.lint`만 본다(GF-39). `tsconfig.json`이 있으면 `tsc --noEmit`를 돌리되
  `npx`를 거치지 않는다 — `npx --no-install`은 PATH가 아니라 npm 자신의 조회 경로를
  보기 때문에 PATH에 `tsc`가 있어도 실패해 정상 커밋을 막는다(GF-79). 그래서
  `node_modules/.bin/tsc` → PATH의 `tsc` 순으로 직접 실행한다.
- `python.py` — `ruff check .`를 우선 쓰고 없으면 `flake8 .`로 대체한다.
- `java.py` — 컴파일까지만 확인한다(테스트/verify는 범위 밖, decision-12).
  `mvn -q compile` 또는 `./gradlew -q compileJava`. `mvn`에 `-o`(오프라인)를 주면
  플러그인 캐시가 없는 첫 실행에서 실패하므로 온라인으로 돌린다(GF-22).
- `cpp.py` — 스테이징된 C/C++ 파일에만 `clang-format --dry-run -Werror`. 확장자
  목록은 `gitformat.conf`의 `gitformat.cpp.ext`에서 읽는다.
- `sql.py` — 스테이징된 `.sql` 파일에만 `sqlfluff lint`. `.sqlfluff` 설정이 없으면
  `gitformat.conf`의 `sqlDialectDefault`를 `--dialect`로 명시해 넘긴다 — dialect가
  아예 없으면 sqlfluff가 린트가 아니라 사용법 에러(exit 2)로 죽는다(GF-22).

공통 규칙이 둘 있다. 첫째, **외부 도구가 없으면 조용히 건너뛰고 0으로 끝낸다** —
도구 부재로 커밋을 막지 않는다. 둘째, 파일 단위로 도는 검사(`cpp.py`/`sql.py`)는
워킹트리 전체가 아니라 `git diff --cached`의 스테이징 파일만 본다.
`--diff-filter=ACMR`의 `R`은 리네임하면서 수정한 파일도 잡기 위한 것이고(GF-37),
확장자 글롭은 셸을 거치지 않고 pathspec 인자로 그대로 넘어가므로 파일시스템에서
미리 펼쳐질 여지가 없다(GF-81).

**언제 쓰나**: 지원 언어를 추가하거나 기존 언어의 검사 내용을 바꿀 때 쓴다. 새
언어를 추가하려면 스크립트 파일 하나와 `gitformat.conf`의 마커 항목, `pre-commit`의
분기 한 줄이 함께 필요하다 — 세 곳 중 하나라도 빠지면 검사가 조용히 안 돈다.
검사 범위를 넓힐 때는 decision-12(무거운 검사는 프로젝트 범위 밖)를 먼저 확인한다.

**관련 명령**:

- `python3 hooks/checks/ts.py "$(git rev-parse --show-toplevel)"` — 스크립트 하나만 따로 실행
- `git config --file hooks/gitformat.conf --get-regexp '^gitformat\.marker\.'` — 마커 목록 조회
- `bats tests/checks-ts.bats` — 언어별 검사 테스트(`checks-{ts,python,java,cpp,sql}.bats`)
- `bats tests/robustness-dispatch.bats` — 마커 감지·디스패치 자체의 테스트
