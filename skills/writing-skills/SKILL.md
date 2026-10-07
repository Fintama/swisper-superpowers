---
name: writing-skills
description: Use when creating new skills, editing existing skills, or verifying skills work before deployment
---

# Writing Skills

## Overview

**Writing a skill is test-driven development applied to process documentation.** You run a
pressure scenario on a subagent without the skill and watch it fail (the baseline), write the
skill, watch the agent comply, then close the loopholes it found. If you didn't watch an agent
fail without the skill, you don't know whether the skill teaches the right thing.

Background: swisper-superpowers:test-driven-development defines the RED-GREEN-REFACTOR cycle
this skill adapts. Anthropic's general authoring guide is linked, with the points this repo
relies on, in [anthropic-best-practices.md](anthropic-best-practices.md). The test method
(scenarios, pressures, closing loopholes) has one home:
[testing-skills-with-subagents.md](testing-skills-with-subagents.md).

In this repo a skill lives at `skills/<name>/SKILL.md`, ships in the `swisper-superpowers`
plugin, and is invoked as `swisper-superpowers:<name>`.

## What a skill is, and what it is not

A skill is a reusable technique, pattern, tool or reference that changes what the reader does.

**A skill holds rules, each with at most one clause of reason** ("…, because X"). The evidence
behind a rule (the measurement, the incident, the dated ruling, what the rule replaced) goes to
`CHANGELOG.md`, and for a fork enhancement to its row in `DIVERGENCE.md`, not into the
skill: no "Measured 2026-…", no "in session X we found…", no "this section used to say…".

Create a skill when the technique was not obvious, applies across projects, and others would
use it. Don't create one for a one-off, for practice documented well elsewhere, for a
project's own conventions (CLAUDE.md or AGENTS.md), or for a constraint a script or lint can
enforce (automate it and keep the skill for judgment).

## Length and tone

**As short, concise and clear as possible, but as long as necessary.** There is no word or line
target. For each sentence, ask: does it change what the reader (an implementer or a lead) does?

- Yes: keep it, however long the skill gets.
- No: cut it. That covers duplicates (keep one home and point to it), dated stories, histories
  of what was removed, a rationale tail on every rule, red-flag or rationalization tables that
  repeat the body, examples that repeat the rule, and outdated steps.

`using-superpowers` is injected into every session, so each of its sentences costs every
session; hold it to the test most strictly.

Write plain sentences. No 🔴, ⚠️ or ⛔, no bold capitals; bold the one key phrase of a section at
most. Implementers copy a skill's style into code and comments, so a skill written as alarms
teaches alarms.

Absolute language ("never", "no exceptions") is for safety rails only: secrets and printing
env, prod and a release freeze, main merges that need the human's OK, removing a dirty
worktree, re-spawning a live lane. Any other rule is a default with its named exception.

State a rule as a trigger and an action ("when X, do Y"), not as a general aim. Where following
matters, ask for an explicit act: announce the skill, choose A, B or C, one todo per checklist
item. Don't use flattery or an appeal to being liked to get compliance; it produces sycophancy.

Ways to stay short: point to `--help` instead of listing flags; reference another skill instead
of repeating its workflow; one example per pattern; don't explain what the command already
says.

## Frontmatter and description

- Two required fields, `name` and `description` (see the
  [specification](https://agentskills.io/specification)), at most 1024 characters together.
- `name`: letters, numbers and hyphens. Verb-first or a gerund that names what you do:
  `condition-based-waiting`, not `async-test-helpers`.
- `description`: third person, starting "Use when…", naming the triggers, symptoms and
  contexts. It may say in a few words what the skill is for, but **it never summarizes the
  skill's process**, because an agent follows a summarized workflow from the description and
  skips the body.

```yaml
# Bad: summarizes the workflow, so the agent does what the description says
description: Use when executing plans - dispatches subagent per task with code review between tasks
# Good: triggers only
description: Use when executing implementation plans with independent tasks in the current session

# Bad: technology named, but the skill is not specific to it
description: Use when tests use setTimeout/sleep and are flaky
# Good: describes the problem
description: Use when tests have race conditions, timing dependencies, or pass/fail inconsistently
```

If the skill is technology-specific, say so in the trigger ("Use when using React Router and
handling authentication redirects"). Use the words an agent would search for: error messages,
symptoms, synonyms, tool names, and put them early.

## Structure

```
skills/<name>/
  SKILL.md            # required
  supporting-file.*   # only for heavy reference (100+ lines) or a reusable tool
```

Keep principles and code patterns under ~50 lines inline. Link supporting files one level deep
from SKILL.md. A typical SKILL.md has: Overview (the core principle in a sentence or two), When
to use (symptoms, and when not), the core pattern or rules, a quick reference, and common
mistakes. Use only the sections that carry something.

**Links.** Name another skill with its prefix: `swisper-superpowers:test-driven-development`,
marked as required background or required sub-skill where it is. Link a supporting file with a
plain relative path or markdown link, not `@file` syntax, because `@` force-loads the file into
context before it is needed.

**Flowcharts** only for a non-obvious decision, a loop where an agent might stop too early, or
"A or B". Not for reference (use a table), code (use a code block) or linear steps (use a
numbered list), and with labels that mean something. Style rules:
[graphviz-conventions.dot](graphviz-conventions.dot). To show a human, `./render-graphs.js
../<skill>` renders a skill's diagrams to SVG (`--combine` for one file).

**Code examples:** one excellent example in the most relevant language (shell or Python for
system work, TypeScript for testing techniques), complete, runnable, from a real scenario. No
ports to five languages, no fill-in-the-blank templates. Its comments follow
[clean-code.md](../test-driven-development/clean-code.md), because the example is what gets
copied.

## The Iron Law

**No new skill and no behavioural edit without a failing baseline first.**

A behavioural edit is anything that can change what an agent does: a new or changed rule, a
condensed section, a removed table. Wrote it before the baseline? Revert it, run the baseline,
then write it again; don't keep the untested version as a reference.

**Exempt:** mechanical or factual edits that change no instruction (a skill prefix, a path, a
typo, a link, a renamed file, a stale version or tool name). If you are unsure whether an edit
is behavioural, treat it as behavioural.

Test each skill before starting the next; batching untested skills is the same as shipping
untested code.

## The process

Make one todo per item.

**RED**
- [ ] Write scenarios for the skill's type (3+ combined pressures for a discipline skill) and
  run them without the skill. Record the choices and rationalizations verbatim. How:
  [testing-skills-with-subagents.md](testing-skills-with-subagents.md).

**GREEN**
- [ ] Write the skill against those failures only; nothing for hypothetical cases.
- [ ] Frontmatter and description as above.
- [ ] Run the same scenarios with the skill; the agent now complies.

**REFACTOR**
- [ ] Close each new loophole and re-test until no new rationalization appears.

**Quality**
- [ ] Every sentence passes the length test; no dated story, no history, no alarm markers.
- [ ] Links resolve; no `@` links; other skills named with the `swisper-superpowers:` prefix.

**Ship the edit** (mechanical edits too)
- [ ] `DIVERGENCE.md`: if the edit adds or changes something upstream `superpowers` lacks, add
  or update its row (the marker must hit our SKILL.md and miss upstream). If you removed a
  phrase that is a marker, update its row. Run `bash scripts/divergence-check.sh`; if you
  changed the checker, also `bash scripts/divergence-check-control.sh`.
- [ ] `CHANGELOG.md`: an entry under `[Unreleased]`. This is where the evidence goes.
- [ ] Bump `version` in `.claude-plugin/plugin.json`; a plugin update against an unchanged
  version installs nothing.
- [ ] Open a PR. After it merges, update the plugin (`INSTALL.md`, "Updating") and restart the
  session, because a session builds its skill table at startup.
