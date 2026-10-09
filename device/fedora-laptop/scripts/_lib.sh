#!/bin/bash
# =============================================================================
# _lib.sh — Shared functions for fedora-laptop scripts
#
# Source this file at the top of any script:
#   SCRIPT_DIR="$(dirname "$(realpath "$0")")"
#   source "$SCRIPT_DIR/_lib.sh"
#
# Provides: color variables, logging helpers, download_file()
# =============================================================================

BOLD="\e[1m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
RED="\e[31m"
RESET="\e[0m"

info()    { echo -e "${CYAN}ℹ️  $*${RESET}"; }
success() { echo -e "${GREEN}✅ $*${RESET}"; }
warn()    { echo -e "${YELLOW}⚠️  $*${RESET}"; }
error()   { echo -e "${RED}❌ $*${RESET}"; exit 1; }
step()    { echo -e "\n${BOLD}━━━ $* ━━━${RESET}"; }

# ── Helper: fast parallel download ─────────────────────────────────────────
# Downloads a file using the parallel downloader if available, otherwise wget.
# Usage: download_file <url> <destination>
SCRIPT_DIR_FOR_DL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOWNLOADER="${SCRIPT_DIR_FOR_DL}/parallel-download.py"

download_file() {
    local url="$1"
    local dest="$2"
    if [ -f "$DOWNLOADER" ]; then
        info "Downloading with parallel downloader (16 connections)…"
        python3 "$DOWNLOADER" "$url" "$dest" 16 \
            && return 0 \
            || { warn "Parallel download failed — trying wget."; }
    fi
    wget --show-progress -O "$dest" "$url" \
        && return 0 \
        || return 1
}

# ── Helper: run a command, log result, never abort script ──────────────────
# Only used by update-system.sh which intentionally ignores errors.
run_or_warn() {
    local description="$1"
    shift
    if "$@"; then
        return 0
    else
        warn "${description} — continuing anyway."
        return 1
    fi
}
