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

You hold the senior seat: you write the brief, launch the agent, wait, and
judge what comes back. Herdr runs the panes; read `herdr --skill` before
your first Herdr command. Settle what your judgment covers, and bring the
user only what it doesn't, with your recommendation.

A subagent is invisible and spends your context: use one for mechanical
work you can check, such as a search. A handoff is a pane the user can watch
and steer, on its own budget: use it for work that needs judgment.

## The brief

The agent has none of your conversation. Brief a builder from
[build-brief.md](build-brief.md), a reviewer from
[review-brief.md](review-brief.md), and a checker from the `tophat` skill's
`check-brief.md`. A build brief has four parts:

- **The problem, in the user's words.**
- **The outcome:** what's true when it's done. Name a method only when the
  user or the repo requires one. For research or design, describe the
  subject as the user sees it and keep your favourite answer out, since one
  suggested direction steers the whole result.
- **What must stay true:** the rules the change keeps in every state and at
  every hour, with the case seen as an example ("the index and the stocks
  read the same way at every hour; today, at 06:22, they don't").
- **Where to stop:** the first point where someone else can act, in a
  brief and in every later message. By default it commits and pushes or
  opens a pull request as the repo's rules say, or else stops with the work
  uncommitted.

Size the brief to the change: a 25-line fix needs a few lines, since the
repo's instruction files already cover style, branches and what done means.
When no check covers the change, building one is part of the task. Note
`git status` before launching, so changes already there aren't blamed on
the builder.

## Launch

[launch.md](launch.md) has the commands, and which agent, model and effort
each role gets.

- Find your own pane in the live pane list by title and cwd before changing
  the layout: inherited `HERDR_*` values can be stale.
- Give each builder a named tab; add its reviewer on the right and checker
  below only when the rules below require those roles. Label each pane with
  its agent's name.
- Each builder gets its own worktree from the working branch's last passing
  commit, and the list of files the others are changing. Builders work in
  parallel, even on the same files, build only on merged work, and rebase
  only on a conflict. Leave a builder's files to it while it works.
- A small change the builder reviews and checks itself. A bigger change, or
  a risky one (it could lose data, changes what the program runs, reads,
  writes or fetches, or touches auth or money), gets fresh eyes: a reviewer
  from another model in another harness, which stays until the work merges.
- Give each builder a sizeable chunk, such as every fix from one
  investigation, and send it the follow-ups on its work: each extra agent
  is another session to brief, wait on and pay for. Unrelated work goes to a
  fresh builder, since a long session makes every turn cost more.

## Wait

- Give every message its own wait that reaches you without polling (in
  Claude Code, a background command). A builder waiting on the user is
  already idle: wait for it to start, then to stop.
- A timed-out wait proves nothing: read the pane and wait again.
- A turn's end is a report, not proof the work is done: read it with
  `herdr agent read`. If work is open and no blocker named, send a short
  message saying what's open; after two or three, bring it to the user.
- A builder stopped by a usage limit: move its work to another account's
  agent, or wait for the reset and send one message to carry on.
- A dialog or question in a pane, and a builder that needs the user, go to
  the user at once; relay the answer. Live runs share one desktop, so run
  one at a time.
- When timing matters, say what's left in steps: builders finish in minutes
  to an hour what feels like days.
- The user steers panes directly. When an agent changes unexpectedly, read
  the user's latest messages to it (`herdr agent get NAME`,
  `.result.agent.agent_session.value`) and let it do what they said. Leave
  an agent they closed closed. One they restarted comes back in the same
  pane without its name: give it back its name.

## Judge the result

- Read the runs: each ran to the end, with no failure, on the tree that
  merges. A review's or a check's verdict holds after a rebase that left
  the patch identical (`git patch-id`).
- Read the reviewer's report when there is one, the fixes the builder lists
  for it, and the pull request's comments, checking each finding against the
  code. AI reviews are input, not a gate to wait for.
- A small change the user can see or touch, its builder tophats itself; a
  bigger one gets its independent check (the `tophat` skill) once its pull
  request is ready. A gap in the proof of what a user would see is
  unverified, not done.
- Read the diff for what the next agent will copy: a workaround, a second
  way of doing what the repo does one way, or a comment excusing a shortcut
  is worth changing even when the checks pass. Judge simplicity by what each
  piece owns, not by line counts. Send back a design that only moves a
  problem or replaces what works.
- Tell the user it holds up, it's worth changing, or it's unverified.

## Close out

When a builder's work merges, or an investigator's or checker's report is
in:

1. Find its tab by the builder's name now (`herdr agent get NAME` gives
   `.result.agent.tab_id`): a stale pane ID can close the agent next to it.
2. If `herdr pane list` shows only the builder and its reviewer there, close
   the tab (`herdr tab close`); otherwise close their two panes, found by
   name.
3. Check with `herdr agent list` that every other agent is still there.
4. Remove its worktree, and move its briefs to where the project keeps
   finished ones.
