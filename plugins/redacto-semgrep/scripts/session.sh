#!/bin/bash
# SessionStart hook: one quiet status line, and pre-warm the rules cache in the background.
. "$(dirname "$0")/common.sh"

if ! command -v semgrep >/dev/null 2>&1; then
  echo "Redacto Semgrep: semgrep CLI not found — writes are NOT being scanned. Run: brew install semgrep"
  exit 0
fi

ver=$(semgrep --version 2>/dev/null | tail -n1)
if [ -z "$ver" ]; then
  echo "Redacto Semgrep: semgrep CLI found but not runnable — writes are NOT being scanned. Try: brew reinstall semgrep"
  exit 0
fi
echo "Redacto Semgrep (open-source): active — semgrep ${ver}, rules: ${REDACTO_SEMGREP_CONFIG}"

# Pre-fetch rules so the first file write doesn't wait on the registry. Detached, silent.
# shellcheck disable=SC2046
( nohup semgrep scan $(semgrep_config_args | tr '\n' ' ') --metrics off --quiet --json /dev/null >/dev/null 2>&1 & ) 2>/dev/null
exit 0
