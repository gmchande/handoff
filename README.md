# handoff

You plan and review with one coding agent. Another agent does the work in a
tab of its own, where you can watch it. `handoff` is the Agent Skill that
carries the task across: it writes the brief, launches the builder in a
[Herdr](https://herdr.dev) tab, waits properly, and judges what comes back.

It is one file of about 130 lines, a short launch reference, and brief templates. Herdr
already knows how to split a pane, start a known agent, submit a prompt, and
say when that agent has settled, so the skill carries none of the run
directories, lifecycle hooks, completion markers, or per-terminal launch code
that delegation skills needed before. What it carries instead is the part
that actually decides whether the work comes back right: what goes in the
brief, and what you check afterwards.

Any Agent Skills client can sit in either seat. Claude Code can hand a task to
Codex; Codex can hand one to Cursor; any of them can hand a review to another.

## Install

```sh
git clone https://github.com/gmchande/handoff ~/.claude/skills/handoff
```

That is the Claude Code path. For another client, clone into its skills
directory instead (`~/.codex/skills`, `~/.cursor/skills`), or clone once and
symlink into each. Then invoke it with `/handoff`, `$handoff`, or just tell
your agent to hand the work to another one.

## Requirements

- [Herdr](https://herdr.dev), and a session running inside it (`HERDR_ENV=1`).
- The builder's own CLI, installed and authenticated: Claude Code, Codex,
  Cursor, or any other kind Herdr knows.
- `jq`, for `send-brief`, which sends a brief from its file and makes sure the
  agent starts on it. `test-send-brief.sh` proves it against stand-ins for Herdr.

## Use

```
/handoff opus docs/phase-4-implementation-plan.md
/handoff codex "Step 2 of the plan; verify it before building"
/handoff cursor "review the diff on this branch"
/handoff opus go
```

The first word names the builder, the rest is the task: a plan file, a step of
one, an inline task, a review, or a follow-up to the builder already working
for you.

## What it insists on

- **The brief is self-contained.** The builder has none of your conversation,
  so a build brief gives the problem in the user's words, the outcome, what
  must stay true, and where to stop; a template holds how the builder works.
- **A review handoff is a different job.** The reviewer changes nothing, and
  every finding must name the concrete failure it causes. Pedantry, premature
  optimization, and over-engineering are not findings.
- **A turn's end is a report, not proof it's done.** The skill tells you to
  read what the builder says, send it back with what's still open, and hand
  dialogs to you rather than answer them.
- **The builder gives irrefutable proof it works end to end.** It runs the
  parts of the check its change touches and tries the change the way a user
  would, then hands back what it ran and saw as real output and screenshots.
  When no check covers the change, building one is part of the task.
- **A change gets the eyes its size calls for.** A small change the builder
  reviews and checks itself. A bigger or risky one gets a reviewer from
  another model in another harness, which stays until the work merges.
- **The builder's "done" is evidence, not the result.** You read its runs,
  see that the full check runs once on what merges, and read the diff against
  the brief before anything ships.
- **Nothing ships unasked.** No commit, push, or pull request until you or
  your rules say so.

## License

MIT
