"""Python 체크(hooks/checks/python.py)를 실제 ruff로 검증한다(구 checks-python.bats).

GF-22: PATH 셔밍이 아니라 실제 ruff를 쓴다 — 도구가 없으면 "차단돼야 할" 테스트가
조용히 통과한다.
GF-115: 검사 스코프가 저장소 전체(`ruff check .`)에서 스테이징된 파일로 좁혀졌다 —
이번 커밋과 무관한 기존 린트 에러로 커밋이 막히지 않는지(false blocking), 그리고
스테이징된 파일의 에러는 여전히 막는지 양쪽을 본다.
"""

import unittest

from isolated_repo import IsolatedRepoTestCase


class LintPythonTest(IsolatedRepoTestCase):
    def setUp(self):
        super().setUp()
        self.write("pyproject.toml", "")

    def test_린트_문제_없는_코드는_통과한다(self):
        """린트 문제 없는 코드는 통과한다"""
        self.write("clean.py", "x = 1\n")
        self.git_ok("add", "pyproject.toml", "clean.py")
        self.assertAccepted(self.commit("[feat][py] add clean module"))

    def test_미사용_import는_실제_ruff가_잡아_커밋을_막는다(self):
        """실제 ruff가 미사용 import를 잡아 커밋을 막는다"""
        self.write("unused.py", "import os\n")
        self.git_ok("add", "pyproject.toml", "unused.py")
        self.assertRejected(self.commit("[feat][py] add unused import"))

    def test_ruff가_없으면_조용히_건너뛴다(self):
        """ruff가 없으면 조용히 건너뛴다"""
        shadow = self.path_without("ruff")
        self.write("unused.py", "import os\n")
        self.git_ok("add", "pyproject.toml", "unused.py")
        self.assertAccepted(
            self.commit("[feat][py] no ruff on PATH", env={"PATH": str(shadow)})
        )

    def test_스테이징되지_않은_파일의_린트_에러는_막지_않는다(self):
        """스테이징되지 않은 파일의 린트 에러는 커밋을 막지 않는다 (GF-115)"""
        self.write("legacy.py", "import os\n")
        self.write("clean.py", "x = 1\n")
        self.git_ok("add", "pyproject.toml", "clean.py")
        self.assertAccepted(self.commit("[feat][py] add clean module"))

    def test_이미_커밋된_파일의_린트_에러는_막지_않는다(self):
        """이미 커밋된 파일의 린트 에러는 이후 커밋을 막지 않는다 (GF-115)"""
        # 기존 부채를 재현한다 — 검사가 좁아지기 전에 들어온 에러 있는 파일이
        # 무관한 다음 커밋까지 막던 게 GF-115의 false blocking이다.
        #
        # 부채를 심을 때 --no-verify를 쓸 수 없다(GF-126) — lint가 prepare-commit-msg로
        # 옮겨오면서 --no-verify로도 검사가 돌아 이 준비 커밋 자체가 막힌다. 훅을 아예
        # 떼어내(core.hooksPath를 /dev/null로) 부채만 심는다.
        self.write("legacy.py", "import os\n")
        self.git_ok("add", "pyproject.toml", "legacy.py")
        self.git_ok(
            "-c",
            "core.hooksPath=/dev/null",
            "commit",
            "-q",
            "-m",
            "[feat][py] pre-existing lint debt",
        )
        self.write("clean.py", "y = 2\n")
        self.git_ok("add", "clean.py")
        self.assertAccepted(self.commit("[feat][py] add unrelated module"))

    def test_스테이징된_Python_파일이_없으면_건너뛴다(self):
        """스테이징된 Python 파일이 없으면 건너뛴다 (GF-115)"""
        self.write("legacy.py", "import os\n")
        self.write("notes.txt", "메모\n")
        self.git_ok("add", "pyproject.toml", "notes.txt")
        result = self.commit("[docs][py] add notes")
        self.assertAccepted(result)
        self.assertIn("스테이징된 Python 파일 없음", result.output)

    def test_하위_디렉터리의_스테이징된_파일도_검사한다(self):
        """하위 디렉터리의 스테이징된 파일도 검사한다 (GF-115)"""
        self.write("pkg/unused.py", "import os\n")
        self.git_ok("add", "pyproject.toml", "pkg/unused.py")
        self.assertRejected(self.commit("[feat][py] add nested unused import"))


if __name__ == "__main__":
    unittest.main()
