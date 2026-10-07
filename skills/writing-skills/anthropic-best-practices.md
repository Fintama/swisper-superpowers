# Anthropic's skill authoring guide

The full guide: [Skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices).
Read it when you write your first skill or a skill with scripts. The points this repo relies on:

1. **Only what Claude doesn't already know.** A loaded SKILL.md competes with everything else
   in context, so cut what a capable model would do anyway. No time-sensitive text ("before
   August, use the old API"); state the current method.
2. **The description chooses the skill.** Third person, specific triggers and key terms, at most
   1024 characters. The guide also has it say what the skill does; here that is a few words at
   most and never the workflow (SKILL.md, "Frontmatter and description").
3. **Progressive disclosure.** SKILL.md is the overview; supporting files are linked one level
   deep from it; a reference file over 100 lines starts with a table of contents.
4. **Match freedom to fragility.** Give exact commands or a script for a fragile operation and
   heuristics where several approaches are valid. Offer one default with an escape hatch, not a
   menu of options.
5. **Scripts solve, they don't punt.** Handle errors in the script, state its dependencies,
   make validation messages specific enough to act on, and use forward slashes in paths.
