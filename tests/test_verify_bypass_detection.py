"""검증 마커의 유무로 --no-verify 우회를 탐지하는지 본다(decision-3, GF-31).

구 robustness-post-commit.bats의 상태전이 케이스. pre-commit은 시작할 때 마커를
지우고 통과하면 다시 쓰고, post-commit은 그 마커의 존재만 보고 판정한 뒤 항상
지운다 — 그래야 다음 커밋으로 스테일 마커가 새지 않는다.
"""

import unittest

from isolated_repo import IsolatedRepoTestCase

MARKER_NAME = ".gitformat-verified"


class VerifyBypassDetectionTest(IsolatedRepoTestCase):
    def test_정상_커밋은_마커가_남지_않고_Verify_Bypassed도_없다(self):
        """[상태전이] 정상 커밋(pre-commit 통과)은 마커가 결과적으로 남지 않고 Verify-Bypassed가 안 붙는다"""
        marker = self.git_dir_file(MARKER_NAME)
        self.assertFalse(marker.exists())
        self.write("a.txt", "hi\n")
        self.git_ok("add", "a.txt")
        self.assertAccepted(self.commit("[feat] normal commit"))
        self.assertFalse(marker.exists(), "post-commit이 마커를 지우지 않았다")
        self.assertTrailerKeyAbsent(self.head_message(), "Verify-Bypassed")

    def test_no_verify_커밋에는_Verify_Bypassed가_붙는다(self):
        """[상태전이] --no-verify로 커밋하면 마커가 없어 Verify-Bypassed: true가 post-commit에서 붙는다"""
        self.write("a.txt", "hi\n")
        self.git_ok("add", "a.txt")
        self.assertAccepted(self.commit("[feat] bypass verification", "--no-verify"))
        self.assertFalse(self.git_dir_file(MARKER_NAME).exists())
        self.assertTrailerCount(self.head_message(), "Verify-Bypassed: true", 1)


if __name__ == "__main__":
    unittest.main()
