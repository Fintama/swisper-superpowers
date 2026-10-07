# The page standard (architecture site)

The binding sources are the approved spec (Swisper_Documentation `specs/swisper/2026-10-04-architecture-site-design.md`: §1.2 page format, §1.4 diagrams, §1.5 findings, §1.6 quality, §8 amendments) and the model pages `architecture/pages/0-start/0.3-*.md` (Overview) and `architecture/pages/E/E.2-*.md` (Design). **Copy the shape of the model page nearest yours.** This file is the summary, not a substitute.

## Front matter (strict: these keys, nothing else)

`id` (stable, never renumbered) · `title` · `subtitle` · `tag` (Overview | Design | Code | Runbook | Code map) · `chapter` · `covers` {paths, symbols, concepts, tables, routes, graphs, flags, jobs, workflows, mcp_tools} · `verified` {sha, date, by} — written by `gates.py verify`, never by hand · `assessment` {sound, flaw, robust, elegant, fast, extensible} · `findings` [ids] · `asks` (6 questions a reader would ask that the page answers).

- `covers` drives both gates: list what the page explains, no more. `symbols` (`path::Symbol`) narrows staleness to those functions; prefer it to a whole busy file in `paths`. A concept must exist in `architecture/concepts.yaml` and needs an Overview or Design page.
- `assessment` answers start with a verdict word: `yes` / `no concern` (green), `partly` / `mostly` (amber), `no` (red), then the finding ids: `'partly · F-003'`. `flaw` is a finding id or `none`.

## Body, top to bottom

1. `::: lead` … `:::` — **in plain words**, 2–3 short paragraphs a product manager can read. No code, no internal names.
2. **Picture first.** For each section decide the picture that carries the idea before writing prose: the boundary crossed, the path a request takes, the states it moves through, what changes between two options. **Picture-only test:** hide the text; the reader must still get the logic from the picture and its caption. A diagram that only lists names fails.
   - Hand-drawn SVG in the E.2 style: the `d-*` classes only, `currentColor`, no literal colours, labelled arrows, `role="img"` and an `aria-label` carrying the claim. `![[diagrams/<ch>/x.svg]]` on its own line, then `caption: <the claim>`.
   - Generated, never hand-drawn, when the code fully defines it: `{{graph: <name>}}`, `{{er: <slice>}}`, inventories.
   - Screenshot when the user's view explains best: `![[screenshots/<ch>/x.png]]`, then `caption:`, `captured: <date · source>`, `alt:`.
3. **The pyramid.** Overview pages: plain words only; inline `code` only inside `::: dev`, no fenced code. Design pages: contracts, decisions and the rejected alternative, ownership, a rules grid (`:::: rules` / `::: rule <Title>` … `:::` / `::::`, optional `src:` line). Developer detail goes in the collapsed `::: dev` block: code anchors (`path::Symbol` for Python, `path:line` for TS and other files; SKILL.md §3) and the tests that pin them.
4. `{{findings}}` places the generated findings section. Cross-links: `[[2.5]]`, `[[2.5|text]]`, `[[F-031]]` — the build fails on a dangling one.

## Honest assessment and findings

Answer the five questions honestly on every page: is it sound; is there a design flaw; could it be more robust, more elegant, faster, more extensible. Each answer is a finding or an explicit "no concern". Code-quality problems count: comment bloat, stale comments, dead code, duplication, oversized units, layer violations.

A finding entry, in its chapter's section of `FINDINGS.md`, next free id of that range:

```
### F-E07 · <one-line claim>

category: robustness            # design-flaw | security | robustness | performance | extensibility | elegance | tech-debt | code-quality | docs-drift
severity: medium                # high | medium | low
status: suspected               # suspected | verified (needs second_read) | accepted (needs reason) | fixed (needs fixed_by)
component: agents / delegation
pages: [E.2]
consequence: <for Overview readers, plain words>
impact: <for Design readers>
evidence: `path/file.py:123` (what it shows)
fix: <the proposed fix>
cost: S                         # S | M | L | XL
first_seen: <sha>
```

Pages reference ids; they never restate a finding's evidence. Evidence stays pinned to `first_seen`: line shifts never make a finding stale.
