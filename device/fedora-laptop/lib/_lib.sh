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

download_file() {
    local url="$1"
    local destination="$2"
    if command -v curl &>/dev/null; then
        curl -fL --progress-bar -o "$destination" "$url"
    elif command -v wget &>/dev/null; then
        wget --show-progress -O "$destination" "$url"
    else
        error "Neither curl nor wget is available."
    fi
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
