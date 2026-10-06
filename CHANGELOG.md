# Changelog

All notable changes to swisper-superpowers will be documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.9.0] - 2026-10-06

### Added
- **Senior-engineer pass** (Heiko, 2026-10-06: "how can I avoid the code being that of a junior developer? What
  would a junior developer do, and how would a senior make it more robust, scalable and maintainable?").
  - `subagent-driven-development/implementer-prompt.md`: before the first test the implementer writes a ≤12-line
    note — **J** 2–4 junior anti-patterns specific to this task (picked from a named list), **S** the senior design
    (reuse by `path::symbol`, failure modes, limits with numbers, compatibility, log codes and timing, what it will
    NOT build), **I** each invariant → the test that proves it. It goes in the first commit's body (proof it came
    first) and verbatim in the report; self-review diffs the code against it.
  - `code-quality-reviewer-prompt.md`: the reviewer grades the diff against the note — a J line present, an S claim
    not borne out, a listed anti-pattern the note missed, or a "will NOT build" item built is a finding.
  - `subagent-driven-development/SKILL.md`: new short section; the dispatch carries the spec's §1 `seam`,
    `mechanism` and `senior` lines; process graph and Red Flags updated. Not a gate — nobody approves the note.
  - `test-driven-development`: the pass picks the tests before the first RED (promise altitude, negative path,
    the named limit, each dependency failing), mapped to R2 ids — it adds no untraced tests. Links `proving-acs.md`.
  - `brainstorming`: §1 gains a one-line `senior` field (junior would… / senior does…) feeding `seam` and
    `mechanism`; it **replaces** the seam's "name the obvious alternative it beat" clause. Self-review check 7
    confirms the rest of the spec carries it (still seven checks; no agent review gate).
  - DIVERGENCE.md: 3 rows guard it.

## [1.8.2] - 2026-10-05

### Fixed
- `trace-check.sh` could report a **false PASS**. A `test.each` table it could not close (`] as const)(`, or the title on the line after `])(`) swallowed every later test in the file, so an untraced `it(...)` after it was never seen. Now a table closes on any `)(`, a title on the next line is read, a new test head while a table is open records the table as unreadable (untraced) and is itself scanned, and a table still open at file end is counted. Four self-test cases cover it, all red on 1.8.1. Reported by Foundry WS7.

## [1.8.1] - 2026-10-05

### Fixed
- `trace-check.sh`: `it.each(X)(` with the title on the next line (the shape biome formats long titles into) was reported as "title is not a string literal"; it is now read like a multi-line call. Two self-test cases cover it (red on 1.8.0, green now). Reported by Foundry WS9.

## [1.8.0] - 2026-10-05

### Changed
- **Tests prove value, not volume** (Heiko, 2026-10-05: "I don't want useless tests … 15000 tests seem an
  overkill"). Measured on Foundry main: ~21,500 test cases, ~18% naming an AC, ~18k backend tests on every merge.
  - `test-driven-development` rewritten around R1–R8: a test proves a promise at the altitude it is received; its
    title names an AC / INV / FM id or it is not written; unit tests only for a pure-core table/property, an
    invariant or a hard-to-reach failure mode; **the test pyramid is replaced** by boundary-first; the plan names
    the tests; strengthen before add; delete what a higher test covers, and report added / strengthened / deleted.
    SKILL.md 767 → ~340 lines; pipeline, contract and mutation tooling moved to `toolchain-matrix.md`.
  - New `test-driven-development/trace-check.sh`: lists new tests whose title names no id and exits 1
    (`trace-allow: <reason>` escape; `--self-test` positive control; added/removed/net counts).
  - `subagent-driven-development` (R9): dispatches carry the plan's named test list; fix rounds and surviving
    mutants strengthen an existing test; reviewers flag untraced or mechanism-only tests as Important with
    strengthen-or-delete; reports and ledger lines count tests added / strengthened / deleted.
  - Aligned so no skill still teaches the old mapping: `requesting-code-review/code-reviewer.md`, `writing-plans`
    (test altitude rule), `verification-before-completion` (test-level check).
  - DIVERGENCE.md: 4 rows guard the new rules.

## [1.7.0] - 2026-10-05

### Changed
- **`update-documentation`: cite code by symbol** (Heiko, 2026-10-05: docs updates were far too slow). Python code is cited
  `path::Symbol`, never `file:line`; `covers.symbols` narrows the staleness gate to the functions a page explains;
  re-verifying a symbol anchor needs no re-counting; `FINDINGS.md` evidence stays `file:line` at `first_seen`; docs
  are written once per (combined) PR at the end. Needs the architecture-site tooling from helvetiq #2544.
- **Seven efficiency rules** (Heiko, 2026-10-05, after the helvetiq model-layer programme took far too long; each
  rule carries its measurement):
  1. `subagent-driven-development`: before task 1, a no-op draft PR proves CI grades the integration branch and is green.
  2. `subagent-driven-development`, `running-a-programme`: rule on the property (plus a failing test), not the
     mechanism; a named mechanism is probed first (≤5 min).
  3. `writing-plans`, `subagent-driven-development`: one PR per wave — parallel tasks in worktrees, merged locally
     `--no-ff`, CI once per wave.
  4. `requesting-code-review`: draft PR and `@codex review` at the first push (drafts are not auto-reviewed;
     the comment trigger is unconfirmed in helvetiq); `finishing-a-development-branch` marks the draft ready.
  5. `writing-plans`, `subagent-driven-development`: generated and shared files once, at the end of the wave PR.
  6. `writing-plans`, `running-a-programme`: ship to main by value — a proven goal is never held for an unfinished one.
  7. `implementer-prompt.md`, `code-reviewer.md`: helpers stay in their own worktree and scratch dir, never write
     through shared tool installs, never delete others' files, never print env.
- DIVERGENCE.md: 12 rows guard these rules.

## [1.6.0] - 2026-10-04

### Changed
- **Docs home (Heiko, 2026-10-04).** For Fintama products, `brainstorming` saves specs to
  `specs/<product>/` and `writing-plans` saves plans to `plans/<product>/` in Swisper_Documentation.
  That repo is main only, written with its `tools/docs-save`, and its README is the rulebook.
  Other projects keep `docs/superpowers/…`. Deferred work goes to the tracker (Jira, project SA),
  not a backlog section.
- **ADRs and TDRs dropped where a project has an architecture site.** `update-documentation`
  records a non-obvious decision in the shaped page's `## Why it is like this` block, and
  technical debt becomes a Jira ticket carrying the finding number. The reviewers and the
  verification checklists check for that record instead of an ADR file.
- React screen mocks stay in the product repo (`design/mocks/<slug>/`); `brainstorming` says so.
- DIVERGENCE.md: three rows guard these paths against an upstream merge.

## [1.5.0] - 2026-10-04

### Added
- **`update-documentation` — the architecture site matches the PR before the PR is
  opened** (Heiko, 2026-10-04: "only when relevant: not when this is a code change or
  a bug fix"). The skill is a decision per page — update, re-verify only, new page or
  nothing — then the edits that decision demands, then proof (`make
  architecture-check`, prettier 3.9.6, a Documentation section in the PR). Baseline
  (`skills/update-documentation/BASELINE-2026-10-04.md`): without it, 7 of 7 runs
  skipped the proof step, 4 of 4 stamps were left unformatted for CI, one agent
  skipped the re-verify on a bug fix because the gate was WARN-only, and one rewrote
  the findings register's pinned evidence. Wired into
  `finishing-a-development-branch` (Step 1b), the `writing-plans` per-PR merge gate
  and the `subagent-driven-development` boundary review, each only for repos with
  `architecture/tools/impact.py`.
- `divergence-check.sh` also requires a `.md` marker to exist as a file, so a merge
  cannot drop `page-standard.md` while the skill still sends agents to it.

### Changed
- **Live coordination uses Claude Code's built-in cross-session messaging**
  (Heiko, 2026-10-01). A running session is reached by `SendMessage` to its session
  name — the name `ListAgents` shows is the address — and the message wakes it. The
  file bus shrinks to two jobs: the mailbox for a session that is not running
  (a built-in message to one is lost — two lanes were unreachable after a restart),
  and the durable record of decisions, rulings and hand-overs. The rules live in
  one place, `running-a-programme/references/messaging.md`. `program.yaml` gains
  `address` per lane and `pm_address`; spawn documents hand a lane its PM's address.

### Removed
- The outbox as the lane-to-PM channel, the lane's mailbox poll cron, the PM's
  outbox-reading wake-up, and `msg.py`'s tmux typing as the live channel. The PM's
  recurring `stall-check` and the board's `Monitor` watch stay — they do something
  other than read mail.

## [1.4.0] - 2026-08-30

### Added
- **`update-program-board` — "A decision channel that only writes a file is half a
  channel."** Measured the hard way: Heiko clicked three decisions on the board,
  could not tell whether any had been seen, and had to ask — then took a screenshot
  to be sure. *"Otherwise the board is only half useful."* He was right, and the
  skill had asserted otherwise: it said the write-back lands in the outbox *"which
  the PM wake-up already reads"*. That was true of the programme it was written for
  and **false of the next one**, where nothing was watching the file at all. A
  mechanism assumed rather than checked.

  Two halves are now mandatory when a board is stood up, and neither is polish:

  - **The wake path.** A click must WAKE the PM, not wait to be noticed. Arm a
    `Monitor` on the outbox **in the same turn the server starts** — with
    `tail -n 0` (or every historical line replays as a fresh event) and
    `--line-buffered` (or grep holds matches in its buffer and the watch is silently
    dead). **Verify it by clicking a button** — a watch that cannot fire looks
    exactly like a quiet afternoon.
  - **The return path.** A `/state` endpoint returning `answers` (parsed back out of
    the outbox, last-wins) and `acks` (`board/acks.json`, written by the PM *after*
    acting), so each card renders one of three states: unanswered · 🟡 answered but
    unacknowledged · ✅ acted, **with what the PM actually did about it**. The `did`
    field is the point and it is not a receipt — *"Acknowledged"* is worse than
    silence, because it looks like closure.

  The general rule this is an instance of: **a channel needs a return path, or the
  sender cannot distinguish "delivered" from "broken"** — the same defect class as a
  guard that cannot fail.

### Fixed
- **`scripts/board-server.py` served the wrong directory and bound a hardcoded
  port.** Its web root was a path from one specific programme's docs submodule, so
  on any other programme it served that programme's mocks or nothing. It now prefers
  `.handover/board` and falls back to the legacy location.
- **Ports are global to the machine, not per-programme.** The port was hardcoded to
  8794; measured 2026-08-30 with two programmes on one laptop, the second simply
  fails to bind. It now reads `board.port` from `program.yaml`.

## [1.3.0] - 2026-08-30

### Changed
- **`setup-delivery-program` §6 no longer spawns lanes — it hands the human an
  opening card per lane.** Lanes are watched in VS Code tabs, and a Claude tab
  can only be opened from inside VS Code: there is no URI, command or CLI that
  creates one with a chosen working directory. The card carries the worktree to
  open a window on and the three lines to paste — `/model`, `/rename`, then the
  one-line briefing. `scripts/spawn-lane.sh` remains as the no-human
  alternative, and is still the only route that pins the model itself.
- **One VS Code window per lane worktree is now stated as a rule.** A Claude tab
  always runs in its own window's folder. Measured 2026-08-30: opening a session
  by id from a window rooted elsewhere does not fail — it silently creates a
  *new, empty* session in the wrong directory. Two lanes sharing one
  `.git/index` produce silent false greens, not conflicts.

### Fixed
- **`spawn-lane.sh` never set the lane's working directory.** It had no `-c`, so
  every lane started in *the PM's* cwd and reached its worktree only if it read
  and obeyed a sentence in its spawn document — the same class as a subagent
  inheriting the session cwd. The worktree is now a required argument, validated
  before boot (exists · is a worktree **root**, since git's upward discovery
  reports the enclosing repo and looks entirely healthy · not already occupied
  by a live session) and **asserted from the running session afterwards**,
  before the lane is typed at, so a mis-placed lane receives nothing. Controlled
  by mutating `-c` to a wrong directory: exit 76, expected vs actual named.
- **The readiness check could not observe readiness.** It grepped the pane for
  `│`, `>` or `Welcome`; Claude Code 2.1.251 draws `❯` and `─` and says no
  "Welcome", so none of the three ever matched. Every spawn burned the full 60s,
  exited 75 "no prompt", and left a healthy un-renamed, un-briefed lane running
  in tmux — a failure report for something that did not fail, and an orphan
  generator. Readiness is now taken from the session registry, which the session
  writes itself and which does not change shape between releases, with the pane
  scrape kept only as the second half and widened to cover both TUIs.
- **`spawn-lane.sh` now reports the lane's session id**, so the monitoring map
  no longer has to be filled in by hand.

## [1.0.3] - 2026-08-28

### Fixed
- **The review loop's click-to-select only reached components under
  `/src/screens/`.** `sourceStamp` stamped nothing else, so anything factored
  into `src/ui/` — the pills, tags and avatars a reviewer actually points at —
  carried no source location. Clicking one walked up to the nearest stamped
  ancestor, usually a layout wrapper or a dialog frame, and the readout named
  that instead. It does not read as "selection is broken"; it reads as
  "selection is coarse", which is why it survived a session of use.
  `sourceStamp` now takes `roots` (default: the whole of `/src/`) and `exclude`
  (default: the review loop itself), and skips `node_modules`. Measured on a
  live mock: a component file went from 0 stamps to 19, and the selection chain
  from 3 levels to the full depth.

- **Browser automation silently overwrote the reviewer's selection.**
  `current-selection.json` is written on every click, and a scripted
  `element.click()` is indistinguishable from a human one to a DOM listener. Any
  agent driving the page to verify its own work destroyed what the reviewer had
  just pointed at — between them clicking and anyone reading the file — and the
  file still looked perfectly valid afterwards. The click handler now ignores
  events where `isTrusted` is false, which no synthetic event can forge.
  Controlled in both directions: scripted clicks leave the file byte-identical,
  a real click still writes it.

## [1.0.2] - 2026-08-28

### Fixed
- **`creating-screen-mocks` assumed a design system is one package.** Phase 2 now
  enumerates org-scoped dependencies from the consuming app's `package.json`,
  because tokens, general components, product-specific components and icons
  normally ship separately — and stopping at the tokens package (which has no
  components at all) is the common failure. Also: **count the filesystem, not the
  registry table.** Measured on Fintama's system, the registry documented 36
  components while 44 shipped. Adds a step to enumerate the app's own
  `domain/`/`blocks/` components, which are usually the real graft target.

## [1.0.1] - 2026-08-28

Found by running the published package against a programme that is not Foundry.
Everything below was green on the machine it was written on, and broken
everywhere else.

### Fixed
- **The programme state directory was never created.** `setup-delivery-program`
  did not mention `.handover/` at all, so `reap-ghosts.sh`, `stall-check.py` and
  `ctx-check.py` aborted on a missing lane map. New
  **`scripts/init-programme.sh`** seeds it, is idempotent, never overwrites an
  existing roster, and **runs the seeded map to prove it works** rather than
  reporting on file existence.
- **`ctx-check.py` and `stall-check.py` had a hard-coded personal transcript
  path** — missed by the portability pass that fixed `ws-pulse.py`. On any other
  machine they read a directory that does not exist, so every lane looked
  silent-with-no-transcript and both reported clean while being structurally
  incapable of reporting anything else. Now use `program_transcripts()`.
- **Both parsed the lane map without stripping comments**, so a row commented out
  per the retirement protocol still counted as a live lane. `reap-ghosts.sh` had
  always stripped them; these two had not.
- **The seeded lane map could not import its own dependencies.**
  `init-programme.sh` now places `program_root.py` and `program_yaml.py` beside
  it — the failure appeared only after the map had been edited.
- **Skills invoked stateless tools from `.handover/`**, the pre-plugin location.
  They now use `$CLAUDE_PLUGIN_ROOT/scripts/`. Both protocol docs gained a header
  stating which tools live where and why the lane map is the exception.
- `gemini-tools.md` referenced `spec-reviewer-prompt.md`, deleted with the
  per-task spec review.
- `respawn-workstream` now warns that `reap-ghosts.sh` must be run in report mode
  first: it reads the lane map to tell live from retired, so an incomplete map
  makes every real session look like a ghost.

## [1.0.0] - 2026-08-28

First public release. The repository moved from a private Fintama repo to a
public one; the history starts fresh here, because making a repo public
publishes everything it has ever contained, not only its current tip.

### Changed
- **Public.** No credentials, no org membership, no auth setup — `INSTALL.md`
  loses its private-repo prerequisite section.
- **`hooks/session-start` taught the wrong rule.** It told every session to use
  bare skill names and never the plugin prefix. Plugin skills are always
  namespaced, so the prefix is required: `swisper-superpowers:brainstorming`.
- `ws-pulse.py` / `ws-pulse-delta.py` ship with an **empty lane map template**
  instead of a live roster. The scripts were always generic; only the data in
  them was not.
- `README.md` rewritten for readers who have never seen this repo, and no longer
  documents the superseded symlink install.

### Removed
- `memory/` — machine-local memory entries, not part of the plugin.
- `setup-user-level.sh`, `install-as-submodule.sh`, `settings.skill-overrides.json`
  — installers for the symlink arrangement this plugin replaced. Shipping them
  invited the failure mode we removed.
- `mirror-memory.sh` — mirrored the `memory/` directory that no longer ships.
- A stray `.superpowers/` brainstorm working directory, committed by accident and
  now gitignored.

## [0.6.0] - 2026-08-28

### Added
- **`creating-screen-mocks`** — how to build a mock that IS the implementation
  spec: ground in the design system, plan, two variants, then a clickable
  prototype. Ships `review-loop/` — source stamping, a current-selection sink,
  progressive drill-in, and `render-gate.mjs`.
- **`running-a-workstream`** and **`running-a-programme`** — the invariants half
  of a lane brief and of the PM seat, so a spawn document carries only state.
  Nothing briefed the PM before.
- **`writing-exec-summaries`** — the five-section report format, made portable.
  It previously existed only in one machine's project memory.
- **`scripts/spawn-lane.sh`** — the tmux spawn recipe `respawn-workstream`
  described in prose, extracted so setup and succession share one implementation.

### Changed
- **`setup-delivery-program`** rewritten: codebase grounding and market research
  before the goals, a gap analysis and validated architecture, **seven explicit
  tests a lane must pass**, and it now stands the lanes up instead of stopping
  at a roster.
- **`brainstorming`** routes a user-visible surface to `creating-screen-mocks`
  BEFORE the spec, and §1 records a **graft target**.
- **Trigger partition** — `brainstorming` is for one feature; programme-sized
  work goes to `setup-delivery-program`. Each description now names the other.
  Previously `brainstorming` swallowed programme work and the other was
  unreachable.
- **`subagent-driven-development`** — the render gate is mechanical, and the
  implementer adapts the mock's files rather than rebuilding from a description.
- **`INSTALL.md`** rewritten for the plugin path; the symlink-plus-overrides
  arrangement is superseded and led into a two-copies hazard.

### Notes
- `DIVERGENCE.md` now carries 29 markers; `scripts/divergence-check.sh` is
  positive-controlled in both directions.
- This repository has **no CI**. The divergence check and skill validation are
  the gate, run by hand.

## [Unreleased]

## [1.8.0] - 2026-10-05

## [1.7.0] - 2026-10-05

### Added

- **The repo is now an installable Claude Code plugin, and its own marketplace**
  (`.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`). Install with
  `/plugin marketplace add Fintama/swisper-superpowers` then
  `/plugin install swisper-superpowers@swisper-superpowers`.
  ⚠ **The existing `scripts/setup-user-level.sh` symlink install is unchanged and
  still supported** — the plugin is a third install path, not a replacement. The
  two coexist; `~/.claude/skills` keeps resolving to your clone.
  ⚠ **Installing the plugin does NOT edit `~/.claude/settings.json`.**
  `setup-user-level.sh` still does, deliberately — that merge is what turns off the
  14 stock plugin skills so these versions take precedence.

## [0.4.0] — 2026-05-25

### Added

- **`skills/brainstorming/SKILL.md` — Codebase grounding rule.** New mandatory rule applying to ALL spec content: every identifier the spec mentions (import paths, class names, method signatures, base-class contracts, env vars, ruff rule IDs, file paths) must be EITHER verified against the actual codebase with a `path/to/file.py:LINE` reference, OR explicitly marked as new (introduced as a BUILD artifact with ownership boundary declared). Closes the dominant spec→plan→implementation drift mode where the spec author writes pseudocode using imagined APIs.
- **`skills/brainstorming/SKILL.md` Step 1 — Memory consult.** Step 1 ("Explore project context") now explicitly requires reading `MEMORY.md` + linked handover/pickup-card files for known landmines in the touched area. Landmines reflected in spec §10.1 Risks with `Mitigation: avoid pattern X (see MEMORY.md entry Y)`. Prevents re-stepping on documented issues (e.g., TYPE_CHECKING string forward-refs not surviving LangGraph's `get_type_hints`).
- **`skills/brainstorming/SKILL.md` self-review checks #10 + #11.** Spec self-review gains two checks: (10) Codebase reality — grep / Read every pre-existing symbol the spec names; fix any mismatch inline; (11) Memory landmines — re-read relevant MEMORY.md entries; confirm spec either avoids the pattern or documents the workaround.
- **`skills/brainstorming/design-fitness-reviewer.md` — Tier 6 Codebase fidelity.** New high-leverage tier inserted before the Questions tier (Questions renumbered 6 → 7). Reviewer subagent greps every pre-existing symbol claim, verifies signatures + ABC contracts + Settings vs env vars + file paths + ruff rules. Every Tier 6 finding is at least IMPORTANT — caught at spec time, they cause guaranteed implementer drift if uncaught.
- **`skills/writing-plans/SKILL.md` — "Reference the spec, don't duplicate it" principle.** NEW opening principle of the skill: the plan SEQUENCES the work; the spec DESCRIBES the work. Implementation source bodies live in the spec; the plan references the spec section (`Implement A<n> per spec §X.Y verbatim source body, plan-drift corrections: [list]`). Test bodies, shell commands, and ≤5-line sequencing snippets remain in the plan. Eliminates the duplication failure mode where a plan-pasted source body diverges from the spec AND from the codebase.
- **`skills/writing-plans/SKILL.md` Task Structure template rewritten.** Step 3 ("implement the artifact") now uses spec-reference form by default, not pasted code blocks. New task body shape documented inline with allowed/forbidden code-block taxonomy.
- **`skills/writing-plans/SKILL.md` self-review checks #12 + #13.** Plan self-review gains two checks: (12) Reference, don't duplicate — classify every plan code block; flag forbidden source-body pastes; recommend spec-section references; (13) Plan-time codebase grounding re-verify — grep every pre-existing identifier the plan names to catch drift introduced between spec write and plan write.
- **`skills/writing-plans/plan-document-reviewer-prompt.md`** — Two new check rows in the Mode A table mirroring self-review #12 + #13, so the reviewer subagent enforces them too.

### Why

Direct response to a 13-drift inventory observed across mobility v3 PR-V3-1 + PR-V3-2 implementation (2026-05-25). Root cause analysis grouped drifts into three categories:

- **Category A (~60% of drifts):** spec named pre-existing APIs without grep-verifying them (e.g., `DataObjectTypeRegistry.resolve()` doesn't exist; real API is `deserialize_data_object()`). The "Codebase grounding" rule + self-review #10 + design-fitness Tier 6 catch these at spec time.
- **Category B (~25%):** spec didn't consult MEMORY.md → re-stepped on documented landmines (TYPE_CHECKING/get_type_hints failure mode). Step 1 update + self-review #11 catch these.
- **Category C (~15%):** plan duplicated source bodies from spec → second source of truth that drifted. The "Reference, don't duplicate" principle structurally prevents this.

Net effect for implementers: ~30-50% shorter plans, single source of truth (the spec) per artifact, drastically reduced per-task fix-loops, fewer wasted review cycles.

### Required action for installed team members

After `git pull` on this repo, **restart Claude Code** so the new SKILL.md content is loaded. No re-install needed — the symlink set up by `setup-user-level.sh` already points at this repo's `skills/` directory.

## [0.3.0] — 2026-05-10

### Added

- **`skills/brainstorming/design-fitness-reviewer.md`** — NEW prompt template for a design-fitness-review subagent dispatched at the new step 7.5 of brainstorming. Catches design issues at spec time before they cascade into implementation problems. Six-tier protocol: (1) Principle violations (DIP/OCP/LSP/ISP/SRP), (2) Anti-patterns (AHA / speculative interface, premature distribution, stringly-typed dispatch, anemic data + behavior orchestrator, god class, leaky abstraction), (3) Testability (Functional Core / Imperative Shell), (4) Unwritten assumptions (sync vs async, idempotency, ordering, single-writer vs multi-writer, failure-mode matrix), (5) Pattern recommendations (OPTIONAL — default zero, skip-if-simple threshold, codebase-awareness check mandatory), (6) Questions for architect (each with `affects:` annotation, not a dumping ground). Default verdict on a well-formed spec is "fit for purpose; no changes recommended." Evidence > speculation: every finding cites the spec section + quotes verbatim.
- **`skills/brainstorming/SKILL.md` step 7.5** — new checklist step + flowchart node + prose section describing the design-fitness review dispatch and finding triage matrix (Tier 1/2 → fix inline; Tier 4 → spec §10.1 Risks or §10.3 Open Questions; Tier 6 → route to architect; pattern conflicting with codebase convention → drop).
- **`memory/feedback_design_fitness_review_skill.md`** — durable backup documenting the discipline + the RGR-with-pressure development cycle that produced v1.
- **`scripts/mirror-memory.sh` FILES array** — extended to include `feedback_design_fitness_review_skill.md`.

### Methodology

Skill developed via `superpowers:writing-skills` RGR-with-pressure cycle:

- **RED phase (3 baselines, no skill):** (a) B1 fit spec + neutral prompt → 5 top fixes + 7 secondary findings on a well-designed spec (over-recommendation); (b) B1 fit spec + pressure prompt → 13 sections of issues + 10 recommended actions including manufactured findings (e.g., "R9-R12 missing", "Bun version drift" — neither in scope); (c) synthetic unfit spec + neutral prompt → caught most planted issues but unstandardized output, inconsistent §N citations, no Default Verdict header.
- **GREEN phase (3 tests, with v1 skill):** (1) B1 fit spec → "Design is fit for purpose; no changes recommended", 0 findings all tiers; (2) synthetic unfit spec → caught all planted issues (DIP/OCP/SRP/anemic in Tier 1; AHA/stringly-typed/god orchestrator/premature distribution in Tier 2; testability gap in Tier 3; sync/async, idempotency, failure-modes, ordering, single-writer in Tier 4) with cited evidence and standardized output, declined to recommend Strategy for channels because spec already defines NotificationStrategy; (3) older real vision spec → 3 calibrated findings (Groq prefix LSP violation, concurrent-version contract gap, single-user FK consistency).
- **REFACTOR pressure test:** v1 + the same RED-B pressure prompt + B1 fit spec → held the default verdict, explicitly addressed the pressure framing ("There is no scale surface to fail under"), cited the protocol's "evidence > speculation" rule.

## [0.2.0] — 2026-05-10

### Changed — BREAKING for installers

- **Complete fork.** The repo now contains all 14 superpowers skills, not just the 7 we explicitly enhanced in this session. Verified by file mtime: 8 skills are actually modified (1 in a prior session, 7 in this session); 6 skills are stock from the 2026-05-05 plugin install. We vendor the unchanged 6 anyway for completeness — single source of truth, survives plugin uninstalls, no mental overhead about "is this skill ours or theirs?". Maintenance burden stays low because we don't actively own the unchanged 6.
- `settings.skill-overrides.json` now overrides **all 14** stock skills (was 7).
- `scripts/setup-user-level.sh` writes overrides for all 14.
- README + INSTALL.md updated; the previous "Skills NOT in here" / "do not disable these" guidance is removed (it was wrong — `brainstorming` had been modified in a prior session and excluding it from the override layer would have lost the four-required-spec-sections discipline).

### Added

- `skills/brainstorming/` — fork of cache version including the four-required-sections enhancement from a prior session (mtime 2026-05-09 22:41). See `feedback_brainstorming_required_sections.md` for the durable record.
- `skills/dispatching-parallel-agents/`, `skills/finishing-a-development-branch/`, `skills/receiving-code-review/`, `skills/using-git-worktrees/`, `skills/using-superpowers/`, `skills/writing-skills/` — vendored unchanged from the plugin cache (mtimes confirm no Swisper-specific modifications).

### Migration for existing installs

If you ran `setup-user-level.sh` from v0.1.x:
1. Pull the latest swisper-superpowers (`git pull --ff-only origin main`)
2. Re-run `./scripts/setup-user-level.sh` — it merges the new 7 entries into `~/.claude/settings.json` idempotently
3. Restart Claude Code

If you installed per-project, copy the new `settings.skill-overrides.json` block into each project's `.claude/settings.json` (replacing the old 7-entry version).

## [0.1.0] — 2026-05-09

### Added

- Initial repo content forked from `anthropics/claude-plugins-official` superpowers 5.1.0 (commit `917e5f53...`).
- Enhanced seven skills with the Swisper PDLC discipline:
  - **writing-plans** — Mode A / Mode B; spec-driven planning consuming Artifact Inventory + B-AC/T-AC + Contracts + Risks/Spikes/Phases; PR decomposition with binding merge gates; 11-step self-review.
  - **executing-plans** — Per-PR loop (not per-task); merge-gate verification; mandatory two-stage review (code + maintainability) at PR boundary; Playwright E2E for frontend touches.
  - **subagent-driven-development** — Per-PR boundary on top of per-task two-stage review; `implementer-prompt.md` explicitly invokes `test-driven-development` and requires TDD evidence + AC coverage + frontend-touched flag in the report.
  - **requesting-code-review** — Wires in the new maintainability reviewer; reviewer ordering (code first, maintainability second). Code reviewer prompt extended with AC-mapped tests, contracts-tested-across-consumer-boundary, no-escape-hatches, frontend Playwright requirement, ADR-required check, TDD anti-pattern flags.
  - **requesting-code-review/maintainability-reviewer.md** — NEW. Structural consistency, public/internal API discipline, naming, dead code / debt markers, ADR debt, cross-component drift.
  - **test-driven-development** — TDD evidence binding (commit history); AC-ID test naming; test pyramid + level discipline; Functional Core / Imperative Shell as first-class pattern; property-based testing with fast-check; frontend testing (Playwright as binding for frontend touches); negative-path / failure-mode tests; test isolation; flake-as-bug; no escape hatches; mutation testing; contract testing; inside-out vs outside-in. Anti-patterns extended with 5 new entries.
  - **systematic-debugging** — Use observability before ad-hoc instrumentation; property-test shrinking as debugging tool; async / race / FSM debugging section; reproduction order; AC-named regression tests; architectural-question rule fires on 2+ files (architectural smell); env-diff debugging.
  - **verification-before-completion** — Per-PR merge gate verification section with concrete commands; common-failures table extended.
- Four memory entries backing the discipline: brainstorming-required-sections, writing-plans-required-structure, execute-phase-discipline, TDD-skill-required-extensions.
- `README.md`, `INSTALL.md`, `settings.skill-overrides.json` template, `scripts/install-as-submodule.sh`.

### Notes

- Skills NOT in this repo (use upstream `superpowers` plugin unchanged): `brainstorming`, `using-superpowers`, `using-git-worktrees`, `finishing-a-development-branch`, `dispatching-parallel-agents`, `writing-skills`, `receiving-code-review`.
- Maintenance model: when upstream releases a new superpowers version, re-evaluate per skill (rebase OR keep ours OR retire).
