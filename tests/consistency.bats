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
