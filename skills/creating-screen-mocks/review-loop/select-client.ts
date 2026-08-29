/**
 * The review loop — browser side. Import once from the mock's entry file:
 *
 *   import "./select-client";
 *
 * 🔴 A PLAIN CLICK USES THE PROTOTYPE. ALT/OPTION-CLICK SELECTS.
 *
 *   plain click            the mock behaves like the real thing
 *   Alt + click            select (the prototype does NOT act)
 *   Alt + click again      one level in …wrapping at the leaf
 *   Alt + Shift + click    add to the selection ("make ALL of these …")
 *   S                      toggle select-mode — plain click selects
 *   N                      leave a note on the current selection
 *   Esc                    clear the selection (S also clears on exit)
 *
 * PROGRESSIVE DRILL-IN is still the interaction: Alt-click again on the same
 * spot and watch it narrow. The readout in the corner names the current level,
 * and the mode, so the reviewer knows what "this" will mean before they say it.
 *
 * ⚠ The drill-in was originally chosen *because* it needed no modifier. That
 * reasoning held only while the mock was a picture. A prototype is interactive,
 * so an unmodified click already means "use me", and taking it for selection
 * made every act of pointing also press the thing being pointed at. See the
 * SELECTING vs USING block below for why it was invisible for so long.
 */
type Entry = {
  level: number; source: string; tag: string; className: string | null;
  nth: number; ofSameSource: number; text: string;
};

let leaf: Element | null = null;
let depth = 0;
let current: Entry[] = [];

const readout = document.createElement("div");
readout.id = "mock-select-readout";
readout.style.cssText =
  "position:fixed;top:10px;right:10px;z-index:2147483647;background:#1b2331;" +
  "border:1px solid #2a3547;border-radius:8px;padding:8px 10px;color:#e6e8eb;" +
  "font:12px ui-monospace,SFMono-Regular,Menlo,monospace;max-width:320px;" +
  "pointer-events:none;line-height:1.45";
addEventListener("DOMContentLoaded", () => document.body.appendChild(readout));

/** Ancestors OUTERMOST-first, dropping wrappers that cover most of the
 *  viewport — otherwise click 1 selects "the whole page", which is useless. */
function chainOf(el: Element): { entry: Entry; el: Element }[] {
  const up: Element[] = [];
  for (let n: Element | null = el; n && n !== document.body; n = n.parentElement) up.push(n);
  const page = innerWidth * innerHeight;
  return up
    .reverse()
    .filter((e) => e.getAttribute("data-source"))
    .filter((e) => {
      const r = e.getBoundingClientRect();
      return (r.width * r.height) / page < 0.7;
    })
    .map((e, i) => {
      const source = e.getAttribute("data-source")!;
      const peers = [...document.querySelectorAll(`[data-source="${source}"]`)];
      return {
        el: e,
        entry: {
          level: i, source,
          tag: e.tagName.toLowerCase(),
          /* 🔴 `getAttribute("class")`, NEVER `.className`. On an SVG element
             `.className` is an SVGAnimatedString OBJECT, not a string — so the
             readout printed `line.[object` and the JSON carried `"className":{}`.
             Measured 2026-08-29 the moment a reviewer selected a chart
             connector. Every mock with a chart, an icon or any inline SVG hits
             this, and it degrades exactly where the element is hardest to
             identify by tag alone. `getAttribute` returns a plain string for
             both HTML and SVG. */
          className: e.getAttribute("class") || null,
          // Several JSX elements can sit on ONE line and share an anchor.
          // `nth` is what separates them, and it is not optional.
          nth: peers.indexOf(e) + 1,
          ofSameSource: peers.length,
          text: ((e as HTMLElement).innerText || "").trim().slice(0, 40),
        },
      };
    });
}

function render(chain: { entry: Entry; el: Element }[], d: number) {
  document.querySelectorAll("[data-mock-hl]").forEach((n) => {
    n.removeAttribute("data-mock-hl");
    (n as HTMLElement).style.outline = "";
  });
  const pick = chain[d];
  if (!pick) return;
  const el = pick.el as HTMLElement;
  el.setAttribute("data-mock-hl", "1");
  el.style.outline = "2px solid #4f8cff";
  el.style.outlineOffset = "-2px";
  const { tag, className, source } = pick.entry;
  const name = tag + (className ? "." + String(className).split(/\s+/)[0] : "");
  readout.innerHTML =
    `<b>${name}</b><br><span style="color:#9db8e8">${source}</span><br>` +
    `<span style="color:#7a8594">level ${d + 1} of ${chain.length} — Alt-click again to go deeper · N to note</span>` +
    modeLine();
}

/**
 * Drop the selection — visual, in-memory, AND on disk.
 *
 * 🔴 THE FILE GOES TOO, AND THAT IS THE POINT. A highlight left over an
 * interactive prototype is clutter; a STALE current-selection.json is a wrong
 * answer waiting to happen. The reviewer exits select-mode, uses the prototype
 * for ten minutes, then says "make this bigger" — and the session reads an
 * element they stopped pointing at half an hour ago, confidently. No file is an
 * honest "I don't know which one"; a stale file is a confident wrong one.
 */
function clearSelection() {
  document.querySelectorAll("[data-mock-hl]").forEach((n) => {
    n.removeAttribute("data-mock-hl");
    (n as HTMLElement).style.outline = "";
  });
  leaf = null; depth = 0; current = [];
  readout.innerHTML = modeLine().replace(/^<br>/, "");
  fetch("/__select", { method: "DELETE" }).catch(() => {});
}

/* 🔴 THE MODE MUST BE ON SCREEN AT ALL TIMES. A modifier is stateless and needs
   no indicator, but select-mode is a MODE, and an unlabelled mode is how someone
   clicks a button expecting it to work and gets a selection instead — then
   reports the prototype as broken. */
function modeLine() {
  return selectMode
    ? `<br><span style="color:#ffd479">SELECT MODE — plain click selects · S to exit</span>`
    : `<br><span style="color:#7a8594">Alt-click to select · S for select-mode</span>`;
}

function renderMode() {
  if (!readout.innerHTML) { readout.innerHTML = modeLine().replace(/^<br>/, ""); return; }
  readout.innerHTML = readout.innerHTML.replace(
    /<br><span style="color:(#ffd479|#7a8594)">(SELECT MODE|Alt-click to select)[^<]*<\/span>$/,
    modeLine(),
  );
}

/* ══ SELECTING vs USING THE PROTOTYPE ══════════════════════════════════════
 *
 * 🔴 A PROTOTYPE IS INTERACTIVE, SO A CLICK MEANS TWO THINGS AND WE MUST PICK.
 *
 * Until 1.2.0 every review click ALSO drove the prototype, and `preventDefault()`
 * looked like it was preventing that. It was not. This listener sits on `window`
 * in the BUBBLE phase; React attaches its handlers at the root container, which
 * is below window — so React's `onClick` had already run by the time we got the
 * event. `preventDefault()` only cancels the BROWSER's default action (following
 * a link, submitting a form, ticking a checkbox); it cannot un-run a handler.
 * Pointing at a tab to say "make this wider" therefore also switched the tab.
 *
 * The fix is the CAPTURE phase — window's capture listener runs before the root
 * container's — plus `stopPropagation`, so a selection click never reaches React
 * at all.
 *
 *   plain click              use the prototype. It behaves like the real thing.
 *   ALT/OPTION + click       select. The prototype does NOT act.
 *   ALT + SHIFT + click      add to the selection ("make ALL of these …").
 *   press S                  toggle select-mode, where a PLAIN click selects —
 *                            for an extended review where holding Alt is tiring.
 *
 * 🔴 ALT, NOT SHIFT, AND THAT IS NOT A PREFERENCE. Shift was already taken by
 * add-to-selection, and shift-click also extends the browser's text selection.
 * Cmd-click opens links in a new tab and Ctrl-click is a right-click on macOS.
 * Alt is the only modifier free of a conflict, and it is what design tools use.
 */
let selectMode = false;

addEventListener("keydown", (e) => {
  /* Same guard as the click handler, for the same reason — automation must not
     be able to flip a reviewer's mode out from under them. */
  if (!e.isTrusted) return;
  if (e.key.toLowerCase() !== "s") return;
  const t = (e.target as HTMLElement)?.tagName;
  if (t === "INPUT" || t === "TEXTAREA" || (e.target as HTMLElement)?.isContentEditable) return;
  selectMode = !selectMode;
  /* Leaving select-mode means "done pointing, back to using it" — so the
     selection goes with the mode. Entering it only changes the mode. */
  if (!selectMode) clearSelection(); else renderMode();
});

/* Escape clears too, which is the only way out when selecting with ⌥ rather
   than in select-mode — otherwise the highlight can only be replaced, never
   dismissed. */
addEventListener("keydown", (e) => {
  if (!e.isTrusted || e.key !== "Escape" || !current.length) return;
  clearSelection();
});

addEventListener("click", (e) => {
  /* ONLY REAL CLICKS. A scripted `el.click()` — browser automation verifying
     the mock, a test driving it — produces an untrusted event, and until this
     guard existed every one of those OVERWROTE current-selection.json. The
     reviewer's selection could be destroyed between them clicking and anyone
     reading it, silently, and the file would still look perfectly valid.
     `isTrusted` is false for any synthetic event and cannot be forged. */
  if (!e.isTrusted) return;

  /* 🔴 THE DEFAULT IS "USE THE PROTOTYPE". Returning here leaves the event
     completely untouched, so the mock behaves exactly as a user would find it.
     A review tool that silently changes how the thing under review responds is
     measuring something other than the thing under review. */
  /* 🔴 ⌘ IS THE WRONG KEY AND SAYING SO BEATS DOING NOTHING. Measured: a
     reviewer reached for Command — entirely natural on a Mac — got a plain
     click, and reported the tool as broken. Cmd cannot BE the selector (it
     opens links in new tabs), but a silent no-op is the worst possible answer.
     Naming the mistake costs one line and replaced a whole debugging round. */
  if (e.metaKey && !e.altKey && !selectMode) {
    const near = (e.target as HTMLElement).closest?.("[data-source]");
    if (near) {
      readout.innerHTML =
        `<span style="color:#ffd479">that was ⌘ — hold ⌥ (Option) to select</span>` +
        `<br><span style="color:#7a8594">⌥ is immediately left of ⌘ · or press S for select-mode</span>`;
    }
    return;
  }

  if (!e.altKey && !selectMode) return;

  const hit = (e.target as HTMLElement).closest("[data-source]");
  if (!hit) return;

  /* 🔴 BOTH, AND IN THE CAPTURE PHASE. `stopPropagation` is what keeps React
     from acting; `preventDefault` is what keeps the browser from following a
     link or submitting a form. Neither alone is enough, and the earlier version
     had only the second. */
  e.stopPropagation();
  e.preventDefault();

  if (hit !== leaf) { leaf = hit; depth = 0; } else { depth += 1; }
  const chain = chainOf(hit);
  if (!chain.length) return;
  if (depth >= chain.length) depth = 0;
  render(chain, depth);
  const selected = chain[depth].entry;
  /* Alt+SHIFT adds; Alt alone replaces. In select-mode plain Shift adds. */
  current = e.shiftKey ? [...current, selected] : [selected];
  fetch("/__select", {
    method: "POST",
    body: JSON.stringify({
      screen: location.pathname,
      selectedLevel: depth,
      selected,
      alsoSelected: current.slice(0, -1),
      chain: chain.map((c) => c.entry),
    }),
  });
  /* 🔴 CAPTURE — window's capture listener runs BEFORE the React root's, which
     is what makes stopPropagation above able to keep React from ever seeing the
     event. In the bubble phase React has already handled it and nothing can
     undo that. This single option is the difference between "the prototype also
     acted" and "it did not". */
}, { capture: true });

addEventListener("keydown", (e) => {
  /* 🔴 isTrusted HERE TOO. The click handler has always had it; these two did
     not, so a scripted keypress could append notes a human never wrote — into
     the one file this loop treats as a DURABLE record rather than current
     state. An invented note is worse than an overwritten selection: the
     selection is replaced on the next click, a note persists and gets acted on. */
  if (!e.isTrusted) return;
  if (e.key.toLowerCase() !== "n" || !current.length) return;
  const target = (e.target as HTMLElement)?.tagName;
  if (target === "INPUT" || target === "TEXTAREA") return;
  const note = prompt(`Note on ${current[0].tag} (${current[0].source}):`);
  if (!note) return;
  fetch("/__note", {
    method: "POST",
    body: JSON.stringify({ at: new Date().toISOString(), note, on: current }),
  });
});
