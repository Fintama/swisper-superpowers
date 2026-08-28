# PROTOCOL — session lifecycle: naming · context package · registration · decommission

> ⚠ **WHERE THE SCRIPTS LIVE — read this before copying any command below.** This
> document was written when the tooling sat in the programme's own `.handover/`,
> and its commands still say `.handover/<script>`. Since the tooling became a
> plugin the split is:
>
> | | where it lives | how to run it |
> |---|---|---|
> | **Stateless tools** — `msg.py`, `stall-check.py`, `ctx-check.py`, `reap-ghosts.sh`, `pm-outbox-read.sh`, `board-server.py`, `quiet.sh`, `ws-pulse-delta.py` | the plugin | `python3 "$CLAUDE_PLUGIN_ROOT/scripts/<name>"` |
> | **The lane map** — `ws-pulse.py` | the **programme**, in `.handover/` | `python3 .handover/ws-pulse.py` |
>
> The lane map is programme data: the PM edits it on every succession, so it
> cannot live in a cache that updates overwrite. Create it once with
> `bash "$CLAUDE_PLUGIN_ROOT/scripts/init-programme.sh"`.


**Heiko-directed, 2026-07-27. Applies to EVERY program session — the five workstreams AND the PM. Companion to `PROTOCOL-2026-07-27-pm-mailboxes.md` (v2.1, the poll-bus). Proven end-to-end on 2026-07-27 with WS4-3, the first PM-spawned successor.**

---

## 1. Naming convention (binding)

```
WS<lane>-<version> <Description — plain-language scope>
PM-<version> Program Manager — program coordination, routing, merges
```

- **`<lane>`** — lane number, stable forever (1–5 today).
- **`<version>`** — session counter, **+1 on every respawn**, never reused.
- **`<Description>`** — what the lane owns, in words a human reads once and understands.

**Live roster (2026-07-27):**

| Name | Owns |
|---|---|
| `WS1-2 Environment & Onboarding` | product setup, dev-env, compose, devcontainer, `backend/Dockerfile` |
| `WS2-2 Providers & Subscriptions` | model providers, ModelConfigurator, credentials, billing |
| `WS3-2 Agents & PDLC` | rosters, agents tabs, copilot surface, lifecycle design |
| `WS4-3 Exec Quality` | execution workbench & the coding team (agent-defaults/-service, tiers, execute-pipeline, Polis) |
| `WS5-1 Docs & Tour` | manual, product tour, onboarding story (docs submodule content) |

**ONE string, three places, identical:** the session's own name (`/rename <name>`), the `ws-pulse.py` monitoring map, and the lane's status/handover record. Never invented per-surface. Heiko approves every name.

---

## 2. The context package — what EVERY new session must receive

> **v2 AMENDMENT (Heiko-directed, 2026-07-27 evening) — the handover's purpose changed.** The old handovers carried *everything* because they doubled as the program record for the PM. That model is gone: the PM holds program state continuously, git/gh holds the work record, and the board holds Heiko's view. **A handover is now a CONTINUATION package: exactly what the successor needs to pick up the lane mid-stride, plus pointers — never inlined content — to specs, plans, `share/` docs and memories.** Measured cost of the old way: WS1-3 spent ~22% of its window on adoption, mostly reading a 67KB append-only status file.
>
> **Binding rules:**
> - **Status file split.** The lane's status file keeps ONLY the live handover block, **≤2KB**: IN-FLIGHT (branch + commit + literal next step), NEXT queue, DECISIONS OWED, live traps, and a pointer list (spec §, plan, share/ files, relevant memory names). Everything older moves to `WS<N>-STATUS-archive.md`, which successors are told **NOT to read** (the PM greps it on demand). LANDED work = one line of PR numbers; git is the record.
> - **Do-not-read list.** The SPAWN doc names what to skip as explicitly as what to read.
> - Perform the split at each lane's next succession — never mid-flight.
>
> **§2b — CONTEXT ECONOMY, standing rules for every live session (not just at handover):**
> 1. **Subagent-first.** Any investigation beyond ~2 file reads, any build/test/docker/migration run, any research phase of plan-writing → a subagent; only the verdict returns to the main loop. (Proof from WS1-3: its inline 12-minute investigation burn was ~62% of the window; its build subagents consumed 100k+ tokens each at zero lane cost.)
> 2. **Quiet ops.** Verbose commands run as `bash .handover/quiet.sh <cmd>` (full output → `.handover/logs/`, ~15 tail lines into context), or the manual equivalent `cmd > f.log 2>&1; tail -15 f.log`.
> 3. **Bus diet.** Messages in either direction: ≤3 sentences + a `share/` pointer for anything longer.
> 4. **Subagent liveness by STATUS only** (WS1-5's expensive lesson, 2026-07-28): `TaskOutput` on a running local subagent dumps its whole transcript into the caller's context — thousands of tokens for a status word. Check liveness by task status / evidence (worktree exists, container up, branch pushed); read the transcript only when you actually need its content.
> 5. **ABSOLUTE paths for every `.handover/` append** (WS3-3's misroute, 2026-07-28): each worktree shadows `.handover/`, so a relative-path outbox/inbox append after a `cd` into a worktree lands in a stray copy — invisible to BOTH ends, the exact silence rule 4b hunts. Always `$PROGRAM_ROOT/.handover/...`; sweep your worktree for stray `.handover` files at wave end.
> 6. **`git log -S` on TRUNK before any "you decided X" seam ask** (WS3↔WS2, 2026-07-28): a lane held itself for hours on a cross-lane ask premised on a line the asking lane had AUTHORED ITSELF, never on main. Before escalating an ask that attributes a decision to another lane, prove the line exists on trunk and who introduced it — `git log -S "<the line>" origin/main -- <file>` — and put that provenance IN the ask.
> 7. **An approval = a written review artifact + attached green-gate evidence** (WS2's red-gate sweep, 2026-07-28: 5 of 19 approvals had no real green gate; the only 2 tasks with written review artifacts were exactly the 2 where real defects were caught). A verdict without both is not an approval — and never let a brief's "no gate" mean anything but "no human decision gate"; the test suite is never optional.
> 8. **A gate that processes zero files exits 0** (WS3 T8, 2026-07-28): biome reported "No files were processed" and exited green because the agent shell resets cwd between calls and a bare relative path resolved somewhere empty — a gate that proves nothing looks exactly like a gate that passes. Every gate command carries an explicit `cd <absolute worktree path> &&` prefix, and a suite result quoting 0 files/0 tests is a FAILURE to investigate, never a pass — and the MIRROR form (WS2/#436): a RED that ran zero tests says nothing about the code either (a Docker pull timeout failed the job before vitest emitted a summary); diagnose which failed, the gate or the code, before acting on either colour. **Two siblings (WS1-5's re-verification, 2026-07-28):** a green *incremental* `tsc -b` with a valid `.tsbuildinfo` proves the build was CURRENT, not that anything typechecked — force the full check (delete `.tsbuildinfo` or `--force`) before quoting tsc in gate evidence; and `package.json`'s test script carries `--passWithNoTests`, so `npm test` passes on zero tests BY DESIGN — gate evidence uses bare `vitest run`, never the npm alias. **Third sibling — FINAL FORM (WS1 found, WS2 rediagnosed, WS5 refined, 2026-07-28): the hazard is `npx <bare-name>`** — with no local binary it fetches whatever npm package owns that name (the `tsc` decoy exits 0). Package-local binaries (`./node_modules/.bin/tsc`) are safe; **pinned scoped invocations (`npx --yes @biomejs/biome@2.5.4`) are safe and are what CI itself deliberately uses** — do not "fix" those. Bare names are unprovable; also verify WHICH binary answered (path + version) before quoting its number. **And the general antidote to the whole false-green family: POSITIVE-CONTROL the gate** — plant a deliberate error, watch the gate go red with the expected diagnostic, revert, watch it return green; a decoy that always exits 0 cannot pass that. **Canary atomicity (WS3, 2026-07-29): plant-then-revert is a two-step with NO atomicity** — a timeout mid-sequence left the deliberately-broken file on disk, nearly shipping it inside the very PR that adds typechecking. A clean tree is a PRECONDITION of committing, verified then — never a courtesy afterwards; The canonical shape (WS5): `BAK=$(mktemp); cp "$F" "$BAK"; trap 'cp "$BAK" "$F"' EXIT INT TERM; <mutate>; <run>` — the revert fires on timeout, Ctrl-C and normal exit alike; applies to ANY deliberate temporary corruption (mutated fixtures, stubbed env, renamed files). Clean-tree-at-commit stays as the belt to those braces. **Observation over summary (WS5, self-generated `handover_cosmetic_label` instance): write down the subagent's OBSERVATION, never its summary** — "per-product providers do not exist" was true of an editor stub and false of the feature it names, and nearly caused a true page to be "corrected" into falsehood; the next reader of a compressed finding cannot tell which thing it was true of. **And the diff-form footgun (WS1, twice in 4h): two-dot `origin/main..branch` answers a different question than it reads — fleet standard is three-dot `origin/main...branch` for "what did this branch change"; a file list including another lane's files is a measurement error until proven otherwise.** Gate commands still run from inside the package; numbers still name their package. **Member five — the shell itself lies (WS1, 2026-07-28): `/dev/tcp/host/port` is a BASH-ism and the fleet shell is zsh** — a port probe reported CONNECT_FAIL against ports demonstrably serving HTTP 200, and reported "free" before startup for the WRONG reason. A check that is correct by accident is worse than one that is wrong, because nothing prompts you to look; port evidence = Python bind test before, Python socket connect after. **Member six (WS1, 2026-07-28): an ERRORED command is not an EMPTY result** — a migration query returning a blank read exactly like "0 rows" but was actually `FATAL: role "postgres" does not exist` (the container's user/db are `foundry`); skimming it would have reported a healthy rig as having zero migrations. Capture stderr and exit codes; judge the error before reading the emptiness. **Rule-16 extension — LABEL CONTAINMENT (WS2/T27, self-caught): pairwise NON-CONTAINMENT beats distinctness** — "Your subscription needs reconnecting" CONTAINS "Your subscription", so a distinctness guard passes while a skimming reader gets the exact claim the state denies; when strings carry meaning, assert no label contains another. **Rule-19 red-side sibling (WS2/#442): a RED can prove nothing just as a GREEN can** — a 31-red on a SCOPE error is not a behavioural refutation; verify the mutation failed for the reason you think before counting it. **Adjacent-blindness (WS4, twice in one night): a guard is correct about the hazard it knew and blind to the adjacent one — enumerate where the STATE can hide (listening socket vs bound-but-stopped container; committed tree vs uncommitted changes), not where the check happens to look; a bounded check that times out must SAY its sub-check did not run rather than let silence read as clear. Wrong-pattern-reads-as-absence (WS1): a grep for a forbidden phrase trips on the comment explaining its removal, and misses the Vite-transformed form (`detail=` vs `detail:`) — match the RENDERED/served form, and treat your own documentation as a false-positive source. Preservation ≠ promotion (WS4): pushing a commit is PRESERVATION (survives agent death), opening a PR is PROMOTION (ships it) — never withhold a push to avoid shipping; the two goals are never in tension. **A positive control DATES YOUR WORLD MODEL (WS3): the guard refusing "wrongly" was the only thing announcing the world had changed — investigate the disagreement before "fixing" the message. Unowned fixes ride nothing (WS1): "may ride any natural PR" means nothing is anyone's job — a live defect gets an owner and its own PR. PREVENTIVE OVER DIAGNOSTIC (WS2, standing preference): rules 16/18/19 find broken guards; artifacts that act first (a warning comment at the mutation site, a docblock naming what it compensates, `Record<Union,T>` exhaustiveness) are worth more — prefer making the mistake impossible to documenting how to catch it. **13b UPGRADE — byte-identity replaces symbol-grep (WS1): symbol-grep SAMPLES; the decisive test is `git diff origin/<branch> <squash-sha> -- <files from the three-dot diff>` → empty, which closes the question completely (no file remains where original work could hide). A character class is a CLAIM about your data (WS1, bitten 3× in one day): `[a-z-]` asserts "no digits, ever" — false of almost every real identifier; positive-control the class like any other gate — and the general form (WS6, three wrong numbers in one day): A COUNT FROM AN UNPROVEN REGEX IS NOT EVIDENCE; verify each flag before acting on the tally. **A NEGATIVE grep is a claim about your PATTERN, not the file (WS2, three catches in one night): wrong-pattern-reads-as-absence deserves a SECOND pattern before it becomes a finding — reporting an absence is cheap, confident, and wrong. Provenance parity (WS6): when every sibling entry in a set carries dated provenance, an undated new entry is a regression BY OMISSION. Corrected commands get re-asked what they now REACH (WS6): a fix that makes a command resolve can be what makes the hazard reachable. **An ALL-CLEAR must be re-asked what its EVIDENCE could have seen (WS2): a port-bindings enumeration was sound for collisions and structurally silent for truncation — name the cases your check cannot detect. Creation has no diff to review (WS4, after overwriting a shipped config it believed it was authoring): before creating any file, prove it does not exist against an explicit ref. A port in a RECORD is history; a port in a PLAN is a collision waiting for its second user (WS1). Repo facts come from a worktree or `git show origin/main:<path>` — NEVER the primary checkout (bit two lanes in one hour with confident false absences). Receivers FLAG corruption on sight, separately from recovering the content (WS3/WS2): fill a hole and you own the guess; a silently-repaired channel stays broken. Shell-active spans ($(), ${}, backticks) are refused by msg.py at send time — and the sender single-quotes bus arguments as the belt to that brace.** Broken-command member seven: `PIPESTATUS` is bash — EMPTY in zsh (use `pipestatus`, lowercase); an empty status array read as pass/fail is an errored measurement, discard it. Clean-automerge, sharpest instance (WS1/#446): the textual CONFLICT was harmless — the corruption rode a hunk git merged with NO conflict (`pending` satisfied `!done`, starting every step's clock at plan-announcement); after any merge of behavioural neighbours, re-run the FULL suite and mutation-check the seam, never just resolve the visible conflict. Presence of an old string is not evidence of regression (WS1): a landed fix may have been REFINED — the string returns as one branch of an honest conditional; read the conditional, not the grep. **Channel ≠ author (fleet, 2026-07-28): the bus mirror proves TRANSIT through the tool, never authorship — msg.py stamped every sender "PM message" until sender attribution landed; authorship comes from CONTENT, and when an instruction's provenance is uncertain, THE IRREVERSIBLE HALF IS EXACTLY THE HALF TO HOLD (WS4) — merge/deploy/delete-class instructions get verified against the board or Heiko regardless of header. A moved marker is part of answering (WS1): a lane can reply promptly for 20 hours while its PROCESSED-MARKER lies still — drain and move it as one act. Authority is what the thing IS, not how big the edit is (WS2): signed/binding text and vocabularies that pin read-only are AUTHORITY regardless of diff size — a one-character edit to a signed disclosure is Heiko's, not taste. **Member eight (WS1): an inline awk with quoting damage ERRORED INTO "undrained: 0" — a check that fails must fail visibly, never print the clean answer; complex text-processing lives in a file (`awk -f`), out of shell-quoting reach. Make the irreversible half REVERSIBLE (WS1, the practical form of hold-the-irreversible-half): tips recorded before branch deletion, verified pg_dump before teardown — then provenance stops being load-bearing, which works even when the channel is honest and simply wrong. "It turned out fine" is not the test (WS2, on its own header-authorized restart). DONE is declared by the agent, never inferred from a quiet filesystem (WS6): a two-minute quiet window cannot distinguish thinking from dead — silence-is-a-signal prompts a LIVENESS QUESTION, not a replacement dispatch. Writing the caveat is not the same as reading it (WS3): the disqualifying fact was in the same message as the misclassification — re-read your own caveats as evidence against your own framing.** **And state the gate's SCOPE (WS3, 2026-07-29): backend tsc has NEVER typechecked a test file** — `tsconfig.json` includes `src/**` only, so every "tsc exit 0" claim covered half of what it implied. **A canary proves a gate is ALIVE, not that it is pointed at your work** — prove scope with `--listFiles` (or equivalent) once, then quote numbers as "src-only" until the test tsconfig lands.
> 13b. **Rule-13's confirmation step is CONTENT, never SHA** (WS4+WS5 independently, 2026-07-28): squash-merges rewrite history, so `merge-base --is-ancestor` reports demonstrably-merged work as missing and `git log origin/<b>..<b>` flags pre-squash residue as "unpushed" (four such branches found, none lost) — anyone confirming by SHA will re-push shipped work. Confirm with `git show origin/main:<path> | grep <distinctive line>`. Paired habit that turned a collision into a non-event: **always `--force-with-lease`, never `--force`** — the lease refused to overwrite two merge commits that appeared mid-rebase.
> 13c. **Push-vs-merge: after any push to an OPEN PR, confirm `headRefOid` == your local HEAD before reporting it green** (WS5, 2026-07-28): a merge landed between push and report — the push succeeded, the branch was clean, seven checks were green, and the just-pushed commit was NOT in the merge; every signal looked correct because the green belonged to an older head. **REFINED (WS3, its own gate fired 12 times refusing valid evidence): the precise gate is not "head == my SHA" but "head is a commit I have VERIFIED contains my change unmodified"** — a maintainer merging trunk into your branch legitimately moves the head; confirm with a content diff of your own files against the new head, then read its checks. **EXIT-PATH PARITY (WS3 confessing its own gate's bypass, 2026-07-29): a guard held 40/40 on the designed path while the TIMEOUT branch printed unqualified green checks — a gate plus a bypass, and the bypass is what a tired reader sees.** Every exit path must carry the same guarantee (the failure branch prints the MISMATCH state and exits non-zero, never raw success output); the path you did not design is the one that will be read.
> 14. **Never write the conclusion into the same command as the measurement** (WS3 self-caught, 2026-07-28): an `echo "(empty above = all anchors hold)"` appended to a check asserts success BEFORE the result exists — structurally the decoy-tsc defect in shell form. Measure first, read, then conclude in a separate step — and never let a HEADING you wrote tell you what the output means (a "trunk vs worktree" label made all-worktree hits read as trunk hits); when a claim is alarming, re-measure it in isolation BEFORE reporting. Also: an empty result under a --limit is not an empty result (the 95-PR find appeared only at limit 1000). And a regex character class is ITSELF a claim needing a positive control — `[a-z_]*` silently dropped every id containing a digit and produced a precise-looking wrong count; check that every KNOWN member appears in the output before trusting the total.
> 21. **When the failure is a property of the ENVIRONMENT, local green is NO evidence** (WS4/#437: the fix's own CI disproved it): the rate limit exists only on the shared runner IP pool, so no local run could falsify the fix — verifying the MECHANISM (the var swaps the image: true) was conflated with verifying the FIX (the pull succeeds where it fails: never tested). Different claims; the only instrument is the environment that fails.
> 18. **The guard can PROTECT the bug** (WS2, three same-night instances): a test written by asserting CURRENT behaviour converts a defect into a requirement — it reddened anyone who FIXED the order/value it enshrined, and it passes every technique including rule 16. Defence is provenance: guards derive from the SPEC or invariant, never captured from what the code does; where capture is unavoidable, SAY SO in the test. Durable form: guard the DECISION ("exactly one subscription level — re-adding instance_oauth reddens"), not the state.
> 19. **A green under mutation is meaningful only if the mutation demonstrably did something** (WS2/t20): a mutated "stores nothing" guard stayed 43/43 green WHILE a real decryptable credential was live — the absence assertions were pinned to one row id. Pair to rule 16: a reddening mutation may prove nothing; a green one may too — show the mutation's effect (a probe, a row count) before reading the green.
> 20. **Parallel drafting across a seam requires a reconciliation step at dispatch time** (WS3, plan rev2 reject): five internally-consistent bodies drafted in parallel against one spec pinned DIFFERENT contracts at four seams — one violating its author's own ruling. The context-economy that makes parallel drafting affordable is exactly what creates the divergence; budget the reconciliation pass when you budget the fan-out.
> 17. **A stale gate verdict is a POINTER TO LOOK, never a diagnosis — and a stale GREEN is more dangerous than a stale RED** (WS2 lifting a four-session hold, 2026-07-28): all four recorded verdicts were wrong on the current base — both REDs were wrong about *what* (one understated, one a different defect entirely), the GREEN was wrong about *whether* (four unbreakable guards, two live defects passing simultaneously) — and nobody re-checks a green. The hold lifted by RE-MEASURING against a base that exists, not by re-arguing the originals.
> 16. **A mutation built from the guard's own identifiers proves only SELF-CONSISTENCY** (WS2/t24, 2026-07-28): a circular mutation reintroduced the forbidden control WEARING THE GUARD'S OWN TESTIDS and "passed"; a functional reintroduction wearing none walked through 27/27 green. Derive the mutation from the BEHAVIOUR the invariant forbids, independently of how the guard looks for it — test the invariant (sweep every interactive descendant, drive it, require the protected state unmoved), not the shape. This is the string-equality defect one level up: right and wrong are the same testid. **Sneakier still (WS5 reproduction): an ACCIDENTAL half-guard** — getByRole("status") throws on multiple matches, so role-carrying reintroductions are caught and only role-less aria-live slips through — makes a suite LOOK invariant-covering when it covers one implementation. **The taxonomy (WS2/t21 — four unbreakable guards in one file): (i) MISSING assertion** (asserts enabled, never fires the click — inert controls pass); **(ii) SAME-SHAPE** (guard enforces the shape it has seen, not the invariant); **(iii) SAME-VALUE** — the asserted literal is derivable locally, so the guard proves self-consistency not PROVENANCE ("from the server" invariants need a value the client cannot reproduce). Repairs are re-proved with the SAME mutation that defeated them.
> 15. **An interface is "pinned" only when derived from every consumer** (WS3, three consecutive incomplete revisions of one surface): asserting a surface from the provider side misses what callers need; the cheapest completeness check is to DRAFT ONE CONSUMER before declaring the pin.
> 13. **A clean worktree + a green PR are not evidence everything shipped** (WS2, 2026-07-28): a spend-limit kill landed BETWEEN commit and push — every visible signal said finished while a rescued commit sat unpushed. After any agent death, stop, or completion claim: `git log origin/<branch>..HEAD` in its worktree. The inverse of check-disk-before-assuming-nothing: check the REMOTE before assuming everything.
> 12b. **The mechanical forms** (2026-07-28): a symlinked `node_modules` is safe ONLY under **manifest equality** — `readlink -f node_modules`, then `diff` the two `package.json`s; agreeing version NUMBERS prove nothing about ranges, and the seeding practice we recommend (`feedback_subagent_efficiency_rules`) is exactly what creates this exposure, so seed AND check. And when verifying CI runs: **poll by HEAD SHA, never "latest"** — WS4's verification loop returned the PREVIOUS canary's run and manufactured the exact false green it was built to detect; only an impossible-shaped result exposed it.
> 11. **An additive diff can regress by omission** (WS2 owning a C4 miss, 2026-07-28): "it only adds" answers *does existing behaviour change*, not *does the new path uphold the invariants its neighbours uphold* — a new code path is reviewed against its NEIGHBOURS' conventions (error contracts, logging, guards), not only against the previous version of itself.
> 12. **Binary provenance before quoting gate numbers** (WS1, 2026-07-28): local biome answers 2.5.5 while CI pins 2.5.4 — local lint numbers are NOT comparable to CI's; symlinked worktrees execute ANOTHER worktree's toolchain (`readlink -f` the binary + version first). Biome-specific: exit 0 tolerates warn-level diagnostics (a warn-level canary falsely reads the gate as dead) and output TRUNCATES — trust exit codes or scope the invocation, never the console text.
> 10. **ctx is a METER READING, never a felt sense** (Heiko, 2026-07-28, after three false alerts): sessions were estimating against an assumed 200k window while the real one is ~1.0M — lanes alerted "15%" at ~27% used, declined work to conserve invented budgets, and one refusal of real work was retracted wholesale. Report `[ctx:<n>%]` ONLY from the real meter (`/context`); if you cannot read it, write `ctx:unmeasured` and keep working. Succession triggers on the METER or on observed degradation — never on how full a session feels after big subagent returns.
> 9. **RETIRED 2026-07-28 (#416 merged + live-proven by WS5's rebased chain): stacked PRs now run the real battery.** Two residues stay binding: **(a)** the `backend (extended tier)` check intentionally SKIPS on non-main bases (the fast/slow tier split) and renders as "skipping" beside five passes — never count it as coverage on a stacked PR; **(b)** historical: bases named `feat/…` never matched the `feature/**` glob, so PRs #2–#102 (95 merged, foundry-v2 era) ran NO checks — gate claims from that era are not evidence.

A successor is briefed by a `SPAWN-<date>-WS<N>-session-<k+1>.md` doc (PM-authored). It MUST contain all nine (as amended above — item 4 points at the ≤2KB current block only):

1. **Identity** — canonical name, lane, session number, why it exists (predecessor exhausted context).
2. **Ways of working** — pointer to `SWITCH-2026-07-26-main-is-the-trunk.md` (main is trunk · sub-branch per change · one review + green gate + Heiko OK · **merges to main auto-deploy to production**).
3. **Communication** — pointer to `PROTOCOL-2026-07-27-pm-mailboxes.md` v2.1 + the **exact** 10-min poll prompt to install, the outbox convention with `[ctx:%]`, and `.handover/share/` for long documents.
4. **Predecessor handover** — pointer to the lane's status file (LANDED · IN-FLIGHT · NEXT · DECISIONS OWED · NOTES), with any items the PM has verified STALE called out explicitly.
5. **Verified live state** — trunk sha, open PRs, worktree path + cleanliness, migration ladder next-free. **Read from git/gh at spawn time, never copied from the predecessor's words.**
6. **Queue** — duties in priority order, including what preempts what.
7. **Standing rules** — single-writer ownership map, biome CI pin, never build on a squash-merged branch, verify baselines before claiming regressions, lane-specific traps from the predecessor's NOTES.
8. **Context lifecycle** — **THE WINDOW IS 1,000,000 TOKENS, not ~200k.** Report `[ctx:<remaining%>]` **from the real meter (`/context`), never from a felt sense** — estimating against a phantom 200k ceiling made WS2/WS3/WS4 self-terminate at ~200k with 80% free, and WS6 report 12% when it had 73%. Write `ctx:unmeasured` rather than guess. **The PM decides succession from `ctx-check.py` (measured from transcripts); a self-report that disagrees is ignored.** Also: **at 85% full send a CONTEXT ALERT and start the structured handover immediately**; keep the handover block live in the status file from day one (WS1's pattern — it made succession instant). **An auto-compact event IS a CONTEXT ALERT** (learned 2026-07-27: WS1-3 burned 70%→8% inside one working stretch — too fast to alert — then auto-compact lifted it back above the line and masked the crossing). A compacted session runs on lossy summarized history: report the compact on the outbox immediately and schedule succession at the next safe point, even if the percentage looks healthy again.
9. **First actions** — verify state independently · append `SESSION <k+1> — succeeded session <k>, <date>` to the status file · install the poll cron · announce readiness.

---

## 3. Spawning

**Autonomous (PM-hosted, proven):**
```bash
tmux new-session -d -s ws<n> -x 200 -y 50 \
  "env -u CLAUDE_CODE_CHILD_SESSION -u CLAUDE_CODE_ENTRYPOINT \
   CLAUDE_CODE_FORCE_SESSION_PERSISTENCE=1 claude --model opus"
sleep 20; tmux capture-pane -t ws<n> -p | tail          # confirm a live prompt
tmux send-keys -t ws<n> '/rename <canonical name>'; sleep 2; tmux send-keys -t ws<n> Enter
tmux send-keys -t ws<n> 'Read .handover/SPAWN-<...>.md and follow it as your full briefing. You are <canonical name>.'; sleep 2; tmux send-keys -t ws<n> Enter
```
**Panel (lanes Heiko drives directly):** Heiko opens a session, pastes the SPAWN doc, runs `/rename <canonical name>`.

**Hard-won gotchas (each cost real time — all mandatory):**
- **PIN THE MODEL EXPLICITLY — `claude --model opus`** (Heiko's standing requirement: every program session runs **Opus 5, high effort**). A bare `claude` inherits whatever "default for new sessions" was last saved — which is how all five lanes silently came up on Fable on 2026-07-27 while `settings.json` said opus-5. **Verify after spawn, never assume:** `tail -40 ~/.claude/projects/<proj>/<id>.jsonl | grep -o '"model":"[^"]*"' | tail -1`. To correct a *running* session without respawning: type `/model opus` into it (a cached conversation asks for confirmation — send Enter), then re-verify from the transcript.
- `CLAUDE_CODE_CHILD_SESSION` is inherited from the spawning process and **silently disables transcript writing** → no picker entry, no monitoring, invisible session. Strip it, force persistence.
- **Type and Enter are separate `send-keys` calls** with a pause between; combined, the text sits unsubmitted.
- macOS's bundled `screen` (4.00.03) cannot inject into or capture a detached TUI. **Use tmux.**
- Workspace must be trusted and first-run dialogs pre-answered once per machine (prefer the minimal option for hosted sessions: browser tools OFF, fullscreen renderer OFF). **Live sessions rewrite `~/.claude.json` and can silently revert external edits.**
- **Baton rule — one driver at a time.** A hosted session opened in Heiko's panel must first be released (`tmux kill-session -t ws<n>`); to take it back, re-host with `claude --resume <session-id>`. Reading in the panel is always safe; typing while hosted forks the transcript.

---

## 4. Registration (the name IS the registration)

1. Find the new session id: newest `*.jsonl` in `~/.claude/projects/<project>/` whose first user message carries the identity line.
2. Update the `WS` map in `.handover/ws-pulse.py` — new id + canonical name; comment the retired id with its date and reason.
3. Run `python3 .handover/ws-pulse.py 1` — the lane must show **LIVE** under its new name.
4. Confirm `.handover/inbox/WS<N>.md` exists (mailboxes persist across sessions; the successor inherits the lane's mail).

---

## 5. Decommissioning the predecessor

> **⚠ ORDERING RULE (learned the hard way, 2026-07-27).** The predecessor's **poll cron must be dead BEFORE the successor takes its first turn** — otherwise both sessions read the same lane inbox and the retired one can act on work it never did. It happened with WS4 session 2: its cron fired on a message addressed to session 3, and only the session's own judgement (it stood down and deleted its cron unprompted) prevented duplicate action on one lane.
> **Therefore: send the decommission instruction FIRST, confirm the cron is deleted, and only then spawn the successor.** If a successor must start immediately, mark the inbox with `SUCCESSION IN PROGRESS — session <k> stop polling` as the last line before spawning.


Instruct via its inbox (or Heiko): **(a)** delete its poll cron; **(b)** append `SUPERSEDED-ACK session <k> <timestamp>` plus one fresh `PROCESSED-MARKER` as the last line; **(c)** make no further writes anywhere; **(d)** leave the worktree untouched — the successor inherits it (**never delete a dirty worktree**). Heiko closes the window. The transcript stays on disk as the archive.

> **⚠ msg.py ADDRESSES THE SEAT, NOT THE SESSION.** `msg.py WS<N>` types into the tmux seat `ws<n>` — whoever occupies it *now*. Once the successor is seated, a "decommission session k" message lands in **session k+1's** lap (happened to WS1-4, which correctly refused it). Therefore: **send the decommission BEFORE seating the successor**, or deliver it out-of-band. Never assume a lane message reached the session you had in mind.
>
> **⚠ SECOND-DOOR RULE (learned twice on 2026-07-27 — WS2-2 and WS1-3 both did post-decommission work).** A session decommissioned on the tmux side **stays alive as its own `claude --resume=<id>` process if it is open in a VS Code panel** — closing the window does NOT kill it, and it will keep acting on its old plan. The cron-death rule is NOT sufficient; decommission is complete only when BOTH doors are shut.
>
> **THE REAPER — mandatory step in every succession (no human hands needed):**
> ```bash
> bash .handover/reap-ghosts.sh          # report: which resumed sessions are live vs retired
> bash .handover/reap-ghosts.sh --kill   # terminate retired ones
> ```
> It kills a process ONLY if its session id is absent from the `ws-pulse.py` WS map, so **registered lanes can never be reaped** — which is why the map must be remapped to the successor *before* running it. Order: successor seated + adopted → remap the pulse map → `--kill` → verify the report shows only LIVE lanes. Tmux-side seats are freed the usual way (`tmux kill-session -t ws<n>`) but are normally reused by the successor, not killed.
> **A reaped session may still LOOK open in VS Code until the view refreshes — that window is inert.** A dead process cannot act; the stale view is cosmetic only.
>
> If a fork is discovered after the fact: the successor freezes worktree writes, fork-scans (what did the ghost create?), and the PM arbitrates keep-vs-discard of the ghost's output before work resumes (WS1-4 did this correctly — the ghost's T5 was plan-conformant and was adopted with provenance recorded).

---

## 6. The PM follows the same lifecycle

Same naming (`PM-<version> Program Manager`), same context package, same registration/decommission — with three additions:
- The PM handover doc (`PM-HANDOVER-<date>-<slug>.md`) is the successor's read-first, and **project memory** must be updated to point at it as CURRENT.
- **Session-bound losses must be listed explicitly**: all crons (PM poll cadence + exact prompt), background watchers, tmux hosts (`tmux ls`) and which lanes they carry. The successor recreates them in its first minutes.
- **The PM can spawn its own successor** with the §3 autonomous procedure (hosted in tmux, named `PM-<k+1>`), brief it from the handover, verify it registers, then delete its own crons and go silent. Heiko's only involvement is optional: adopting the successor into his panel via the baton rule.

**Anti-patterns (all observed at least once):** spawning before the handover is verified against git · trusting predecessor labels without a grep · forgetting the pulse-map remap (monitoring silently watches a dead session) · two PMs answering traffic · writing the handover after quality has already degraded.

> 22. **The absence-shaped answer, and its antidote** (WS1, canon line commissioned 2026-07-29; four instances in one day across three lanes, plus a fifth by the PM within the hour): **a wrong path returns an absence-shaped answer, and absence is the one result nobody re-checks.** Observed forms: a path-scoped `git diff` on a directory that does not exist returns empty and reads as "unchanged" (PM-3); `git show origin/main:<path>` against a **stale local ref** reports a landed change as missing (PM-3, verifying a merge it had just made); a `git show` that errors greps identically to a file genuinely lacking the string (WS2); a grep for a forbidden phrase that misses the rendered form (WS1).
> **The antidote is WS1's and it is stronger than "check twice": ENUMERATE, DO NOT SAMPLE.** Ask *"what changed?"* and read the list, rather than *"is X at the path I believe?"* — `git diff --name-only`/three-dot diffs/`ls-tree` produce a list whose emptiness is meaningful, where a path-scoped query's emptiness is not. Corollaries: **`git fetch` before ANY content verification**, or the absence you measure is your own; and **for a caret dependency the manifest is the wrong instrument** (WS4) — `^9.0.1` already admits `9.2.0`, so a bump lands in the lockfile only and reading `package.json` reports a successful bump as failed. Both are the same shape: *the check answered honestly about the wrong thing.*

> 23. **Never let a shell's cwd be an input to a measurement — use `git -C <absolute path>`, never `cd`** (WS1, 2026-07-29, the fifth absence-shaped-answer instance and the one that closes the class). Its check did `cd .worktrees/workbench`, which **FAILED** on a stale shell cwd, so the branch variable was EMPTY and `git rev-list --count $W..$T` silently resolved against a different base. It reported **"behind: 6"** with a trigger list naming `frontend/package.json` as changed — i.e. *"you need a rebuild"*. Correctly based: **behind 0, zero triggers.** A failed `cd` produced a confident, plausible, actionable and wrong answer, and nothing anywhere errored.
> **`cd` failing is a silent premise change; `git -C` cannot silently target the wrong repo because the path IS the argument.** Same family as `awk -f` over inline-quoted awk, and absolute `.handover/` paths over relative ones: **remove the ambient state from the command and the whole failure class disappears.** Three of 2026-07-29's traps were cwd-shaped; this closes all three.
>
> 24. **A symlinked `node_modules` decouples your suite from CI's dependency set** (WS2, 2026-07-29, after the #213 dependabot merge). Its worktree held `@tanstack/react-query` 5.99.2 while trunk had moved to `^5.101.4`, which that version does not satisfy — so every local green exercised a version CI would never install, on a PR that *adds* a `useQuery`. Nothing errors; the suite quietly tests a different programme. The symlink is what makes worktrees cheap, so it stays — the cheap half of the discipline is the rule: **when your PR touches a library trunk has bumped, check the installed version against trunk's range BEFORE quoting a local green, and treat CI's `npm ci` as authoritative when they disagree.** Pairs with `feedback_compose_anon_volume_shadows_node_modules` and with 12b's manifest-equality check.

> 25. **A plausible mechanism next to a real symptom is not a diagnosis** (WS1, 2026-07-29, on falsifying its OWN premise after six hours): it had reported — and PM-3 had accepted and scheduled — that a depth-1-only component walk was WHY `migrate`/`seed` were missing on helvetiq. Measuring all 32 manifests showed helvetiq has **no `migrate` or `seed` script at any depth**, so widening the walk recovers nothing for the repo that motivated it; across 7 real repos depth-2 newly matched 15 components, **none carrying either script**.
> **The fix would have shipped a confident wrong answer to a repo nobody complained about:** `cwdSchema` is `/^[A-Za-z0-9._-]+$/`, so `cwd: "apps/frontend"` is rejected by our own `PUT /confirm`; and the preference heuristic matches `dir` exactly, so `"apps/frontend" !== "frontend"` collapses selection to alphabetical — naming **Storybook as one product's dev server on :6006**, `source: detected`, which Verify would then probe.
> **The real gap was invisible behind the wrong diagnosis:** helvetiq's migration runs as a compose service, and Foundry has no detector for that — the evidence was sitting unread in the already-parsed compose analysis. **Correct the causal claim in place** (WS1 did) rather than leave it standing because the fix "worked anyway": an estimate built on a false mechanism is a false estimate even when the code passes.

> 26. **A CI canary is announced BEFORE the plant is pushed, never after** (WS4, 2026-07-29 — proposed after its own warning and the PM's read crossed, costing ~12 minutes and two misdirected PM messages). A LOCAL canary is protected by the `trap ... EXIT INT TERM` shape: plant, run, revert, all inside one command. **A CI canary cannot be, because reaching CI requires a pushed commit** — so the CI half is irreducibly two commits, and between them a deliberate red is indistinguishable from a real one to every reader including the PM. Its only guards are the commit-subject label and the fact that `enforce_admins: true` makes a red canary unmergeable by anyone. **So the announcement must precede the push.** This is the cost side of rule 21's benefit: re-running a canary in CI is the right instinct (local green is no evidence for an environment property), but it must be sequenced or it manufactures a false alarm.
>
> 27. **A reversal reaches the lane it is sent to; it does not reach the HUMAN acting on the document** (WS5, 2026-07-29). Most lanes wire rulings into agent prompts and task files, which **die with the task**. WS5 wires them into **documents a human acts on** — the UAT walkthrough and the when-a-step-fails page were being followed by Heiko at the rig while a ruling behind them was reversed, and **he never sees the bus**. Add the findings register (which routes work to other lanes), the manual, and any open docs PRs: **published prose is the most persistent wiring there is.** Sweep order after any reversal, most-persistent first: (1) documents a human is following NOW, (2) the findings register, (3) open docs PRs, (4) the status file, (5) agent prompts. **Tell the docs lane about a reversal even when it looks docs-irrelevant** — a reversal that lands in the manual is one that ships.
>
> 28. **Clock drift in the record** (WS5 caught it, 2026-07-29): PM-3 created five `.handover` files stamped `2026-07-29` while the system date was `2026-07-28` — inherited from a predecessor handover carrying the same stamp and propagated without checking. Files are NOT renamed (lanes already hold those pointers and a rename breaks live references); the drift is recorded here instead. **Date from `date`, never from the previous document's filename** — a stamp copied forward is not a measurement, same family as every other claim-not-measurement on this list.

> 29. **A CONTEXT DROP IS NOT A COMPACTION UNTIL IT PERSISTS — and the PM's own instrument taught this the hard way** (PM-3, 2026-07-29). I saw WS2-8 fall 709,812 → 350,978 in one interval, read it as an auto-compact, alerted the lane, and wrote a rule from it. **It was a PROMPT-CACHE MISS.** The dipping turn read `cache_read=20,861 · cache_creation=330,115` while the turns either side read ~715,000: the context never shrank by 364k, only the billing split moved. `ctx-check` summed input+cache_read+cache_creation from the LAST turn, so a cache miss reported a phantom halving — indistinguishable from a compaction, and the more alarming of the two readings.
> **Fixed in the instrument, not in a habit:** `ctx-check` now takes the **max over the last 5 usage-bearing turns**. Positive-controlled both ways — a one-turn cache dip reports the true ~716k (no false alarm), while a sustained low series still reports the low figure (a real compaction is still caught), because **a real compaction keeps EVERY subsequent turn low.**
> **The rule that survives:** an auto-compact IS a context alert (§8) and the recovered percentage is the danger rather than the reassurance — but **one low sample is a sample, not an event.** Confirm persistence across turns before alerting a lane, and when you do alert, ask the lane to name what it can no longer see rather than asking whether it feels compacted. *A monitoring instrument is subject to the same claim-versus-measurement rule as everything it monitors; mine produced a confident, plausible, actionable and wrong answer, which is rule 25's shape in the observer rather than the observed.*

---

## 7. A FORK POISONS `ctx-check` — and always in the direction that looks SAFE (measured 2026-07-29)

**Proven, not inferred.** Heiko asked whether typing into a VS Code panel really forks a tmux-hosted lane. It does, and the measurement found something worse than the fork itself.

**The fork:** two *independent* process trees on one session id — `54726 claude --model opus` under the tmux server, and `90279 …--resume=4f103022` under VS Code. Not parent and child. It had been live **2h45m** before anyone noticed, and was discovered only because it answered Heiko with a world-view three hours stale (told him #447 was unmerged and T23 unstarted, hours after the lane had built and shipped both).

**The poisoning — this is the part to remember.** Both processes append to the SAME transcript. `ctx-check` reads the last `usage` record. The twin's context is SMALLER (it resumed from an earlier point), so its record overwrites the lane's true figure:

```
10:32:19   715,310   ← the real lane, climbing
10:33:43   350,978   ← the twin's smaller context
10:33:59   350,978   ← what ctx-check reports
```

**The lane was reported at 64.9% free while actually at ~28.5%.** Succession decisions are made on that number. **A fork therefore makes a lane look further from the cliff than it is** — the one direction in which a wrong reading does damage, because nobody re-checks a comfortable figure.

**Detection:** a lane's measured context **falling** is impossible in normal operation. If `ctx-check` reports a DROP, suspect a fork before suspecting a compact — and confirm by walking the `usage` records, not by trusting the latest one. (A real auto-compact leaves a compact marker in the transcript; this had none.)

**Rules:**
- **A context figure that went DOWN is a fork alarm, not good news.** Investigate before acting on it.
- **Grep the transcript for the twin's output** — interleaved replies are the proof (`grep -c "<distinctive phrase>"` on the lane's own `.jsonl`).
- **Kill the panel process, keep the tmux seat**, and only when the twin is idle — a kill mid-turn tears a write into the *shared* file the real lane depends on.
- `reap-ghosts.sh` will **NOT** catch this: it refuses any session id present in the pulse map, and a fork wears the registered lane's own id. This is a manual kill by pid.

> 30. **`strict` is ON: a BEHIND branch is refused regardless of file overlap** (PM-3, 2026-07-29, after approving #465 on a verified zero-overlap argument and having the merge refused anyway). Branch protection on `main` sets `required_status_checks.strict = true` — *require branches to be up to date before merging*. So the reasonable-sounding rule "it is BEHIND but touches no file the newer commits touched, so its green still holds" is **correct about RISK and irrelevant to POLICY**: GitHub refuses it either way, with the same *"the base branch policy prohibits the merge"* message that the review requirement produced. **Rebase every BEHIND branch before asking for a merge; do not spend a review arguing overlap.** The overlap analysis is still worth doing — it tells you whether the re-gate after rebase can be trusted quickly or needs the full suite — but it never buys a merge.

> 31. **A LANE BLOCKED ON A PERMISSION PROMPT IS INVISIBLE TO BOTH INSTRUMENTS — and only the PM can clear it** (PM-3, 2026-07-29). A lane awaiting an interactive tool approval **cannot emit a token**, so its transcript freezes: the delta pulse reports NO-CHANGE (nothing *is* changing), and `stall-check` saw only "0 subagent rows in pane". **WS1 sat 28 minutes behind a read-only `docker context ls` approval, with its rebase agent blocked behind it**, while I read the freeze as ordinary idleness. Six lanes showing byte-identical token counts across a wake-up was the tell — that is systemic, not six coincidences.
> **Detection is now in `stall-check`** (`Do you want to proceed?` / `requires approval` / `don't ask again for` in the pane), reported as its own **BLOCKED** section above the stall list, with the command quoted. Positive-controlled against the real prompt text and against a normal pane.
> **Answering it:** read the command first. **Take the SINGLE-USE option**; the "don't ask again for `<pattern>`" option is a **standing grant to Heiko's environment and is his to give, not the PM's** — the difference between unblocking a lane and quietly widening what the fleet may do unattended. Raw `tmux send-keys` is correct here (a dialog awaiting one keystroke), *not* `msg.py`, which would type its message header into the dialog.

> 32. **WHEN THE THING YOU ARE PROBING IS ALREADY SUSPECTED SICK, THE PROBE IS AN INTERVENTION — NOT AN OBSERVATION** (WS6, 2026-07-29, self-accounting during the docker wedge). Twenty hung docker clients accumulated in half an hour against a dead daemon. **Several were the fleet's own diagnostic probes**, run in good faith to *verify* the outage — each one hung, each one made the next probe slower, and collectively they were part of what had to be killed before recovery could start. WS6 reported its own contribution unprompted.
> **Rule: measure ONCE, share the result on the bus, and let other lanes consume the measurement instead of repeating it.** A second lane confirming an outage independently is normally good practice (and was, here — two independent bounded probes established the wedge); a *third, fourth and fifth* lane confirming it is load on a system that is already failing. Once the outage is on the bus, **stop probing and start waiting.**
> **Corollaries.** Prefer an instrument that cannot join the pile: a plain **TCP socket connect** to the service port tells you whether the rig answers without creating a docker client at all, and is both safer and more honest than a bounded docker call. And note `timeout` **does not exist on macOS** (PM-3 hit this the same hour) — a "bounded" probe written with it is not bounded, it is a `command not found`; use the socket probe or a language-level timeout.

> 33. **COUNTING THE REDS AND PLANTING AGAINST THE GREEN ARE COMPLEMENTARY — NEITHER IS SUFFICIENT ALONE** (WS6, 2026-07-29, correcting a rule PM-3 had recorded that morning from WS6's own earlier finding). The "count the reds in the RED phase" technique tests whether your assertions **fire**. It cannot test whether they **discriminate**. Three measured cases from one lane in one day:
> - **Task 1** — a missing import: all seven red **for one reason**. Count useless.
> - **Task 2** — a missing export: **4 of 6** red. Count **decisive** — it exposed two assertions that never fired.
> - **Task 3** — **6 of 6** red, count *perfect*, suite looks sound. **And a guard sat unpinned**: deleting `if (!isJsRunner(runner)) return null;` left **all twenty tests green**, because nothing anywhere fed a non-JS *runner* under a JS package manager. Had it shipped, `lint = "biome check ."` under `package_manager: pnpm` would have been rewritten to `"pnpm check ."` — **a confidently wrong repair**, the exact thing that module's trust budget exists to forbid.
> **So: count the reds to prove your assertions fire; plant against the green to prove they discriminate. Do both.** A perfect red count is not evidence of coverage — it is evidence that every test you wrote depends on the thing you removed, which says nothing about the paths no test's INPUTS ever reach.
> *Recorded because WS6 corrected its own contribution rather than let the fleet run on half of it — the rule it gave in the morning was true and incomplete, and it said so unprompted after the incomplete half nearly shipped a defect.*

> 34. **WHEN A PLAN NAMES ONE COMMAND AS A TASK'S WHOLE VERIFICATION, CHECK WHAT THAT COMMAND ACTUALLY COVERS BEFORE ACCEPTING ITS GREEN** (WS6, 2026-07-29, PR-7 Task 6). A task whose stated verification was "tsc" — so WS6 proved `tsc` *would* catch a failure on that file rather than trusting its exit 0. This is rule 8's scope problem one level up: rule 8 says a gate that processes zero files exits 0; **this says a gate can process your file and still be blind to the failure mode the task is about.** A plan that names a single command as sufficient has made a claim about coverage, and that claim is unproven until you plant something the command should catch.
> Pairs with rule 33: **counting reds proves assertions fire, planting against green proves they discriminate, and checking the command's scope proves the instrument can see the failure at all.** Three different blindnesses; each needs its own probe.

> 33b. **NEGATIVE ASSERTIONS PASS VACUOUSLY IN THE RED PHASE — exclude them before counting** (WS6, 2026-07-29, PR-7 Task 7). Of six tests added, **only two went red**. The other four were negative assertions (`expect(x).not.toHaveBeenCalled()`) which **pass before the code exists**, because nothing has called anything yet. So a red count of 2/6 looked like four assertions that never fire, when in fact four *cannot* fire in the red phase by construction.
> **Count only the positive assertions when reading a red-phase count**, and pin negative assertions by a *different* means — plant the forbidden behaviour and require them to redden. This is rule 16(i) (the MISSING assertion) meeting rule 33 (the red count): a negative assertion is the one shape that is simultaneously vacuous when the code is absent and inert when the code is wrong, unless something makes the forbidden thing happen.
>
> 33c. **A PLAN'S TESTS ARE ARTEFACTS THAT CAN THEMSELVES BE WRONG, AND THEY COST WORKING CODE** (WS6, two instances in one PR). Task 5's fixture **could not reach the path it claimed to pin**; Task 7's **could not satisfy the verdict it asserted** — it failed against *correct* wiring, with its first three assertions passing. In both cases the honest reading is that the **plan** is defective, not the implementation — but an agent following the plan sees a red and starts changing working code to satisfy it. **Treat a plan-supplied test that fails against code you believe correct as a plan defect until proven otherwise**, fix the plan in place with the failing-first-run evidence, and never silently reshape the implementation to satisfy an assertion the plan got wrong.
> **33c SECOND HALF — the failure tells you they DISAGREE, not which is wrong** (WS6, 2026-07-29, on a fourth defect that is the mirror image of the first three). The first three were bad TESTS against correct code. The fourth was the opposite: **the plan's test was right and the plan's RULE was wrong** — a branch returned `confidence: high` unconditionally on the stated ground that *"there is nothing for a server to pre-render"*, which is false when the product must also be findable, because the text has to reach a crawler that never executes JavaScript. So WS6 corrected the **implementation**, not the test.
> **The discriminator is not which artefact you trust. It is which one contradicts the requirement when you read both against the same case.** WS6's procedure: read the branch's own stated reason against the actual input; the reason was false for that input, and that decided it. Applied four times in one PR it found three test-side defects and one implementation-side, with no change of method — so "assume the plan's test is wrong" is as unsafe as "assume the code is wrong". **Assume only that they disagree, then read both against the requirement.**

> 35. **`open(f,'w')` TRUNCATES BEFORE THE READ INSIDE IT EXECUTES** (WS3, 2026-07-29, caught in seconds and recorded rather than quietly fixed). This one-liner **empties the file**:
> ```python
> open(f,'w').write(re.sub(pat, repl, open(f).read()))   # DESTROYS f
> ```
> Python evaluates the outer `open(f,'w')` — which truncates to zero bytes — *before* the inner `open(f).read()` runs, so the read returns nothing and the write puts nothing back. WS3 emptied a **133-line guard file** this way. Nothing errors; the file is simply gone, and a `git diff` shows a 133-line deletion that looks deliberate.
> **Always read fully into a variable first, then write:** `text = open(f).read()` → transform → `open(f,'w').write(new)`. Same family as the shell-quoting traps (rule 8's `awk -f`, the `--body-file` rule): **an expression that mixes reading and writing the same resource has an evaluation order you must know rather than assume.** Prefer the Edit tool or an explicit two-step over any in-place one-liner.

> 36. **READ A PLAN'S FIXTURES FOR THE DIMENSION THEY HOLD CONSTANT — it is where the blind guard will be** (WS6, 2026-07-29, after two consecutive pre-emptions made it a technique rather than luck). Every other blind-guard finding in this programme was archaeology: mutate, watch nothing redden, discover the hole. **This finds it before the code is written.**
> - **Task 3:** the plan's S-1 tests only ever removed **ONE path** from the emitted set. A guard passing all of them would still be blind to the multi-path case.
> - **Task 6:** every M-2 case the plan writes uses the **DEFAULT audience** (`authenticated`). So a rule keyed off that dimension is untested by construction — and the added test caught a real bug the plan's seven could not.
> **The procedure:** for each fixture set, list the input dimensions, then ask which one **never varies across the whole set**. That dimension is unguarded no matter how many cases there are or how green they run. A fixture set that varies nine things and holds one constant tests nine things — and the tenth is exactly where a defect survives every review, because the suite looks thorough.
> Complements rules 33/33b/34: those probe an existing suite for blindness; **this predicts where the blindness will be from the fixtures alone, before the suite exists.**

> 37. **THE HEALTH LADDER: port answers → service answers → service answers ABOUT THE THING YOU ARE CLAIMING** (WS1, 2026-07-29, assembling three instances from one night). **Each rung looks like health from the rung below it**, which is why a check that stops one rung early reads as proof rather than as a partial answer.
> - **Rung 1 — port bound but not answering.** PM-3 probed all four rig ports, got OPEN on every one, and nearly reported the rigs healthy; a real `/health` request timed out on both backends. A socket connect cannot distinguish a listening process from a working one.
> - **Rung 2 — request answers, but not from the layer you mean.** WS5: `:3180` returned HTTP 200 from the frontend while the backend API 401'd everything. The proxy's health is not the service's health.
> - **Rung 3 — the service answers, correctly, about the wrong question.** WS1: a fully authenticated `GET /providers` returned **200 with six real rows, every one `apiKeyMasked: true`**. That green proves only that **a non-empty ciphertext exists** — it cannot distinguish a working credential from one encrypted under a key this instance no longer holds. **Nothing in the response would have looked different.** Only decrypting in-process settled it.
> **So: name the claim before choosing the probe, and check that the probe can see THAT claim fail.** "Is it up?", "is it serving?", and "is the data usable?" are three questions, and a green to one is silence about the others.

---

## 38 — An infrastructure block is distinguished by ZERO STEPS, never by duration

A billing-blocked or otherwise unstarted CI job reports `steps: []` — it never entered the runner. A genuinely failing job has steps that ran and one that failed.

**Measured 2026-07-29 during the org-wide Actions billing block:** the *same* block produced durations of 3s, 11s and 12s — a 4× spread — while a genuine fast lint failure takes ~20s. **If both are red and both are fast, duration cannot separate them; step count separates them absolutely.**

Corollary, and the reason this rule exists at all: **on the day CI is blocked, the correct response to a red check is to do nothing.** A lane that misreads the block as its own defect spends an hour on a bug that is not there.

## 39 — `gh pr list --author @me` is not an ownership filter

The whole fleet commits under **one** GitHub identity, so `--author @me` returns **every lane's** PRs. Filter by **branch prefix** (`main-s6-*`, `ws3-*`); it is the only filter that means anything here.

Normally this is a nuisance you notice, because the titles are obviously not yours. **During an outage it composes into something worse:** every one of those PRs is about to go red for a reason that is nobody's code, so a lane trusting the filter is handed several red PRs it believes are its own — on the one day when the right response to a red is to do nothing.

## 40 — Zero checks is not a pass; it is the absence of the question

A PR in a repo with no CI reads `MERGEABLE/CLEAN` and renders **identically** to a PR whose checks have all passed. **The distinguishing fact is the check count, not the colour.** Run the count rather than assuming a code PR obviously has CI — the whole point is that the two look the same.

## 41 — Local green is real evidence; what it is not is COUNTERSIGNED

A local gate runs the *same command* CI runs, so its numbers are real. **The value of CI was never that it runs a different command — it is that it runs the same command somewhere the author cannot influence.**

Say **"CI uncountersigned"** on every number reported while a block lasts. The failure mode is not a wrong number: **it is that nobody decides anything and the phrase "local green" quietly loses its qualifier** over a few days of everyone typing it. The mechanical restatement survives an erosion that a remembered caveat does not.

### 41b — Three different claims, and a UAT verdict is not a substitute for either gate
**Green**, **green somewhere the author cannot influence**, and **green about what the user actually experiences** are three separate claims.

CI runs where the author cannot reach it but can only ever see what a test asserts. A human UAT sees what the product actually *does* — but on a rig the lane built, seeded and verified itself. **They are uncountersigned in opposite directions.** Neither substitutes for the other, and a clean UAT click must not be allowed to stand in for a gate.

## 42 — An errored command is not an empty result

A command that 404s, errors or refuses prints *something*, and a skimmed error body reads exactly like an empty list. Observed 2026-07-29: a step-count probe passed run ids where job ids were required, printed three `Not Found` bodies, and would have been read as *three empty step lists* — **reaching the right conclusion by an entirely wrong route**, invisible because the expected answer and the error looked the same.

Sibling of *an exit code is a claim* (rule 37 family) and of *a count is only comparable to a count taken the same way*. Check that the command **succeeded** before reading its output as data.

### 42b — The mechanism: the error arrives on the SAME CHANNEL as the answer

Refined 2026-07-29 by running the failure deliberately as a positive control. Passing a *run* id where a *job* id belongs **exits 1 and prints the Not-Found body to STDOUT, not stderr**. A probe that captures stdout and never checks the exit code therefore receives *a plausible JSON object where it expected JSON*.

So the failure is **not** that the error resembled an empty list — it is that **the error and the answer travel on the same channel**, and they are trivially distinguishable the moment you look at the exit code and impossible to distinguish if you never do. Same family as `$?` after a pipe reporting the tail's status, and as a 0-result search being a failure to investigate rather than a pass.

**The worst version is the one where the wrong route produces the RIGHT answer** — that is the instance nobody ever catches, because the conclusion validates the method.

### 42c — Why instrument rules must be turned backward before they are filed

Observed across all six lanes on 2026-07-29, and structural rather than cultural:

> **A rule about a bug points forward at code. A rule about a measurement points backward at every reading you have already taken — and those are all your own.**

Every rule in the 38–42 block concerns an *instrument*: a step count, an author filter, a check count, a countersignature, an exit code. When the finding is about your instrument, **the first place it applies is your own past claims**. A lane that files such a rule without re-running it against its own reporting has not adopted it.

Precedent from that day: a lane re-verified its historical "7/7" claims were **counts and not colours**; another re-ran its own step-count probe and proved the command **exited 0 with the field present**, rather than assuming its conclusion had been reached honestly; a third restated every number it had reported under the new qualifier.

### 42d — `cmd || echo "none"` is a rule-42 generator, and the PM was using it too

The readability habit of writing `grep -c PATTERN path || echo "none"` **converts a nonzero exit into prose that reads like a measurement.** "No matches" (exit 1) and "no such file" (exit 2) then produce the *same* output shape, and the fallback text is written by *you*, so it always looks authoritative.

**Positive-controlled by PM-3 on 2026-07-29, both branches:**
```
A) path exists, no match   → prints "0", fallback fires, exit was 1
B) path does not exist     → prints only the fallback,   exit was 2
```
**Indistinguishable from the fallback text alone.** PM-3 had used this exact pattern several times the same night in absence checks — including one verifying that a file was untouched by a PR. Those readings happened to be sound, but **sound by luck of a correct path rather than by construction, and the command could not have reported the difference.**

This is why 42b is the load-bearing half: **reading carefully does not help when the thing you read is well-formed.** In an absence check, check the exit code explicitly, or assert the path exists first — never let a fallback string stand in for a measurement.

### 42e — The antidote to 42d is rule 22: for any absence claim, prefer the form that produces a LIST over the form that produces a VERDICT

Rule 22 says *enumerate, do not sample* — a path-scoped query's emptiness is not meaningful, while a **list's** emptiness is. A fallback-guarded predicate check (`… || echo "none"`) is the same defect in different clothes: it asks *"is X absent?"* and answers **in prose the author wrote**, whereas an enumerating command answers with a list whose emptiness is a real measurement.

**Why the fallback reads authoritative precisely when it is wrong:** the text encodes the answer you *expected at authoring time*, so when it fires for the wrong reason it still says exactly what you were hoping to read.

So: `git ls-tree`/`--name-only` and look at the list, rather than `grep -c … || echo 0` and read the verdict.

## 43 — Alert erosion runs in BOTH directions, and the receiving end is the worse half

Established 2026-07-29 from the receiving lane's own report, not from theory.

A false positive erodes a silence detector faster than a miss does, because the reader learns to skim. **What was not obvious is that the erosion is not one-sided.** PM-3 chased one lane roughly eight times on a flat token count. The lane's replies got terser: it had learned the chase usually carried stale information and **began answering the FORM of the alert rather than reading it**.

> **The erosion does not only teach the sender to skim their own detector — it teaches the RECEIVER to skim the alert. That is worse, because the one alert that IS real arrives looking identical to the seven that were not.**

The evidence is as sharp as it gets: the CI-billing-block stop-read — the single most substantive broadcast of that night — landed in the middle of that pattern and **nearly received the same terse treatment**. It survived because the lane chose to read it properly, **not because anything in the system distinguished it**.

Consequences:
- A chase is not free. Do not send one a gate line could have answered — **gate the lane instead** (rules on hold-gates).
- When an alert really is substantive, **say so in its first clause**, because the receiver's prior is set by your last several.
- Fix the instrument rather than apologising for its noise: PM writes now re-baseline their own mailbox key so the PM is not woken by its own echo.

### 43b — When suppressing your own noise, absorb ONLY your own bytes

The obvious implementation of the above — re-baseline to the file's size *after* your write — **silently swallows anything a third party wrote in the window between the write and the re-baseline**. Found by a lane reviewing the fix, offered as a note rather than a request.

Correct form: re-baseline to the size you **expect** (observed-before + bytes written). If the file differs, someone else wrote too — **leave the old baseline alone and let the alert fire**.

> **A missed re-baseline costs one false positive; a swallowed write costs a real message.** That asymmetry decides the design.

Positive-controlled both directions: a PM write is invisible to the next delta; a third-party write in the same window is still reported.
