# OpenWork

**Source**: https://github.com/different-ai/openwork | **Install**: `~/.local/lib/openwork/`

**Version last recorded in the updater tracker**: `0.18.56` (2026-10-08; confirm after the current update run).

> OpenWork is distributed as an AppImage for Linux, but to bypass the FUSE requirement on Silverblue, the update script extracts the AppImage to `~/.local/lib/openwork` and creates a wrapper executable in your PATH.

---

## Running OpenWork

```bash
openwork                                    # via CLI or App Launcher
~/.local/lib/openwork/openwork --no-sandbox # directly (extracted executable)
```

---

## Architecture

```
┌───────────────────────────────────────────┐
│     OpenWork (Electron)                   │
│     Native browser MCP, in-process server │
└───────────────┬───────────────────────────┘
                 ↕ HTTP/SSE
┌───────────────────────────────────────────┐
│     OpenCode Server (Port 4096)           │
│     AI coding, LSP ops, sessions          │
└───────────────────────────────────────────┘
```

### Bundled binaries (inside `~/.local/lib/openwork/`)

| Binary | Size | Purpose |
|--------|------|---------|
| `OpenWork-Dev` | ~11 MB | Main Electron GUI |
| `opencode` | ~153 MB | AI coding assistant |
| `openwork-server` | ~100 MB | Backend server |
| `openwork-orchestrator` | ~109 MB | Orchestration layer |
| `opencode-router` | ~101 MB | Request routing |
| `chrome-devtools-mcp` | ~100 MB | Chrome DevTools MCP bridge |

**Total AppImage**: ~206 MB — fully self-contained, no Rust/Bun/Node.js needed on the host.

### Extension System

- **Skills**: Markdown files in `.opencode/skills/`, install via `opkg`
- **Commands**: Slash commands in `.opencode/commands/`
- **Plugins**: TypeScript/JavaScript with scoped permissions
- **MCP**: Authenticated third-party integrations (OAuth)

### User Data (host filesystem)

```
~/.opencode/           # Config & extensions
~/.config/openwork/    # App settings
~/.local/bin/openwork  # The wrapper script
~/.local/lib/openwork/ # The extracted app files
~/.local/bin/openwork.version    # Installed version tracker
```

---

## Install / Update

Handled by `scripts/setup-user.sh` (initial install) and `scripts/update-system.sh` (updates). Run manually:

```bash
update-openwork        # check for updates and install if newer
update                 # full system update (includes OpenWork)
```

### Check installed version

```bash
cat ~/.local/bin/openwork.version
```

---

## Troubleshooting

```bash
# Check version file
cat ~/.local/bin/openwork.version

# Reinstall from scratch
rm -rf ~/.local/lib/openwork ~/.local/bin/openwork ~/.local/bin/openwork.version
update-openwork
```
