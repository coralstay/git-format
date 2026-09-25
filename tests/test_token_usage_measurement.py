"""Tokens-Used/Tool-Calls 측정을 본다(decision-5 확장, GF-96/GF-97/GF-112).

구 robustness-post-commit.bats의 토큰 측정 케이스. 값은 Claude Code 세션
트랜스크립트(JSONL)의 델타 구간을 집계해 얻고, 커서는 .git/.gitformat-token-cursor에
남는다. 측정할 수 없는 경우에도 조용히 생략하지 않고 unavailable (사유)로 명시하는
것이 GF-97이 고정한 동작이다.

GF-111에서 트랜스크립트 파싱이 jq 서브프로세스에서 json.loads()로 바뀌어 jq 의존성이
사라졌다 — "jq가 없으면 skip"하던 가드가 없으므로 이 케이스들은 모든 환경에서 실제로
실행된다.
"""

import unittest

from isolated_repo import IsolatedRepoTestCase

CURSOR_NAME = ".gitformat-token-cursor"


def assistant(input_tokens, output_tokens, tool_names=()):
    return {
        "type": "assistant",
        "message": {
            "usage": {"input_tokens": input_tokens, "output_tokens": output_tokens},
            "content": [{"type": "tool_use", "name": n} for n in tool_names],
        },
    }


class TokenUsageMeasurementTest(IsolatedRepoTestCase):
    def cursor_value(self):
        return self.git_dir_file(CURSOR_NAME).read_text(encoding="utf-8").strip()

    def test_알려진_usage_값이_정확히_합산된다(self):
        """[GF-96] 알려진 usage 값을 가진 트랜스크립트로 커밋하면 Tokens-Used/Tool-Calls가 정확히 합산된다"""
        home = self.fake_home()
        self.write_transcript(
            home,
            [
                {
                    "type": "assistant",
                    "message": {
                        "usage": {"input_tokens": 10, "output_tokens": 5},
                        "content": [{"type": "text", "text": "hi"}],
                    },
                },
                assistant(20, 10, ("bash", "grep")),
                {"type": "user", "message": {"content": "hello"}},
            ],
        )
        self.write("a.txt", "hi\n")
        self.git_ok("add", "a.txt")
        self.assertAccepted(
            self.commit("[feat] token usage first commit", env=self.claude_env(home))
        )
        message = self.head_message()
        self.assertTrailerCount(message, "Tokens-Used: 45", 1)
        self.assertTrailerCount(message, "Tool-Calls: 2", 1)
        self.assertEqual("3", self.cursor_value())

    def test_두_번째_커밋은_새로_추가된_줄만_집계한다(self):
        """[GF-96] 같은 세션의 두 번째 커밋은 첫 커밋 이후 새로 추가된 줄만 델타로 집계한다"""
        home = self.fake_home()
        env = self.claude_env(home)
        self.write_transcript(home, [assistant(10, 5)])
        self.write("a.txt", "hi\n")
        self.git_ok("add", "a.txt")
        self.assertAccepted(self.commit("[feat] token usage commit one", env=env))
        self.assertTrailerCount(self.head_message(), "Tokens-Used: 15", 1)

        self.write_transcript(home, [assistant(1, 1), assistant(2, 2, ("bash",))])
        self.write("b.txt", "bye\n")
        self.git_ok("add", "b.txt")
        self.assertAccepted(self.commit("[feat] token usage commit two", env=env))
        message = self.head_message()
        self.assertTrailerCount(message, "Tokens-Used: 6", 1)
        self.assertTrailerCount(message, "Tool-Calls: 1", 1)
        # 누적 합(21)이 아니라 델타(6)여야 한다.
        self.assertTrailerCount(message, "Tokens-Used: 21", 0)
        self.assertEqual("3", self.cursor_value())

    def test_트랜스크립트_파일이_없으면_사유가_명시된다(self):
        """[GF-97] 트랜스크립트 파일이 없으면 Tokens-Used/Tool-Calls가 unavailable (transcript-not-found)로 명시된다"""
        home = self.fake_home()
        self.write("a.txt", "hi\n")
        self.git_ok("add", "a.txt")
        self.assertAccepted(
            self.commit(
                "[feat] no transcript file",
                env=self.claude_env(home, session_id="nonexistent-session"),
            )
        )
        message = self.head_message()
        self.assertTrailerCount(
            message, "Tokens-Used: unavailable (transcript-not-found)", 1
        )
        self.assertTrailerCount(
            message, "Tool-Calls: unavailable (transcript-not-found)", 1
        )
        self.assertFalse(self.git_dir_file(CURSOR_NAME).exists())

    def test_claude_code_외_도구는_no_usage_channel로_명시된다(self):
        """[GF-97] claude-code 외 AI 도구가 감지되면 unavailable (no-usage-channel)로 명시된다"""
        self.write("a.txt", "hi\n")
        self.git_ok("add", "a.txt")
        # commit-msg 게이트(decision-5)는 claude-code 외 AI 도구가 감지되면
        # gitformat.aiModel이 설정돼 있을 것을 요구한다 — 이 테스트의 관심사는 그
        # 게이트 통과 이후 post-commit의 분기이므로 먼저 채워둔다.
        self.git_ok("config", "gitformat.aiModel", "gpt-5")
        self.assertAccepted(
            self.commit("[feat] other ai tool", env={"AI_AGENT": "other-tool_1-0"})
        )
        message = self.head_message()
        self.assertTrailerCount(message, "AI-Tool: other-tool", 1)
        self.assertTrailerCount(
            message, "Tokens-Used: unavailable (no-usage-channel)", 1
        )
        self.assertTrailerCount(message, "Tool-Calls: unavailable (no-usage-channel)", 1)

    def test_실측_0은_unavailable이_아니라_0으로_명시된다(self):
        """[GF-97] 실측 결과가 정말 0이면 unavailable이 아니라 Tokens-Used: 0/Tool-Calls: 0으로 명시된다"""
        home = self.fake_home()
        self.write_transcript(home, [assistant(0, 0)])
        self.write("a.txt", "hi\n")
        self.git_ok("add", "a.txt")
        self.assertAccepted(
            self.commit("[feat] genuine zero token delta", env=self.claude_env(home))
        )
        message = self.head_message()
        self.assertTrailerCount(message, "Tokens-Used: 0", 1)
        self.assertTrailerCount(message, "Tool-Calls: 0", 1)
        self.assertNotIn("unavailable", message)
        self.assertEqual("1", self.cursor_value())

    def test_깨진_줄이_있으면_배치_전체가_실패하고_커서는_그대로다(self):
        """[GF-112] 새 구간에 깨진 줄이 하나라도 있으면 배치 전체가 unavailable (transcript-parse-failed)이고 커서는 그대로다"""
        home = self.fake_home()
        env = self.claude_env(home)
        self.write_transcript(home, [assistant(10, 5)])
        self.write("a.txt", "hi\n")
        self.git_ok("add", "a.txt")
        self.assertAccepted(
            self.commit("[feat] parse failure baseline commit", env=env)
        )
        self.assertTrailerCount(self.head_message(), "Tokens-Used: 15", 1)
        self.assertEqual("1", self.cursor_value())

        # 새 구간에 정상 줄과 깨진 줄을 함께 넣는다 — 깨진 줄만 건너뛰고 정상 줄을
        # 집계하면 "일부만 집계된 값"이 정상값인 척 기록되므로, 배치 전체가 실패해야
        # 한다(GF-111 AC #4가 고정한 동작).
        self.write_transcript(
            home, [assistant(7, 3), "{ this line is not valid json"]
        )
        self.write("b.txt", "bye\n")
        self.git_ok("add", "b.txt")
        self.assertAccepted(self.commit("[feat] parse failure commit", env=env))
        message = self.head_message()
        self.assertTrailerCount(
            message, "Tokens-Used: unavailable (transcript-parse-failed)", 1
        )
        self.assertTrailerCount(
            message, "Tool-Calls: unavailable (transcript-parse-failed)", 1
        )
        self.assertTrailerCount(message, "Tokens-Used: 10", 0)
        # 커서가 그대로라야 다음 커밋이 같은 구간을 다시 시도한다.
        self.assertEqual("1", self.cursor_value())


if __name__ == "__main__":
    unittest.main()
