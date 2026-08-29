#!/usr/bin/env node
/**
 * Is the review loop actually working? Two measurements, no browser.
 *
 *   node verify-review-loop.mjs http://localhost:5173
 *
 * Exits 0 only if the reviewer can genuinely point at things.
 *
 * ── WHY THIS EXISTS ─────────────────────────────────────────────────────────
 *
 * Measured 2026-08-29 (BASELINE-2026-08-29.md): an agent shipped a mock with no
 * review loop and PASSED every item in the skill's verification phase — it
 * typechecked, it positive-controlled the typecheck, it used only real design
 * system components, and it rendered correctly in a browser screenshot. The
 * human then could not click a single element.
 *
 * 🔴 A VERIFICATION PHASE THAT CANNOT FAIL ON THE MOST IMPORTANT OMISSION IS
 * NOT A GATE. This script is the missing assertion.
 *
 * ── 🔴 WHY IT DOES NOT SIMULATE A CLICK, AND YOU MUST NOT EITHER ────────────
 *
 * `select-client.ts` refuses untrusted events:
 *
 *     if (!e.isTrusted) return;
 *
 * That guard is deliberate and load-bearing — a scripted click from browser
 * automation would OVERWRITE `current-selection.json` and silently destroy the
 * reviewer's selection between them clicking and you reading it. So a synthetic
 * click correctly does nothing.
 *
 * The trap this creates, and it cost the measured run real time: an agent
 * verifies by scripting a click, sees nothing happen, and concludes the loop is
 * broken — then debugs working code. It is not broken. It is protecting the
 * human from you.
 *
 * This script therefore checks the two halves it CAN check honestly:
 *   1. the stamp reaches the served source  (sourceStamp is registered)
 *   2. the sink accepts and persists a POST (selectSink is registered)
 * The human's real click is the only thing that can exercise the middle, and
 * that is by design.
 */
import { writeFileSync, existsSync, rmSync } from "node:fs";
import { join } from "node:path";

const base = (process.argv[2] || "").replace(/\/$/, "");
if (!base) {
  console.error("usage: node verify-review-loop.mjs <url>   e.g. http://localhost:5173");
  process.exit(2);
}
/* 🔴 Vite binds `localhost`, which on a dual-stack host may resolve to ::1 only.
   The measured run checked 127.0.0.1, got a connection refusal, and read the
   Vite banner printed by the `||` branch as success. Say which name you used. */
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
    /* 🔴 MATCH THE ATTRIBUTE NAME ONLY, NEVER `data-source=`.
       Measured while building this script: the module Vite serves has ALREADY
       been through React's JSX transform, so the stamp is a PROP —
       `"data-source": "src/App.tsx:7"` — and the `=` form never appears. An
       earlier draft matched `data-source=` and reported "0 stamped" against a
       perfectly wired workspace, which would have sent agents to debug working
       code. A verifier that can produce a false red is worse than none. */
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
  /* Never clobber a real selection — that is the very thing isTrusted protects. */
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
      "🔴 Do NOT try to confirm with a scripted click: select-client ignores\n" +
      "   untrusted events on purpose, so it will do nothing and look broken.\n"
    : `\n${failures} check(s) failed — the mock is NOT reviewable yet.\n`
);
process.exit(failures === 0 ? 0 : 1);
