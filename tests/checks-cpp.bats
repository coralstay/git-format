#!/usr/bin/env bats
# GF-22: C/C++ 체크를 실제 clang-format으로 검증한다(이전엔 PATH 셔밍만 했음).
# clang-format은 프로젝트에 .clang-format이 없으면 기본 LLVM 스타일을 기준으로
# 삼는다 — "정상" 픽스처는 실제 clang-format으로 포맷한 결과를 그대로 쓴다.

load 'helpers/git-format'

setup() {
  make_isolated_repo
  touch CMakeLists.txt
}

teardown() {
  cleanup_isolated_repo
}

@test "clang-format 기본 스타일에 맞는 코드는 통과한다" {
  printf 'int main() { return 0; }\n' > clean.cpp
  git add CMakeLists.txt clean.cpp
  run git commit -m "feat(cpp): add formatted main"
  [ "$status" -eq 0 ]
}

@test "포맷이 어긋난 코드는 실제 clang-format이 차단한다" {
  printf 'int main(){\nreturn 0;\n      }\n' > messy.cpp
  git add CMakeLists.txt messy.cpp
  run git commit -m "feat(cpp): add messy main"
  [ "$status" -ne 0 ]
}

@test "공백이 포함된 파일명도 정확히 검사한다 (GF-36)" {
  printf 'int main(){\nreturn 0;\n      }\n' > "my file.cpp"
  git add CMakeLists.txt "my file.cpp"
  run git commit -m "feat(cpp): add spaced filename"
  [ "$status" -ne 0 ]
}

@test "리네임하면서 수정한 파일도 검사한다 (GF-37)" {
  printf 'int main() { return 0; }\n' > clean.cpp
  git add CMakeLists.txt clean.cpp
  git commit -q -m "feat(cpp): add clean baseline"
  git mv clean.cpp renamed.cpp
  printf 'int main(){\nreturn 0;\n      }\n' > renamed.cpp
  git add renamed.cpp
  run git commit -m "feat(cpp): rename and mangle formatting"
  [ "$status" -ne 0 ]
}

@test "루트에 정상 포맷 cpp가 있어도 하위 디렉터리 cpp 위반은 검사된다 (GF-81)" {
  mkdir -p src
  printf 'int main() { return 0; }\n' > root.cpp
  printf 'int main(){\nreturn 0;\n      }\n' > src/deep.cpp
  git add CMakeLists.txt root.cpp src/deep.cpp
  run git commit -m "feat(cpp): add root and nested cpp files"
  [ "$status" -ne 0 ]
}

@test "clang-format이 없으면 조용히 건너뛴다" {
  printf 'int main(){\nreturn 0;\n      }\n' > messy.cpp
  git add CMakeLists.txt messy.cpp
  PATH="$(path_without clang-format)" run git commit -m "feat(cpp): no clang-format on PATH"
  [ "$status" -eq 0 ]
}
