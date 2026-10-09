# Personal Config & Life Log

This repository is a practical, centralized record of system configurations, device setups, issue tracking, and personal workflows — across all my devices (Windows desktop, Windows laptop, Fedora laptop, phone).

It is intentionally designed to grow organically: start with raw thoughts, process them into structured modules, and maintain a clear history across multiple devices.

---

## Directory Map

| Area | Purpose & Contents |
|---|---|
| [`inbox/`](inbox/) | Raw, unsorted notes, quick thoughts, and incoming ideas to be processed later |
| [`outbox/`](outbox/) | Agent's outgoing work — ready to dispatch to another chat/app/agent |
| [`device/`](device/) | Per-device setup notes, hardware specs, installed software, maintenance logs, and per-device scripts |
| [`notes/`](notes/) | Long-term reference guides, workflows, and technical decisions |
| [`games/`](games/) | Game settings and controller configuration backups |

> Scripts live inside their owning device folder (e.g. [`device/desktop/scripts/`](device/desktop/scripts/)), not in a shared top-level `scripts/`.

---

## Data & Information Workflow

To keep logging frictionless, raw information enters through **intake points** and is progressively structured into canonical records.

```text
┌──────────────────────────────┐
│      Incoming Raw Input      │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│           inbox/             │
│  (Loose ideas, draft notes)  │
└──────────────┬───────────────┘
               │ (Process & Structuring)
               ▼
┌──────────────────────────────┐
│ Feature Specs & Guides       │
│ (device/, notes/, games/)    │
└──────────────────────────────┘
```

### 1. Capture First (`inbox/`)
- Create a quick Markdown file in [`inbox/`](inbox/). Include title, device metadata, date, and core thoughts.

### 2. Process Later
- Move or distill inbox ideas into dedicated folders ([`device/`](device/), [`notes/`](notes/), [`games/`](games/)).
- Use [`outbox/`](outbox/) for work that needs to be dispatched elsewhere.

---

## Multi-Device Workflow (Desktop, Laptops, Phone)

This repository is shared across multiple machines (Windows desktop, Windows laptop, Fedora laptop, phone). Follow this standard routine to prevent sync conflicts:

1. **Before starting work on any machine**:
   ```bash
   git pull origin main
   ```
2. **When creating raw notes**:
   Include standard header metadata so context is clear across devices:
   ```markdown
   # Topic Title
   > Device: desktop (or laptop, fedora-laptop, phone)
   > Added: YYYY-MM-DD
   ```
3. **After completing a task or capturing notes**:
   ```bash
   git add .
   git commit -m "Brief description of changes"
   git push origin main
   ```

> **Note:** The Fedora laptop's full setup (scripts, docs, hardware) lives in
> [`device/fedora-laptop/`](device/fedora-laptop/). Its `update`/`cleanup`
> automation inspired the Windows laptop's [`cleanup-system.ps1`](device/laptop/scripts/cleanup-system.ps1).

---

## Agent & AI Collaboration Rules

When an AI agent assists with this repository, it must follow these principles:

1. **Fidelity of Canonical Data**: Never summarize away, re-categorize, or aggregate historical data without explicit instruction.
2. **No Invented Values**: Do guess values, balances, or specs. Mark unverified values as `needs-review`.
3. **Preserve Provenance**: Keep original inbox notes as provenance until feature specs are fully implemented and verified.
4. **Clean Commits**: Commit changes with clear, concise messages and verify `git status` before completing turns.
5. **Step-by-Step**: Work in small steps, commit after each — don't batch everything into one giant change.

---

## Privacy & Security

This repository contains personal system configurations. Treat repository access as private and verify contents before publishing or sharing publicly.
