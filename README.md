# Redacto Claude Code plugins

Internal plugin marketplace for Claude Code. Pushed to developer Macs via Fleet as a managed setting;
nothing here needs a user to install anything by hand.

## redacto-semgrep

Scans every file Claude Code writes or edits with the **open-source Semgrep CLI** and hands the findings
back to Claude so it fixes them before moving on.

- No Semgrep account or login. No telemetry (`--metrics off`). No upgrade nags.
- Rules: public registry packs `p/default` + `p/secrets` (override per user with `REDACTO_SEMGREP_CONFIG`).
- Fails open: if semgrep is missing or the registry is unreachable, the write goes through and the skip is
  logged to `~/.redacto-semgrep.log`. Nothing blocks a developer.
- Skips: `node_modules`, `.git`, `vendor`, `dist`, `build`, lockfiles, minified assets, docs/images.

### Requirements on the Mac

`semgrep` on PATH (`brew install semgrep`). The Fleet rollout script installs it.

### Manual install (for testing)

```
claude --plugin-dir /path/to/claude-plugins/plugins/redacto-semgrep
```

or:

```
/plugin marketplace add redactolabs/claude-plugins
/plugin install redacto-semgrep@redacto
```

### Managed rollout

`/Library/Application Support/ClaudeCode/managed-settings.d/10-redacto-plugins.json`:

```json
{
  "extraKnownMarketplaces": {
    "redacto": { "source": { "source": "github", "repo": "redactolabs/claude-plugins" } }
  },
  "enabledPlugins": {
    "redacto-semgrep@redacto": true,
    "security-guidance@claude-plugins-official": true
  }
}
```
