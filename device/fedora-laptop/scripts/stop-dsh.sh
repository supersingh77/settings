#!/bin/bash
set -u

PID_FILE="$HOME/.local/share/dsh/dsh.pid"

stopped=0
if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    kill "$(cat "$PID_FILE")" 2>/dev/null || true
    stopped=1
fi

pkill -f '@deepseek-ai/dsh web' 2>/dev/null || true

rm -f "$PID_FILE"

if [ "$stopped" = "1" ]; then
    echo "DeepSeek Harness stopped."
else
    echo "DeepSeek Harness was not running."
fi
