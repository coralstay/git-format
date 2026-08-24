# template/

`git config --global init.templateDir`가 가리키는 디렉터리다(decision-2).
`git init`/`git clone`을 실행할 때마다 git이 이 디렉터리의 내용을 새 저장소의
`.git/`로 복사한다 — 특히 `hooks/` 하위 파일들은 `.git/hooks/`로 복사된다.

`template/hooks/`는 이 저장소를 클론한 위치에 따라 달라지는 절대경로 심볼릭
링크라서 git에 커밋하지 않는다(.gitignore 참고). `install.sh --global`(또는
프롬프트에서 y 선택)을 실행하면 그 시점에 자동으로 생성된다.
