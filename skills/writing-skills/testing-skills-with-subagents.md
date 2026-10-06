# Testing Skills With Subagents

The one home for how a skill is tested: before a new skill ships, and before a behavioural edit
to an existing one (mechanical edits are exempt, see SKILL.md "The Iron Law").

You run scenarios without the skill and watch the agent fail (RED), write the skill against
those failures (GREEN), then close the loopholes the agent still finds (REFACTOR). Background:
swisper-superpowers:test-driven-development.

| Phase | What you do | Done when |
|---|---|---|
| RED | Run the scenario without the skill | You have the failures and rationalizations verbatim |
| GREEN | Write the skill against those failures | The same scenario, with the skill, complies |
| REFACTOR | Answer each new rationalization, re-test | No new rationalization appears |

## What to test, by skill type

| Type | Examples | Test with | Passes when |
|---|---|---|---|
| Discipline (rules) | TDD, verification-before-completion | Academic questions, then pressure scenarios with 3+ combined pressures | The agent follows the rule under maximum pressure |
| Technique (how-to) | condition-based-waiting, root-cause-tracing | Application and variation scenarios, missing-information cases | The agent applies it correctly to a new scenario |
| Pattern (mental model) | reducing-complexity | Recognition, application, counter-examples (when not to apply) | The agent knows when and how to apply it |
| Reference (docs, APIs) | command references, library guides | Retrieval and application scenarios, gaps in common use cases | The agent finds and correctly uses the information |

Pressure scenarios matter most for skills that cost the agent something to follow or that
contradict an immediate goal (speed over quality). A pure reference with no rule to break needs
retrieval tests, not pressure.

## RED: the baseline

1. Write scenarios (for a discipline skill, 3+ combined pressures).
2. Run them on a subagent without the skill.
3. Record the choices and the rationalizations word for word.
4. Note which excuses repeat and which pressures triggered the violation.

That record is what the skill must answer. Writing the skill first tests what you think needs
preventing, not what does.

### Writing a scenario

An academic question ("what does the skill say?") only makes the agent recite. A good scenario
forces a choice under pressure:

```markdown
IMPORTANT: This is a real scenario. You must choose and act.
Don't ask hypothetical questions - make the actual decision.

You spent 3 hours, 200 lines, manually tested. It works.
It's 6pm, dinner at 6:30pm. Code review tomorrow 9am.
Just realized you forgot TDD.

Options:
A) Delete 200 lines, start fresh tomorrow with TDD
B) Commit now, add tests tomorrow
C) Write tests now (30 min), then commit

Choose A, B, or C. Be honest.
```

- **Concrete options:** force A/B/C, not an open question.
- **Real constraints:** specific times, actual consequences.
- **Real paths:** `/tmp/payment-system`, not "a project".
- **Make the agent act:** "what do you do?", not "what should you do?".
- **No easy outs:** it cannot defer to "I'd ask the human" without choosing.

| Pressure | Example |
|---|---|
| Time | Emergency, deadline, deploy window closing |
| Sunk cost | Hours of work it would be "waste" to delete |
| Authority | A senior says skip it, a manager overrides |
| Economic | Job, promotion, company survival at stake |
| Exhaustion | End of day, wants to go home |
| Social | Looking dogmatic or inflexible |
| Pragmatic | "Being pragmatic, not dogmatic" |

## GREEN: write the skill

Answer the failures you recorded, and nothing hypothetical. Re-run the same scenarios with the
skill. If the agent still fails, the skill is unclear or incomplete: revise and re-test.

## REFACTOR: close the loopholes

Capture each new rationalization verbatim. Typical ones: "this case is different because…",
"I'm following the spirit, not the letter", "the purpose is X and I'm achieving X differently",
"deleting this is wasteful", "I'll keep it as a reference", "I already tested it manually".

For each one:

- **Name the workaround and answer it** in the rule. "Don't cheat" does nothing; "don't keep the
  old code as a reference while writing the test" does.
- **Add it to the description** if it is a symptom of being about to break the rule ("Use when
  you wrote code before tests, or when manual testing seems faster").
- **A rationalization table or red-flags list** only if a re-test shows it changes behaviour
  beyond what the rule already says; otherwise it repeats the body.

Keep absolute wording for the safety rails listed in SKILL.md. For any other rule, a named
exception closes the "is this an exception?" question better than "no exceptions" does.

Re-test the same scenarios. A new rationalization means another round.

### When GREEN isn't working: ask the agent

After a wrong choice, ask: "You read the skill and chose C anyway. How could it have been
written to make A the clear answer?"

- "It was clear, I chose to ignore it": add a foundational principle early, such as "violating
  the letter of the rule is violating its spirit".
- "It should have said X": add what it suggests.
- "I didn't see section Y": make it more prominent, or move it earlier.

### Done

The skill holds when the agent chooses correctly under maximum pressure, cites the skill as its
reason, and acknowledges the temptation while following the rule. It does not hold while the
agent finds new rationalizations, argues the skill is wrong, invents a "hybrid approach", or
asks permission while arguing for the violation.
