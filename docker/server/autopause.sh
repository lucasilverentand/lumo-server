#!/bin/bash
# Auto-pause script - pauses server when idle, wakes on connection
#
# Pause conditions (all must be true for AUTOPAUSE_TIMEOUT minutes):
#   1. No players online
#   2. Chunker not actively generating (progress files not modified recently)
#
# Wake condition:
#   - Queued TCP connections detected on port 25565

# Configuration
AUTOPAUSE_TIMEOUT=${AUTOPAUSE_TIMEOUT:-10}      # Minutes idle before pause
AUTOPAUSE_POLL_INTERVAL=${AUTOPAUSE_POLL_INTERVAL:-30}  # Seconds between checks
AUTOPAUSE_WAKE_INTERVAL=${AUTOPAUSE_WAKE_INTERVAL:-5}   # Seconds between wake checks when paused
CHUNKER_ACTIVITY_THRESHOLD=120                   # Seconds - if progress file modified within this, Chunker is active
RCON_HOST="localhost"
RCON_PORT="${RCON_PORT:-25575}"
RCON_PASSWORD="${RCON_PASSWORD:-minecraft}"
MC_PORT=25565

# State
IDLE_SECONDS=0
PAUSED=false
JAVA_PID=""

log() {
    echo "[AutoPause] $(date '+%H:%M:%S') $1"
}

rcon() {
    mcrcon -H "$RCON_HOST" -P "$RCON_PORT" -p "$RCON_PASSWORD" "$@" 2>/dev/null
}

get_player_count() {
    local result
    result=$(rcon "list" 2>/dev/null) || echo ""
    # Parse "There are X of Y players online"
    echo "$result" | grep -oP 'There are \K[0-9]+' || echo "-1"
}

is_chunker_active() {
    local now
    now=$(date +%s)

    # Check all potential Chunker progress files
    for progress_file in /data/*_pregenerator.txt /data/plugins/Chunker/*.txt; do
        if [ -f "$progress_file" ]; then
            local mtime
            mtime=$(stat -c %Y "$progress_file" 2>/dev/null || echo "0")
            local age=$((now - mtime))
            if [ "$age" -lt "$CHUNKER_ACTIVITY_THRESHOLD" ]; then
                return 0  # Active
            fi
        fi
    done
    return 1  # Not active
}

has_pending_connections() {
    # Check for connections in SYN_RECV or ESTABLISHED state to MC port
    # When server is paused, clients will be stuck in connection queue
    local conn_count
    conn_count=$(ss -tn state syn-recv state established "( sport = :$MC_PORT )" 2>/dev/null | wc -l)
    [ "$conn_count" -gt 1 ]  # Header line counts as 1
}

find_java_pid() {
    pgrep -f "paper.jar" || pgrep -f "java.*-jar" || echo ""
}

pause_server() {
    if [ "$PAUSED" = "true" ]; then
        return
    fi

    JAVA_PID=$(find_java_pid)
    if [ -z "$JAVA_PID" ]; then
        log "Cannot find Java process to pause"
        return
    fi

    log "Pausing server (PID: $JAVA_PID)..."
    kill -STOP "$JAVA_PID" 2>/dev/null || true
    PAUSED=true
}

resume_server() {
    if [ "$PAUSED" = "false" ]; then
        return
    fi

    JAVA_PID=$(find_java_pid)
    if [ -n "$JAVA_PID" ]; then
        log "Resuming server (PID: $JAVA_PID)..."
        kill -CONT "$JAVA_PID" 2>/dev/null || true
    fi

    PAUSED=false
    IDLE_SECONDS=0
}

wait_for_server() {
    log "Waiting for server to be ready..."
    until rcon "list" > /dev/null 2>&1; do
        sleep 5
    done
    log "Server is ready, starting auto-pause monitor"
}

main_loop() {
    local timeout_seconds=$((AUTOPAUSE_TIMEOUT * 60))

    while true; do
        if [ "$PAUSED" = "true" ]; then
            # When paused, check for incoming connections
            if has_pending_connections; then
                log "Connection attempt detected, waking server..."
                resume_server
            fi
            sleep "$AUTOPAUSE_WAKE_INTERVAL"
            continue
        fi

        local player_count
        player_count=$(get_player_count)

        if [ "$player_count" = "-1" ]; then
            # RCON failed, server might be starting/stopping
            IDLE_SECONDS=0
            sleep "$AUTOPAUSE_POLL_INTERVAL"
            continue
        fi

        if [ "$player_count" -gt 0 ]; then
            # Players online, reset idle counter
            if [ "$IDLE_SECONDS" -gt 0 ]; then
                log "Players online ($player_count), resetting idle timer"
            fi
            IDLE_SECONDS=0
        elif is_chunker_active; then
            # No players but Chunker is working
            if [ "$IDLE_SECONDS" -gt 0 ]; then
                log "Chunker active, resetting idle timer"
            fi
            IDLE_SECONDS=0
        else
            # No players and Chunker idle
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

# Main
log "Auto-pause enabled (timeout: ${AUTOPAUSE_TIMEOUT}m, poll: ${AUTOPAUSE_POLL_INTERVAL}s)"
wait_for_server
main_loop
