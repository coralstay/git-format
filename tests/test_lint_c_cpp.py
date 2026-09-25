"""C/C++ 체크(hooks/checks/cpp.py)를 실제 clang-format으로 검증한다(구 checks-cpp.bats).

GF-22: clang-format은 프로젝트에 .clang-format이 없으면 기본 LLVM 스타일을 기준으로
삼는다 — "정상" 픽스처는 실제 clang-format으로 포맷한 결과를 그대로 쓴다.
"""

import unittest

from isolated_repo import IsolatedRepoTestCase

CLEAN_CPP = "int main() { return 0; }\n"
MESSY_CPP = "int main(){\nreturn 0;\n      }\n"


class LintCppTest(IsolatedRepoTestCase):
    def setUp(self):
        super().setUp()
        self.write("CMakeLists.txt", "")

    def test_기본_스타일에_맞는_코드는_통과한다(self):
        """clang-format 기본 스타일에 맞는 코드는 통과한다"""
        self.write("clean.cpp", CLEAN_CPP)
        self.git_ok("add", "CMakeLists.txt", "clean.cpp")
        self.assertAccepted(self.commit("[feat][cpp] add formatted main"))

    def test_포맷이_어긋난_코드는_실제_clang_format이_차단한다(self):
        """포맷이 어긋난 코드는 실제 clang-format이 차단한다"""
        self.write("messy.cpp", MESSY_CPP)
        self.git_ok("add", "CMakeLists.txt", "messy.cpp")
        self.assertRejected(self.commit("[feat][cpp] add messy main"))

    def test_공백이_포함된_파일명도_정확히_검사한다(self):
        """공백이 포함된 파일명도 정확히 검사한다 (GF-36)"""
        self.write("my file.cpp", MESSY_CPP)
        self.git_ok("add", "CMakeLists.txt", "my file.cpp")
        self.assertRejected(self.commit("[feat][cpp] add spaced filename"))

    def test_리네임하면서_수정한_파일도_검사한다(self):
        """리네임하면서 수정한 파일도 검사한다 (GF-37)"""
        self.write("clean.cpp", CLEAN_CPP)
        self.git_ok("add", "CMakeLists.txt", "clean.cpp")
        self.commit_ok("[feat][cpp] add clean baseline", "-q")
        self.git_ok("mv", "clean.cpp", "renamed.cpp")
        self.write("renamed.cpp", MESSY_CPP)
        self.git_ok("add", "renamed.cpp")
        self.assertRejected(self.commit("[feat][cpp] rename and mangle formatting"))

    def test_하위_디렉터리의_위반도_검사된다(self):
        """루트에 정상 포맷 cpp가 있어도 하위 디렉터리 cpp 위반은 검사된다 (GF-81)"""
        self.write("root.cpp", CLEAN_CPP)
        self.write("src/deep.cpp", MESSY_CPP)
        self.git_ok("add", "CMakeLists.txt", "root.cpp", "src/deep.cpp")
        self.assertRejected(self.commit("[feat][cpp] add root and nested cpp files"))

    def test_clang_format이_없으면_조용히_건너뛴다(self):
        """clang-format이 없으면 조용히 건너뛴다"""
        shadow = self.path_without("clang-format")
        self.write("messy.cpp", MESSY_CPP)
        self.git_ok("add", "CMakeLists.txt", "messy.cpp")
        self.assertAccepted(
            self.commit(
                "[feat][cpp] no clang-format on PATH", env={"PATH": str(shadow)}
            )
        )


if __name__ == "__main__":
    unittest.main()
