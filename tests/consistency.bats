#!/usr/bin/env bats
# 여러 파일에 "값은 같아야 하지만 로직/문서는 공유하지 않는" 항목들이 실제로
# 일치하는지 검증한다(런타임 결합 없이 테스트로만 drift를 잡는다는 게 이
# 프로젝트의 설계 원칙 - decision-8/decision-9 참고).

load 'helpers/git-format'

@test "gitformat.conf의 커밋 타입 목록과 .gitmessage에 적힌 타입 목록이 일치한다 (GF-68)" {
  CONF_TYPES="$(git config --file "${GITFORMAT_ROOT}/hooks/gitformat.conf" \
    --get-all gitformat.type | sort)"
  MSG_TYPES="$(sed -n '/type 목록/,/scope (선택)/p' "${GITFORMAT_ROOT}/.gitmessage" \
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
    gitformat.trailer.hooksCommit \
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

@test "resolve_self() 6개 사본이 글자 그대로 동일하다 (GF-62)" {
  # commit-msg/pre-commit/pre-push/post-commit/checks/cpp.sh/checks/sql.sh는
  # 각자 독립적으로 resolve_self()를 갖고 있다(로직은 공유하지 않는다는 설계
  # 원칙, decision-9). 이 함수 자체는 지금 6곳 모두 동일해야 하고, 한 곳만
  # 고치고 나머지를 빠뜨리면(GF-16류) 이 테스트가 잡는다.
  files="${GITFORMAT_ROOT}/hooks/commit-msg
${GITFORMAT_ROOT}/hooks/pre-commit
${GITFORMAT_ROOT}/hooks/pre-push
${GITFORMAT_ROOT}/hooks/post-commit
${GITFORMAT_ROOT}/hooks/checks/cpp.sh
${GITFORMAT_ROOT}/hooks/checks/sql.sh"

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
