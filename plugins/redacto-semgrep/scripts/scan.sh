#!/bin/bash
# PostToolUse hook (Write|Edit|MultiEdit|NotebookEdit):
# scan the file Claude just wrote with open-source Semgrep and hand findings back to Claude.
# Fails OPEN: any problem with semgrep/rules/network → exit 0 silently (logged to ~/.redacto-semgrep.log).
. "$(dirname "$0")/common.sh"

input=$(cat)

# Extract the target file path from the hook payload.
file=$(printf '%s' "$input" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin); ti = d.get("tool_input", {})
    print(ti.get("file_path") or ti.get("notebook_path") or ti.get("path") or "")
except Exception:
    print("")' 2>/dev/null)
[ -z "$file" ] && file=$(printf '%s' "$input" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)

[ -z "$file" ] && exit 0
[ -f "$file" ] || exit 0
case "$file" in
  */node_modules/*|*/.git/*|*/vendor/*|*/dist/*|*/build/*|*.lock|*.min.js|*.min.css|*.md|*.txt|*.svg|*.png|*.jpg) exit 0 ;;
esac

command -v semgrep >/dev/null 2>&1 || { log "semgrep not on PATH, skipped $file"; exit 0; }

# shellcheck disable=SC2046
out=$(semgrep scan $(semgrep_config_args | tr '\n' ' ') \
        --metrics off --quiet --json --timeout 20 --max-target-bytes 2000000 \
        "$file" 2>>"$LOG")
rc=$?

# No parseable JSON → registry/network/CLI problem. Fail open.
case "$out" in \{*) ;; *) log "semgrep rc=$rc, no JSON output for $file"; exit 0 ;; esac

printf '%s' "$out" | python3 -c '
import sys, json, os
d = json.load(sys.stdin)
res = d.get("results", [])
if not res:
    sys.exit(0)
sev_rank = {"ERROR": 0, "WARNING": 1, "INFO": 2}
res.sort(key=lambda r: (sev_rank.get(r.get("extra", {}).get("severity", "INFO"), 3), r.get("start", {}).get("line", 0)))
path = res[0].get("path", "")
lines = [f"Redacto Semgrep found {len(res)} issue(s) in {path}:"]
for r in res[:15]:
    e = r.get("extra", {})
    sev = e.get("severity", "INFO")
    rule = r.get("check_id", "").split(".")[-1]
    line = r.get("start", {}).get("line", "?")
    msg = " ".join(e.get("message", "").split())[:220]
    lines.append(f"  [{sev}] {rule} @ line {line}: {msg}")
if len(res) > 15:
    lines.append(f"  ... and {len(res) - 15} more")
lines.append("Fix these in the file you just wrote (parameterize queries, avoid shell=True/eval, remove hardcoded secrets) unless the user explicitly asked for vulnerable code. Re-scan happens automatically on your next write.")
print(json.dumps({"decision": "block", "reason": "\n".join(lines)}))
' 2>>"$LOG"
exit 0
