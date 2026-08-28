/**
 * The review loop — two Vite plugins. Copy into the mock workspace's vite.config.
 *
 *   export default defineConfig({
 *     plugins: [sourceStamp(), react(), selectSink()],
 *   });
 *
 * `sourceStamp` MUST come before the React plugin (enforce: "pre" handles it).
 *
 * WHAT THIS BUYS: the reviewer clicks a component in their own browser; the
 * session reads `current-selection.json` with plain file access and gets an
 * exact `file:line`. No browser automation, no instrumented imports, no rule
 * for anyone to remember. Proven end to end 2026-08-28 with a human clicking.
 *
 * ⚠ DEV ONLY. Neither plugin should run in a production build — `sourceStamp`
 * adds attributes to markup and `selectSink` writes to disk.
 */
import { writeFileSync } from "node:fs";
import { join, relative } from "node:path";
import type { Plugin } from "vite";

/**
 * Stamp `data-source="<relpath>:<line>"` onto every JSX opening tag in the
 * screens directory, so a click resolves to the exact line that rendered it.
 *
 * 🔴 LINE-BASED, NOT AN AST PASS. It is deliberately simple and it is the
 * weakest part of this loop. It handles ordinary screen JSX; it will misfire on
 * a line containing a `<` that is not a tag (a generic, a comparison). If you
 * hit that, upgrade to a Babel plugin over JSXOpeningElement rather than
 * layering more regex — the fix is a parser, not a better pattern.
 *
 * ⚠ THE STAMP ONLY REACHES THE DOM IF THE ELEMENT PASSES UNKNOWN PROPS THROUGH.
 * Raw DOM elements always do. A component that spreads (`{...rest}`) onto its
 * root does. A component that destructures only what it wants SWALLOWS the
 * stamp — its instances then resolve to the nearest stamped ancestor instead.
 * That is a real, measured limitation and it is not fixable here; wrap those
 * few components explicitly if you need them selectable.
 */
export function sourceStamp(screensDir = "/src/screens/"): Plugin {
  return {
    name: "source-stamp",
    enforce: "pre",
    apply: "serve",
    transform(code, id) {
      if (!id.includes(screensDir) || !/\.[jt]sx$/.test(id)) return null;
      const rel = relative(process.cwd(), id.split("?")[0]);
      const out = code.split("\n").map((line, i) => {
        if (line.includes("data-source")) return line;
        return line.replace(
          /<([a-zA-Z][a-zA-Z0-9.]*)(?=[\s/>])/g,
          (_m, tag) => `<${tag} data-source="${rel}:${i + 1}"`,
        );
      });
      return { code: out.join("\n"), map: null };
    },
  };
}

/**
 * Receive the reviewer's current selection and any note they leave.
 *
 * 🔴 CURRENT STATE, NOT AN EVENT LOG. `current-selection.json` is OVERWRITTEN
 * on every selection. This is the design, not a shortcut: with a log, "make
 * this dashed" has to guess which of forty clicks you meant. With one value
 * there is exactly one answer, and no de-duplication problem.
 *
 * Notes DO append — a note is a considered statement worth keeping, unlike a
 * click.
 */
export function selectSink(outDir = process.cwd()): Plugin {
  return {
    name: "select-sink",
    apply: "serve",
    configureServer(server) {
      const read = (req: any) =>
        new Promise<string>((res) => {
          let b = "";
          req.on("data", (c: any) => (b += c));
          req.on("end", () => res(b));
        });

      server.middlewares.use("/__select", async (req, res) => {
        if (req.method !== "POST") { res.statusCode = 405; return res.end(); }
        writeFileSync(join(outDir, "current-selection.json"), await read(req));
        res.statusCode = 204; res.end();
      });

      server.middlewares.use("/__note", async (req, res) => {
        if (req.method !== "POST") { res.statusCode = 405; return res.end(); }
        const body = await read(req);
        writeFileSync(join(outDir, "review-notes.jsonl"), body.trim() + "\n", { flag: "a" });
        res.statusCode = 204; res.end();
      });
    },
  };
}
