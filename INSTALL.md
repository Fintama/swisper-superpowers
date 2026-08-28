# Installing swisper-superpowers

**One path: install it as a plugin.** The old arrangement — a symlink at
`~/.claude/skills` plus a `skillOverrides` block — is **superseded and should not
be used**. It required upstream `superpowers` to stay installed and hidden behind
overrides, which produced two copies of every skill and a way to load the wrong
one. See *Migrating off the symlink* below if you still have it.

---

## Install

This repository is public — no credentials, no org membership, nothing to set up
first.

```bash
claude plugin marketplace add Fintama/swisper-superpowers
claude plugin install swisper-superpowers@swisper-superpowers
```

Then **restart your session.** A session builds its skill table at startup, so a
running one keeps resolving from wherever it started — this is the single most
common "I installed it and nothing changed".

### Verify it took

Invoke any skill and read the `Base directory:` line it prints. It must be:

```
~/.claude/plugins/cache/swisper-superpowers/swisper-superpowers/<version>/skills/<name>
```

⚠ **A `Base directory:` under `~/.claude/skills` or under
`claude-plugins-official` means something else is being loaded** — the old
symlink survived, or upstream `superpowers` is still installed. Fix that before
trusting anything.

### Skill names are namespaced

Plugin skills always carry their plugin's name: `swisper-superpowers:brainstorming`,
not `brainstorming`. That is structural, not a quirk — it is what stops a plugin
skill colliding with a personal or project one.

### Updating

```bash
claude plugin marketplace update swisper-superpowers
claude plugin update swisper-superpowers@swisper-superpowers
```

⚠ **An update against an unchanged version number is a silent no-op.** It exits
cleanly and installs nothing, so the cache can sit several commits behind while
the command reports success. If you are testing a change, bump the version in
`.claude-plugin/plugin.json` or you will be measuring the old copy.

Check what you actually have:

```bash
ls ~/.claude/plugins/cache/swisper-superpowers/swisper-superpowers/
```

---

## Uninstall upstream `superpowers`

**Do this.** This fork is a **complete replacement**, not an addition — it
carries a version of every upstream skill (see `DIVERGENCE.md`). Leaving both
installed gives you two of everything and no rule about which wins.

```bash
claude plugin uninstall superpowers@claude-plugins-official
```

If you previously merged `settings.skill-overrides.json` into your settings,
delete that `skillOverrides` block too — it names a plugin that is gone, so it
does nothing but confuse the next reader.

---

## Migrating off the symlink arrangement

If `~/.claude/skills` is a symlink into a clone of this repo:

```bash
rm ~/.claude/skills                       # the symlink only — never the clone
claude plugin marketplace add Fintama/swisper-superpowers
claude plugin install swisper-superpowers@swisper-superpowers
claude plugin uninstall superpowers@claude-plugins-official
```

Then remove the `skillOverrides` block and any
`~/.claude/plugins/cache/claude-plugins-official/superpowers/*` paths from
`permissions.additionalDirectories`. **Restart every running session** — none of
them will see the change otherwise.

---

## Developing on the skills

The installed plugin is a **cache copy**. Editing it is not editing the repo, and
your change vanishes on the next update.

```bash
git clone https://github.com/Fintama/swisper-superpowers.git
cd swisper-superpowers
git remote add upstream https://github.com/obra/superpowers.git   # for syncs
```

Edit under `skills/`, then before every commit:

```bash
bash scripts/divergence-check.sh    # exit 1 if an enhancement went missing
```

**Positive-control it once** so you know it can fail: remove a marker named in
`DIVERGENCE.md`, watch it go red naming the enhancement, restore it.

To try a change locally without publishing, point a marketplace at your clone:

```bash
claude plugin marketplace add /path/to/your/clone
```

⚠ **A marketplace pointed at a worktree or feature branch serves whatever that
branch holds.** Convenient for development, and a machine-wide single point of
failure if you forget and later reap the worktree.

---

## Taking changes from upstream

This is a **hard fork** — of the 14 skills shared with upstream, zero are
byte-identical. There is nothing to inherit automatically. Read `DIVERGENCE.md`
before any sync; the short version:

```bash
git fetch upstream
git diff v6.3.0..upstream/main -- skills/<name>/   # decide hunk by hunk
bash scripts/divergence-check.sh                   # did we lose anything?
```

**Never take an upstream skill wholesale.** A clean merge that silently deletes
one of our enhancements is the failure this fork is most exposed to, and a clean
merge is exactly what nobody re-reads.
