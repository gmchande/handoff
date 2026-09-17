# handoff

You plan and review with one coding agent. Another agent does the work, in a
pane beside you, where you can watch it. `handoff` is the Agent Skill that
carries the task across: it writes the brief, launches the builder in a
[Herdr](https://herdr.dev) pane, waits properly, and judges what comes back.

It is one file of about a hundred lines. Herdr already knows how to split a
pane, start a known agent, submit a prompt, and say when that agent has
settled, so the skill carries none of the run directories, lifecycle hooks,
completion markers, or per-terminal launch code that delegation skills needed
before. What it carries instead is the part that actually decides whether the
work comes back right: what goes in the brief, and what you check afterwards.

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
  so anything you would otherwise have to correct afterwards belongs in the
  brief: the role, what to read, the task, the standard, and where to stop.
- **A review handoff is a different job.** The reviewer changes nothing, and
  every finding must name the concrete failure it causes. Pedantry, premature
  optimization, and over-engineering are not findings.
- **Settled is not the same as done.** A fresh agent can open with a trust
  dialog that swallows the brief while the runtime still reports it idle. The
  skill tells you to read the report, not the state, and hands dialogs back to
  you rather than answering them.
- **The builder's "done" is evidence, not the result.** You run the check
  yourself and read the diff against the brief before anything ships.
- **Nothing ships unasked.** No commit, push, or pull request until you say so.

## License

MIT
