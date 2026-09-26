"""검증 마커와 --no-verify의 관계를 본다(decision-3, GF-31, GF-126).

구 robustness-post-commit.bats의 상태전이 케이스. 마커를 쓰는 훅은 검사 시작 시점에
남은 마커를 지우고 통과하면 다시 쓰고, post-commit은 그 마커의 존재만 보고 판정한 뒤
항상 지운다 — 그래야 다음 커밋으로 스테일 마커가 새지 않는다.

**GF-126이 이 관계를 바꿨다.** lint가 pre-commit에서 prepare-commit-msg로 옮겨왔고,
prepare-commit-msg는 --no-verify로도 건너뛸 수 없다(doc-15). 그래서 마커는 --no-verify
커밋에서도 항상 써지고, 마커의 부재로 우회를 판정하는 Verify-Bypassed는 **도달 불가능**
해졌다. 대신 이제는 --no-verify로도 검사가 실제로 돌아 실패하면 커밋이 막힌다(AC #4) —
아래 두 테스트가 그 앞뒤를 함께 고정한다.

이 시점의 한계도 기록해 둔다: --no-verify는 아직 commit-msg를 건너뛰므로 '메시지 검증
우회'는 여전히 가능하고, 그것을 기록하는 신호는 없다. 검증을 prepare-commit-msg로 옮기는
GF-127이 그 한 태스크짜리 과도기를 닫는다.
"""

import unittest

from isolated_repo import IsolatedRepoTestCase

MARKER_NAME = ".gitformat-verified"


class VerifyBypassDetectionTest(IsolatedRepoTestCase):
    def test_정상_커밋은_마커가_남지_않고_Verify_Bypassed도_없다(self):
        """[상태전이] 정상 커밋(검사 통과)은 마커가 결과적으로 남지 않고 Verify-Bypassed가 안 붙는다"""
        marker = self.git_dir_file(MARKER_NAME)
        self.assertFalse(marker.exists())
        self.write("a.txt", "hi\n")
        self.git_ok("add", "a.txt")
        self.assertAccepted(self.commit("[feat] normal commit"))
        self.assertFalse(marker.exists(), "post-commit이 마커를 지우지 않았다")
        self.assertTrailerKeyAbsent(self.head_message(), "Verify-Bypassed")

    def test_no_verify_커밋에도_Verify_Bypassed가_붙지_않는다(self):
        """[상태전이] --no-verify로 커밋해도 마커가 써져 Verify-Bypassed가 붙지 않는다

        GF-126까지는 반대였다 — pre-commit이 --no-verify로 스킵돼 마커가 없었고,
        post-commit이 그 부재를 우회 증거로 읽어 Verify-Bypassed: true를 붙였다. lint와
        마커 기록이 --no-verify로 건너뛸 수 없는 prepare-commit-msg로 옮겨온 뒤에는
        마커가 항상 써지므로 이 트레일러는 도달 불가능하다. post-commit과 함께 GF-128에서
        사라질 신호다.
        """
        self.write("a.txt", "hi\n")
        self.git_ok("add", "a.txt")
        self.assertAccepted(self.commit("[feat] bypass verification", "--no-verify"))
        # post-commit이 판정 후 항상 지우므로 마커 자체는 남지 않는다.
        self.assertFalse(self.git_dir_file(MARKER_NAME).exists())
        self.assertTrailerKeyAbsent(self.head_message(), "Verify-Bypassed")

    def test_no_verify로도_검사가_실행돼_실패하면_커밋이_막힌다(self):
        """[GF-126 AC #4] --no-verify로도 언어별 검사가 실행되고 실패하면 커밋이 막힌다

        위 테스트가 'Verify-Bypassed가 사라졌다'는 사실만 고정하면, 검사가 아예 돌지
        않게 되는 회귀도 똑같이 통과한다. 실제 ruff가 잡는 에러로 커밋이 막히는지까지
        봐야 그 신호가 필요 없어진 이유가 증명된다(GF-22: 실도구로 검증한다).
        """
        self.write("pyproject.toml", "")
        self.write("unused.py", "import os\n")
        self.git_ok("add", "pyproject.toml", "unused.py")

        result = self.commit("[feat][py] lint runs even with no-verify", "--no-verify")

        self.assertRejected(result)
        self.assertIn("python: ruff check", result.output)
        # 커밋 객체가 정말 안 생겼는지까지 확인한다.
        self.assertRejected(self.git("rev-parse", "--verify", "-q", "HEAD"))


if __name__ == "__main__":
    unittest.main()
