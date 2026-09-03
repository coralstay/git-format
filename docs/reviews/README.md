# docs/reviews/

`.github/workflows/weekly-review.yml`이 매주 자동으로 생성하는 종합 코드 리뷰
기록이다. 사람이 대화형 세션에서 실행하는 `/review-full` 슬래시 커맨드(로컬
전용, `.claude/commands/review-full.md` — `.gitignore`의 `.claude/` 규칙에 따라
저장소에는 커밋되지 않는다)와 같은 절차를 따르되, 자동 실행은 claude.ai
Artifact를 발행할 수 없어(대화형 세션 전용 기능) 결과를 이 디렉터리에
`weekly-<YYYY-MM-DD>.md` 파일로 커밋하는 방식으로 남긴다.

- **트리거**: 매주 1회 GitHub Actions `schedule`(cron) + 수동 `workflow_dispatch`.
- **실행자**: `anthropics/claude-code-action` — 저장소의 `ANTHROPIC_API_KEY`
  시크릿이 필요하다(설정 방법은 `.github/workflows/weekly-review.yml` 상단 주석 참고).
- **내용 구조**: 프로그램 개요 / 기능 상세 / 비기능 요구사항 / 아키텍처 · 파일
  관계도 / 데이터 흐름 / 설계 결정의 역사 / 테스트 커버리지 / 발견 사항 / 권고
  사항 — 9개 섹션은 매주 고정, 내용은 그 시점 저장소 상태를 다시 읽어 갱신한다.
- 알려진 제약: GitHub Actions의 `schedule` 트리거는 저장소가 60일 이상
  비활성 상태면 자동으로 비활성화된다(GitHub 자체 정책). 오래 커밋이 없었다면
  `workflow_dispatch`로 수동 실행하거나 Actions 탭에서 워크플로를 다시
  활성화해야 한다.
