#!/bin/bash

BOLD="\e[1m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
RED="\e[31m"
RESET="\e[0m"

info() { echo -e "${CYAN}ℹ️  $*${RESET}"; }
success() { echo -e "${GREEN}✅ $*${RESET}"; }
warn() { echo -e "${YELLOW}⚠️  $*${RESET}"; }
error() {
    echo -e "${RED}❌ $*${RESET}"
    exit 1
}
step() { echo -e "\n${BOLD}━━━ $* ━━━${RESET}"; }

SCRIPT_DIR_FOR_DL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

download_file() {
    local url="$1"
    local destination="$2"
    if python3 "$SCRIPT_DIR_FOR_DL/parallel-download.py" "$url" "$destination" 16; then
        return 0
    fi
    warn "Parallel download failed; retrying with wget."
    wget --show-progress -O "$destination" "$url"
}

run_or_warn() {
    local description="$1"
    shift
    if "$@"; then
        return 0
    fi
    warn "${description} — continuing anyway."
    return 1
}
