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

You hold the senior seat. You write the brief, launch the agent, wait for it,
and judge what it brings back; the agent does the building or reviewing.
Herdr runs the panes. Before your first Herdr command, read `herdr --skill`:
it covers Herdr's commands and states, and this skill covers the rest.

Decide what your own judgment covers, and say what you decided. Bring the user
only what you can't settle, with your recommendation.

## Handoff or subagent

A subagent is invisible, answers only to you, and spends your context: use
one for mechanical work you can check, such as a search. A handoff is a pane
the user can watch and steer. It persists, takes follow-ups, and spends its
own budget: use it for work that needs judgment, or that the user will want
to see. When the request leaves it open, say which one you're using.

## Before launching

- Settle the repo, the task, the agent, any model or effort the user named,
  and the check: the command that proves the work. The task can be a plan
  file, a step of one, an inline task, or a follow-up such as "go" for the
  builder already working for you.
- When no check covers the change, building one is part of the task. Say so,
  and ship without one only if the user says to.
- Note `git status` first, so changes already there aren't blamed on the
  builder.

## The brief

The agent has none of your conversation, so the brief carries everything you
would otherwise have to correct afterwards. Every brief gives:

- **The role.** A builder does this task. A reviewer changes nothing, and each
  finding names the concrete failure it causes; pedantry, premature
  optimization, and over-engineering aren't findings. The role goes in the
  brief, never in an `AGENTS.md`, which every agent reads.
- **What to read first, by absolute path** (a builder in another worktree
  can't see this checkout's ignored files): the repo's instruction files; the
  user's own, `~/.agents/AGENTS.md`, when the agent doesn't load them itself
  (Cursor doesn't); then the files the task names. The repo's rules already
  cover style, branches, and what done means, so restate only what this task
  turns on.
- **The outcome that must be true, and the problem behind it.** Name a method
  only when the repo's rules require one. For research or design, describe
  the subject as the user sees it, and leave out your own favourite answer:
  one suggested direction steers the whole result. A design starts from what
  the person is trying to do and where today's design fails them, asks for
  the smallest change that meets that need, and offers a choice only where a
  real one exists.
- **How it reports:** by ending its turn, which your wait picks up. It never
  types into your pane, where its words would look like the user's. When it
  needs the user, for a look, a choice, or a live run, it ends its turn and
  says what it needs and why.
- **Room to object.** When the agent doubts an assumption or sees a better
  way, it stops and says so before building that part, instead of complying
  or quietly working around it: a test bent to pass can hide a real
  regression. For a non-trivial plan, ask for its plan and its view of the
  brief first.

A build brief also gives:

- **The check, and irrefutable proof it works end to end.** The builder runs
  the check, tries the change as a user would, and brings back what it ran
  and saw (output, screenshots) and what it couldn't check. When the full
  check is slow, it runs only the parts its change touches while it works,
  and the full check once, on its final commit.
- **Its reviewer, by name.** Once the parts of the check its change touches
  pass, the builder asks the reviewer to review its diff
  (`herdr agent prompt REVIEWER "..." --wait`), and fixes what holds up before
  it pushes. On a pull request, it answers the review comments the same way.
- **Where to stop.** By default the builder commits, then pushes or opens a
  pull request as the user's and the repo's rules say; where neither says,
  it stops with the work uncommitted. When the user's go comes later, relay
  it to the builder rather than committing yourself.

## Launch

[launch.md](launch.md) has the commands, each agent's arguments, and model
names.

- Find your own pane in the live pane list, by title and cwd, before you
  change the layout: inherited `HERDR_*` values can be stale.
- Each builder gets its own tab, named after it, with the builder on the left
  and its reviewer on the right. Label each pane with its agent's name.
- Each builder also gets its own worktree, and is told which files the others
  are changing. Never edit alongside a builder. A builder whose change
  touches another's files builds on that branch, points its pull request at
  it, and rebases whenever it moves.
- Every builder gets a reviewer from another model: by default Codex with the
  newest Sol at `xhigh`, or a Claude model when the builder is Codex. The
  reviewer changes no code and stays until the work merges. It checks the
  code rather than the taste, writes each report to a file, and replies with
  a summary, so closing its pane loses nothing. Work that ships nothing, such
  as a review or ideas for the user to pick from, gets no reviewer.
- Send a builder its own follow-ups, since it already knows the work: fixes,
  review findings, rebases, and new work on its files or its unmerged branch.
  Anything else goes to a fresh builder, because a long session makes every
  turn cost more. Another session's idle agent isn't yours.
- Run about three builders at once and queue the rest, unless the user asks
  for more: more slow the machine's test runs, outpace your reviews, and use
  up the reviewers' quota.

## Wait

- Give every message its own wait, run so that its end reaches you without
  polling (in Claude Code, a background command). A builder that's waiting on
  the user is already idle, so wait for it to start working, then to stop.
- A wait that times out proves nothing: read the pane, and wait again without
  sending the message again.
- A turn's end is a report, not proof the work is done: read it with
  `herdr agent read`. If the builder stops with work still open and names no
  blocker, send a short message saying what's open; after two or three such
  nudges, bring it to the user.
- A dialog or a question in the pane is the user's to answer: tell them which
  pane and what it asks, and stop. Send the brief once they've cleared it.
- When a builder needs the user, bring it to them at once, and relay their
  answer. Live runs share one desktop, so run one at a time.
- Don't guess how long a builder will take: builders finish in minutes to an
  hour what feels like days of work. When timing matters, say what's left, in
  steps.
- The user steers panes directly. When an agent changes unexpectedly, first
  read the user's latest messages in its session (`herdr agent get NAME`
  gives it as `.result.agent.agent_session.value`), and let the agent do what
  they said; never restart an agent they closed. An agent they restarted
  comes back in the same pane without its name: check `herdr pane list`
  before reporting it stopped, and give it back its name.

## Judge the result

- The builder's "done" is evidence, not the result. Read its run of the
  check: it ran to the end, on the commit you'll merge, with no failure. Run
  the check yourself only when what you merge differs from what ran (after a
  rebase, or when you merge several changes together), or when you can't see
  the run.
- Read the reviewer's report and the pull request's comments, not just the
  builder's summary, and never wait for an AI review. Every review is input,
  not authority: check each finding against the code.
- Judge the proof of what a user would see. Any gap in it is unverified, not
  done.
- Read the diff against the brief, and for what the next agent will copy: a
  workaround, a second way of doing something the repo already does one way,
  or a comment excusing a shortcut is worth changing even when the check
  passes. Judge simplicity by what each piece owns and no longer has to know,
  never by line counts.
- Judge a design before the user sees it: send back one that only moves a
  problem around, or that replaces what already works.
- Tell the user it holds up, it's worth changing, or it's unverified.
- Send fixes back to the same builder. When its mistake could happen again,
  make the fix stick: in the code, or else a check, or else a line in the
  repo's instructions. A fix for something that quietly broke says when and
  why it broke, and closes the gap that let it through.

## Close out

When a builder's work merges:

1. Find its tab by the builder's name at that moment (`herdr agent get NAME`
   gives `.result.agent.tab_id`): a stale pane ID can close the agent next to
   it.
2. If `herdr pane list` shows only the builder and its reviewer in that tab,
   close the tab (`herdr tab close` ends its agents); otherwise close their
   two panes, each found by name.
3. Check with `herdr agent list` that every other agent is still there.
4. Remove its worktree.
