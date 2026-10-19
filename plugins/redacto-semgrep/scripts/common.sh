#!/bin/bash
# Shared setup for redacto-semgrep hooks.

# Find semgrep wherever it was installed (brew, pipx, pip --user, native).
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH"
for d in "$HOME"/Library/Python/3.*/bin; do [ -d "$d" ] && PATH="$d:$PATH"; done
export PATH

# Open-source CLI only: no telemetry, no version nag, no login.
export SEMGREP_SEND_METRICS=off
export SEMGREP_ENABLE_VERSION_CHECK=0
export OTEL_SDK_DISABLED=true

# Rulesets (public Semgrep registry, no account needed). Override per-user with REDACTO_SEMGREP_CONFIG.
REDACTO_SEMGREP_CONFIG="${REDACTO_SEMGREP_CONFIG:-p/default p/secrets}"

LOG="${HOME}/.redacto-semgrep.log"
log() { printf '%s %s\n' "$(date '+%F %T')" "$*" >> "$LOG" 2>/dev/null; }

semgrep_config_args() {
  local c; for c in $REDACTO_SEMGREP_CONFIG; do printf -- '--config\n%s\n' "$c"; done
}
