#!/bin/bash
set -u

LOG_DIR="$HOME/.local/share/dsh"
LOG_FILE="$LOG_DIR/dsh.log"
PID_FILE="$LOG_DIR/dsh.pid"
URL="http://127.0.0.1:3080/"

mkdir -p "$LOG_DIR"

if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "DeepSeek Harness is already running (PID $(cat "$PID_FILE"))."
    echo "Open:   $URL"
    echo "Log:    $LOG_FILE"
    echo "Stop with: dsh-stop"
    exit 0
fi

if ss -ltn 2>/dev/null | grep -q ':3080'; then
    echo "DeepSeek Harness is already running on port 3080."
    echo "Open:   $URL"
    echo "Log:    $LOG_FILE"
    echo "Stop with: dsh-stop"
    exit 0
fi

nohup toolbox run -c fedora-toolbox-44 sh -lc \
    'npx --yes @deepseek-ai/dsh web --no-open --port 3080' \
    > "$LOG_FILE" 2>&1 &
echo $! > "$PID_FILE"

echo "Starting DeepSeek Harness Web UI (PID $(cat "$PID_FILE"))..."
echo "Open:   $URL"
echo "Log:    $LOG_FILE"
echo "Stop with: dsh-stop"
