# Launch

## Commands

```sh
herdr tab create --workspace WORKSPACE --cwd "$CHECKOUT" --label NAME --no-focus      # the builder's tab: .result.root_pane.pane_id
herdr pane split --pane BUILDER_PANE --direction right --cwd "$CHECKOUT" --no-focus   # its reviewer: .result.pane.pane_id
herdr pane rename PANE_ID NAME
herdr agent start NAME --kind KIND --pane PANE_ID -- ARGS
./send-brief NAME BRIEF_FILE                     # in this skill's directory; from a file, since inline the brief's backticks and $ would run
herdr agent wait NAME --timeout 7200000          # then its turn's end
```

`send-brief` presses Enter once when omp leaves a pasted brief unsent, and
exits 7 when the agent still doesn't start: read its pane then, since
sending again by hand would send the brief twice.

Before the day's first launch, upgrade each agent's CLI with `mise upgrade
TOOL`, named as `mise ls` names it. If Herdr's socket asks for approval,
handle it as your own harness does.

## Who runs what

Unless the user names an agent, a model or an effort:

| Role | Kind | Model | Effort |
| --- | --- | --- | --- |
| Builder | omp | `anthropic/claude-opus-5-5` | `medium`; `high` when the brief says it's hard or risky |
| Research, design, exploration | claude | `opus` | `xhigh` |
| Reviewer | codex | the newest Sol | `xhigh` |
| Reviewer of a builder using Codex or running Sol | claude | `opus` | `high` |
| Independent checker | omp or claude | `anthropic/claude-opus-5-5` or `opus` | `medium` |
| An agent the user names | its own | as named | `high` for Claude, `xhigh` for Codex |

Research and design go to Claude Code because it carries the user's skills
and MCP tools. Use these models rather than smaller ones; when an account is
out of room, use another account's agent rather than wait.

| Kind | Args |
| --- | --- |
| claude | `--model MODEL --effort EFFORT`; with no model, its default, which isn't `opus` |
| codex | `-m MODEL -c model_reasoning_effort=EFFORT` |
| cursor | `--model MODEL`, or its default |
| omp | `--model PROVIDER/ID --thinking EFFORT`, the provider as `omp models` groups it (`openai-codex/GPT_ID`; a bare GPT id picks the keyless `openai` provider, which fails) |

Any other Herdr kind takes its own arguments.

A nickname ("sol", "opus", "fable") means the newest model id that carries
it. Claude takes the alias. For Codex, read `~/.codex/models_cache.json`;
for omp, pick the id from `omp models` yourself, since its fuzzy match can
pick a retired model. A GPT model Codex lists and omp doesn't runs as the
`codex` kind.
