#!/usr/bin/env bash
# Stand up a mock workspace with the review loop already wired.
#
#   ./init-workspace.sh <workspace-dir> <app-dir>
#
#   <workspace-dir>  where the mock goes, e.g. design/mocks/checkout
#   <app-dir>        the app whose design system and node_modules it borrows,
#                    e.g. frontendV2  (must contain node_modules/ and src/)
#
# node_modules is symlinked, never installed: the mock must compose against the
# version the app ships, and an install can rewrite a node_modules other worktrees share.
set -euo pipefail

WS="${1:?usage: init-workspace.sh <workspace-dir> <app-dir>}"
APP="${2:?usage: init-workspace.sh <workspace-dir> <app-dir>}"
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

APP_ABS="$(cd "$APP" && pwd)"

# A worktree without the feature fails later as an unresolved import; fail here instead.
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
  // sourceStamp must run before React's JSX transform; without both plugins nothing is selectable.
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
  "//": "src/ only: review-loop/ is Node tooling that would need @types/node, which the borrowed node_modules may lack.",
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
// The browser half of the review loop: without it nothing is selectable.
import "../review-loop/select-client";

createRoot(document.getElementById("root")!).render(<StrictMode><App /></StrictMode>);
EOF

cat > src/mock.css <<EOF
/* Import the app's own theme entry; never copy token values here.
   Edit the second import to point at your app's real theme/token entry. */
@import "tailwindcss";
@import "$REL_APP/src/styles/global.css";
EOF

cat > src/App.tsx <<'EOF'
// Replace with the index page: the design decisions, and a link to every screen and variant.
export default function App() {
  return (
    <div className="p-10">
      <h1 className="text-2xl font-semibold">Mock index</h1>
      <p className="mt-2 text-sm opacity-70" data-testid="scaffold-placeholder">
        Scaffolded with the review loop wired. Option-click me — the readout should
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
    3. node $SKILL_DIR/verify-review-loop.mjs <url> $WS_ABS     ← must pass before you build screens

BANNER
