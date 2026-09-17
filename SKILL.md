---
name: handoff
description: >
  Hand a task, plan, or review to another coding agent in a Herdr pane, then
  judge what comes back. Use when the owner asks to hand off, delegate, or
  "send this to" an agent (opus, claude, codex, cursor, or any Herdr kind), or
  invokes /handoff or $handoff. You hold the senior seat.
---

# Handoff

You plan and judge the result. The other agent does the work: building, or
reviewing something you hand it. Herdr runs the pane; read `herdr --skill` for
its mechanics and restate none of them here. Requires `HERDR_ENV=1`. One
builder per repo at a time, and do not edit alongside it.

## 0. Not a subagent

A subagent, the background helper your own client spawns, and a handoff are
different tools:

- A subagent is invisible and ephemeral, answers only to you, and spends your
  context. Right for mechanical work you can verify yourself afterwards: a
  sweep, a search, a batch of repetitive commands.
- A handoff is a visible pane the owner can watch, interrupt, and answer
  dialogs for. It persists and takes follow-ups, and it spends its own CLI's
  budget, not yours. Right for work that needs judgment, work the owner will
  want to see, and anything long enough that they may want to steer it.

When the owner's wording is ambiguous, say in one line which you are using
before the work starts, so they can redirect.

## 1. Before launching

Settle from the owner's request: the repo, the task (a plan file, a step of
one, an inline task, or a follow-up such as "go"), the builder, any model or
effort override, and the loop, meaning the command the builder can run to
check its own work. When no loop covers this change, that is the owner's call
and not yours: ask before launching whether building one is part of the task,
whether you check it yourself, or whether it ships unverified. Run
`git -C "$REPO" status` and note the branch and existing changes, so they are
not blamed on the builder. If it is not a repo, say so and carry on.

## 2. The brief

Self-contained; the builder has none of your conversation. Anything you would
otherwise have to correct afterwards belongs here.

Every brief:

- Your role: implementer for this task. For a review handoff, reviewer
  instead: read and report findings, change nothing; every finding names the
  concrete failure it causes, and pedantry, premature optimization, and
  over-engineering are not findings.
- What to read first, by path: the repo's instruction files, the owner's
  (`~/.agents/AGENTS.md`) when the work sits outside a repo, then the plan or
  the files named.
- The task. Expand "the two bugs above" into the bugs.
- The stopping point: what to finish alone and what comes back to you.
  Default: stop with the work uncommitted and report what changed, what was
  verified with its numbers, and what is unfinished.

A build brief also:

- Values by reference: the repo's own rules govern style, branches, and what
  done means. Restate only what the task turns on.
- Simplicity: the simplest complete change. No dependency, abstraction,
  setting, or flag the task does not need. Untangle what the task already
  touches when the chance is genuine, and nothing else.
- The check that proves it, named. Verify the behaviour a user would see, not
  that the code exists; say plainly what you could not verify.
- When the plan is non-trivial, ask for a verdict on the plan first, then
  implementation or a stop.

## 3. Launch

Reuse the builder you started for this handoff: `herdr agent prompt` alone.
Another session's idle agent in the same directory is not your builder. Start
a fresh one only when you have none:

```sh
herdr pane split --current --direction right --cwd "$REPO" --no-focus   # .result.pane.pane_id
herdr agent start NAME --kind KIND --pane PANE_ID -- ARGS
herdr agent prompt NAME "BRIEF" --wait --timeout 1800000
```

| Builder | Kind | Args |
| --- | --- | --- |
| `opus` | claude | `--model opus --effort xhigh` |
| `claude` | claude | configured defaults, which are not `opus` |
| `codex` | codex | configured defaults; override with `-m MODEL -c model_reasoning_effort=LEVEL` |
| `cursor` | cursor | configured default; override with `--model MODEL` |

Any other Herdr kind works with its own arguments. A follow-up like "go" goes
to your builder; without one, there is nothing to continue. Run the long wait,
and any approval Herdr's socket needs, your own harness's way.

## 4. Wait

Settled means the builder answered this brief, not that its state changed: a
fresh agent can open with a trust or approval dialog that swallows the brief
while Herdr still reports `idle`. Read the report with `herdr agent read
NAME`; if the pane holds a dialog or an untouched prompt, tell the owner the
pane and the question, and stop. Dialogs are theirs. Send the brief once after
they clear it: "never re-send" guards a turn that ran, not a prompt that never
landed. On anything else, or a timeout, inspect with `herdr agent get NAME`
and `herdr agent read NAME --source visible`, then `herdr agent wait NAME`. If
the report is cut off, ask the builder to write it to a file and read that.

## 5. Judge the result

The builder's "done" is evidence, not the result. Run the named check
yourself. Read the diff against the brief at the depth the change deserves.
Tell the owner: holds up, worth changing, unverified. Send fixes back to the
same builder. When it came back wrong in a way the named check would not have
caught, the fix is the check, not only the code.

Findings from a review handoff are input, not authority: check each against
the code. Reject pedantry, premature optimization, and over-engineering; a
finding must name a concrete failure this code can produce.

## 6. Ship

Unless the owner already authorized shipping in the brief, nothing is
committed, pushed, or opened as a pull request until the owner says go. Then
relay it to the builder, by the repo's own commit rules.
