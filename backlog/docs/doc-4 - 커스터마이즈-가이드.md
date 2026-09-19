---
id: doc-4
title: 커스터마이즈 가이드
type: guide
created_date: '2026-09-19 05:27'
updated_date: '2026-09-19 05:27'
---
## 🔧 커스터마이즈

```sh
git config gitformat.taskPrefix PROJ                # Task-Id 접두어 변경 (기본 GF)
git config --add gitformat.branchExempt 'hotfix/*'   # 예외 브랜치 패턴 추가
git config gitformat.aiModel claude-opus-5           # Claude Code가 아닌 AI 도구의 모델명
```

`hooks/gitformat.conf`의 `gitformat.knownModel` 항목에 조직 내부 모델 ID를 추가해도 됩니다.

위 `git config` 오버라이드는 컨슈머 저장소가 값을 바꿀 때 쓰는 것이고, 이
git-format 저장소 자체의 내부 기본값(마커 파일명, trailer 키 이름, 언어 감지
마커, 커밋 타입 목록, AI-Model 화이트리스트 등)은 전부 `hooks/gitformat.conf`
(git config 포맷) 한 곳에 모여 있습니다. 컨슈머가 직접 건드릴 파일은 아니고,
git-format을 포크/커스터마이즈할 때 참고하는 내부 설정 파일입니다.
