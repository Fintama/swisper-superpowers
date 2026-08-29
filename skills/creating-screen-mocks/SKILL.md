---
name: creating-screen-mocks
description: Use when a feature has a user-visible surface and no approved mock exists yet - designing a screen, a flow, a panel, a dialog, or reshaping an existing one. Symptoms - a spec is about to describe a screen in prose, an implementer is about to invent a layout, or someone asks "what should this look like". Not for test doubles or API fixtures, which are a different kind of mock entirely.
---

# Creating screen mocks

**Announce at start:** "I'm using creating-screen-mocks — I'm taking the UX/UI lead role for this surface."

**You are the head of UX and UI.** Your job is a product that is optimally usable
and genuinely enjoyable — as beautiful as you can make it within the design
system. Not a wireframe that proves the fields fit.

## The mock is the specification

🔴 **An approved mock IS the implementation spec for that surface.** It is real
React composing the real design system, typechecked against the installed
version — **never HTML that resembles a screen, and never a picture.**

- An implementer builds **from the mock**, not from prose about the mock.
- A spec describing a screen in words, where a mock exists, is describing it
  twice — and the two will disagree.
- **Throwaway-quality, load-bearing role.** The code bar is low: it is never
  copied into the product and never ships. Its *authority* is total.

**Why real React and not a drawing:** a drawing cannot be typechecked, so it can
promise a component that does not exist, a prop the design system rejects, or a
layout the tokens cannot express. Every one of those becomes an implementer's
problem weeks later. A mock that compiles has already failed those tests for you.

---

## Phase 1 · Intent and flow, before any pixel

Understand what the user is trying to **accomplish**, then propose the **screen
flow** that supports it — which screens exist, what moves between them, where the
decision points are.

Show the flow and get agreement. **A beautiful screen in the wrong flow is
wasted work**, and flow is the cheapest thing to change.

---

## Phase 2 · Ground yourself in the design system

**Do this before choosing a single component.** Skipping it is how a mock
acquires invented components and hardcoded colours that a reviewer then has to
find.

🔴 **`DESIGN.md` AND THE PER-COMPONENT `.md` FILES ARE NOT REFERENCE DOCS. THEY
ARE THE CHIEF EXPERIENCE OFFICER'S DIRECTION, WRITTEN DOWN.**

Someone senior decided how this product should feel, which component means what,
and where the line is. **Building a screen without reading them is not skipping
documentation — it is overriding a person who is not in the room**, and doing it
by accident. If you end up disagreeing with a direction, that is a conversation
to have, never something to settle silently inside one mock.

- [ ] **Find and read the design system's `DESIGN.md`** (or equivalent).
      Its agent guidance, decision hierarchy and component-selection logic tell
      you **how to choose**, not merely what exists.
      *Example: `@fintama/design-system/src/DESIGN.md` §6, §10, §16.*
- [ ] **Read the tokens file first, and never invent a value.** Colour, spacing,
      radius, typography, elevation — if a token exists, use it.
- [ ] **Read the component's own `.md` before composing with it.** Most component
      folders ship one, and it carries the intended use — which is regularly
      *not* what the name suggests. This is where "which of these two similar
      components is the right one" is already answered.
- [ ] **Enumerate what exists** before concluding something is missing. A mature
      design system ships more than you remember, sub-components included.

### 🔴 A DESIGN SYSTEM IS USUALLY MORE THAN ONE PACKAGE

**Finding one package and designing from it is the most common way this phase
fails.** The tokens live in one package, the components in another, the
product-specific components in a third, and the icons in a fourth. Compose from
one of them and you will "discover" gaps that do not exist, and invent things
that already ship.

**Enumerate from the CONSUMING APP, not from a directory you happened to open:**

```bash
# the authoritative list of what this product may compose with
cat <app>/package.json | grep -E '"@<org>/'
```

Every org-scoped dependency is a candidate. Then, for each one, count what is
actually in it:

```bash
ls -d node_modules/@<org>/<pkg>/src/components/*/ | wc -l
```

Typical shape, and all four are in scope:

| package | holds | trap |
|---|---|---|
| `…/design-system` | tokens, theme | **has no components** — finding it and stopping is the classic error |
| `…/ui` | the general component library | the biggest one; read its per-component `.md` |
| `…/<product>-ui` | product-specific components (chat, editor…) | often undocumented, and often exactly what you need |
| `…/icons` | icons | reach for it before drawing an SVG |

🔴 **THE REGISTRY IN `DESIGN.md` CAN BE STALE — COUNT THE FILESYSTEM, NOT THE
TABLE.** A component table is written by hand and drifts. *Measured on Fintama's
system: the registry documented 36 components while 44 shipped — eight, including
`avatar` and `popover`, existed and were invisible to anyone trusting the doc.*
The doc tells you **how to choose**; the filesystem tells you **what exists**.
When they disagree, the filesystem wins and the difference is a finding worth
raising.

### Also enumerate the app's OWN components

Beyond the shared packages, the product almost always has local components —
`src/domain/`, `src/blocks/`, `src/features/`. **These are precedent, and they are
frequently the real graft target.** If the product already renders the object you
are designing for (an email, an event, an invoice), that rendering is the
established language, and a mock that invents a second one for the same object
is asking users to learn it twice.

**The decision order, when two rules conflict:** accessibility → tokens →
existing component contracts → documented patterns → the design system doc →
local product context. **Higher always wins.**

🔴 **You may create something new only when there is genuinely no token and no
component for it.** And when you do, it is **flagged, not silent** — mark it in
the mock (`DS-GAP:` or the project's convention) and raise it. A new component
nobody was told about is a fork of the design system that no one chose.

**Match the component to the intent, not to visual similarity.** Two components
that look alike often behave differently under keyboard, screen reader and
error — and the difference is exactly what you are specifying.

---

## Phase 3 · Plan, and get the plan agreed

Before building anything, decide and **present**:

| | |
|---|---|
| **Colour** | which token roles, and what carries emphasis |
| **Components** | the actual DS components each region uses |
| **Layout** | structure, hierarchy, what is primary |
| **Precedent** | the existing screens and patterns you are matching |

**Look at the product's existing screens first.** A mock that ignores established
patterns is asking every user to learn the product twice. Where you deliberately
depart, say so and why — that is a design decision, and it should be visible.

**Present the plan and get feedback before building.** A plan is minutes to
change; a built prototype is hours.

---

## Phase 4 · Two variants of the hardest screen

Pick the **most complex** screen — the one where the layout question is genuinely
open — and build **two real variants**. Not five, not one.

**Two is the number** because it forces a comparison rather than a verdict. One
variant gets "yes, fine". Five get "I like bits of each", which is not a
decision.

Show both, get the direction, then build the rest to it. **Do not build the whole
set before the direction is settled** — you would be paying twice for every
screen.

⚠ **The variants need the workspace and the review loop already wired** — they
are the first thing anyone clicks on, and the direction conversation is exactly
where pointing beats describing. So **do Phase 5 now**: `init-workspace.sh`, then
`verify-review-loop.mjs` exits 0, then build two variants in it, then continue.

---

## Phase 5 · Stand the workspace up — and PROVE it is reviewable

🔴 **THIS PHASE COMES BEFORE ANY SCREEN, AND IT ENDS WITH A SCRIPT SAYING YES.**
Not because setup is interesting, but because the thing that makes a mock a mock
— the human being able to point at an element and have you read it — is
invisible when it is missing. The screens still render. The screenshots still
look right. Everything passes. See `BASELINE-2026-08-29.md`: an agent shipped a
mock with no review loop, cleared every verification item in this skill, and the
human's first words were *"why doesn't point to click work?"*

### Scaffold it — do not hand-write it

```bash
./init-workspace.sh <workspace-dir> <app-dir>
# e.g. ./init-workspace.sh design/mocks/checkout frontendV2
```

**Where:** one workspace per feature, **outside the application source** so it is
excluded from app builds and app CI. Follow the convention the repo already uses
— `ls` for an existing mocks directory and match it rather than inventing a
second location. *(Foundry's own repo uses `mocks/<slug>/`; an onboarded product
gets `design/mocks/<slug>/` on its feature branch.)*

The script writes the vite config with **`sourceStamp()` first, then React, then
`selectSink()`**, an entry file that already imports `select-client`, a tsconfig
that excludes the vendored loop (with the reason inline), and a `node_modules`
symlink. **An agent cannot forget a step it never performs** — which is the only
fix that has ever worked here, because the previous one was a three-line
instruction at the bottom of the longest phase and it was read and skipped.

🔴 **`<app-dir>` MUST BE THE WORKTREE THAT ACTUALLY HAS THE FEATURE.** In a repo
with several worktrees, the one you are standing in may be many commits behind
and simply not contain the code. The script fails fast if `node_modules` or
`src` is missing; it cannot tell you the branch is stale. Check that yourself —
in the measured run the workspace was built against a worktree 30+ commits
behind, every design-system import resolved to nothing, and it surfaced as a
Vite error long after the screens were written.

### 🔴 Never `npm install` in a mock workspace — symlink instead

The skill cannot ship `node_modules`: hundreds of MB, platform- and
arch-specific binaries, and it would have to match the host app's React/Vite
versions or the mock composes against a **different design system than the
product**. Borrowing the app's is not a shortcut, it is the only way the mock
typechecks against the version that actually ships.

An install is also actively dangerous where a repo shares one `node_modules`
across git worktrees by symlink — it can rewrite the tree every other worktree
points at.

### Then prove it, before you build anything

```bash
npx vite --port <found-port> --strictPort      # never a fixed port
node verify-review-loop.mjs http://localhost:<port> <workspace-dir>
```

Three measurements, exit 0 or the mock is not reviewable: the entry imports the
client, the served module carries stamps, and `POST /__select` persists.

🔴 **DO NOT TRY TO CONFIRM IT WITH A SCRIPTED CLICK — IT WILL DO NOTHING AND
LOOK BROKEN.** `select-client.ts` opens its click handler with

```ts
if (!e.isTrusted) return;   // scripted clicks must not clobber the reviewer's selection
```

so automation cannot overwrite `current-selection.json` between the human
clicking and you reading it. A synthetic `el.click()` is *correctly* ignored.
Agents hit this, conclude the loop is broken, and go debugging working code —
it cost the measured run real time. Only a human's real click exercises that
path, and that is the design, not a gap.

## Phase 6 · Build the prototype

### Import straight from the design system

```tsx
import { Button, Card, TextField } from "@your-org/ui";
```

**You do not need an instrumented import layer to make a mock reviewable.**
Selection comes from a build transform (see *The review loop* below) that stamps
every JSX tag with its own source location — raw `<div>`s included. It cannot be
forgotten and it needs no rule.

⚠ **If the project already has an instrumented toolkit and enforces importing
from it, follow that** — it is their contract, not yours to retire mid-task.
Raise it as a finding instead.

### Put a `data-testid` on every element that matters

Not decoration — it is the **join key** between the mock and the screen someone
builds from it. `review-loop/render-gate.mjs` compares the two element by element
on that key, and an element without one is invisible to the gate.

Put one on every interactive element, every region a reviewer would name, and
every piece of content that carries meaning. Skip pure layout wrappers.

⚠ **The implementer must preserve them.** Say so in the spec — a build that
renames them silently turns the gate green by having nothing left to compare.

### Components AND tokens — both, always

🔴 **If a component exists, use it. If a token exists, use it. Never a raw
value.** No hex colours, no pixel numbers, no invented spacing — not for a
one-off, not "just here", not because it is faster.

Colour · spacing · radius · typography · elevation · shadow · z-order: all of
them are tokens. A raw value is not a small shortcut — it is **a fork of the
design system with a scope of one screen**, and the next person copies it.

**A one-off visual request is never a reason to bypass a token.** It is a
**token gap**, and it gets raised as one. The same applies mid-review when
someone points at a thing and asks for it bolder or bluer — that is the moment
this rule is least convenient and most load-bearing.

Where a project enforces this at build time, let it — a mechanical check beats a
review comment. Where it does not, hold the line yourself.

### The index page is mandatory, and it is the first thing you build

A landing page listing:

- **the key design decisions** you took, in one line each
- **every screen**, linked
- **every variant**, side by side where they exist

**Every prototype page links back to the index.** A reviewer who has to use the
browser's back button, or retype a URL, stops exploring — and you lose the
feedback the prototype existed to collect.

### Make it genuinely clickable

The reviewer must be able to **walk the journey**, not stare at stills. Wire the
navigation between screens. Where a state matters (empty, loading, error, full,
degraded), make it reachable — a screen with only its happy state specifies only
its happy state, and the other four get invented by an implementer.

---

## Phase 7 · Verify, then present

- [ ] 🔴 **`verify-review-loop.mjs` exits 0.** First, not last — every other item
      below passed on a mock the human could not click, which is how the measured
      failure got all the way to presentation. If you changed `vite.config.ts`
      after Phase 5, run it again.
- [ ] **It typechecks against the *installed* design system version.**
- [ ] 🔴 **Positive-control the typecheck.** Inject a prop the DS must reject
      (a plausible one from a framework it is not — e.g. a size value it does not
      define), confirm the expected error, then restore and confirm clean.
      **A typecheck that cannot go red proves nothing.**
- [ ] **No invented components** — every one is a real DS export, or an
      explicitly flagged gap.
- [ ] **Interactive elements are real interactive elements.** A clickable tile is
      a `<button>`, not a `<div>` with a click handler. Linters treat this as an
      error, not a style preference, and a mock that cannot be committed is not a
      specification.
- [ ] **Run it locally and show it in a browser.** Do not hand over a file path or
      a screenshot when the point is the journey.

---

## Phase 8 · The review loop — how feedback actually arrives

Once the mock is up, **the reviewer points and you edit.** They click a component
in their own browser and then tell you what they want in words.

**Read `current-selection.json` before acting on any "this" / "here" / "that
one".** Never guess which element they meant — the file says.

```
selected : span.tile-label   src/screens/overview.tsx:66   nth 2 of 3
level    : 3 of 3
chain    : div.tiles(:64) > div.tile(:66) > span.tile-label(:66)
```

Three fields decide what you edit, and skipping any of them gets it wrong:

| | |
|---|---|
| **`source`** | the file and line. Several JSX elements can share a line |
| **`nth`** | which element on that line — the tile, its label, or its value |
| **`level`** | how wide they meant. Level 3 of 3 is the label; level 2 is the whole tile |

🔴 **The level IS the instruction.** *"Make this bigger"* on a label and on the
card containing it are different edits, and the reviewer already chose between
them by how many times they clicked. Honour it; do not substitute your own
reading of what they probably meant.

### Notes are for review you are NOT present for

A reviewer can press `N` on a selection to leave a note; notes append to
`review-notes.jsonl`. **They exist for one case: someone reviewing when you are
not in the room** — clicking through at night and leaving a queue. Read the queue
before a revision round.

⚠ **When you ARE in the room, notes are dead weight** — the reviewer types it
faster than they fill a prompt box, and the selection file already says what
"this" means. Do not push someone toward notes during a live session.

🔴 **A note is INPUT, never the durable record.** If a note turns out to encode a
design decision, **promote it into the source** as the project's design-note
convention (in Foundry, a `DesignNote` whose id links to the feature's design
decisions) so it reaches the spec and the implementer. A note that was only
*"make this bigger"* gets acted on and dropped.

**Do not let the queue become a second spec.** Two note systems that both claim
to carry design intent will drift, and the one the implementer reads will be the
wrong one.

⚠ **This is where token discipline quietly erodes.** *"Make it bold"* is an easy
thing to satisfy with a one-off inline style. Reach for the token, or flag the
gap — the same rule as everywhere else in this skill, applied at the moment it
is least convenient.

---

## Red flags

- **Your `vite.config.ts` has no `sourceStamp()` / `selectSink()`** — the mock is
  a picture, and the reviewer cannot point at anything
- **You hand-wrote the workspace** instead of running `init-workspace.sh`
- **You presented without `verify-review-loop.mjs` exiting 0**
- **You ran `npm install` in a mock workspace** — symlink the app's `node_modules`
- **You tried to verify click-to-select by scripting a click**, saw nothing
  happen, and started debugging the loop — it ignores untrusted events by design
- **You pointed `<app-dir>` at a worktree that does not contain the feature**
- You chose a component before reading its `.md`
- You started designing without reading `DESIGN.md`
- You wrote a hex colour or a pixel value
- You satisfied a "make it bolder/bluer" request with a raw value instead of a
  token, or instead of raising a token gap
- You acted on "make this…" without reading the current selection
- You edited a different level than the one the reviewer had selected
- You built every screen before the direction was agreed
- You produced one variant of the hardest screen, or five
- Your prototype has no index, or a page with no way back to it
- Only the happy state is reachable
- You created a new component without flagging it
- You are describing the screen in the spec instead of pointing at the mock
- Your mock has no `data-testid`s, so nothing downstream can be compared to it

---

## When the design system genuinely lacks something

**Escalate rather than improvise.** Say what the design needs, what the closest
existing component is, and why it does not fit. That is a design-system finding
worth having — and it is a decision someone owns, not a gap for you to fill
silently in one product's mock.
