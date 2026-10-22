# Launch

## Commands

```sh
herdr tab create --workspace WORKSPACE --cwd "$CHECKOUT" --label NAME --no-focus      # the builder's tab: .result.root_pane.pane_id
herdr pane split --pane BUILDER_PANE --direction right --cwd "$CHECKOUT" --no-focus   # its reviewer: .result.pane.pane_id
herdr pane rename PANE_ID NAME
herdr agent start NAME --kind KIND --pane PANE_ID -- ARGS
herdr agent prompt NAME "$(cat BRIEF_FILE)" --wait --timeout 7200000             # from a file: inline, the brief's backticks and $ would run
```

Before starting a fresh agent, upgrade its CLI (with mise:
`MISE_MINIMUM_RELEASE_AGE=0 mise upgrade TOOL`, naming the tool as `mise ls`
does). If Herdr's socket asks for approval, handle it the way your own harness
does.

## Agents

| Agent | Kind | Args |
| --- | --- | --- |
| `opus` | claude | `--model opus --effort high` |
| `claude` | claude | configured defaults, which aren't `opus` |
| `codex` | codex | `-m MODEL -c model_reasoning_effort=xhigh` |
| `cursor` | cursor | configured default; override with `--model MODEL` |
| `omp` | omp | `--model PROVIDER/ID --thinking high`, with the provider as `omp models` groups it: `anthropic/claude-opus-5-5`, `openai-codex/GPT_ID`. A bare GPT id picks the keyless `openai` provider, which fails. |

Any other Herdr kind works with its own arguments.

- When the user names no agent, a coding task goes to `omp` with
  `anthropic/claude-opus-5-5`, and research, design, and other exploration go
  to `opus`, since Claude Code carries the user's skills and MCP tools.
- Effort is `high` for Claude models and `xhigh` for Codex models, unless the
  user names another level.
- A nickname ("sol", "opus", "fable") means the newest model id that carries
  it: pass that id. Codex lists its models in `~/.codex/models_cache.json`,
  and its default is `model` in `~/.codex/config.toml`. omp lists its models
  in `omp models`; resolve the id yourself there, since omp's own fuzzy match
  can pick an older or retired model. Claude takes the alias itself. When
  omp's list lacks a GPT model that Codex's list has, use the `codex` kind.
