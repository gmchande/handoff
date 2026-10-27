#!/usr/bin/env bash
# Proves send-brief's outcomes against a stand-in for herdr, so nothing real
# is typed: it sends the brief once, presses Enter at most once, and only when
# omp's paste sits unsent.
#
#   ./test-send-brief.sh        # prints one line per case; exits 1 on any failure

set -u
export LC_ALL=C.UTF-8
SCRIPT=$(cd "$(dirname "$0")" && pwd)/send-brief
ROOT=$(mktemp -d)
trap 'rm -rf "$ROOT"' EXIT
FAILED=0

# herdr stand-in: the agent's kind and status, and its pane, live in $FX.
# A prompt starts the agent unless $FX/stuck exists; Enter starts it unless
# $FX/deaf exists.
cat >"$ROOT/herdr" <<'EOF'
#!/usr/bin/env bash
echo "$*" >>"$FX/calls.log"
case "$1 $2" in
  "agent get") jq -n --arg k "$(cat "$FX/kind")" --arg s "$(cat "$FX/status")" '{result:{agent:{agent:$k,agent_status:$s,pane_id:"w1:p1"}}}' ;;
  "agent read") cat "$FX/pane.txt" ;;
  "agent prompt") [ -e "$FX/stuck" ] || echo working >"$FX/status" ;;
  "pane send-keys") [ -e "$FX/deaf" ] || { echo working >"$FX/status"; echo " ⠙ 3s  Opus" >"$FX/pane.txt"; } ;;
  *) exit 1 ;;
esac
EOF
chmod +x "$ROOT/herdr"
echo "# Build brief" >"$ROOT/brief.md"

run() { # name kind expected-exit expected-enters [stuck] [deaf] [no-chip]
  FX="$ROOT/$1"; mkdir -p "$FX"; export FX
  echo "$2" >"$FX/kind"; echo idle >"$FX/status"
  if [ "${7:-}" = no-chip ]; then echo "╰─" >"$FX/pane.txt"; else printf ' Opus 5.5  stonks\n╰─  #1\n' >"$FX/pane.txt"; fi
  [ -z "${5:-}" ] || touch "$FX/stuck"
  [ -z "${6:-}" ] || touch "$FX/deaf"
  HERDR="$ROOT/herdr" SEND_BRIEF_WAIT=2 "$SCRIPT" builder "$ROOT/brief.md" >/dev/null 2>&1
  local code=$? prompts enters
  prompts=$(grep -c '^agent prompt' "$FX/calls.log")
  enters=$(grep -c '^pane send-keys' "$FX/calls.log")
  if [ "$code" = "$3" ] && [ "$prompts" = 1 ] && [ "$enters" = "$4" ]; then
    echo "ok   $1"
  else
    echo "FAIL $1: exit $code, $prompts prompts, $enters Enters"; FAILED=1
  fi
}

run starts-at-once omp 0 0
run omp-paste-unsent omp 0 1 stuck
run omp-enter-no-help omp 7 1 stuck deaf
run omp-input-empty omp 7 0 stuck "" no-chip
run claude-never-starts claude 7 0 stuck

exit $FAILED
