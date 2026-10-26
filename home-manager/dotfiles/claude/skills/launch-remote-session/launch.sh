#!/usr/bin/env bash
# Launch an interactive `claude --remote-control` session in a transient
# systemd user unit, and print its claude.ai/code URL.
#
# See SKILL.md for the rationale behind the details here.
set -euo pipefail

usage() {
    cat >&2 <<EOF
usage: $0 [options] [DIR]

Start (or resume) a Claude Code session in DIR with Remote Control enabled.

  --name NAME              Session title shown in claude.ai/code and the app
  --resume ID              Resume a conversation: a local session UUID, or a
                           claude.ai/code session ID/URL this machine served
  --continue               Resume the most recent conversation in DIR
  --permission-mode MODE   Starting permission mode (default, acceptEdits,
                           auto, plan, ...)
  --timeout SECS           How long to wait for the session URL (default 60)
  --list                   List recent conversations in DIR instead of launching

DIR is required unless --resume is given, in which case it defaults to the
directory the conversation ran in.
EOF
    exit 2
}

dir=
name=
resume=
cont=
perm=
list=
timeout=60
while [ $# -gt 0 ]; do
    case "$1" in
    --name) name=$2; shift 2 ;;
    --resume) resume=$2; shift 2 ;;
    --continue) cont=1; shift ;;
    --permission-mode) perm=$2; shift 2 ;;
    --timeout) timeout=$2; shift 2 ;;
    --list) list=1; shift ;;
    -h | --help) usage ;;
    -*) echo "unknown option: $1" >&2; usage ;;
    *)
        [ -z "$dir" ] || usage
        dir=$1; shift
        ;;
    esac
done

[ -n "$resume" ] && [ -n "$cont" ] && { echo "--resume and --continue are exclusive" >&2; exit 2; }

projects=$HOME/.claude/projects

# Claude stores transcripts under a directory named after the cwd with every
# non-alphanumeric character replaced by '-'.
project_dir() {
    printf '%s/%s' "$projects" "$(printf '%s' "$1" | sed 's/[^A-Za-z0-9]/-/g')"
}

transcript_cwd() {
    grep -m1 -o '"cwd":"[^"]*"' "$1" | sed 's/^"cwd":"//; s/"$//'
}

# Resolve --resume to a transcript file.
transcript=
if [ -n "$resume" ]; then
    if [[ "$resume" =~ (session_[A-Za-z0-9]+) ]]; then
        sid=${BASH_REMATCH[1]}
        transcript=$(grep -l -F "\"url\":\"https://claude.ai/code/$sid\"" "$projects"/*/*.jsonl 2>/dev/null |
            xargs -r ls -t | head -n1 || true)
        if [ -z "$transcript" ]; then
            echo "No local transcript records Remote Control session $sid." >&2
            echo "Find the local session UUID instead (e.g. with --list DIR)." >&2
            exit 1
        fi
    elif [[ "$resume" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]]; then
        transcript=$(ls -t "$projects"/*/"$resume".jsonl 2>/dev/null | head -n1 || true)
        [ -n "$transcript" ] || { echo "No transcript found for session $resume" >&2; exit 1; }
    else
        echo "Don't know how to resume '$resume': expected a session UUID or claude.ai/code session ID" >&2
        exit 1
    fi
    resume=$(basename "$transcript" .jsonl)
    if [ -z "$dir" ]; then
        dir=$(transcript_cwd "$transcript")
        [ -n "$dir" ] || { echo "Can't determine directory for $resume; pass DIR" >&2; exit 1; }
    fi
fi

[ -n "$dir" ] || usage
[ -d "$dir" ] || { echo "Not a directory: $dir" >&2; exit 1; }
dir=$(cd "$dir" && pwd -P)
pdir=$(project_dir "$dir")

if [ -n "$list" ]; then
    ls -t "$pdir"/*.jsonl 2>/dev/null | head -n 20 | while read -r f; do
        prompt=$(jq -r 'select(.type == "user" and (.message.content | type) == "string")
                        | .message.content' "$f" 2>/dev/null | head -n1 | cut -c1-80)
        printf '%s  %s  %s\n' "$(basename "$f" .jsonl)" "$(date -r "$f" '+%F %R')" "$prompt"
    done
    exit 0
fi

if [ -n "$cont" ]; then
    transcript=$(ls -t "$pdir"/*.jsonl 2>/dev/null | head -n1 || true)
    [ -n "$transcript" ] || { echo "No previous conversations in $dir" >&2; exit 1; }
    resume=$(basename "$transcript" .jsonl)
fi

if [ -n "$transcript" ] && [ "$(transcript_cwd "$transcript")" != "$dir" ]; then
    echo "warning: $resume ran in $(transcript_cwd "$transcript"), not $dir" >&2
fi

shell=$(command -v zsh || command -v bash)
script=$(command -v script)

args=(claude --remote-control)
[ -n "$name" ] && args+=("$name")
args+=(--remote-control-session-name-prefix "$(hostname -s):$(basename "$dir")")
[ -n "$perm" ] && args+=(--permission-mode "$perm")
if [ -n "$resume" ]; then
    args+=(--resume "$resume")
    offset=$(stat -c %s "$transcript")
else
    resume=$(cat /proc/sys/kernel/random/uuid)
    args+=(--session-id "$resume")
    transcript=$pdir/$resume.jsonl
    offset=0
fi

unit="claude-rc-$(basename "$dir" | sed 's/[^A-Za-z0-9_-]/_/g')-${resume:0:8}"

# Print the newest Remote Control URL recorded in the transcript after byte $1.
find_url() {
    [ -f "$transcript" ] || return 0
    tail -c +$(($1 + 1)) "$transcript" |
        grep '"subtype":"bridge_status"' |
        grep -o '"url":"https://claude.ai/code/[^"]*"' | tail -n1 | sed 's/^"url":"//; s/"$//' || true
}

report() {
    echo "unit:       $unit"
    echo "directory:  $dir"
    echo "session:    $resume"
    echo "url:        $1"
}

if systemctl --user is-active --quiet "$unit"; then
    echo "Already running." >&2
    report "$(find_url 0)"
    exit 0
fi

# - `zsh -i` gives claude the same environment as a fresh terminal, rather
#   than inheriting this (possibly Claude-spawned) process's environment.
# - `script` provides the pty an interactive claude needs. Nothing reads it,
#   and its output is discarded so TUI redraws don't flood the journal.
inner="exec $(printf '%q ' "${args[@]}")"
systemd-run --user --quiet --collect \
    --unit="$unit" \
    --description="claude --remote-control in $dir" \
    --working-directory="$dir" \
    --setenv=SHELL="$shell" \
    --setenv=TERM=xterm-256color \
    --property=StandardOutput=null \
    -- "$script" -qfec "$(printf '%q ' "$shell" -i -c "$inner")" /dev/null

fail() {
    echo "$1" >&2
    journalctl --user -u "$unit" -o cat --no-pager -n 20 >&2 || true
    systemctl --user stop "$unit" 2>/dev/null || true
    exit 1
}

url=
deadline=$((SECONDS + timeout))
while [ $SECONDS -lt $deadline ]; do
    systemctl --user is-active --quiet "$unit" || fail "claude exited before Remote Control connected."
    url=$(find_url "$offset")
    [ -n "$url" ] && break
    sleep 1
done
[ -n "$url" ] || fail "Timed out after ${timeout}s waiting for Remote Control to connect.
The usual cause is that $dir is not trusted yet: run \`claude\` there in a
terminal once and accept the trust prompt, then try again."

report "$url"
