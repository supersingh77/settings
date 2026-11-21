# Shell Configuration — ~/.bashrc

**File**: `~/.bashrc` | **Shell**: bash (Fedora Silverblue default)
This is the documented target configuration, not a live dump of `~/.bashrc`.

The `~/.bashrc` is the user shell configuration loaded for every interactive bash session. On Fedora Silverblue, the host OS is immutable — the shell environment is one of the few things fully under your control.

---

## Current ~/.bashrc

```bash
# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Source ~/.bashrc.d/*.sh fragments (if any)
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc

# settings repo aliases (commands live in ~/.local/bin via install-links.sh)
alias docs='cd ~/Desktop/settings/device/fedora-laptop'
alias update='update-system'
alias update-openwork='update-openwork'
alias update-uad='update-uad'
alias update-antigravity='update-antigravity'
alias cleanup='cleanup-system'
alias uad='launch-uad'
```

---

## PATH

`~/.local/bin` and `~/bin` are prepended to `$PATH` at login. This is where user-installed binaries live:

| Binary | Purpose |
|--------|---------|
| `openwork` | Wrapper script for OpenWork AppImage (`~/.local/lib/openwork/AppRun --no-sandbox`) |
| `uad-ng` | UAD-NG Android debloater — installed by `bootstrap.sh` |

---

## Aliases Reference

### System Management

| Alias | Expands To | Purpose |
|-------|-----------|---------|
| `update` | `bash .../scripts/update-system.sh` | Fast daily update: Flatpaks + OpenWork + UAD-NG + Antigravity + Fedora Toolbox + rpm-ostree |
| `update-openwork` | `bash .../scripts/update-openwork.sh` | OpenWork AppImage update only (idempotent) |
| `update-uad` | `bash .../scripts/update-uad.sh` | UAD-NG binary update only (idempotent) |
| `update-antigravity` | `bash .../scripts/update-antigravity.sh` | Antigravity 2.0 Hub update only (idempotent) |
| `cleanup` | `bash .../scripts/cleanup-system.sh` | Slow maintenance: Btrfs scrub + Flatpak unused-runtime removal + rpm-ostree deployment cleanup + journal vacuum + DNS cache flush + GNOME Trash emptying |

### Navigation

| Alias | Expands To | Purpose |
|-------|-----------|---------|
| `docs` | `cd ~/Desktop/settings/device/fedora-laptop` | Jump to the system config repo |

### Applications

| Alias | Expands To | Purpose |
|-------|-----------|---------|
| `uad` | `bash .../scripts/launch-uad.sh` | Launch UAD-NG Android debloater with ADB checks |



## How Aliases Are Set Up

Aliases are written to `~/.bashrc` by the setup scripts. The block is marked with a comment header (`# settings repo aliases`) to prevent duplicates. The commands they call (`update-system`, `cleanup-system`, etc.) are symlinked into `~/.local/bin/` by `scripts/install-links.sh`, so they work from anywhere:

```bash
# In bootstrap.sh or setup-phase3.sh:
ALIAS_MARKER="# settings repo aliases"
if grep -q "$ALIAS_MARKER" "$BASHRC" 2>/dev/null; then
    warn "Aliases already present, skipping."
else
    cat >> "$BASHRC" << 'ALIASES'
    # ... aliases appended here
ALIASES
fi
```

> ⚠️ **If you manually edit `~/.bashrc`** and the marker line is present, re-running any setup script will skip writing aliases — this is intentional. Edit the block directly if you need to add or change aliases.

---

## Activating Changes

After editing `~/.bashrc`, reload it in the current shell:

```bash
source ~/.bashrc
```

New terminal windows automatically get the updated environment.

---

## Adding a New Alias

Add it to the `# settings repo aliases` block in `~/.bashrc`:

```bash
# Example
alias myalias='some-command --with-flags'
```

Then `source ~/.bashrc` to use it immediately.
