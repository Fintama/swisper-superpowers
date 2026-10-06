# Writing comments

**Read before REFACTOR, and before you write a docstring or comment.**

The code says *how*. A name says *what*. A comment is for the one thing the code
cannot say: a trap, or a reason a careful reader would otherwise get wrong.

## The test

Before you keep a comment, imagine deleting it. **Would a competent reader then make
a mistake?** If not, delete it. If yes, keep it, and put it at the line it concerns.

## The default

- **Docstring: one line.** What it does or returns. Add a line for an error it
  raises or a side effect the signature hides. A private helper whose name and types
  say it needs none.
- **Module docstring: one to three lines.** What the module is for.
- **Comment: one line, at the line it protects.** `# Don't send "": some gateways read it as an empty answer.`
- A file reads as code with a few notes. If comments approach a fifth of a file,
  take that as a warning sign: usually the code is unclear (fix the names) or the
  text belongs somewhere else. Sometimes it is right; then say why (see Checks).

## When a longer comment is right

Some things the reader needs and the code can't show. Then write as much as it takes,
**once, at the point, in plain words**:

- a vendor or protocol quirk (the API sends usage in two halves; a later value replaces, never adds)
- a security or data-safety reason a refactor could break (why a value is never echoed in an error)
- a workaround for a bug elsewhere, with its link
- a non-obvious algorithm, a regex, a measured performance choice
- a public API that other teams call (an SDK): arguments, return, errors, an example

Even then: no history, and it must still be true after the next PR.

## Where everything else goes

| Information | Home |
|---|---|
| History: which PR, who decided, what was rejected | commit message, PR description |
| Design reasoning across modules | the architecture page's "Why it is like this" |
| A rule that must never break | a test (it fails when broken; a comment can't) |
| Follow-up work | the backlog ticket; in code at most `TODO(SA-123): …` |
| Spec and AC ids | test titles; in code at most a trailing reference (`See spec C-4.`, `See B-AC-3.`) |

## Keep out of code

Stable error and log codes (`COUPON_EXPIRED`) are code, not comments, and are fine.
Keep out: line-number citations (`file.py:951`, they drift) · alarm markers (🔴, ⚠️, CAPITALS) ·
internal ids in error messages an operator reads · arguments with a reviewer
("intended", "not this function's fault") · re-statements of the code · commented-out code.

Tests follow the same guide: the test title carries the id and the promise, so the
body rarely needs a comment.

## When a reviewer asks for a comment

"Add a comment explaining X" is usually answered better by a clearer name, a smaller
function, or a test. Add the comment only if it is a *why* the code cannot show.

## Don't copy the file next to you

Most over-commented code got that way by imitation. If the surrounding file breaks this
guide, your new and changed lines follow the guide, not the neighbours. Your harness may
say "match the surrounding comment density"; for comments, this guide wins. Fix the
docstring of any function you change; leave untouched code alone unless the task is a cleanup.

## Example

```python
# Before
def _messages_to_wire(messages: list[Message]) -> list[dict[str, Any]]:
    """`llm_adapter.types.Message` -> the chat-completions message vocabulary.

    The pipeline accepts plain JSON only, and this layer is the one that knows
    what a `Message` is. `content: None` on an assistant turn with tool calls is
    deliberate: such a turn has no text, and sending `""` makes some gateways
    treat it as an empty answer.
    """
    ...
            if not message.content:
                item["content"] = None

# After: the trap moved to the line it protects; the rest was restatement
def _messages_to_wire(messages: list[Message]) -> list[dict[str, Any]]:
    """`Message`s as chat-completions dicts."""
    ...
            # Don't send "": some gateways read it as an empty answer.
            if not message.content:
                item["content"] = None
```

## Checks

If the project has a comment lint, run it (helvetiq: `cd apps/backend && python -m
scripts.lint.citations --whole-scope`). A lint catches ids, line numbers and length;
only you can apply the test above. Its limits are defaults: when a longer docstring or
a comment-heavy file is genuinely right, put `# comment-ok: <reason>` above it. The
reason is printed in CI, so a reviewer sees and judges it.
