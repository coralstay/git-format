"""TypeScript/JavaScript 체크(hooks/checks/ts.py) 검증(구 checks-ts.bats).

GF-73: 특정 린터를 설치하지 않고도 package.json의 lint 스크립트 자체의 성공/실패로
`npm run lint` 연동을 검증하고, tsc는 로컬에 실제로 설치된 도구를 그대로 쓴다
(GF-22 실도구 재검증 원칙과 동일).

GF-115: tsc가 저장소 전체가 아니라 스테이징된 파일만 보게 바뀌었다. 좁히는 방법으로
`tsc --noEmit <파일>`을 쓰면 tsconfig.json이 무시돼 strict 전용 타입 에러를 놓치므로,
tsconfig를 extends하는 임시 프로젝트 파일을 쓴다 — 아래 strict 테스트가 그
회귀(= tsconfig 무시 형태로 되돌아감)를 잡는 감시탑이다.

asdf 등 버전 매니저로 node를 관리하는 로컬 환경에서는 격리된 임시 디렉터리에
.tool-versions가 없어 node/npx/tsc 셈이 버전을 못 찾는다(체크 자체와 무관한 로컬
환경 이슈) — isolated_repo.asdf_pins()가 자식 환경에 노드 버전을 채워준다.
"""

import unittest

from isolated_repo import IsolatedRepoTestCase

STRICT_TSCONFIG = '{ "compilerOptions": { "strict": true } }\n'


class LintTypeScriptTest(IsolatedRepoTestCase):
    def test_lint_스크립트가_성공하면_커밋이_통과한다(self):
        """lint 스크립트가 성공하면 커밋이 통과한다"""
        self.write("package.json", '{ "scripts": { "lint": "exit 0" } }\n')
        self.git_ok("add", "package.json")
        result = self.commit("[feat][ts] lint script succeeds")
        self.assertAccepted(result)
        self.assertIn("ts: npm run lint", result.output)

    def test_lint_스크립트가_실패하면_실제_npm이_커밋을_막는다(self):
        """lint 스크립트가 실패하면 실제 npm이 커밋을 막는다"""
        self.write("package.json", '{ "scripts": { "lint": "exit 1" } }\n')
        self.git_ok("add", "package.json")
        self.assertRejected(self.commit("[feat][ts] lint script fails"))

    def test_lint_스크립트가_없으면_건너뛴다(self):
        """package.json에 lint 스크립트가 없으면 건너뛴다"""
        self.write("package.json", "{}\n")
        self.git_ok("add", "package.json")
        result = self.commit("[feat][ts] no lint script")
        self.assertAccepted(result)
        self.assertIn("lint 스크립트가 없어 건너뜀", result.output)

    def test_npm이_없으면_조용히_건너뛴다(self):
        """npm이 없으면 조용히 건너뛴다"""
        shadow = self.path_without("npm")
        self.write("package.json", '{ "scripts": { "lint": "exit 1" } }\n')
        self.git_ok("add", "package.json")
        self.assertAccepted(
            self.commit("[feat][ts] no npm on PATH", env={"PATH": str(shadow)})
        )

    def test_tsconfig가_있으면_실제_tsc를_실행한다(self):
        """tsconfig.json이 있으면 실제 tsc --noEmit을 실행한다"""
        self.write("package.json", "{}\n")
        self.write("tsconfig.json", STRICT_TSCONFIG)
        self.write("clean.ts", "const x: number = 1;\n")
        self.git_ok("add", "package.json", "tsconfig.json", "clean.ts")
        result = self.commit("[feat][ts] add tsconfig")
        self.assertAccepted(result)
        self.assertIn("tsc --noEmit", result.output)

    def test_타입_에러가_있는_파일은_실제_tsc가_차단한다(self):
        """타입 에러가 있는 .ts 파일은 실제 tsc가 차단한다"""
        self.write("package.json", "{}\n")
        self.write("tsconfig.json", STRICT_TSCONFIG)
        self.write("broken.ts", 'const x: number = "not a number";\n')
        self.git_ok("add", "package.json", "tsconfig.json", "broken.ts")
        self.assertRejected(self.commit("[feat][ts] add type error"))

    def test_tsc가_어디에도_없으면_조용히_건너뛴다(self):
        """tsconfig.json은 있지만 tsc가 어디에도 없으면 조용히 건너뛴다 (GF-79)"""
        # npx --no-install tsc는 PATH가 아니라 npm/npx 자체의 조회 경로를 따로
        # 참조해서, tsc가 정말 없을 때도 npx 특유의 실패로 정상 커밋을 막았다
        # (typescript를 devDependency로만 설치하는 흔한 실사용 패턴, 그리고 이
        # 프로젝트 자체 CI도 typescript를 따로 설치하지 않아 같은 문제를 겪었다).
        shadow = self.path_without("tsc")
        self.write("package.json", "{}\n")
        self.write("tsconfig.json", STRICT_TSCONFIG)
        self.write("clean.ts", "const x: number = 1;\n")
        self.git_ok("add", "package.json", "tsconfig.json", "clean.ts")
        result = self.commit(
            "[feat][ts] no tsc anywhere", env={"PATH": str(shadow)}
        )
        self.assertAccepted(result)
        self.assertIn("tsconfig.json은 있지만 tsc를 찾을 수 없어 건너뜀", result.output)

    def test_strict_전용_타입_에러도_스테이징_파일에서_잡힌다(self):
        """strict 전용 타입 에러도 스테이징 파일에서 여전히 잡힌다 (GF-115)"""
        # noImplicitAny(strict)에서만 나는 에러다. `tsc --noEmit <파일>`처럼 파일
        # 인자를 주면 tsc가 tsconfig.json을 무시해 이 에러가 조용히 통과한다 —
        # 스코프를 좁히면서 그 형태로 되돌아가면 이 테스트가 깨진다.
        self.write("package.json", "{}\n")
        self.write("tsconfig.json", STRICT_TSCONFIG)
        self.write("implicit.ts", "export function f(x) {\n  return x;\n}\n")
        self.git_ok("add", "package.json", "tsconfig.json", "implicit.ts")
        self.assertRejected(self.commit("[feat][ts] add implicit any"))

    def test_스테이징되지_않은_ts의_타입_에러는_막지_않는다(self):
        """스테이징되지 않은 .ts의 타입 에러는 커밋을 막지 않는다 (GF-115)"""
        self.write("package.json", "{}\n")
        self.write("tsconfig.json", STRICT_TSCONFIG)
        self.write("legacy.ts", 'const bad: number = "not a number";\n')
        self.write("clean.ts", "const x: number = 1;\n")
        self.git_ok("add", "package.json", "tsconfig.json", "clean.ts")
        self.assertAccepted(self.commit("[feat][ts] add clean module"))

    def test_이미_커밋된_ts의_타입_에러는_막지_않는다(self):
        """이미 커밋된 .ts의 타입 에러는 이후 커밋을 막지 않는다 (GF-115)"""
        # tsconfig.json이 없는 동안 들어온 기존 부채를 재현한다 — 검사가 좁아지기
        # 전에는 무관한 다음 커밋까지 이 에러 때문에 막혔다(false blocking).
        self.write("package.json", "{}\n")
        self.write("legacy.ts", 'const bad: number = "not a number";\n')
        self.git_ok("add", "package.json", "legacy.ts")
        self.commit_ok("[feat][ts] pre-existing type debt", "-q")
        self.write("tsconfig.json", STRICT_TSCONFIG)
        self.write("clean.ts", "const x: number = 1;\n")
        self.git_ok("add", "tsconfig.json", "clean.ts")
        self.assertAccepted(self.commit("[feat][ts] add unrelated module"))

    def test_tsconfig의_include가_스코프를_다시_넓히지_않는다(self):
        """tsconfig의 include가 스테이징 범위를 다시 넓히지 않는다 (GF-115)"""
        # extends는 같은 이름의 키만 덮으므로, 임시 프로젝트 파일이 include를 []로
        # 덮지 않으면 원본의 include가 살아남아 스테이징되지 않은 파일까지 끌려온다.
        self.write("package.json", "{}\n")
        self.write(
            "tsconfig.json",
            '{ "compilerOptions": { "strict": true }, "include": ["src"] }\n',
        )
        self.write("src/legacy.ts", 'const bad: number = "not a number";\n')
        self.write("src/clean.ts", "const x: number = 1;\n")
        self.git_ok("add", "package.json", "tsconfig.json", "src/clean.ts")
        self.assertAccepted(self.commit("[feat][ts] add clean module under src"))

    def test_스테이징된_TypeScript_파일이_없으면_tsc를_건너뛴다(self):
        """스테이징된 TypeScript 파일이 없으면 tsc를 건너뛴다 (GF-115)"""
        self.write("package.json", "{}\n")
        self.write("tsconfig.json", STRICT_TSCONFIG)
        self.write("legacy.ts", 'const bad: number = "not a number";\n')
        self.write("notes.txt", "메모\n")
        self.git_ok("add", "package.json", "tsconfig.json", "notes.txt")
        result = self.commit("[docs][ts] add notes")
        self.assertAccepted(result)
        self.assertIn("스테이징된 TypeScript 파일 없음", result.output)

    def test_tsc가_실패해도_임시_프로젝트_파일은_남지_않는다(self):
        """tsc가 실패해도 임시 프로젝트 파일은 남지 않는다 (GF-115)"""
        self.write("package.json", "{}\n")
        self.write("tsconfig.json", STRICT_TSCONFIG)
        self.write("broken.ts", 'const x: number = "not a number";\n')
        self.git_ok("add", "package.json", "tsconfig.json", "broken.ts")
        self.assertRejected(self.commit("[feat][ts] add type error"))
        leftovers = sorted(self.repo.glob("tsconfig.gitformat-*.json"))
        self.assertEqual([], leftovers, f"임시 프로젝트 파일이 남았다: {leftovers}")


if __name__ == "__main__":
    unittest.main()
