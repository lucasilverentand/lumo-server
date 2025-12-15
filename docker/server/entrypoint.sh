#!/bin/bash
set -e

log() { echo "[Lumo] $1"; }

# =============================================================================
# EULA Check
# =============================================================================
if [ "$EULA" != "true" ] && [ "$EULA" != "TRUE" ]; then
    echo "ERROR: You must accept the Minecraft EULA by setting EULA=true"
    echo "See: https://www.minecraft.net/en-us/eula"
    exit 1
fi

log "EULA accepted"

# =============================================================================
# First-time setup: Copy server files to data volume
# =============================================================================
if [ ! -f "/data/paper.jar" ]; then
    log "First run - copying server files..."
    cp /server/paper.jar /data/paper.jar
fi

if [ ! -d "/data/plugins" ]; then
    log "Copying plugins..."
    cp -r /server/plugins /data/plugins
else
    # Update plugins from image (preserving configs)
    log "Syncing plugins..."
    for jar in /server/plugins/*.jar; do
        [ -f "$jar" ] && cp "$jar" /data/plugins/
    done
    # Copy default configs for new plugins
    for dir in /server/plugins/*/; do
        dirname=$(basename "$dir")
        [ ! -d "/data/plugins/$dirname" ] && cp -r "$dir" "/data/plugins/$dirname"
    done
fi

if [ ! -d "/data/world/datapacks" ]; then
    mkdir -p /data/world/datapacks
fi
log "Syncing datapacks..."
cp /server/datapacks/* /data/world/datapacks/ 2>/dev/null || true

# =============================================================================
# Generate server.properties
# =============================================================================
log "Generating server.properties..."

# When autopause is enabled, server listens on internal port 25566
# (proxy handles external 25565). Otherwise, listen directly on 25565.
if [ "${ENABLE_AUTOPAUSE}" = "true" ]; then
    MC_SERVER_PORT=25566
else
    MC_SERVER_PORT=25565
fi

cat > /data/server.properties <<EOF
# Lumo Server Configuration
motd=${MOTD}
max-players=${MAX_PLAYERS}
difficulty=${DIFFICULTY}
gamemode=${GAMEMODE}
hardcore=${HARDCORE}
pvp=${PVP}
online-mode=${ONLINE_MODE}
view-distance=${VIEW_DISTANCE}
simulation-distance=${SIMULATION_DISTANCE}
spawn-protection=${SPAWN_PROTECTION}
enable-command-block=${ENABLE_COMMAND_BLOCK}
white-list=${WHITELIST}
enforce-whitelist=${ENFORCE_WHITELIST}
enable-rcon=${ENABLE_RCON}
rcon.password=${RCON_PASSWORD}
rcon.port=${RCON_PORT}
server-port=${MC_SERVER_PORT}
level-name=world
level-type=minecraft:normal
max-tick-time=${MAX_TICK_TIME}
enable-status=true
allow-flight=${ALLOW_FLIGHT}
player-idle-timeout=${PLAYER_IDLE_TIMEOUT}
spawn-animals=${SPAWN_ANIMALS}
spawn-monsters=${SPAWN_MONSTERS}
spawn-npcs=${SPAWN_NPCS}
network-compression-threshold=${NETWORK_COMPRESSION_THRESHOLD}
entity-broadcast-range-percentage=${ENTITY_BROADCAST_RANGE}
EOF

# =============================================================================
# Accept EULA
# =============================================================================
echo "eula=true" > /data/eula.txt

# =============================================================================
# Configure ops.json (server operators)
# =============================================================================
if [ -n "$OPS" ]; then
    log "Configuring server operators..."
    echo "[" > /data/ops.json
    first=true
    IFS=',' read -ra OP_LIST <<< "$OPS"
    for op in "${OP_LIST[@]}"; do
        op=$(echo "$op" | xargs)  # trim whitespace
        if [ -n "$op" ]; then
            if [ "$first" = true ]; then
                first=false
            else
                echo "," >> /data/ops.json
            fi
            # Format: username or username:level (default level 4)
            if [[ "$op" == *":"* ]]; then
                username="${op%%:*}"
                level="${op##*:}"
            else
                username="$op"
                level="4"
            fi
            cat >> /data/ops.json <<OPENTRY
  {
    "name": "$username",
    "level": $level,
    "bypassesPlayerLimit": true
  }
OPENTRY
        fi
    done
    echo "]" >> /data/ops.json
    log "Added ${#OP_LIST[@]} operator(s)"
fi

# =============================================================================
# Configure whitelist.json
# =============================================================================
if [ -n "$WHITELIST_USERS" ]; then
    log "Configuring whitelist..."
    echo "[" > /data/whitelist.json
    first=true
    IFS=',' read -ra WL_LIST <<< "$WHITELIST_USERS"
    for user in "${WL_LIST[@]}"; do
        user=$(echo "$user" | xargs)  # trim whitespace
        if [ -n "$user" ]; then
            if [ "$first" = true ]; then
                first=false
            else
                echo "," >> /data/whitelist.json
            fi
            cat >> /data/whitelist.json <<WLENTRY
  {
    "name": "$user"
  }
WLENTRY
        fi
    done
    echo "]" >> /data/whitelist.json
    log "Added ${#WL_LIST[@]} whitelisted user(s)"
fi

# =============================================================================
# JVM Arguments (Aikar's flags)
# =============================================================================
MEMORY_OPTS="-Xms${MEMORY} -Xmx${MEMORY}"

AIKAR_FLAGS="-XX:+UseG1GC \
-XX:+ParallelRefProcEnabled \
-XX:MaxGCPauseMillis=200 \
-XX:+UnlockExperimentalVMOptions \
-XX:+DisableExplicitGC \
-XX:+AlwaysPreTouch \
-XX:G1NewSizePercent=30 \
-XX:G1MaxNewSizePercent=40 \
-XX:G1HeapRegionSize=8M \
-XX:G1ReservePercent=20 \
-XX:G1HeapWastePercent=5 \
-XX:G1MixedGCCountTarget=4 \
-XX:InitiatingHeapOccupancyPercent=15 \
-XX:G1MixedGCLiveThresholdPercent=90 \
-XX:G1RSetUpdatingPauseTimePercent=5 \
-XX:SurvivorRatio=32 \
-XX:+PerfDisableSharedMem \
-XX:MaxTenuringThreshold=1 \
-Dusing.aikars.flags=https://mcflags.emc.gs \
-Daikars.new.flags=true"

JVM_OPTS="${MEMORY_OPTS} ${AIKAR_FLAGS}"

# =============================================================================
# Start Background Services
# =============================================================================

# World initialization
if [ -f "/init-worlds.sh" ]; then
    log "Starting world initialization in background..."
    /init-worlds.sh &
fi

# Auto-pause (monitors players and Chunker, pauses when idle)
if [ "${ENABLE_AUTOPAUSE}" = "true" ] && [ -f "/autopause.sh" ]; then
    log "Starting auto-pause monitor (timeout: ${AUTOPAUSE_TIMEOUT:-10}m)..."
    /autopause.sh &
fi

# =============================================================================
# Start Server
# =============================================================================
log "Starting Minecraft server..."
log "Memory: ${MEMORY}"

cd /data
exec java ${JVM_OPTS} -jar paper.jar --nogui "$@"
