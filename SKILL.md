---
name: handoff
description: >
  Hands a task, plan, or review to another coding agent in a Herdr pane, then
  judges what comes back. Use when the user asks to hand off, delegate, or
  "send this to" an agent (opus, claude, codex, cursor, omp, or any Herdr
  kind), or invokes /handoff or $handoff. Not for passing your own seat to a
  successor.
---

# Handoff

You hold the senior seat: you write the brief, launch the agent, wait for it,
and judge what comes back, while it builds or reviews. Herdr runs the panes.
Before your first Herdr command, read `herdr --skill`: it covers Herdr's
commands and states, and this skill adds what Herdr leaves to you.

Decide what your own judgment covers, and say what you decided. Bring the user
only what you can't settle, with your recommendation.

## Handoff or subagent

A subagent is invisible, answers only to you, and spends your context: use
one for mechanical work you can check, like a search. A handoff is a pane the
user can watch and steer; it persists, takes follow-ups, and spends its own
budget: use it for work that needs judgment or that the user will want to
see. When the user's wording leaves it open, say which you're using.

## Before launching

Settle the repo, the task (a plan file, a step of one, an inline task, or a
follow-up like "go" for the builder already working for you), the agent, any
model or effort the user named, and the check: the command that proves the
work. When no check covers the change, building one is part of the task: say
so, and ship it unverified only if the user says to. Note `git status` first,
so existing changes aren't blamed on the builder.

## The brief

The agent has none of your conversation, so the brief carries everything you
would otherwise correct afterwards. Every brief:

- **The role.** A builder does this task. A reviewer changes nothing, and each
  finding names the concrete failure it causes; pedantry, premature
  optimization, and over-engineering aren't findings. A role's assignment
  goes in its brief, never in an `AGENTS.md`, which every agent reads.
- **What to read first, by absolute path,** since a builder in another
  worktree can't see this checkout's ignored files: the repo's instruction
  files, the user's own (`~/.agents/AGENTS.md`) when the agent doesn't load
  them (Cursor doesn't), then the files the task names. The repo's rules
  govern style, branches, and what done means; restate only what this task
  turns on.
- **The outcome that must be true, and the problem behind it,** not the
  method, unless the repo's rules name one. For research or design, describe
  the subject as the user sees it and keep your own favourite answer out: one
  suggested direction steers the whole result. A design starts from what the
  person is trying to do and where today's design fails them, asks for the
  smallest real answer, and offers a choice only where a real one exists.
- **How it reports:** by ending its turn, which your wait picks up, never by
  typing into your pane, where its text would land as the user's. When it
  needs the user, for a look, a choice, or a live run, it ends its turn saying
  what and why.
- **Room to object.** Where the agent doubts an assumption or sees a better
  path, it stops and says so before building that part, rather than complying
  or quietly working around it: a test bent to pass can hide a real
  regression. For a non-trivial plan, ask for its plan and that verdict first.

A build brief also carries:

- **The check, and irrefutable proof it works end to end:** the builder runs
  the check, tries the change as a user would, and brings back what it ran and
  saw (output, screenshots) and what it couldn't check. When the full check is
  slow, it runs the parts its change touches while it works, and the whole
  once, on its final commit.
- **Its reviewer, by name.** When the parts of the check its change touches
  pass, the builder asks the reviewer to review its diff (`herdr agent prompt
  REVIEWER "..." --wait`) and fixes what holds up before it pushes; on a pull
  request, it answers the review comments the same way.
- **Where to stop.** By default the builder commits, then pushes or opens a
  pull request as the user's and the repo's rules say; where both say
  nothing, it stops with the work uncommitted. When the user's go comes later,
  relay it to the builder rather than committing yourself.

## Launch

[launch.md](launch.md) has the commands, each agent's arguments, and model
names.

- Find your own pane in the live pane list, by title and cwd, before changing
  the layout: inherited `HERDR_*` values can be stale.
- Each builder gets its own tab, named for it: the builder on the left, its
  reviewer on the right, each pane labelled with its agent's name. It also
  gets its own worktree, and is told which files the others are changing.
  Never edit alongside a builder. One whose change touches another's files
  builds on that branch and rebases whenever it moves.
- Every builder gets a reviewer from another model: by default Codex with the
  newest Sol at `xhigh`, or a Claude model when the builder is Codex. The
  reviewer changes no code, stays until the work merges, checks the code
  rather than the taste, and writes each report to a file and replies with a
  summary, so closing its pane loses nothing. Work that ships nothing, a
  review or exploration the user picks from, gets none.
- A builder's follow-ups go to it, since it starts knowing its work: fixes,
  review findings, rebases, and new work on its own files or unmerged branch.
  Anything else gets a fresh builder, because a long session makes every turn
  cost more. Another session's idle agent isn't yours.
- Keep to about three builders at once, and queue the rest unless the user
  asks for more: more slow the machine's test runs and outrun your reviews.

## Wait

- Give every message its own wait, run so its end reaches you without
  polling: in Claude Code, a background command. A builder waiting on the user
  is already idle, so wait for it to start working, then for it to stop.
- A wait that times out proves nothing: read the pane, and wait again without
  sending the message again.
- A turn's end is a report, not proof the work is done: read it
  (`herdr agent read`). If it stops with work open and no blocker named, send
  a short message naming what's open; after two or three, bring it to the
  user.
- A dialog or a question in the pane is the user's: tell them which pane and
  what it asks, and stop. Send the brief once they've cleared it.
- When a builder needs the user, bring it to them at once and relay the
  answer. Live runs share one desktop: one at a time.
- Don't guess how long a builder will take: builders finish in minutes to an
  hour what feels like days of work. When timing matters, say what's left in
  steps.
- The user steers panes directly. When an agent changes unexpectedly, first
  read the user's latest messages in its session (`herdr agent get NAME`
  gives it as `.result.agent.agent_session.value`), and let it do what they
  said; never restart an agent they closed. One they restarted comes back in
  the same pane, unnamed: check `herdr pane list` before reporting it
  stopped, and give it back its name.

## Judge the result

- The builder's "done" is evidence, not the result. Read its run of the check:
  to the end, on the commit you'll merge, with no failure. Run it yourself
  only when what you merge differs from what ran (a later rebase, or changes
  merged together), or the run can't be seen.
- Read the reviewer's report and the pull request's comments, not just the
  builder's summary, and never wait for an AI review. Every review is input,
  not authority: check each finding against the code.
- Judge the proof of what a user would see; any gap in it is unverified, not
  done.
- Read the diff against the brief, and for what the next agent will copy: a
  workaround, a second way of doing what the repo does one way, or a comment
  excusing a shortcut is worth changing even when the check passes. Judge
  simplicity by what each piece owns and no longer has to know, never by line
  counts.
- Judge a design before the user sees it: send back one that only moves a
  problem around, or replaces what already works.
- Tell the user it holds up, it's worth changing, or it's unverified.
- Send fixes back to the same builder. When its mistake could recur, make the
  fix stick: in the code, else a check, else a line in the repo's
  instructions. A fix for something that quietly broke says when and why it
  broke, and closes the gap that let it through.

## Close out

When a builder's work merges:

1. Find its tab by the builder's name at that moment (`herdr agent get NAME`
   gives `.result.agent.tab_id`): a stale pane ID can close the agent next to
   it.
2. If `herdr pane list` shows only the builder and its reviewer there, close
   the tab (`herdr tab close` ends its agents); otherwise close their two
   panes, each found by name.
3. Check with `herdr agent list` that every other agent is still there.
4. Remove its worktree.
