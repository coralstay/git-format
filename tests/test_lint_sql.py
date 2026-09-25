"""SQL 체크(hooks/checks/sql.py)를 실제 sqlfluff로 검증한다(구 checks-sql.bats).

GF-22: sqlfluff는 dialect 미지정 시 사용법 에러(exit 2)를 낸다는 걸 실도구 테스트로
발견해 hooks/checks/sql.py가 .sqlfluff 없을 때 --dialect ansi를 기본값으로 넘기도록
고쳤다 — 이 회귀를 고정한다.
"""

import unittest

from isolated_repo import IsolatedRepoTestCase


class LintSqlTest(IsolatedRepoTestCase):
    def test_sqlfluff_설정_없이도_유효한_SQL은_통과한다(self):
        """.sqlfluff 없이도 유효한 SQL은 통과한다 (ansi 폴백)"""
        self.write("migrations/001.sql", "SELECT 1;\n")
        self.git_ok("add", "migrations/001.sql")
        self.assertAccepted(self.commit("[feat][db] add migration"))

    def test_문법이_깨진_SQL은_실제_sqlfluff가_차단한다(self):
        """문법이 깨진 SQL은 실제 sqlfluff가 차단한다"""
        self.write("migrations/broken.sql", "select   *,,, from bad(((")
        self.git_ok("add", "migrations/broken.sql")
        self.assertRejected(self.commit("[feat][db] add broken migration"))

    def test_sqlfluff_설정이_있으면_그_dialect를_존중한다(self):
        """.sqlfluff 설정이 있으면 그 dialect를 존중한다"""
        self.write(".sqlfluff", "[sqlfluff]\ndialect = postgres\n")
        self.write("migrations/001.sql", "SELECT 1;\n")
        self.git_ok("add", ".sqlfluff", "migrations/001.sql")
        self.assertAccepted(self.commit("[feat][db] postgres dialect"))

    def test_sqlfluff가_없으면_조용히_건너뛴다(self):
        """sqlfluff가 없으면 조용히 건너뛴다"""
        shadow = self.path_without("sqlfluff")
        self.write("migrations/001.sql", "SELECT 1;\n")
        self.git_ok("add", "migrations/001.sql")
        self.assertAccepted(
            self.commit("[feat][db] no sqlfluff on PATH", env={"PATH": str(shadow)})
        )


if __name__ == "__main__":
    unittest.main()
