"""gitformat.conf를 읽을 수 없을 때 각 파일이 즉시 멈추는지 본다(구 conf-guard.bats).

GF-76에서 CONF를 읽는 파일들에 "읽기 검증 가드"를 넣었고, GF-77에서 그 가드가 텍스트로
동일한지만 검증되던 것을 런타임 검증으로 바꿨다. conf가 깨진 상태에서 각 파일을 직접
실행해 exit 0이 아니고 명확한 에러 메시지가 나오는지 본다 — 빈 값으로 진행하면 원인을
알 수 없는 거부가 된다.

진짜 저장소의 hooks/gitformat.conf는 절대 건드리지 않고, 매 테스트마다 hooks/를 임시
디렉터리에 복사해 그 사본의 conf만 깨뜨린다.
"""

import shutil
import unittest

from isolated_repo import (
    CONF_GUARD_MESSAGE,
    HOOKS_DIR,
    INSTALL_SH,
    IsolatedRepoTestCase,
)


class ConfigFileUnreadableTest(IsolatedRepoTestCase):
    def setUp(self):
        self.hooks_copy = self.copy_hooks()
        self.break_conf(self.hooks_copy)
        # 가드가 conf를 읽는 시점에 걸리는지만 보므로 core.hooksPath는 연결하지 않고
        # 각 파일을 직접 실행한다.
        self.repo = self.make_repo(hooks_path=None)

    def assertConfGuardFires(self, result):
        self.assertNotEqual(0, result.returncode, str(result))
        self.assertIn(CONF_GUARD_MESSAGE, result.output)

    def test_commit_msg가_멈춘다(self):
        """commit-msg(python): conf가 깨지면 명확한 에러로 즉시 멈춘다"""
        msg_file = self.write("msgfile", "[feat] test\n")
        self.assertConfGuardFires(
            self.python(self.hooks_copy / "commit-msg", msg_file)
        )

    def test_prepare_commit_msg가_멈춘다(self):
        """prepare-commit-msg(python): conf가 깨지면 명확한 에러로 즉시 멈춘다"""
        # GF-126에서 lint가 pre-commit에서 이 훅으로 옮겨오고 pre-commit이 삭제됐다 —
        # conf를 키 단위로 읽는 훅도 그쪽으로 바뀌었으므로 가드 검증 대상도 옮긴다.
        msg_file = self.write("msgfile", "[feat] test\n")
        self.assertConfGuardFires(
            self.python(self.hooks_copy / "prepare-commit-msg", msg_file)
        )

    def test_post_commit이_멈춘다(self):
        """post-commit(python): conf가 깨지면 명확한 에러로 즉시 멈춘다"""
        self.assertConfGuardFires(self.python(self.hooks_copy / "post-commit"))

    def test_checks_cpp가_멈춘다(self):
        """checks/cpp.py: conf가 깨지면 명확한 에러로 즉시 멈춘다"""
        self.assertConfGuardFires(
            self.python(self.hooks_copy / "checks" / "cpp.py", self.repo)
        )

    def test_checks_java가_멈춘다(self):
        """checks/java.py: conf가 깨지면 명확한 에러로 즉시 멈춘다"""
        self.assertConfGuardFires(
            self.python(self.hooks_copy / "checks" / "java.py", self.repo)
        )

    def test_checks_sql이_멈춘다(self):
        """checks/sql.py: conf가 깨지면 명확한 에러로 즉시 멈춘다"""
        self.assertConfGuardFires(
            self.python(self.hooks_copy / "checks" / "sql.py", self.repo)
        )

    def test_install_sh가_멈춘다(self):
        """install.sh: conf가 깨지면 명확한 에러로 즉시 멈춘다"""
        # install.sh는 자기 옆의 hooks/를 읽으므로 클론 구조를 그대로 흉내낸다.
        clone_copy = self.temp_dir(prefix="gitformat-clone-")
        shutil.copytree(HOOKS_DIR, clone_copy / "hooks")
        (clone_copy / "install.sh").write_bytes(INSTALL_SH.read_bytes())
        self.break_conf(clone_copy / "hooks")
        self.assertConfGuardFires(
            self.run_cmd(["sh", clone_copy / "install.sh", self.repo])
        )


if __name__ == "__main__":
    unittest.main()
