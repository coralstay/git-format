#!/usr/bin/env bats
# 여러 파일에 "값은 같아야 하지만 로직/문서는 공유하지 않는" 항목들이 실제로
# 일치하는지 검증한다(런타임 결합 없이 테스트로만 drift를 잡는다는 게 이
# 프로젝트의 설계 원칙 - decision-8/decision-9 참고).

load 'helpers/git-format'

@test "gitformat.conf의 커밋 타입 목록과 .gitmessage에 적힌 타입 목록이 일치한다 (GF-68)" {
  CONF_TYPES="$(git config --file "${GITFORMAT_ROOT}/hooks/gitformat.conf" \
    --get-all gitformat.type | sort)"
  MSG_TYPES="$(sed -n '/type 목록/,/subsystem (선택)/p' "${GITFORMAT_ROOT}/.gitmessage" \
    | grep -E '^#   [a-z]+' | awk '{print $2}' | sort)"
  [ -n "$CONF_TYPES" ]
  [ -n "$MSG_TYPES" ]
  [ "$CONF_TYPES" = "$MSG_TYPES" ]
}

@test "gitformat.conf에 각 훅이 참조하는 키가 전부 존재하고 값이 비어있지 않다 (GF-61)" {
  CONF="${GITFORMAT_ROOT}/hooks/gitformat.conf"
  # 이 목록은 hooks/*, hooks/checks/*.sh가 `git config --file "$CONF"`로 실제
  # 읽는 키를 grep으로 뽑아 만든 것이다 - 키가 새로 추가/삭제되면 이 목록도
  # 같이 갱신해야 한다(자동 추출이 아니라 수동 목록이라는 한계를 인지할 것).
  for key in \
    gitformat.aiToolClaudeCode \
    gitformat.branchExempt \
    gitformat.coAuthoredBy \
    gitformat.cpp.ext \
    gitformat.knownModel \
    gitformat.marker.cpp \
    gitformat.marker.cppMake \
    gitformat.marker.java \
    gitformat.marker.javaGradle \
    gitformat.marker.python \
    gitformat.marker.sql \
    gitformat.marker.sqlGlob \
    gitformat.marker.ts \
    gitformat.markerFile \
    gitformat.sqlDialectDefault \
    gitformat.taskPrefixDefault \
    gitformat.trailer.aiModel \
    gitformat.trailer.aiTool \
    gitformat.trailer.aiToolVersion \
    gitformat.trailer.coAuthoredBy \
    gitformat.trailer.fixes \
    gitformat.trailer.hooksCommit \
    gitformat.trailer.signedOffBy \
    gitformat.trailer.taskId \
    gitformat.trailer.verifyBypassed \
    gitformat.type \
  ; do
    value="$(git config --file "$CONF" --get "$key" 2>/dev/null || true)"
    if [ -z "$value" ]; then
      echo "누락되거나 빈 값: $key" >&2
      false
    fi
  done
}

@test "resolve_self() 6개 사본이 글자 그대로 동일하다 (GF-62/GF-72)" {
  # commit-msg/pre-commit/post-commit/checks/{cpp,sql,java}.sh는
  # 각자 독립적으로 resolve_self()를 갖고 있다(로직은 공유하지 않는다는 설계
  # 원칙, decision-9). 이 함수 자체는 지금 6곳 모두 동일해야 하고, 한 곳만
  # 고치고 나머지를 빠뜨리면(GF-16류) 이 테스트가 잡는다. 새 파일에
  # resolve_self를 추가할 때는 이 목록도 같이 갱신해야 한다.
  files="${GITFORMAT_ROOT}/hooks/commit-msg
${GITFORMAT_ROOT}/hooks/pre-commit
${GITFORMAT_ROOT}/hooks/post-commit
${GITFORMAT_ROOT}/hooks/checks/cpp.sh
${GITFORMAT_ROOT}/hooks/checks/sql.sh
${GITFORMAT_ROOT}/hooks/checks/java.sh"

  reference=""
  while IFS= read -r f; do
    body="$(awk '/^resolve_self\(\) \{/,/^\}/' "$f")"
    if [ -z "$body" ]; then
      echo "resolve_self()를 찾을 수 없음: $f" >&2
      false
    fi
    if [ -z "$reference" ]; then
      reference="$body"
    elif [ "$body" != "$reference" ]; then
      echo "resolve_self()가 다름: $f" >&2
      false
    fi
  done <<EOF
$files
EOF
}

@test "TASK_PREFIX/BRANCH 계산 블록이 commit-msg와 post-commit에서 동일하다 (GF-70)" {
  # commit-msg가 검증한 Task-Id 브랜치 패턴을 post-commit이 그대로 재파싱해
  # 트레일러로 남긴다(decision-4) - 두 파일이 TASK_PREFIX_DEFAULT/TASK_PREFIX/
  # BRANCH를 계산하는 로직이 정확히 같아야만 서로 어긋나지 않는다. resolve_self
  # 처럼 이 블록도 로직은 공유하지 않고(독립 설계) 동일성만 테스트로 보장한다.
  extract_block() {
    awk '/^TASK_PREFIX_DEFAULT=/,/^readonly BRANCH$/' "$1"
  }

  commit_msg_block="$(extract_block "${GITFORMAT_ROOT}/hooks/commit-msg")"
  post_commit_block="$(extract_block "${GITFORMAT_ROOT}/hooks/post-commit")"

  [ -n "$commit_msg_block" ]
  [ -n "$post_commit_block" ]
  [ "$commit_msg_block" = "$post_commit_block" ]
}

@test "gitformat.conf 읽기 검증 가드가 CONF를 읽는 7개 파일에서 동일하다 (GF-76)" {
  # commit-msg/pre-commit/post-commit/checks/{cpp,java,sql}.sh/install.sh는
  # 각자 독립적으로 이 가드를 갖고 있다(resolve_self와 같은 설계 원칙, decision-9).
  # gitformat.conf 자체를 못 읽을 때 원인을 명확히 알려주는 조기 진단이라, 7곳
  # 모두 같은 문구/로직이어야 한다. 새 파일에 CONF를 읽는 로직을 추가할 때는
  # 이 목록도 같이 갱신해야 한다.
  files="${GITFORMAT_ROOT}/hooks/commit-msg
${GITFORMAT_ROOT}/hooks/pre-commit
${GITFORMAT_ROOT}/hooks/post-commit
${GITFORMAT_ROOT}/hooks/checks/cpp.sh
${GITFORMAT_ROOT}/hooks/checks/java.sh
${GITFORMAT_ROOT}/hooks/checks/sql.sh
${GITFORMAT_ROOT}/install.sh"

  extract_block() {
    awk '/^if ! git config --file "\$CONF" --list/,/^fi$/' "$1"
  }

  reference=""
  while IFS= read -r f; do
    body="$(extract_block "$f")"
    if [ -z "$body" ]; then
      echo "gitformat.conf 읽기 검증 가드를 찾을 수 없음: $f" >&2
      false
    fi
    if [ -z "$reference" ]; then
      reference="$body"
    elif [ "$body" != "$reference" ]; then
      echo "gitformat.conf 읽기 검증 가드가 다름: $f" >&2
      false
    fi
  done <<EOF
$files
EOF
}
