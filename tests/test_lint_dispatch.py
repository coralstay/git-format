"""pre-commit 디스패처가 마커별 체크를 고르고 결과를 전파하는지 본다(구 robustness-dispatch.bats).

GF-24, decision-8: 표준 인증이 아니라 실제 버그 이력(GF-16, GF-39)에 근거한 실용적
테스트. 여러 언어 마커가 동시에 있을 때 셋 다 디스패치되는지(페어와이즈), 하나가
실패하면 커밋 전체가 막히는지, 그리고 template/ 심볼릭 링크로 설치된 저장소에서도
checks/를 정확히 찾는지(GF-16)를 본다.
"""

import unittest

from isolated_repo import GITFORMAT_ROOT, INSTALL_SH, IsolatedRepoTestCase


class LintDispatchTest(IsolatedRepoTestCase):
    def test_ts_python_sql이_모두_클린이면_셋_다_실행된다(self):
        """[페어와이즈] ts+python+sql이 모두 클린이면 셋 다 실행되고 커밋은 통과한다"""
        self.write("package.json", "{}\n")
        self.write("pyproject.toml", "")
        self.write("clean.py", "x = 1\n")
        self.write("migrations/001.sql", "SELECT 1;\n")
        self.git_ok(
            "add", "package.json", "pyproject.toml", "clean.py", "migrations/001.sql"
        )
        result = self.commit("[feat] multi-lang clean")
        self.assertAccepted(result)
        self.assertIn("ts: package.json에 lint 스크립트가 없어 건너뜀", result.output)
        # GF-115에서 `ruff check .`이 스테이징 파일 목록 실행으로 바뀌었다 — 여기서
        # 보려는 건 python 체크가 디스패치됐다는 사실이라 명령 이름까지만 본다.
        self.assertIn("python: ruff check", result.output)
        self.assertIn("sql: sqlfluff lint", result.output)

    def test_python이_깨지면_커밋_전체가_막힌다(self):
        """[페어와이즈] python이 깨지면 (ts/sql은 클린이어도) 커밋 전체가 막힌다"""
        self.write("package.json", "{}\n")
        self.write("pyproject.toml", "")
        self.write("unused.py", "import os\n")
        self.write("migrations/001.sql", "SELECT 1;\n")
        self.git_ok(
            "add", "package.json", "pyproject.toml", "unused.py", "migrations/001.sql"
        )
        self.assertRejected(self.commit("[feat] python breaks the chain"))

    def test_sql만_깨지면_sql_체크가_커밋을_막는다(self):
        """[페어와이즈] python은 클린이고 sql만 깨지면 sql 체크가 커밋을 막는다"""
        self.write("pyproject.toml", "")
        self.write("clean.py", "x = 1\n")
        self.write("migrations/broken.sql", "select   *,,, from bad(((")
        self.git_ok("add", "pyproject.toml", "clean.py", "migrations/broken.sql")
        result = self.commit("[feat] sql breaks alone")
        self.assertRejected(result)
        self.assertIn("python: ruff check", result.output)

    def test_template_심볼릭_링크_설치에서도_checks를_찾는다(self):
        """[GF-16 회귀] template/ 심볼릭 링크로 설치된 새 저장소에서도 pre-commit이 checks/를 정확히 찾는다"""
        # 이 테스트만 HOME을 가짜 디렉터리로 바꾼다. 러너의 HOME은 그대로이므로
        # asdf 버전 해석(isolated_repo.asdf_pins)은 영향을 받지 않는다 — bats 판이
        # asdf_pin_python()을 HOME 교체 전에 불러야 했던 순서 제약이 사라졌다.
        fake_home = self.fake_home()
        env = {"HOME": str(fake_home)}

        # --global은 전역 설정만 하는 플래그가 아니다 — install.sh는 타깃(기본값
        # CWD)에 대한 로컬 설치도 함께 수행하므로 격리된 타깃을 명시한다(GF-123).
        self.run_cmd_ok([INSTALL_SH, "--global", self.repo], env=env)

        new_repo = self.temp_dir()
        self.make_repo(path=new_repo, hooks_path=None, env=env)

        # init.templateDir이 .git/hooks/*를 git-format 클론을 가리키는 심볼릭 링크로
        # 채웠는지부터 확인한다 — 이게 아니면 GF-16 시나리오 자체가 재현 안 된다.
        linked_hook = new_repo / ".git" / "hooks" / "pre-commit"
        self.assertTrue(linked_hook.is_symlink(), f"{linked_hook}가 심볼릭 링크가 아니다")
        self.assertEqual(
            str(GITFORMAT_ROOT / "hooks" / "pre-commit"),
            str(linked_hook.readlink()),
        )

        self.write("pyproject.toml", "", cwd=new_repo)
        self.write("unused.py", "import os\n", cwd=new_repo)
        self.git_ok("add", "pyproject.toml", "unused.py", cwd=new_repo, env=env)
        result = self.commit(
            "[feat][py] add unused import", cwd=new_repo, env=env
        )
        self.assertRejected(result)
        self.assertIn("python: ruff check", result.output)


if __name__ == "__main__":
    unittest.main()
