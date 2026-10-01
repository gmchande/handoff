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
builder per checkout (a worktree counts as one), and do not edit alongside it.

Decide what your own judgment covers and say what you decided. Bring the owner
only what you can't settle, with your recommendation.

## 0. Not a subagent

A subagent is invisible, answers only to you, and spends your context: right
for mechanical work you can check afterwards, like a sweep or a search. A
handoff is a visible pane the owner can watch, steer, and answer dialogs in;
it persists, takes follow-ups, and spends its own CLI's budget: right for work
that needs judgment or that the owner will want to see. When the owner's
wording is ambiguous, say in one line which you are using.

## 1. Before launching

Settle from the owner's request: the repo, the task (a plan file, a step of
one, an inline task, or a follow-up such as "go"), the builder, any model or
effort override, and the check, meaning the command the builder can run to
test its own work. When no check covers this change, building one is part of
the task: tell the owner in one line, and ship it unverified only if they say
so. Run `git -C "$REPO" status` and note the branch and existing changes, so
they are not blamed on the builder. If it is not a repo, say so and carry on.

## 2. The brief

Self-contained; the builder has none of your conversation. Anything you would
otherwise have to correct afterwards belongs here.

Every brief:

- Your role: implementer for this task. For a review handoff, reviewer
  instead: read and report findings, change nothing; every finding names the
  concrete failure it causes, and pedantry, premature optimization, and
  over-engineering are not findings. Roles live in briefs, never in an
  `AGENTS.md`, which every agent reads.
- What to read first, by absolute path (a builder in another worktree cannot
  see this checkout's ignored files): the repo's instruction files, the
  owner's (`~/.agents/AGENTS.md`) when the work sits outside a repo or the
  builder does not load it on its own (Cursor does not), then the plan or the
  files named.
- The task, as the outcome that must be true and the problem behind it; name
  a method only when the repo's rules require one. Expand "the two bugs
  above" into the bugs.
- The stopping point: what to finish alone and what comes back to you.
  Default: commit and open a pull request as far as the repo's own rules
  allow, and stop with the work uncommitted where they say nothing. Report
  what changed, the proof with its numbers, and what is unfinished. If the
  owner's go comes later, relay it to the builder instead of committing
  yourself.

A build brief also:

- Values by reference: the repo's own rules govern style, simplicity,
  branches, and what done means. Restate only what the task turns on.
- The check that proves it, named.
- Ask for "irrefutable proof this works end to end": the builder runs the
  check, tries the change the way a user would, and hands back what it ran
  and saw as real output and screenshots, and what it could not check. When
  that needs the owner's screen, it asks the owner in its own pane and waits
  for the go.
- Its reviewer, by name: when its check passes, the builder asks its reviewer
  to review its diff (`herdr agent prompt REVIEWER "..." --wait`) and fixes
  the findings that hold up before opening the pull request. Once it's open,
  the builder answers the pull request's review comments the same way.
- When the plan is non-trivial, ask for a verdict on the plan first, then
  implementation or a stop.

## 3. Launch

Layout: you on the left of your tab with your reviewer on the right; builders
side by side in a separate tab, each with its own reviewer split down under
it, every pane labelled. Each builder gets its own checkout and is told which
files the others will change; one whose change touches another's files builds
on that branch and rebases whenever it moves.

Reviewers: one per big task, so none is asked two things at once and each
remembers what it already reviewed. Yours reviews your plans before you brief
builders, and anything else you want a second look at, until the plan is
approved. A builder's reviewer starts with the builder and stays until its
pull request merges. Codex with the newest Astra model at high effort,
read-only. Each writes its reports to files and replies with a summary, so
closing its pane loses nothing.

Reuse the builder you started for this handoff: `herdr agent prompt` alone.
Another session's idle agent in the same directory is not your builder. Start
a fresh one only when you have none:

```sh
herdr pane split --current --direction right --cwd "$REPO" --no-focus   # your reviewer; .result.pane.pane_id
herdr tab create --cwd "$REPO" --label builders                         # builders; .result.root_pane
herdr pane split --pane BUILDER_PANE --direction down --cwd "$REPO" --no-focus   # its reviewer
herdr agent start NAME --kind KIND --pane PANE_ID -- ARGS
herdr agent prompt NAME "BRIEF" --wait --timeout 1800000
```

| Builder | Kind | Args |
| --- | --- | --- |
| `opus` | claude | `--model opus --effort high` |
| `claude` | claude | configured defaults, which are not `opus` |
| `codex` | codex | `-m MODEL -c model_reasoning_effort=high` |
| `cursor` | cursor | configured default; override with `--model MODEL` |
| `omp` | omp | `--model PROVIDER/ID --thinking high`, with the provider as `omp models` groups it: `anthropic/claude-opus-5-5`, `openai-codex/gpt-6-astra`; a bare GPT id picks the keyless `openai` provider and fails |

When the owner names no builder for a coding task, use `omp` with
`anthropic/claude-opus-5-5`. Effort is `high` unless the owner names another
level.

Model names by nickname ("sol", "astra", "opus", "fable"): resolve to the
newest id that carries it, and pass that id. Codex's list is
`~/.codex/models_cache.json` and its default is `model` in
`~/.codex/config.toml`; omp's list is `omp models`, and its own fuzzy match
must not be trusted for this (`--model sol` picks `gpt-5.6-sol` over
`gpt-6-sol`, and `sonnet` a retired model). Claude takes the alias itself.
The owner finds Sol subpar: don't pick it, even to save money.

Any other Herdr kind works with its own arguments. A follow-up like "go" goes
to your builder; without one, there is nothing to continue. Handle any
approval Herdr's socket needs your own harness's way.

## 4. Wait

Every message you send a builder, follow-ups included, gets its own wait, and
so does a builder that stopped to ask the owner, who may answer in its pane.
When a builder stops to ask for a live run, tell the owner at once which pane
is asking, so they can step away from the machine and give the go there.
Live runs share one desktop, so keep them one at a time.
Run the wait so its end reaches you without polling: in Claude Code, a
background command that exits when the builder stops working. A builder
waiting on the owner is already idle, so that wait first waits for it to
start working, then for it to stop.

Settled means the builder answered this brief, not that its state changed: a
fresh agent can open with a trust or approval dialog that swallows the brief
while Herdr still reports `idle`. Read the report with `herdr agent read
NAME`; if it ends mid-task, wait again. If the pane holds a dialog or an
untouched prompt, tell the owner the pane and the question, and stop. Dialogs
are theirs. Send the brief once after they clear it: "never re-send" guards a
turn that ran, not a prompt that never landed. On anything else, or a timeout,
inspect with `herdr agent get NAME` and `herdr agent read NAME --source
visible`, then `herdr agent wait NAME`. If the report is cut off, ask the
builder to write it to a file and read that.

## 5. Judge the result

Each change gets three looks: yours, the reviewer's, and the pull request's AI
review. Read the reviewer's report and the pull request's comments, not only
the builder's summary.

The builder's "done" is evidence, not the result. Run the named check yourself
and read its output, not only its exit code: it must run to the end and report
no failure. Judge the builder's proof of what a user would see; any gap in it
is unverified, not done. Read the diff against the brief at the depth the
change deserves, and for what the next agent will copy: a workaround, a second
way to do what the repo already does one way, or a comment excusing a
shortcut is worth changing even when the check passes. Tell the owner: holds
up, worth changing, unverified.

Send fixes back to the same builder. When it got something wrong that could
happen again, make the fix stick: in the code so it can't recur, else a lint
rule or check, else a line in the repo's instructions.

Findings from a review handoff are input, not authority: check each against
the code. Reject pedantry, premature optimization, and over-engineering; a
finding must name a concrete failure this code can produce.