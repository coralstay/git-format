---
id: doc-5
title: 저장소 구조
type: guide
created_date: '2026-09-19 05:27'
updated_date: '2026-09-19 05:27'
---
## 📁 저장소 구조

```
git-format/
├── hooks/                  # core.hooksPath가 가리키는 실제 훅
│   ├── commit-msg
│   ├── pre-commit
│   ├── post-commit
│   ├── gitformat.conf      # 내부 기본값 한 곳에 모음(git config 포맷)
│   └── checks/{ts,python,java,cpp,sql}.sh
├── template/                # init.templateDir용 (hooks/*는 install.sh --global이 생성)
├── .gitmessage               # commit.template
├── install.sh
├── tests/                    # bats-core 테스트(dev 전용, decision-8)
├── .github/workflows/        # test.yml - 이 저장소 자신의 dev용 CI(shellcheck+bats)뿐,
│                              #   컨슈머에게 제공하는 서버사이드 검증 기능은 없음(decision-11)
└── backlog/                  # 이 저장소 자체 개발 관리(decision, task)
```
