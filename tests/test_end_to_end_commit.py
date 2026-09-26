"""커밋 한 번이 훅 전체를 통과하는지 보는 최소 확인(구 smoke.bats, GF-21).

세부 동작은 각 동작별 테스트 파일이 따로 검증한다 — 여기서는 하네스와 훅 연결
자체가 살아 있는지만 본다.
"""

import unittest

from isolated_repo import HOOKS_DIR, IsolatedRepoTestCase


class EndToEndCommitTest(IsolatedRepoTestCase):
    def test_형식에_맞는_커밋은_통과한다(self):
        """[type][subsystem] 형식의 커밋은 통과한다"""
        self.write("a.txt", "hi\n")
        self.git_ok("add", "a.txt")
        self.assertAccepted(self.commit("[feat] smoke test"))

    def test_형식에_안_맞는_커밋_메시지는_거부된다(self):
        """형식에 안 맞는 커밋 메시지는 거부된다"""
        self.write("a.txt", "hi\n")
        self.git_ok("add", "a.txt")
        self.assertRejected(self.commit("이상한 메시지"))

    def test_언어_마커가_없으면_lint가_무해하게_통과한다(self):
        """언어 마커가 없는 저장소는 lint가 무해하게 통과시킨다

        GF-126에서 lint가 pre-commit에서 prepare-commit-msg로 옮겨왔다 — 실행 주체가
        바뀌었을 뿐 "마커가 없으면 아무 것도 하지 않는다"는 동작은 그대로다.
        """
        result = self.python(HOOKS_DIR / "prepare-commit-msg")
        self.assertEqual(0, result.returncode, str(result))


if __name__ == "__main__":
    unittest.main()
