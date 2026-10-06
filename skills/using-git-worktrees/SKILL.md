---
name: using-git-worktrees
description: Use when starting feature work that needs isolation from current workspace or before executing implementation plans - ensures an isolated workspace exists via native tools or git worktree fallback
---

# Using Git Worktrees

Make sure work happens in an isolated workspace. Detect existing isolation first, then
use the platform's native worktree tool, and fall back to `git worktree` only when there
is none.

**Announce at start:** "I'm using the using-git-worktrees skill to set up an isolated workspace."

## First: the instruction file

Read the project's instruction file (`CLAUDE.md`, `AGENTS.md`) and your own instructions
first. A worktree preference, a worktree directory or a setup command declared there wins
over everything below.

## Step 0: Detect existing isolation

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
git rev-parse --show-superproject-working-tree 2>/dev/null
```

`GIT_DIR != GIT_COMMON` is also true inside a submodule. If the last command prints a
path, you are in a submodule: treat it as a normal checkout.

**Already in a linked worktree** (`GIT_DIR != GIT_COMMON`, not a submodule): create
nothing; go to Step 2. Report:
- on a branch: "Already in isolated workspace at `<path>` on branch `<name>`."
- detached HEAD: "Already in isolated workspace at `<path>` (detached HEAD, externally
  managed). Branch creation needed at finish time."

**In a normal checkout:** if the instructions declare a worktree preference, follow it
without asking. A dispatch to execute a plan (`subagent-driven-development`,
`executing-plans`) counts as consent to create one. Otherwise ask:

> "Would you like me to set up an isolated worktree? It protects your current branch from changes."

If the human declines, work in place and go to Step 2.

## Step 1: Create the workspace

### 1a. Native worktree tool (preferred)

If you have a native way to create a worktree (a tool such as `EnterWorktree` or
`WorktreeCreate`, a `/worktree` command, a `--worktree` flag), use it and go to Step 2.
It handles placement, branch and cleanup; a `git worktree add` beside it creates state the
harness can't see or manage.

### 1b. Git fallback (no native tool)

**Directory, first match wins:**

1. the directory the instruction file or your instructions declare;
2. an existing project-local `.worktrees/` or `worktrees/` (both exist: `.worktrees/`);
3. an existing `~/.config/superpowers/worktrees/<project>/` (legacy global location);
4. otherwise `.worktrees/` at the project root.

**A project-local directory must be git-ignored** before you create the worktree, or its
contents end up tracked:

```bash
git check-ignore -q .worktrees 2>/dev/null || git check-ignore -q worktrees 2>/dev/null
```

If it isn't ignored, add it to `.gitignore` and commit that first. The global directory
needs no check.

```bash
git worktree add "$path" -b "$BRANCH_NAME"
cd "$path"
```

If `git worktree add` fails with a permission error (a sandbox denial), tell the human
the sandbox blocked it and work in the current directory instead.

## Step 2: Project setup

Use the instruction file's setup command if it has one. Otherwise detect:

```bash
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)

# Node: pnpm links from its shared store; otherwise borrow the main checkout's node_modules
if [ -f pnpm-lock.yaml ]; then pnpm install --frozen-lockfile
elif [ -f package.json ] && [ -d "$MAIN_ROOT/node_modules" ]; then ln -s "$MAIN_ROOT/node_modules" node_modules
fi

if [ -f Cargo.toml ]; then cargo build; fi
if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
if [ -f pyproject.toml ]; then poetry install; fi
if [ -f go.mod ]; then go mod download; fi
```

Don't run `npm install` in a worktree: it can rewrite a `node_modules` other worktrees
share. Link to the main checkout's `node_modules`, never to another worktree's, because
removing that worktree deletes it and breaks the link.

## Step 3: Clean baseline

Run the scoped baseline: the tests of the area you will change and the project's core
smoke set (the test tiers in `swisper-superpowers:test-driven-development`). The full
suite is CI's job. Tests that need a database or server bring up their own through the
test command; never point them at a standing integration rig, which runs another
branch's code.

If the baseline fails, report the failures and ask whether to proceed or investigate:
otherwise new bugs can't be told from old ones. If it passes, report:

```
Worktree ready at <full-path>
Baseline: <command>, <N> tests, 0 failures
Ready to implement <feature-name>
```

## Quick reference

| Situation | Action |
|-----------|--------|
| Instruction file declares a preference or directory | Use it |
| Already in a linked worktree | Create nothing (Step 0) |
| In a submodule | Treat as a normal checkout |
| Normal checkout, dispatched to execute a plan | Consent given; create |
| Native worktree tool available | Use it (1a) |
| No native tool | `git worktree add` (1b), directory order as listed |
| Project-local directory not ignored | Add to `.gitignore`, commit, then create |
| Permission error on create | Work in place, tell the human |
| Baseline fails | Report and ask |
