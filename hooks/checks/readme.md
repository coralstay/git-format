# checks

**무엇인가**: `pre-commit`이 언어를 감지했을 때 호출하는 커밋 전 검사 스크립트 5개를
담는다. 각 스크립트는 저장소 루트 경로를 인자 하나로 받아 그 디렉터리에서 자기
검사만 하고, 결과를 종료 코드로 알린다. 0이 아니면 `pre-commit`이 그 코드를 그대로
전파해 커밋이 막히고 검증 마커도 기록되지 않는다.

**디스패치 메커니즘**: `pre-commit`이 `gitformat.conf`의 `[gitformat "marker"]`
값을 읽어 저장소 루트에 해당 마커 파일이 있는지 보고, 있는 언어의 스크립트만
실행한다.

| 스크립트    | 마커                                     | 외부 도구            | 검사 범위                               |
| ----------- | ---------------------------------------- | -------------------- | --------------------------------------- |
| `ts.py`     | `package.json`                           | npm, tsc             | `npm run lint`은 전체, `tsc`는 스테이징 |
| `python.py` | `pyproject.toml` 또는 `requirements.txt` | ruff, 없으면 flake8  | 스테이징                                |
| `java.py`   | `pom.xml` 또는 `build.gradle*`           | mvn 또는 `./gradlew` | 프로젝트 전체                           |
| `cpp.py`    | `CMakeLists.txt` 또는 `Makefile`         | clang-format         | 스테이징                                |
| `sql.py`    | `.sqlfluff` 또는 추적되는 `*.sql`        | sqlfluff             | 스테이징                                |

마커가 하나도 없으면 아무 것도 실행하지 않고 통과한다. `build.gradle*`와 `*.sql`은
리터럴 파일명이 아니라 글롭이라 각각 글롭 확장과 `git ls-files`로 확인한다.

호출은 `sys.executable`로 한다 — `pre-commit`을 돌리고 있는 바로 그 인터프리터를
재사용하므로 별도 런처가 필요 없고, PATH의 `python3`가 그것과 갈라질 여지도 없다.
sh 시절에는 실행 권한(`-x`)까지 봤지만 지금은 파일 존재만 확인한다.

**각 스크립트가 하는 일**:

- `ts.py` — `package.json`의 `scripts.lint`가 있으면 `npm run lint`. `"lint"`를
  grep하면 `devDependencies`의 패키지명까지 오탐하므로 JSON을 실제로 파싱해
  `scripts.lint`만 본다(GF-39). `tsconfig.json`이 있으면 `tsc`로 타입 검사도 하되
  `npx`를 거치지 않는다 — `npx --no-install`은 PATH가 아니라 npm 자신의 조회 경로를
  보기 때문에 PATH에 `tsc`가 있어도 실패해 정상 커밋을 막는다(GF-79). 그래서
  `node_modules/.bin/tsc` → PATH의 `tsc` 순으로 직접 실행한다. 타입 검사는 스테이징
  범위로 좁히는데, `tsc --noEmit <파일>` 형태는 쓰지 않는다 — 파일 인자를 주면 tsc가
  `tsconfig.json`을 통째로 무시해 `strict`에서만 잡히는 에러가 조용히 통과한다(실측:
  파일 인자는 exit 0, `tsc --noEmit`은 exit 2). 대신 `tsconfig.json`을 `extends`하고
  `files`를 스테이징 파일로, `include`를 `[]`로 덮은 임시 프로젝트 파일을 저장소 루트에
  써서 `tsc -p <임시 파일> --noEmit`을 돌리고 끝나면 지운다(GF-115). `include`를 반드시
  덮어야 하는 이유는 `extends`가 같은 이름의 키만 덮기 때문이다 — 원본의 `include`가
  남으면 스테이징되지 않은 파일이 다시 끌려온다. `npm run lint`은 컨슈머가 직접 쓴
  스크립트라 파일 인자 계약을 알 수 없어 저장소 전체로 남긴다.
- `python.py` — 스테이징된 `.py`/`.pyi` 파일에만 `ruff check`를 쓰고 없으면 `flake8`로
  대체한다. 둘 다 파일 목록을 인자로 받으므로 스코프를 좁힐 수 있다(GF-115).
- `java.py` — 컴파일까지만 확인한다(테스트/verify는 범위 밖, decision-12).
  `mvn -q compile` 또는 `./gradlew -q compileJava`. `mvn`에 `-o`(오프라인)를 주면
  플러그인 캐시가 없는 첫 실행에서 실패하므로 온라인으로 돌린다(GF-22). 여기만
  프로젝트 전체를 보는데, mvn/gradle에 "이 파일들만 컴파일" 모드가 없기 때문이다 —
  자바 컴파일은 같은 소스 트리의 다른 클래스를 참조해야 성립한다(GF-115).
- `cpp.py` — 스테이징된 C/C++ 파일에만 `clang-format --dry-run -Werror`. 확장자
  목록은 `gitformat.conf`의 `gitformat.cpp.ext`에서 읽는다.
- `sql.py` — 스테이징된 `.sql` 파일에만 `sqlfluff lint`. `.sqlfluff` 설정이 없으면
  `gitformat.conf`의 `sqlDialectDefault`를 `--dialect`로 명시해 넘긴다 — dialect가
  아예 없으면 sqlfluff가 린트가 아니라 사용법 에러(exit 2)로 죽는다(GF-22).

공통 규칙이 둘 있다. **외부 도구가 없으면 조용히 건너뛰고 0으로 끝낸다** — 도구
부재로 커밋을 막지 않는다. 그리고 **검사 범위는 도구가 허용하는 한 스테이징 파일로
좁힌다**(GF-115): 파일 목록을 인자로 받는 도구(ruff/flake8, clang-format, sqlfluff)와
프로젝트 파일로 대상을 지정할 수 있는 도구(tsc)는 `git diff --cached`의 스테이징 파일만
보고, 스테이징된 대상 파일이 없으면 그 검사를 건너뛴다. 파일 단위 모드가 없는
프로젝트 단위 도구(mvn/gradle 컴파일)와 인자 계약을 알 수 없는 컨슈머 스크립트
(`npm run lint`)만 저장소/프로젝트 전체로 남는다 — 이쪽은 이번 커밋과 무관한 기존
에러로도 커밋이 막힐 수 있다는 한계를 그대로 안고 간다. `--diff-filter=ACMR`의 `R`은
리네임하면서 수정한 파일도 잡기 위한 것이다(GF-37). `git diff` 자체가 실패하면
"검사할 파일 없음"으로 흘려 커밋을 막지 않는다(fail-open).

**언제 쓰나**: 지원 언어를 추가하거나 기존 검사 내용을 바꿀 때. 새 언어는 스크립트
파일 하나와 `gitformat.conf`의 마커 항목, `pre-commit`의 분기 한 줄이 함께 필요하다 —
셋 중 하나라도 빠지면 검사가 조용히 안 돈다. 검사 범위를 넓힐 때는 decision-12(무거운
검사는 프로젝트 범위 밖)를 먼저 확인한다.

**관련 명령**:

- `python3 hooks/checks/ts.py "$(git rev-parse --show-toplevel)"` — 스크립트 하나만 따로 실행
- `git config --file hooks/gitformat.conf --get-regexp '^gitformat\.marker\.'` — 마커 목록 조회
- `bats tests/checks-ts.bats` — 언어별 검사 테스트(`checks-{ts,python,java,cpp,sql}.bats`)
- `bats tests/robustness-dispatch.bats` — 마커 감지·디스패치 자체의 테스트
