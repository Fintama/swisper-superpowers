/**
 * The review loop — browser side. Import once from the mock's entry file:
 *
 *   import "./select-client";
 *
 * PROGRESSIVE DRILL-IN, which is the interaction that survived review:
 *   click 1 on a spot  -> the outermost meaningful container
 *   click 2 same spot  -> one level in
 *   click 3 same spot  -> one level further …wrapping at the leaf
 *
 * Chosen over a modifier key because it needs nothing taught: click again,
 * watch it narrow. The readout in the corner names the current level so the
 * reviewer knows what "this" will mean before they go and say it.
 *
 * Shift-click adds to the selection ("make ALL of these secondary").
 * Press N with something selected to leave a note on it.
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
          className: (e as HTMLElement).className || null,
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
    `<span style="color:#7a8594">level ${d + 1} of ${chain.length} — click again to go deeper · N to note</span>`;
}

addEventListener("click", (e) => {
  /* ONLY REAL CLICKS. A scripted `el.click()` — browser automation verifying
     the mock, a test driving it — produces an untrusted event, and until this
     guard existed every one of those OVERWROTE current-selection.json. The
     reviewer's selection could be destroyed between them clicking and anyone
     reading it, silently, and the file would still look perfectly valid.
     `isTrusted` is false for any synthetic event and cannot be forged. */
  if (!e.isTrusted) return;
  const hit = (e.target as HTMLElement).closest("[data-source]");
  if (!hit) return;
  e.preventDefault();
  if (hit !== leaf) { leaf = hit; depth = 0; } else { depth += 1; }
  const chain = chainOf(hit);
  if (!chain.length) return;
  if (depth >= chain.length) depth = 0;
  render(chain, depth);
  const selected = chain[depth].entry;
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
});

addEventListener("keydown", (e) => {
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
