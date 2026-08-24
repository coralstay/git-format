# Conventional Commits v1.0.0 (한국어 요약 vendoring)

> 원문: https://www.conventionalcommits.org/ko/v1.0.0/
> 이 문서는 git-format이 커밋 메시지 규칙(decision-1)의 근거로 삼는 원문을 오프라인에서도
> 참고할 수 있도록 핵심 내용을 요약해 옮겨 적은 것이다. 전문(全文)이 아니라 요약이므로,
> 정확한 표현이나 세부 사항이 필요하면 원문을 확인할 것.

## 커밋 메시지 구조

```
<type>[(scope)][!]: <description>

[optional body]

[optional footer(s)]
```

## type 목록

| type | 의미 | SemVer |
|---|---|---|
| `feat` | 새로운 기능 추가 | MINOR |
| `fix` | 버그 수정 | PATCH |
| `docs` | 문서 변경 | - |
| `style` | 코드 의미에 영향 없는 스타일 변경(포맷팅, 세미콜론 등) | - |
| `refactor` | 기능 변경 없는 코드 구조 개선 | - |
| `perf` | 성능 개선 | - |
| `test` | 테스트 추가/수정 | - |
| `build` | 빌드 시스템 또는 외부 의존성 변경 | - |
| `ci` | CI 설정/스크립트 변경 | - |
| `chore` | 위에 속하지 않는 기타 변경사항 | - |
| `revert` | 이전 커밋 되돌리기 | - |

## scope (선택)

type 뒤에 괄호로 감싸 변경 범위를 명사로 표기한다. 예: `fix(parser): 빈 입력 처리`.
"코드베이스가 적용되는 영역을 기술하는 명사"로 정의된다.

## description

type/scope 뒤 콜론과 공백 다음에 오는, 변경사항의 짧은 요약.

## body (선택)

description 다음 빈 줄로 시작하며, 변경의 배경과 이유 등 추가 문맥을 제공한다.

## footer (선택)

body 다음 빈 줄 뒤에 위치하며 [git trailer 포맷](https://git-scm.com/docs/git-interpret-trailers)
(`Token: value`)을 따른다. 이슈 참조(`Refs: #123`), 브레이킹 체인지 설명, 기타 메타데이터를
여기에 기록한다.

## BREAKING CHANGE (MAJOR)

호환성을 깨는 변경은 반드시 다음 중 하나로 드러나야 한다.

1. type/scope 뒤에 `!`를 붙인다: `feat(api)!: 응답 형식 변경`
2. footer에 `BREAKING CHANGE: <설명>`을 추가한다

## 이 스펙을 쓰는 이유

- CHANGELOG 자동 생성
- 커밋 이력만으로 SemVer(MAJOR/MINOR/PATCH) 자동 산정
- 변경의 성격을 팀/이해관계자에게 구조적으로 전달
- 빌드/배포 파이프라인 자동화의 입력으로 사용
- 기여자와 관계없이 일관된 커밋 히스토리 유지

## git-format에서의 확장

git-format은 이 표준 footer 문법을 그대로 재사용해 자체 트레일러를 추가한다
(decision-3, decision-4, decision-5): `Task-Id`, `Verify-Bypassed`, `AI-Tool`,
`AI-Tool-Version`, `AI-Session-Id`, `AI-Model`, `Co-Authored-By`, `Hooks-Commit`.
전부 `git interpret-trailers`가 이해하는 표준 trailer 포맷이라 별도 파서가 필요 없다.
