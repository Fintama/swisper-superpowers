---
name: finishing-a-development-branch
description: Use when implementation is complete, all tests pass, and you need to decide how to integrate the work - guides completion of development work by presenting structured options for merge, PR, or cleanup
---

# Finishing a Development Branch

Verify → update docs (repos with an architecture site) → detect the environment →
present the options → carry out the choice → clean up.

**Announce at start:** "I'm using the finishing-a-development-branch skill to complete this work."

## Step 1: Verify

Before offering any option, verify the branch head with
`swisper-superpowers:verification-before-completion`: fresh evidence for this commit,
from the scoped tests for the change or from CI's run on this SHA. The full suite is CI's
job.

If anything fails, show the failures and stop: no merge or PR is offered until it passes.

## Step 1b: Update the Documentation (repos with an architecture site)

```bash
[ -f architecture/tools/impact.py ] && echo "architecture site: run update-documentation"
```

If it prints, run `swisper-superpowers:update-documentation` now, before presenting
options. Its proof (`make architecture-check` green) is a precondition like the tests.
Carry its **Documentation** section into the PR body. If it prints nothing, continue.

## Step 2: Detect the environment

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
```

| State | Menu | Cleanup |
|-------|------|---------|
| `GIT_DIR == GIT_COMMON` (normal repo) | 4 options | no worktree to clean up |
| `GIT_DIR != GIT_COMMON`, named branch | 4 options | by provenance (Step 6) |
| `GIT_DIR != GIT_COMMON`, detached HEAD | 3 options, no local merge | none (externally managed) |

## Step 3: Determine the base branch

```bash
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

Or ask: "This branch split from main - is that correct?"

## Step 4: Present the options

Normal repo and named-branch worktree, exactly these four:

```
Implementation complete. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work

Which option?
```

Detached HEAD, exactly these three:

```
Implementation complete. You're on a detached HEAD (externally managed workspace).

1. Push as new branch and create a Pull Request
2. Keep as-is (I'll handle it later)
3. Discard this work

Which option?
```

Keep the options as they are, without added explanation.

## Step 5: Carry out the choice

### Option 1: Merge locally

A merge into `main` needs the human's explicit OK for this merge, asked separately
after the options: name the branch and what the merge triggers (a deploy, a package
publish with its version). Choosing option 1 from the list is not that OK, and an
earlier or general OK is not either.

```bash
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"
git checkout <base-branch>
git pull
git merge <feature-branch>
```

Verify the merged result (Step 1's rule, on the merge commit). Only after the merge
succeeds: clean up the worktree (Step 6), then delete the branch. The worktree goes
first, because `git branch -d` refuses a branch a worktree still has checked out.

```bash
git branch -d <feature-branch>
```

### Option 2: Push and create a PR

If a draft PR already exists from the first push (`requesting-code-review`), push and
mark it ready with `gh pr ready` instead of creating a second one.

```bash
git push -u origin <feature-branch>

gh pr create --title "<title>" --body "$(cat <<'EOF'
## Summary
<2-3 bullets of what changed>

## Test Plan
- [ ] <verification steps>

## Documentation
<from update-documentation, Step 1b; omit only when the repo has no architecture site>
EOF
)"
```

Keep the worktree: the PR feedback is worked there.

### Option 3: Keep as-is

Report: "Keeping branch <name>. Worktree preserved at <path>." Keep the worktree.

### Option 4: Discard

Confirm first:

```
This will permanently delete:
- Branch <name>
- All commits: <commit-list>
- Worktree at <path>

Type 'discard' to confirm.
```

Wait for exactly `discard`. Then:

```bash
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"
```

Clean up the worktree (Step 6), then force-delete the branch:

```bash
git branch -D <feature-branch>
```

Never force-push unless the human asked for it.

## Step 6: Clean up the workspace

Runs only for options 1 and 4; options 2 and 3 keep the worktree.

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
WORKTREE_PATH=$(git rev-parse --show-toplevel)
```

- `GIT_DIR == GIT_COMMON`: a normal repo, nothing to clean up.
- The worktree is under `.worktrees/`, `worktrees/` or `~/.config/superpowers/worktrees/`:
  we created it, so we remove it, from the main root (removal fails from inside it):

  ```bash
  MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
  cd "$MAIN_ROOT"
  git worktree remove "$WORKTREE_PATH"
  git worktree prune
  ```

  **Never remove a dirty worktree**, and never pass `--force` to get past one: its
  uncommitted changes exist nowhere else. If `git status` shows changes, list them,
  leave the worktree, and say so. That holds for option 4 too: the human removes it.
- Anywhere else, the harness owns the workspace: don't remove it. Use the platform's
  workspace-exit tool if it has one; otherwise leave it in place.

## Quick reference

| Option | Merge | Push | Keep worktree | Delete branch |
|--------|-------|------|---------------|---------------|
| 1. Merge locally | yes | - | - | yes |
| 2. Create PR | - | yes | yes | - |
| 3. Keep as-is | - | - | yes | - |
| 4. Discard | - | - | - | yes (force) |
