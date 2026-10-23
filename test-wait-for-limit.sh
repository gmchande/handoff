#!/usr/bin/env bash
# Proves each outcome of wait-for-limit against stand-ins for herdr, sleep and
# date, so nothing real is typed and no test waits. The limit messages are the
# ones Claude Code, Codex and omp really printed (see wait-for-limit).
#
#   ./test-wait-for-limit.sh        # prints one line per case; exits 1 on any failure

set -u
export LC_ALL=C.UTF-8
SCRIPT=$(cd "$(dirname "$0")" && pwd)/wait-for-limit
ROOT=$(mktemp -d)
trap 'rm -rf "$ROOT"' EXIT
FAILED=0
REAL_DATE=$(command -v date)

mkdir -p "$ROOT/bin"
export REAL_DATE

# herdr stand-in: serves the fixture files in $FX; logs every call; a prompt
# makes the agent "working" unless $FX/deaf exists.
cat >"$ROOT/bin/herdr" <<'EOF'
#!/usr/bin/env bash
echo "$*" >>"$FX/calls.log"
[ "$1 $2" = "agent get" ] && { [ -e "$FX/gone" ] && exit 1
  jq -n --arg s "$(cat "$FX/status")" --arg ws "$(cat "$FX/workspace")" --arg pane "$(cat "$FX/pane_id")" --arg kind "$(cat "$FX/kind")" \
    '{result:{agent:{agent:$kind,agent_status:$s,pane_id:$pane,workspace_id:$ws}}}'; exit 0; }
[ "$1 $2" = "agent read" ] && { case "$*" in *ansi*) cat "$FX/ansi.txt" ;; *) cat "$FX/pane.txt" ;; esac; exit 0; }
[ "$1 $2" = "agent prompt" ] && { printf '%s\n' "$4" >>"$FX/sent.log"; [ -e "$FX/deaf" ] || echo working >"$FX/status"; exit 0; }
echo "unexpected herdr call: $*" >>"$FX/calls.log"; exit 1
EOF
# sleep stand-in: advances the clock, then runs the scenario's hook once.
cat >"$ROOT/bin/sleep" <<'EOF'
#!/usr/bin/env bash
echo "$1" >>"$FX/sleeps.log"
echo $(( $(cat "$FX/clock") + $1 )) >"$FX/clock"
[ -x "$FX/on_sleep" ] && { "$FX/on_sleep"; rm -f "$FX/on_sleep"; }
exit 0
EOF
# date stand-in: "now" comes from the fixture clock; everything else is real date.
cat >"$ROOT/bin/date" <<'EOF'
#!/usr/bin/env bash
case "$*" in
  "+%s") cat "$FX/clock" ;;
  "+%Y") "$REAL_DATE" -d "@$(cat "$FX/clock")" +%Y ;;
  *) exec "$REAL_DATE" "$@" ;;
esac
EOF
chmod +x "$ROOT"/bin/*

# ---- fixtures: the real words, in the screen shapes each agent draws ----

CLAUDE_SESSION="You've hit your session limit · resets 4:40pm (America/Toronto)"
CLAUDE_WEEKLY="You've hit your weekly limit · resets Oct 25, 1am (America/Toronto)"
CLAUDE_MONTHLY="You've hit your monthly spend limit · raise it at https://claude.ai/settings/usage?from=cc_cli_limit_message · your weekly limit resets Oct 25, 1am (America/Toronto)"
CODEX_TIME="■ You've hit your usage limit. Upgrade to Pro (https://chatgpt.com/explore/pro), visit https://chatgpt.com/codex/settings/usage to purchase more credits or try again at 6:26 PM."
CODEX_DATED="■ You've hit your usage limit. Upgrade to Pro (https://chatgpt.com/explore/pro), visit https://chatgpt.com/codex/settings/usage to purchase more credits or try again at Oct 25th, 2026 1:22 AM."
OMP_429='Error: 429 {"type":"error","error":{"type":"rate_limit_error","message":"This request would exceed your account'"'"'s rate limit. Please try again later."},"request_id":"req_011CgHpjUfh2ts8ebuGGp7oq"} retry-after-ms=4479000'
UNNAMED="You've hit your session limit"

# $1 limit message, $2 kind: writes pane.txt and an empty-input ansi.txt
screen() {
  local msg=$1 kind=$2
  case $kind in
    claude) printf '● Reviewed the diff.\n\n  %s\n\n──────────\n❯\n──────────\n  ⏵⏵ auto mode on\n' "$msg" >"$FX/pane.txt" ;;
    codex) printf '• Ran the checks.\n\n%s\n\n› Ask Codex to do anything\n\n  GPT-6.1-Sol xhigh · ~/work\n  ? for shortcuts\n' "$msg" >"$FX/pane.txt" ;;
    omp) printf ' Ran the checks.\n\n %s\n\n\xee\x82\xb6 Haiku 5.5 \xee\x82\xb1 /tmp\n╰─\n' "$msg" >"$FX/pane.txt" ;;
  esac
  input "" "$kind"
}
# $1 typed text ("" for none), $2 kind: the input line as ANSI
input() {
  local typed=$1 kind=$2
  case $kind in
    claude) printf '\e[0m\e[38;2;1;2;3m────────\e[0m\r\n\e[0m❯\xc2\xa0%s\r\n\e[0m────────\r\n  \e[0mauto mode\n' "$typed" >"$FX/ansi.txt" ;;
    codex)
      if [ -z "$typed" ]; then
        printf '\e[0m\e[48;2;1;2;3m\e[0m\e[1m\e[48;2;1;2;3m›\e[0m\e[48;2;1;2;3m \e[0m\e[2m\e[48;2;1;2;3mAsk Codex to do anything\e[0m\e[48;2;1;2;3m      \e[0m\r\n  GPT-6.1-Sol xhigh\n' >"$FX/ansi.txt"
      else
        printf '\e[0m\e[1m\e[48;2;1;2;3m›\e[0m\e[48;2;1;2;3m %s\e[0m\r\n  GPT-6.1-Sol xhigh\n' "$typed" >"$FX/ansi.txt"
      fi ;;
    omp)
      if [ -z "$typed" ]; then
        printf '\e[0m\e[38;2;1;2;3m╰─ \e[0m                              \e[38;2;1;2;3m ⟦hint⟧ to change thinking effort\e[0m\n' >"$FX/ansi.txt"
      else
        printf '\e[0m\e[38;2;1;2;3m╰─ %s\e[0m          \n' "$typed" >"$FX/ansi.txt"
      fi ;;
  esac
}

# new_case NAME KIND MESSAGE [CLOCK-UTC]: a fresh stopped agent
new_case() {
  FX=$ROOT/fx-$1; export FX
  rm -rf "$FX"; mkdir -p "$FX" "$ROOT/state-$1"
  echo idle >"$FX/status"; echo w3 >"$FX/workspace"; echo w3:pF2 >"$FX/pane_id"; echo "$2" >"$FX/kind"
  "$REAL_DATE" -u -d "${4:-2026-10-22T19:25:21Z}" +%s >"$FX/clock"
  screen "$3" "$2"
}

total_sleep() { awk '{s+=$1} END{print s+0}' "$FX/sleeps.log" 2>/dev/null; }
sent_count() { [ -e "$FX/sent.log" ] && wc -l <"$FX/sent.log" || echo 0; }

# run NAME [options]: sets STATUS and ERR
run() {
  local name=$1; shift
  ERR=$(PATH="$ROOT/bin:$PATH" HERDR=herdr LIMIT_WAIT_STATE="$ROOT/state-$name" LIMIT_WAIT_POLL="${POLL:-300}" LIMIT_WAIT_MARGIN=120 LIMIT_WAIT_DEFAULT=1800 "$SCRIPT" agentx "$@" 2>&1 >/dev/null)
  STATUS=$?
}

ok() { # description, then a test command
  local desc=$1; shift
  if "$@"; then printf 'PASS  %s\n' "$desc"; else printf 'FAIL  %s\n        status=%s stderr=%s sleeps=%s sent=%s\n' "$desc" "$STATUS" "$ERR" "$(total_sleep)" "$(sent_count)"; FAILED=1; fi
}
status_is() { [ "$STATUS" = "$1" ]; }
sent_once() { [ "$(sent_count)" = 1 ] && [ "$(head -n 1 "$FX/sent.log")" = "Your usage limit has reset. Carry on from where you stopped." ]; }
sent_never() { [ "$(sent_count)" = 0 ]; }
slept() { [ "$(total_sleep)" = "$1" ]; }
err_has() { grep -q -- "$1" <<<"$ERR"; }
never_listed() { ! grep -q -E 'list|--workspace' "$FX/calls.log"; }

# ---- limit stops: wait until the named reset, then send once ----

new_case claude-session claude "$CLAUDE_SESSION"
run claude-session
ok "Claude session limit: sends once, 4:40pm Toronto + 120s margin after 15:25:21 (4479+120 s)" sh -c "[ $STATUS = 0 ] && [ \"$(total_sleep)\" = 4599 ]"
ok "  and the message went once" sent_once
ok "  and only the named agent was ever addressed" never_listed

new_case claude-weekly claude "$CLAUDE_WEEKLY" 2026-10-23T12:00:00Z
POLL=999999 run claude-weekly --max-wait 400000
# Oct 25 1am EDT = 05:00Z; from Oct 23 12:00Z that is 41 h = 147600 s, +120
ok "Claude weekly limit: waits to Oct 25 1am Toronto (147600 s + 120)" sh -c "[ $STATUS = 0 ] && [ \"$(total_sleep)\" = 147720 ]"
ok "  and sent once" sent_once

new_case claude-monthly claude "$CLAUDE_MONTHLY" 2026-10-23T12:00:00Z
POLL=999999 run claude-monthly --max-wait 400000
ok "Claude monthly spend limit: takes the weekly reset it names" sh -c "[ $STATUS = 0 ] && [ \"$(total_sleep)\" = 147720 ]"

new_case codex-time codex "$CODEX_TIME" 2026-10-22T20:00:00Z   # 16:00 Toronto, same zone as this machine
run codex-time
ok "Codex 'try again at 6:26 PM': waits 2h26m + 120s" sh -c "[ $STATUS = 0 ] && [ \"$(total_sleep)\" = 8880 ]"
ok "  and sent once" sent_once

new_case codex-dated codex "$CODEX_DATED" 2026-10-24T12:00:00Z
POLL=999999 run codex-dated --max-wait 400000
ok "Codex dated 'try again at Oct 25th, 2026 1:22 AM': waits to then (+120 s)" sh -c "[ $STATUS = 0 ] && [ \"$(total_sleep)\" = 62640 ]"

new_case omp-429 omp "$OMP_429"
run omp-429
ok "omp 429 rate_limit_error: waits its retry-after-ms (4479 s) + margin" sh -c "[ $STATUS = 0 ] && [ \"$(total_sleep)\" = 4599 ]"
ok "  and sent once" sent_once

new_case omp-label omp "$OMP_429"
cat >"$FX/on_sleep" <<EOF
#!/usr/bin/env bash
printf ' Ran the checks.\n\n %s\n\n  \xf3\xb0\x8a\x9a LIMIT: Session limit reached\n\xee\x82\xb6 Haiku 5.5 \xee\x82\xb1 /tmp\n╰─\n' '$OMP_429' >"$FX/pane.txt"
EOF
chmod +x "$FX/on_sleep"
run omp-label
ok "omp's title label appearing in its footer is not the owner: still sends" sh -c "[ $STATUS = 0 ]"
ok "  and sent once" sent_once

new_case unnamed claude "$UNNAMED"
run unnamed
ok "limit naming no time: waits the default 30 minutes then sends" sh -c "[ $STATUS = 0 ] && [ \"$(total_sleep)\" = 1800 ]"

new_case justpassed claude "$CLAUDE_SESSION" 2026-10-22T20:45:00Z   # 16:45, five minutes after the named 4:40pm
run justpassed
ok "reset passed minutes ago: sends at once, doesn't wait a day" sh -c "[ $STATUS = 0 ] && [ -z \"$(total_sleep)\" -o \"$(total_sleep)\" = 0 ]"

# ---- no limit found ----

new_case notlimit claude "$CLAUDE_SESSION"
printf '● All done. The tests pass.\n\n──────────\n❯\n──────────\n' >"$FX/pane.txt"
run notlimit
ok "an ordinary stop is not a limit: exit 3, nothing sent" sh -c "[ $STATUS = 3 ]"
ok "  and nothing was sent" sent_never

new_case working claude "$CLAUDE_SESSION"; echo working >"$FX/status"
run working
ok "agent still working: exit 3" status_is 3

new_case oldlimit claude "$CLAUDE_SESSION"
{ printf '  %s\n' "$CLAUDE_SESSION"; for i in $(seq 40); do echo "● later work $i"; done; } >"$FX/pane.txt"
run oldlimit
ok "a limit message far above later work is old: exit 3" status_is 3

new_case quoted claude "$CLAUDE_SESSION"
printf '● I found the real message: "You'"'"'ve hit your session limit · resets 4:40pm" in the records.\n\n──────────\n❯\n──────────\n' >"$FX/pane.txt"
run quoted
ok "a report that only quotes the words is not a limit: exit 3" status_is 3

# ---- the owner stepped in ----

new_case typed-before codex "$CODEX_TIME"; input "keep going, I fixed it" codex
run typed-before
ok "Codex input already holds text: exit 4, nothing sent" sh -c "[ $STATUS = 4 ]"
ok "  and nothing was sent" sent_never

new_case typed-during claude "$CLAUDE_SESSION"
cat >"$FX/on_sleep" <<EOF
#!/usr/bin/env bash
printf '\e[0m❯\xc2\xa0half a sentence\r\n' >"$FX/ansi.txt"
EOF
chmod +x "$FX/on_sleep"
run typed-during
ok "Claude: owner types while waiting: exit 4" status_is 4
ok "  and nothing was sent" sent_never
ok "  and says why" err_has "typed"

new_case typed-omp omp "$OMP_429"
cat >"$FX/on_sleep" <<EOF
#!/usr/bin/env bash
printf '\e[0m╰─ ok go\r\n' >"$FX/ansi.txt"
EOF
chmod +x "$FX/on_sleep"
run typed-omp
ok "omp: owner types while waiting: exit 4" status_is 4

new_case newer claude "$CLAUDE_SESSION"
cat >"$FX/on_sleep" <<EOF
#!/usr/bin/env bash
printf '● Reviewed the diff.\n\n  %s\n\n❯ carry on, I raised the limit\n● On it.\n──────────\n❯\n' "$CLAUDE_SESSION" >"$FX/pane.txt"
EOF
chmod +x "$FX/on_sleep"
run newer
ok "a newer message in the pane: exit 4, nothing sent" status_is 4
ok "  and nothing was sent" sent_never

new_case moved codex "$CODEX_TIME"
cat >"$FX/on_sleep" <<EOF
#!/usr/bin/env bash
echo working >"$FX/status"
EOF
chmod +x "$FX/on_sleep"
run moved
ok "the owner already restarted it (now working): exit 4, nothing sent" status_is 4
ok "  and nothing was sent" sent_never

# ---- the agent is gone ----

new_case gone-start claude "$CLAUDE_SESSION"; touch "$FX/gone"
run gone-start
ok "no such agent at the start: exit 5" status_is 5

new_case gone-wait claude "$CLAUDE_SESSION"
cat >"$FX/on_sleep" <<EOF
#!/usr/bin/env bash
touch "$FX/gone"
EOF
chmod +x "$FX/on_sleep"
run gone-wait
ok "agent closed while waiting: exit 5, nothing sent" status_is 5
ok "  and nothing was sent" sent_never

new_case replaced omp "$OMP_429"
cat >"$FX/on_sleep" <<EOF
#!/usr/bin/env bash
echo w3:pZZ >"$FX/pane_id"
EOF
chmod +x "$FX/on_sleep"
run replaced
ok "the name now sits on another pane: exit 5, nothing sent" status_is 5
ok "  and nothing was sent" sent_never

# ---- the wait runs too long ----

new_case toolong claude "$CLAUDE_WEEKLY" 2026-10-23T12:00:00Z
run toolong
ok "weekly reset beyond the 8 h default: exit 6 at once, nothing sent" status_is 6
ok "  and it never slept" sh -c "[ -z \"$(total_sleep)\" -o \"$(total_sleep)\" = 0 ]"
ok "  and nothing was sent" sent_never

# ---- never twice, never in workspace 9, bad input ----

new_case twice claude "$CLAUDE_SESSION"
run twice
first=$STATUS
echo idle >"$FX/status"   # the agent stopped on the limit again, same screen
run twice
ok "a second run for the same stop: exit 8, and the message went once" sh -c "[ $first = 0 ] && [ $STATUS = 8 ]"
ok "  still one message" sent_once

new_case lock claude "$CLAUDE_SESSION"
cat >"$FX/on_sleep" <<EOF
#!/usr/bin/env bash
PATH="$ROOT/bin:$PATH" HERDR=herdr LIMIT_WAIT_STATE="$ROOT/state-lock" "$SCRIPT" agentx >"$FX/second.out" 2>&1
echo \$? >"$FX/second.status"
EOF
chmod +x "$FX/on_sleep"
run lock
ok "two waits at once on one agent: the second exits 8, one message sent" sh -c "[ $STATUS = 0 ] && [ \"$(cat "$FX/second.status")\" = 8 ]"
ok "  one message" sent_once

new_case w9 claude "$CLAUDE_SESSION"; echo w9 >"$FX/workspace"
run w9
ok "agent in workspace w9: exit 8, only 'agent get' was called" sh -c "[ $STATUS = 8 ] && [ \"\$(cat $FX/calls.log)\" = 'agent get agentx' ]"

new_case deaf claude "$CLAUDE_SESSION"; touch "$FX/deaf"
run deaf
ok "message sent but the agent never works: exit 7, sent once, not resent" sh -c "[ $STATUS = 7 ]"
ok "  one message" sent_once

STATUS=; ERR=$(PATH="$ROOT/bin:$PATH" "$SCRIPT" w3:pF2 2>&1 >/dev/null); STATUS=$?
ok "a pane id is not an agent name: exit 2" status_is 2

[ "$FAILED" = 0 ] && echo "all passed" || { echo "FAILURES"; exit 1; }
