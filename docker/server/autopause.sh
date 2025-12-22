#!/bin/bash
# Auto-pause script with TCP proxy - pauses server when idle, shows message on wake
#
# Architecture:
# - External clients connect to port 25565 (PROXY_PORT)
# - When running: socat forwards traffic to internal Minecraft on port 25566
# - When paused: Python wake-listener shows "server starting" message and triggers wake
#
# Pause conditions (all must be true for AUTOPAUSE_TIMEOUT minutes):
#   1. No players online
#   2. Chunker not actively generating
#
# Wake condition:
#   - Client connection attempt (login, not just status ping)

set -o pipefail

# Configuration
AUTOPAUSE_TIMEOUT=${AUTOPAUSE_TIMEOUT:-10}
AUTOPAUSE_POLL_INTERVAL=${AUTOPAUSE_POLL_INTERVAL:-30}
CHUNKER_ACTIVITY_THRESHOLD=120
RCON_HOST="localhost"
RCON_PORT="${RCON_PORT:-25575}"
RCON_PASSWORD="${RCON_PASSWORD:-minecraft}"

# Ports
PROXY_PORT=25565
MC_PORT=25566

# State files
WAKE_SIGNAL="/tmp/autopause_wake"

# State
IDLE_SECONDS=0
PAUSED=false
JAVA_PID=""
SOCAT_PID=""
LISTENER_PID=""
RCON_FAIL_COUNT=0

log() {
    echo "[AutoPause] $(date '+%H:%M:%S') $1"
}

rcon() {
    mcrcon -H "$RCON_HOST" -P "$RCON_PORT" -p "$RCON_PASSWORD" "$@" 2>/dev/null
}

get_player_count() {
    local result
    result=$(rcon "list" 2>/dev/null) || { echo "-1"; return; }
    result=$(echo "$result" | sed 's/\x1b\[[0-9;]*m//g')
    if echo "$result" | grep -qi "There are"; then
        echo "$result" | sed -n 's/.*There are \([0-9]*\).*/\1/p' | head -1
    else
        echo "-1"
    fi
}

is_chunker_active() {
    local now
    now=$(date +%s)
    for progress_file in /data/*_pregenerator.txt /data/plugins/Chunker/*.txt; do
        if [ -f "$progress_file" ]; then
            local mtime
            # Use date -r for Alpine/BusyBox compatibility (stat -c doesn't work)
            mtime=$(date -r "$progress_file" +%s 2>/dev/null || echo "0")
            local age=$((now - mtime))
            if [ "$age" -lt "$CHUNKER_ACTIVITY_THRESHOLD" ]; then
                return 0
            fi
        fi
    done
    return 1
}

find_java_pid() {
    pgrep -f "paper.jar" || pgrep -f "java.*-jar" || echo ""
}

start_proxy() {
    stop_proxy
    log "Starting proxy: $PROXY_PORT -> $MC_PORT"
    socat TCP-LISTEN:$PROXY_PORT,fork,reuseaddr TCP:127.0.0.1:$MC_PORT &
    SOCAT_PID=$!
}

stop_proxy() {
    if [ -n "$SOCAT_PID" ] && kill -0 "$SOCAT_PID" 2>/dev/null; then
        kill "$SOCAT_PID" 2>/dev/null || true
        wait "$SOCAT_PID" 2>/dev/null || true
    fi
    SOCAT_PID=""
    pkill -f "socat.*$PROXY_PORT" 2>/dev/null || true
}

start_wake_listener() {
    stop_wake_listener
    rm -f "$WAKE_SIGNAL"
    log "Starting wake listener on port $PROXY_PORT"
    python3 /wake-listener.py "$PROXY_PORT" "$WAKE_SIGNAL" &
    LISTENER_PID=$!
}

stop_wake_listener() {
    if [ -n "$LISTENER_PID" ] && kill -0 "$LISTENER_PID" 2>/dev/null; then
        kill "$LISTENER_PID" 2>/dev/null || true
        wait "$LISTENER_PID" 2>/dev/null || true
    fi
    LISTENER_PID=""
    pkill -f "wake-listener.py" 2>/dev/null || true
}

check_wake_signal() {
    if [ -f "$WAKE_SIGNAL" ]; then
        rm -f "$WAKE_SIGNAL"
        return 0
    fi
    return 1
}

pause_server() {
    if [ "$PAUSED" = "true" ]; then return; fi

    JAVA_PID=$(find_java_pid)
    if [ -z "$JAVA_PID" ]; then
        log "Cannot find Java process"
        return
    fi

    log "Pausing server (PID: $JAVA_PID)..."
    stop_proxy
    kill -STOP "$JAVA_PID" 2>/dev/null || true
    PAUSED=true
    start_wake_listener
}

resume_server() {
    if [ "$PAUSED" = "false" ]; then return; fi

    stop_wake_listener
    JAVA_PID=$(find_java_pid)
    if [ -n "$JAVA_PID" ]; then
        log "Resuming server (PID: $JAVA_PID)..."
        kill -CONT "$JAVA_PID" 2>/dev/null || true
    fi

    PAUSED=false
    IDLE_SECONDS=0

    # Wait for server to become responsive before starting proxy
    log "Waiting for server to be responsive..."
    local attempts=0
    while ! rcon "list" > /dev/null 2>&1; do
        sleep 1
        attempts=$((attempts + 1))
        if [ "$attempts" -ge 30 ]; then
            log "Server not responding after 30s, starting proxy anyway"
            break
        fi
    done
    start_proxy
    log "Server resumed and proxy started"
}

wait_for_server() {
    log "Waiting for server to be ready..."
    until rcon "list" > /dev/null 2>&1; do
        sleep 5
    done
    log "Server is ready"
    start_proxy
    log "Proxy started, monitoring for idle..."
}

main_loop() {
    local timeout_seconds=$((AUTOPAUSE_TIMEOUT * 60))

    while true; do
        if [ "$PAUSED" = "true" ]; then
            # Check for wake signal
            if check_wake_signal; then
                log "Wake signal received, resuming server..."
                resume_server
            fi
            # Re-start listener if it died
            if ! kill -0 "$LISTENER_PID" 2>/dev/null; then
                start_wake_listener
            fi
            sleep 1
            continue
        fi

        local player_count
        player_count=$(get_player_count)

        if [ "$player_count" = "-1" ]; then
            # RCON failed - don't reset idle timer, just skip this check
            # This prevents RCON flakiness from keeping server awake forever
            RCON_FAIL_COUNT=$((RCON_FAIL_COUNT + 1))
            # Only log every 10th failure to avoid spam
            if [ $((RCON_FAIL_COUNT % 10)) -eq 1 ]; then
                log "RCON unavailable (count: $RCON_FAIL_COUNT), skipping player check"
            fi
            sleep "$AUTOPAUSE_POLL_INTERVAL"
            continue
        fi
        RCON_FAIL_COUNT=0

        if [ "$player_count" -gt 0 ]; then
            if [ "$IDLE_SECONDS" -gt 0 ]; then
                log "Players online ($player_count), resetting idle timer"
            fi
            IDLE_SECONDS=0
        elif is_chunker_active; then
            if [ "$IDLE_SECONDS" -gt 0 ]; then
                log "Chunker active, resetting idle timer"
            fi
            IDLE_SECONDS=0
        else
            IDLE_SECONDS=$((IDLE_SECONDS + AUTOPAUSE_POLL_INTERVAL))
            local remaining=$((timeout_seconds - IDLE_SECONDS))

            if [ "$IDLE_SECONDS" -ge "$timeout_seconds" ]; then
                log "Server idle for $AUTOPAUSE_TIMEOUT minutes, pausing..."
                pause_server
            elif [ $((IDLE_SECONDS % 60)) -eq 0 ] && [ "$remaining" -gt 0 ]; then
                log "Server idle, pausing in $((remaining / 60)) minutes..."
            fi
        fi

        sleep "$AUTOPAUSE_POLL_INTERVAL"
    done
}

cleanup() {
    log "Cleaning up..."
    stop_proxy
    stop_wake_listener
    rm -f "$WAKE_SIGNAL"
    if [ "$PAUSED" = "true" ]; then
        JAVA_PID=$(find_java_pid)
        if [ -n "$JAVA_PID" ]; then
            kill -CONT "$JAVA_PID" 2>/dev/null || true
        fi
    fi
}

trap cleanup EXIT INT TERM

# Main
log "Auto-pause enabled (timeout: ${AUTOPAUSE_TIMEOUT}m, poll: ${AUTOPAUSE_POLL_INTERVAL}s)"
wait_for_server
main_loop
