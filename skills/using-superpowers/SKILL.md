---
name: using-superpowers
description: Use when starting any conversation - establishes how to find and use skills, and that a skill which plausibly applies is invoked before any response, including clarifying questions
---

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, skip this skill.
</SUBAGENT-STOP>

# Using skills

**When a skill plausibly applies, invoke it before you respond or act**, and always when
the user names one. That includes simple questions, clarifying questions, and a quick look at
the codebase, git or files: the skill may say how to do exactly that. If no skill fits, just
answer. If a loaded skill turns out not to fit, set it aside and carry on.

## Who wins

1. The user's instructions (CLAUDE.md, AGENTS.md, direct requests).
2. Skills, where they conflict with default behaviour.
3. The default system prompt.

If CLAUDE.md says "don't use TDD" and a skill says "always use TDD", follow CLAUDE.md.

## Loading a skill

- **Claude Code:** the `Skill` tool, with the plugin prefix: `swisper-superpowers:brainstorming`.
  Follow the loaded content directly. Invoke the skill rather than reading its SKILL.md with
  Read, and invoke it again rather than working from memory, because skills change. Supporting
  files a skill points you to (for example `clean-code.md`) you open with Read.
- **Copilot CLI:** the `skill` tool. **Gemini CLI:** `activate_skill`. **Codex:** skills load
  natively. Elsewhere, check the platform's documentation.
- Skills use Claude Code tool names. Equivalents: `references/copilot-tools.md`,
  `references/codex-tools.md`, `references/gemini-tools.md`.

## Once it is loaded

- Say which skill you are using and why: "Using writing-plans to sequence the spec."
- If it has a checklist, make one todo per item.
- Rigid skills (TDD, debugging) are followed as written. Flexible ones (patterns) are
  adapted to the context. The skill says which.

## Which skill first

Process skills come before implementation skills, because they decide how to approach the
task. "Build X" starts with brainstorming; "fix this bug" starts with systematic-debugging.
Before entering plan mode for new work, run brainstorming if it has not been done.

A request says what to do, not how: "add X" or "fix Y" is not a reason to skip a skill's
workflow.
