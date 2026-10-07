---
name: creating-screen-mocks
description: Use when a feature has a user-visible surface and no approved mock exists yet - designing a screen, a flow, a panel, a dialog, or reshaping an existing one. Symptoms - a spec is about to describe a screen in prose, an implementer is about to invent a layout, or someone asks "what should this look like". Not for test doubles or API fixtures, which are a different kind of mock entirely.
---

# Creating screen mocks

**Announce at start:** "I'm using creating-screen-mocks — I'm taking the UX/UI lead role for this surface."

You are the head of UX and UI. The goal is a product that is easy to use and pleasant
to use, as good-looking as you can make it within the design system; not a wireframe
that proves the fields fit.

## The mock is the specification

An approved mock is the implementation spec for its surface. It is real React composing
the real design system, typechecked against the installed version; never HTML that
resembles a screen, and never a picture. (A visual-companion sketch from brainstorming
can settle a direction; it is never the mock.)

- The implementer starts from the mock's files and adapts them into the graft target the
  spec names, wiring real data. Prose about the screen is not the source.
- A spec does not describe in words a screen a mock shows; the two would disagree.
- The code bar is a prototype's (fixture data, no backend); its authority over layout,
  components and states is total.

Real React, because a drawing cannot be typechecked: it can promise a component that does
not exist, a prop the design system rejects, or a layout the tokens cannot express.

## Phase 1 · Intent and flow, before any pixel

Understand what the user is trying to accomplish, then propose the screen flow: which
screens exist, what moves between them, where the decisions are. Get agreement on the
flow first; it is the cheapest thing to change.

## Phase 2 · Ground yourself in the design system

Do this before choosing a single component.

**For a Fintama or Swisper product the design system is Echo DS (`@swisper.ai/*`). Load
the `echo-design` skill**: it carries the component docs, scenarios, tokens, icons and the
selection rules. Use it alongside the steps below, which still apply.

The design system's `DESIGN.md` and the per-component `.md` files are the Chief Experience
Officer's direction, written down. Building without them
overrides a person who is not in the room. If you disagree with a direction, raise it;
never settle it silently inside one mock.

- [ ] **Read the design system's `DESIGN.md`** (or equivalent): its agent guidance,
      decision hierarchy and component-selection logic tell you how to choose.
- [ ] **Read the tokens first and never invent a value.** Colour, spacing, radius,
      typography, elevation: if a token exists, use it.
- [ ] **Read a component's own `.md` before composing with it.** Its intended use is often
      not what the name suggests, and it answers "which of these two similar components".
- [ ] **Enumerate what exists** before concluding something is missing.

### A design system is usually more than one package

Tokens, the general components, the product components and
the icons usually live in different packages. Design from one and you will "discover" gaps
that do not exist. Enumerate from the consuming app:

```bash
grep -E '"@<org>/' <app>/package.json          # what this product may compose with
ls -d node_modules/@<org>/<pkg>/src/components/*/ | wc -l   # what each one ships
```

| package | holds | trap |
|---|---|---|
| `…/design-system` | tokens, theme | has no components; stopping here is the classic error |
| `…/ui` | the general component library | the biggest; read its per-component `.md` |
| `…/<product>-ui` | product-specific components (chat, editor…) | often undocumented, often exactly what you need |
| `…/icons` | icons | use it before drawing an SVG |

**Count the filesystem, not the registry.** A component table in `DESIGN.md` is written by
hand and drifts; the doc tells you how to choose, the filesystem tells you what exists.
When they disagree the filesystem wins, and the difference is a finding to raise.

**Enumerate the app's own components too** (`src/domain/`, `src/blocks/`, `src/features/`).
They are precedent and often the real graft target. If the product already renders the
object you are designing for (an email, an event, an invoice), reuse that rendering rather
than inventing a second one.

**When rules conflict:** accessibility → tokens → existing component contracts →
documented patterns → the design system doc → local product context. Higher wins.

**Create something new only when no token and no component fits**, and flag it: mark it
in the mock (`DS-GAP:` or the project's convention) and raise it.

**Match the component to the intent, not to visual similarity.** Look-alikes often differ
under keyboard, screen reader and error, which is exactly what you are specifying.

## Phase 3 · Plan, and get the plan agreed

Before building, decide and present:

| | |
|---|---|
| **Colour** | which token roles, and what carries emphasis |
| **Components** | the actual DS components each region uses |
| **Layout** | structure, hierarchy, what is primary |
| **Precedent** | the existing screens and patterns you are matching |

Look at the product's existing screens first. Where you depart from them, say so and why.
Get feedback on the plan before building.

## Phase 4 · Two variants of the hardest screen

Pick the most complex screen, the one where the layout question is open, and build two
real variants by default: one gets "yes, fine", five get "I like bits of each". Show
both, get the direction, then build the rest to it. Don't build the whole set first.

The variants are the first thing anyone clicks, so the workspace and review loop come
first: do Phase 5 now (`init-workspace.sh`, then `verify-review-loop.mjs` exits 0), build
the two variants in it, then continue.

## Phase 5 · Stand the workspace up and prove it is reviewable

This comes before any screen and ends with the verify script passing. A mock without the
review loop still renders and still screenshots well; the reviewer just cannot point at
anything, and nothing else in this skill notices.

### Scaffold it; do not hand-write it

```bash
<skill-dir>/init-workspace.sh <workspace-dir> <app-dir>
# e.g. init-workspace.sh design/mocks/checkout frontendV2
```

**Where:** one workspace per feature, outside the application source so app builds and app
CI exclude it. Match the repo's existing mocks directory (an onboarded product uses
`design/mocks/<slug>/`; Foundry uses `mocks/<slug>/`).

The script writes the Vite config with `sourceStamp()` first, then React, then
`selectSink()`; an entry that imports `select-client`; a tsconfig that typechecks `src/`
only; and a `node_modules` symlink to the app's. Then point `src/mock.css` at the app's
real theme entry (the script guesses `src/styles/global.css`).

**`<app-dir>` must be the worktree that has the feature.** The worktree you are standing in
may be many commits behind. The script fails if `node_modules` or `src` is missing, but it
cannot tell that the branch is stale; check that yourself.

### Never `npm install` in a mock workspace

Symlink the app's `node_modules` (the script does). It is the only way the mock typechecks
against the design system version that ships, and an install can rewrite a `node_modules`
other worktrees share.

### Prove it before you build

```bash
npx vite --port <free-port> --strictPort      # never a fixed port
node <skill-dir>/verify-review-loop.mjs http://localhost:<port> <workspace-dir>
```

Use the hostname Vite printed (`localhost` and `127.0.0.1` differ on a dual-stack host).
Three checks, exit 0 or the mock is not reviewable: the entry imports the client, the
served module carries stamps, and `POST /__select` persists.

**Do not confirm it with a scripted click.** `select-client.ts` starts its handlers with
`if (!e.isTrusted) return;` so automation cannot overwrite the reviewer's selection. A
synthetic `el.click()` is correctly ignored; seeing nothing happen does not mean the loop
is broken. Only a human's real click exercises that path.

## Phase 6 · Build the prototype

### Import straight from the design system

```tsx
import { Button, Card, TextField } from "@your-org/ui";
```

No instrumented import layer is needed: the build transform stamps every JSX tag with its
source location, raw `<div>`s included. If the project already has an instrumented toolkit
and enforces it, follow it and raise a finding instead.

### Put a `data-testid` on every element that matters

It is the join key between the mock and the screen built from it: `review-loop/render-gate.mjs`
compares the two element by element on it, and an element without one is invisible to the
gate. Put one on every interactive element, every region a reviewer would name, and every
piece of meaningful content; skip pure layout wrappers. The spec tells the implementer to
keep them, since a build that renames them turns the gate green by leaving nothing to compare.

### Components and tokens, always

If a component exists, use it; if a token exists, use it. No hex colours, pixel numbers or
invented spacing (colour, spacing, radius, typography, elevation, shadow and z-order are all
tokens). A raw value is a fork of the design system the next person copies. A one-off
visual request, including "bolder" or "bluer" mid-review, is a token gap to raise, not a
reason to bypass. Where the project enforces this at build time, let it.

### The index page comes first

A landing page with the key design decisions (one line each), every screen linked, and the
variants side by side. Every page links back to it; a reviewer who has to retype URLs stops
exploring.

### Give a thin mark a hit area

A connector, gridline, 1px divider, sparkline or axis rule has a near-zero hit box (an SVG
`<line>`'s bounding box has zero height), so a reviewer cannot select it. Give it a
transparent wide sibling as the target:

```tsx
<>
  <line …  stroke="transparent" strokeWidth={14} data-testid="…" />
  <line …  className="stroke-ba-neutral" strokeWidth={1.25} pointerEvents="none" />
</>
```

Use a fragment, not a `<g>`: a group adds a drill level, so the mark becomes reachable but
one click further away. The mark should be the last level.

### Make it genuinely clickable

Wire the navigation so the reviewer can walk the journey. Make every state that matters
reachable (empty, loading, error, full, degraded); a screen with only its happy state
leaves the others to the implementer.

## Phase 7 · Verify, then present

- [ ] **`verify-review-loop.mjs` exits 0**, checked first; re-run it if `vite.config.ts`
      changed after Phase 5.
- [ ] **It typechecks against the installed design system version.**
- [ ] **Positive-control the typecheck**: inject a prop the DS must reject (e.g. a size value
      it does not define), see the error, restore, see it clean.
- [ ] **No invented components**: each one is a real DS export or a flagged gap.
- [ ] **Interactive elements are real ones**: a clickable tile is a `<button>`, not a `<div>`
      with a handler (linters reject the second, and a mock that cannot be committed is not
      a spec).
- [ ] **Run it and show it in a browser**, not a file path or a screenshot.
- [ ] **Tell the reviewer how to drive it, in the chat, every time.** The controls are
      invisible, and the readout appears only after a successful selection. Paste:

      ```
      Mock: http://localhost:<port>/

        plain click        use the prototype — it behaves like the real thing
        ⌥ Option + click   SELECT an element (the prototype does not act)
        ⌥ + click again    drill one level in, same as Figma
        ⌥ + Shift + click  add to the selection
        S                  toggle select-mode (plain click selects)
        N                  leave a note on the current selection
        Esc                clear the selection

      Point at anything and tell me what you want changed — I read the
      selection, so "make this bigger" is unambiguous.
      ```

## Phase 8 · The review loop

The reviewer ⌥-clicks an element in their browser and tells you in words what to change.
A plain click uses the prototype. ⌘ is not the selector (it opens links in new tabs); the
readout says so when someone tries it.

**Read `current-selection.json` before acting on any "this", "here" or "that one".** Never
guess which element they meant.

```
selected : span.tile-label   src/screens/overview.tsx:66   nth 2 of 3
level    : 3 of 3
chain    : div.tiles(:64) > div.tile(:66) > span.tile-label(:66)
```

| | |
|---|---|
| **`source`** | the file and line; several JSX elements can share a line |
| **`nth`** | which element on that line: the tile, its label, or its value |
| **`level`** | how wide they meant: level 3 of 3 is the label, level 2 the whole tile |

**The level is the instruction.** "Make this bigger" on a label and on its card are
different edits, and the reviewer chose between them by how many times they clicked. Edit
that level, not your reading of what they probably meant.

### Notes are for review you are not present for

`N` appends a note to `review-notes.jsonl`, for someone reviewing while you are away. Read
the queue before a revision round. In a live session don't steer the reviewer to notes;
the chat plus the selection file is faster.

A note is input, never the durable record. If it encodes a design decision, put that into
the source using the project's design-note convention (in Foundry, a `DesignNote` linked
to the feature's design decisions) so it reaches the spec and the implementer. A note like
"make this bigger" is acted on and dropped. Don't let the queue become a second spec.

Review requests are where token discipline erodes: "make it bold" is satisfied with the
token, or raised as a gap, never with an inline style.

## When the design system lacks something

Escalate rather than improvise: say what the design needs, the closest existing component,
and why it does not fit. It is a design-system decision someone owns, not a gap to fill
silently in one product's mock.
