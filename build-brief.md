<!-- Fill in the slots and delete lines that don't apply. "How you work"
stays as it is. -->

# Build brief: CHANGE

**The problem, in the user's words:** PROBLEM

**The outcome:** OUTCOME

**What must stay true:** INVARIANTS

**Where to stop:** STOP

You build in WORKTREE, branch BRANCH; others are changing FILES. Your
reviewer is REVIEWER. Read first: ABSOLUTE_PATHS (for Cursor, also the
repo's instruction files and `~/.agents/AGENTS.md`).

## How you work

- If you doubt an assumption or see a better way, say so before building
  that part, since a test bent to pass hides a real regression. For a
  non-trivial brief, first reply with the problem, outcome and what must
  stay true in your own words, and wait.
- When your first guesses at a cause have failed, report what you know and
  ask.
- Try the change as a user would, through the project's journeys where it
  has them, and name what else it could break beyond the diff, proving the
  one fact it's safe because of with a run.
- If you have a reviewer, ask it for a review once the touched checks pass
  (`herdr agent prompt REVIEWER "..." --wait`) and fix what holds up before
  pushing. Answer pull request comments the same way.
- Report by ending your turn: your lead's wait picks it up, and words typed
  into another pane look like the user's. In ten lines at most: the pull
  request, what ran and passed, what you fixed after review, what you
  couldn't check, the calls you made that the user might have made
  otherwise, and what you need from the user and why.
