# Clean code and comments

**Read before REFACTOR, and before you write any docstring or comment.**

Code says *how*. A docstring says *what*: the contract. A comment says *why*,
and only when the code cannot. Everything else has a better home, where it can't
go stale inside the code.

## Where each kind of information belongs

| Information | Home |
|---|---|
| **What** it does: inputs, outputs, errors raised | Docstring, short |
| **Why** something non-obvious is done this way | Comment, at the line it concerns |
| **How** it works | The code itself: names, structure |
| **History**: who decided, which PR, what was refused | Git commit and PR description |
| **Design rationale** across modules | Architecture page, "Why it is like this" |
| **Rules that must never break** | Tests, because a test fails when someone breaks the rule and a comment can't |
| Follow-up work, known debt | The backlog (Jira), not a "PR-n will…" comment |

## 🔴 Do not match the comment style around you

Most heavily commented code was written by agents copying the code next to it.
**When the surrounding file breaks these rules, your new and changed lines follow
this file, not the neighbours.** Your harness may tell you to match the
surrounding comment density. For comments, this file overrides that.

Do not rewrite untouched comments elsewhere in the file (minimal change), unless
the task is a cleanup. **Do** fix the docstring of any function you change.

## Docstrings: the contract

- Start with **one line** that says what it does or returns. Usually that is enough.
- Add more only for what a caller needs and the signature can't show: a
  non-obvious argument, a unit, an error it raises, a side effect.
- **About 1–5 lines.** If you need more, the function probably does too much.
- Private helpers with a clear name and types often need no docstring at all.

## Comments: the why

Write a comment only when a careful reader would get it wrong without it:

- a **hazard**: "Don't default these to 0: absence and zero must stay different."
- a **non-obvious reason**: "Built once: TypeAdapter compiles its validator on construction."
- an **external constraint**: "The vendor sends usage in two halves; a later value replaces, never adds."

## Never in code

| Pattern | Instead |
|---|---|
| History: `PR-6a`, "was proposed and refused", review ruling ids, dates, reviewer names | Commit message and PR description |
| A spec, AC or review id used as the explanation (`C-4`, `HC-7`, `AM-12`) | Say the rule in plain words. A trailing reference (`See spec C-4.`) is allowed, at most once per symbol. **AC ids live in test titles** (R2), not in production comments |
| Internal ids in **error messages or log text** an operator reads | Plain words: what is wrong, which node or field, what is allowed |
| Line-number citations (`openai_compat.py:951`) | `path::Symbol`, or nothing. Line numbers drift with the next edit |
| Re-stating the code ("returns provider, else wire" above code that does exactly that) | Delete it, or make the name say it |
| Alarm markers: 🔴, ⚠️, **bold capitals**, "CRITICAL" | Plain sentences. When everything is red, nothing is |
| Defending against a reviewer ("intended by…", "this loss is the other type's, not this function's") | Write for the next developer, not the last reviewer |
| Measurements and narratives ("Measured 2026-09-14: …", "SPIKE §9 found…") | PR description or architecture page. State the resulting rule in one line if the code needs it |
| "Temporary", "PR-n performs the swap", "until X lands" | A backlog ticket. If you must mark it in code, `TODO(SA-123): …` |
| Commented-out code | Delete it. Git has it |

## Clean code beyond comments

The `senior-engineer pass` (implementer prompt) decides the design. These are
the line-level rules:

- **Names carry the meaning.** If a comment explains what a variable or function
  is, rename it instead and delete the comment.
- **One function, one job.** If you'd write "and" in its one-line docstring, split it.
- **Guard clauses over nesting.** Handle the refusal or empty case first and return.
- **Named constants** for magic numbers: `RETRY_LIMIT = 3`, not `3  # retry limit`.
- **Error messages are documentation that reaches the person with the problem:**
  name the thing, the bad value, and what would be accepted.
- **No dead code**, no unused parameters, no "just in case" branches.

## Example

The "before" is what an implementer wrote when given a spec with ids, a review
ruling, and a heavily commented file next to it:

```python
# ❌ before: 32 lines of documentation for 14 lines of code
def select_wire(row: dict[str, Any], registry: dict[str, object]) -> tuple[str, object]:
    """The wire name and instance a resolved generation row states.

    🔴 **C-4 / HC-3: refuse, never substitute.** A row with no `wire` is refused;
    a row naming a wire *registry* does not hold is refused. Its `provider` or
    route NAME never chooses a wire, and no registered wire stands in for an
    unregistered one (AM-12).
    """
    ...
        raise RowMisconfigured(
            f"node {node!r} states wire {stated!r}, which this runtime does not "
            f"register. Registered wires: {sorted(registry)}. A stated wire is "
            f"never substituted by another (AM-12)."
        )
```

```python
# ✅ after
def select_wire(row: dict[str, Any], registry: dict[str, object]) -> tuple[str, object]:
    """Return the wire the row names, as `(name, wire)`.

    Raises RowMisconfigured if the row names no wire or one that is not
    registered. There is deliberately no fallback: a substitute wire would send
    one vendor's request format to another vendor's host.
    """
    ...
        raise RowMisconfigured(
            f"node {node!r} names wire {stated!r}, which is not registered. "
            f"Registered wires: {sorted(registry)}."
        )
```

The ruling's *reason* stays, in one sentence. Its *history* (PR-6a, AM-12, the
date) goes in the PR description. Its *enforcement* is the T-AC test that fails
if a fallback comes back.

## Self-check before you commit

For each docstring or comment you added or changed:

1. Does the code (names, types, structure) already say this? → delete it.
2. Is it for the **next developer** or the **last reviewer**? → only the first stays.
3. Will it still be true after the next PR? History, plans and line numbers won't be.
4. Could a newcomer understand it **without the spec open**?
5. Is it a rule that must never break? → it needs a test. The comment is optional.

## Red flags

- Your docstring is longer than the function body
- It contains a PR number, a date, a reviewer's ruling, or "was refused"
- It contains 🔴, ⚠️ or a sentence in bold capitals
- An error message cites a spec id
- You are copying the comment style of the file next to you
