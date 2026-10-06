#!/usr/bin/env node
/**
 * Is the review loop working? Three checks, no browser.
 *
 *   node verify-review-loop.mjs <url> [workspace-dir]     e.g. http://localhost:5173 design/mocks/checkout
 *
 * Exits 0 only if the entry imports select-client, the served App module carries
 * source stamps, and POST /__select writes current-selection.json.
 *
 * It does not simulate a click: select-client ignores untrusted events so automation
 * cannot overwrite the reviewer's selection. Only a real click exercises that path.
 */
import { writeFileSync, existsSync, rmSync } from "node:fs";
import { join } from "node:path";

const base = (process.argv[2] || "").replace(/\/$/, "");
if (!base) {
  console.error("usage: node verify-review-loop.mjs <url> [workspace-dir]   e.g. http://localhost:5173");
  process.exit(2);
}
const outDir = process.argv[3] || process.cwd();

let failures = 0;
const ok   = (m) => console.log(`  ✓ ${m}`);
const bad  = (m, fix) => { failures++; console.log(`  ✗ ${m}\n      → ${fix}`); };

console.log(`\nreview loop · ${base}\n`);

/* ── 1 · is the page even up ───────────────────────────────────────────────── */
let html;
try {
  const r = await fetch(base + "/");
  html = await r.text();
  ok(`server answers (HTTP ${r.status})`);
} catch (e) {
  bad(`cannot reach ${base} — ${e.message}`,
      "is the dev server running, and did you use the same hostname Vite printed? " +
      "`localhost` and `127.0.0.1` are not interchangeable on a dual-stack host.");
  process.exit(1);
}

/* ── 2 · sourceStamp · does the stamp reach the SERVED source ──────────────── */
const entry = (html.match(/src="([^"]*main\.[jt]sx?)"/) || [])[1];
if (!entry) {
  bad("no module entry found in index.html",
      "expected a <script type=module src=...main.tsx>");
} else {
  const mod = await fetch(base + entry).then((r) => r.text());
  const appMatch = mod.match(/from\s+["']([^"']*App[^"']*)["']/);
  const appUrl = appMatch ? new URL(appMatch[1], base + entry).pathname : null;

  if (!/select-client/.test(mod)) {
    bad("the entry module never imports `select-client`",
        'add  import "../review-loop/select-client";  to main.tsx — without it ' +
        "nothing is selectable and the mock still looks finished.");
  } else ok("entry imports select-client (browser half present)");

  if (appUrl) {
    const app = await fetch(base + appUrl).then((r) => r.text());
    // Match the name only: the served module is post-JSX-transform, so the stamp is a prop, not `data-source=`.
    const stamps = (app.match(/data-source/g) || []).length;
    if (stamps === 0) {
      bad("0 elements stamped with data-source in the served App module",
          "`sourceStamp()` is not registered, or is not FIRST in the plugin list " +
          "(it must run before the React plugin transforms the JSX away).");
    } else ok(`${stamps} stamped elements in App (sourceStamp is running)`);
  }
}

/* ── 3 · selectSink · does a selection actually persist ────────────────────── */
const probe = join(outDir, "current-selection.json");
const had = existsSync(probe);
if (had) {
  // Never overwrite a real selection.
  ok("current-selection.json already exists (a real selection — not overwriting)");
} else {
  try {
    const r = await fetch(base + "/__select", {
      method: "POST",
      body: JSON.stringify({ probe: "verify-review-loop" }),
    });
    if (r.status !== 204) {
      bad(`POST /__select returned ${r.status}, expected 204`,
          "`selectSink()` is not registered in vite.config.ts");
    } else if (!existsSync(probe)) {
      bad("POST /__select returned 204 but wrote no file",
          `selectSink's outDir is not ${outDir} — pass the workspace dir as arg 3`);
    } else {
      ok("POST /__select → 204 and current-selection.json written");
      rmSync(probe);
    }
  } catch (e) {
    bad(`POST /__select failed — ${e.message}`, "`selectSink()` is not registered");
  }
}

console.log(
  failures === 0
    ? "\nreview loop OK — the reviewer can point at elements.\n" +
      "Do not confirm with a scripted click: select-client ignores\n" +
      "   untrusted events on purpose, so it will do nothing and look broken.\n"
    : `\n${failures} check(s) failed — the mock is NOT reviewable yet.\n`
);
process.exit(failures === 0 ? 0 : 1);
