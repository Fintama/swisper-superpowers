#!/usr/bin/env bash
#
# Stand up a mock workspace with the review loop ALREADY WIRED.
#
#   ./init-workspace.sh <workspace-dir> <app-dir>
#
#   <workspace-dir>  where the mock goes, e.g. design/mocks/checkout
#   <app-dir>        the app whose design system and node_modules it borrows,
#                    e.g. frontendV2  (must contain node_modules/)
#
# ── WHY THIS SCRIPT EXISTS ──────────────────────────────────────────────────
#
# Measured 2026-08-29 (see BASELINE-2026-08-29.md): an agent that hand-wrote the
# workspace shipped a mock with NO REVIEW LOOP — no `sourceStamp`, no
# `selectSink`, no client import — so the human could not click a single element.
# It also picked the wrong worktree, and rediscovered the node_modules and
# tsconfig answers from scratch.
#
# 🔴 THE FIX IS NOT A LOUDER INSTRUCTION. It is having nothing to remember: the
# config this script writes has the plugins in it, in the right order, and the
# entry file imports the client. An agent cannot forget a step it never performs.
#
# ── WHY node_modules IS SYMLINKED AND NEVER INSTALLED ───────────────────────
#
# The skill CANNOT ship node_modules: it is hundreds of MB, it carries
# platform- and arch-specific binaries (esbuild, rollup), and it would have to
# match the host app's React/Vite versions or the mock would compose against a
# different design system than the product. Borrowing the app's is not a
# shortcut — it is the only way the mock typechecks against the version that
# actually ships.
#
# An `npm install` here is also actively dangerous where a repo shares one
# node_modules across git worktrees by symlink: installing can rewrite the tree
# every other worktree is pointing at.
set -euo pipefail

WS="${1:?usage: init-workspace.sh <workspace-dir> <app-dir>}"
APP="${2:?usage: init-workspace.sh <workspace-dir> <app-dir>}"
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

APP_ABS="$(cd "$APP" && pwd)"

# 🔴 THE WORKTREE CHECK, FIRST AND FATAL. The measured failure was a workspace
# built against a worktree that did not contain the feature — every import
# resolved to nothing and it surfaced as a Vite error minutes later, after the
# screens were written. Fail here instead, where it costs one line.
[ -d "$APP_ABS/node_modules" ] || {
  echo "✗ $APP_ABS/node_modules does not exist." >&2
  echo "  Point <app-dir> at the worktree that actually has the app installed." >&2
  exit 1
}
[ -d "$APP_ABS/src" ] || {
  echo "✗ $APP_ABS/src does not exist — is this really the app root?" >&2
  exit 1
}

mkdir -p "$WS/src"
cd "$WS"
WS_ABS="$(pwd)"
REL_APP="$(python3 -c 'import os,sys;print(os.path.relpath(sys.argv[1],sys.argv[2]))' "$APP_ABS" "$WS_ABS/src")"

cp "$SKILL_DIR/review-loop/vite-plugins.ts" \
   "$SKILL_DIR/review-loop/select-client.ts" \
   "$SKILL_DIR/review-loop/render-gate.mjs" . 2>/dev/null || {
     mkdir -p review-loop
     cp "$SKILL_DIR/review-loop/"* review-loop/
   }
[ -f vite-plugins.ts ] && { mkdir -p review-loop; mv vite-plugins.ts select-client.ts render-gate.mjs review-loop/; }

ln -sfn "$APP_ABS/node_modules" node_modules

cat > vite.config.ts <<'EOF'
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { sourceStamp, selectSink } from "./review-loop/vite-plugins";

export default defineConfig({
  /* 🔴 `sourceStamp()` COMES FIRST and that is not stylistic — it stamps raw
     JSX before React transforms it out of existence. `enforce: "pre"` also
     enforces it; the order is written out so nobody "tidies" it later.
     `selectSink()` serves /__select and /__note. Remove either and the reviewer
     silently loses click-to-select — the exact defect this scaffold exists to
     prevent. `verify-review-loop.mjs` fails if you do. */
  plugins: [sourceStamp(), react(), selectSink()],
});
EOF

cat > tsconfig.json <<'EOF'
{
  "compilerOptions": {
    "target": "ES2022", "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "module": "ESNext", "moduleResolution": "bundler", "jsx": "react-jsx",
    "strict": true, "noEmit": true, "skipLibCheck": true,
    "types": ["vite/client"]
  },
  "//": [
    "`include` is src/ ONLY, deliberately.",
    "`review-loop/` is vendored tooling, not part of the specification this mock",
    "carries. It is Node code (node:fs, node:path, process, IncomingMessage) and",
    "typechecking it needs @types/node, which the borrowed node_modules may not",
    "have — and installing it could rewrite a node_modules other worktrees share.",
    "Nothing is lost: Vite transpiles config and plugins with esbuild, which does",
    "not typecheck. What MUST typecheck is src/ — the mock IS the implementation",
    "spec, and a spec promising a prop the design system rejects is the failure",
    "this gate exists to catch."
  ],
  "include": ["src"]
}
EOF

cat > index.html <<'EOF'
<!doctype html>
<html lang="en">
  <head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Mock</title></head>
  <body><div id="root"></div><script type="module" src="/src/main.tsx"></script></body>
</html>
EOF

cat > src/main.tsx <<'EOF'
import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import App from "./App";
import "./mock.css";
/* 🔴 THE BROWSER HALF OF THE REVIEW LOOP. Without this import nothing is
   selectable and the reviewer cannot point at anything — the mock still LOOKS
   finished, which is why its absence went unnoticed in the measured failure.
   Dev only: `selectSink` writes current-selection.json beside this workspace. */
import "../review-loop/select-client";

createRoot(document.getElementById("root")!).render(<StrictMode><App /></StrictMode>);
EOF

cat > src/mock.css <<EOF
/* Tailwind, plus the APP'S OWN token/theme entry, imported from the app source
   so the mock cannot drift from what the product actually paints with. Copying
   token values in here would create a second source of truth, and the mock
   would keep passing while the product changed underneath it.

   👉 EDIT THE SECOND IMPORT to your app's real theme/token entry. */
@import "tailwindcss";
@import "$REL_APP/src/styles/global.css";
EOF

cat > src/App.tsx <<'EOF'
/* Replace with the index page: the design decisions in one line each, and a
   link to every screen and variant. Build the index FIRST — a reviewer who has
   to retype URLs stops exploring, and you lose the feedback the mock exists to
   collect. */
export default function App() {
  return (
    <div className="p-10">
      <h1 className="text-2xl font-semibold">Mock index</h1>
      <p className="mt-2 text-sm opacity-70" data-testid="scaffold-placeholder">
        Scaffolded with the review loop wired. Click me — the readout should
        appear top-right. If it does not, run <code>verify-review-loop.mjs</code>.
      </p>
    </div>
  );
}
EOF

cat > .gitignore <<'EOF'
node_modules
dist
.vite
current-selection.json
review-notes.jsonl
EOF

cat >&2 <<BANNER

✓ workspace ready: $WS_ABS
    review loop     WIRED (sourceStamp + selectSink + select-client)
    node_modules    symlinked → $APP_ABS/node_modules  (nothing installed)
    tsconfig        src/ only — see the "//" note inside for why

  Next:
    1. point src/mock.css at your app's real theme entry (it guesses global.css)
    2. npx vite --port \$(node -e 'const s=require("net").createServer();s.listen(0,()=>{console.log(s.address().port);s.close()})') --strictPort
    3. node review-loop/../verify-review-loop.mjs <url>     ← MUST pass before you build screens

BANNER
