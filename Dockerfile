# Lumo Minecraft Server - Built from scratch
# Minimal image with Paper server and plugins

ARG MC_VERSION=1.21.4
ARG JAVA_VERSION=21

# =============================================================================
# Stage 1: Build mcrcon for RCON communication
# =============================================================================
FROM alpine:3.20 AS mcrcon-builder

RUN apk add --no-cache gcc musl-dev make git
RUN git clone --depth 1 https://github.com/Tiiffi/mcrcon.git /tmp/mcrcon && \
    cd /tmp/mcrcon && make

# =============================================================================
# Stage 2: Build PlotSquared from source
# =============================================================================
FROM eclipse-temurin:21-jdk-alpine AS plotsquared-builder

RUN apk add --no-cache git

WORKDIR /build
RUN git clone --depth 1 https://github.com/IntellectualSites/PlotSquared.git .
RUN ./gradlew :plotsquared-bukkit:shadowJar --no-daemon -x test -q
RUN cp Bukkit/build/libs/plotsquared-bukkit-*.jar /PlotSquared.jar

# =============================================================================
# Stage 3: Download everything
# =============================================================================
FROM alpine:3.20 AS downloader

RUN apk add --no-cache curl jq parallel

WORKDIR /downloads
RUN mkdir -p plugins datapacks

ARG MC_VERSION

# Download Paper server
RUN echo "Downloading Paper server..." && \
    PAPER_BUILD=$(curl -s "https://api.papermc.io/v2/projects/paper/versions/${MC_VERSION}/builds" | jq -r '.builds[-1].build') && \
    curl -sSL -o /downloads/paper.jar \
    "https://api.papermc.io/v2/projects/paper/versions/${MC_VERSION}/builds/${PAPER_BUILD}/downloads/paper-${MC_VERSION}-${PAPER_BUILD}.jar"

# Download script for Modrinth
COPY <<'EOF' /usr/local/bin/download_modrinth
#!/bin/sh
set -e
PROJECT=$1; MC_VERSION=$2; LOADER=${3:-paper}
echo "Downloading $PROJECT..."
VERSION_DATA=$(curl -sS "https://api.modrinth.com/v2/project/$PROJECT/version?loaders=%5B%22$LOADER%22%5D&game_versions=%5B%22$MC_VERSION%22%5D" | jq -r '.[0]')
[ "$VERSION_DATA" = "null" ] && VERSION_DATA=$(curl -sS "https://api.modrinth.com/v2/project/$PROJECT/version?loaders=%5B%22$LOADER%22%5D" | jq -r '.[0]')
FILE_URL=$(echo "$VERSION_DATA" | jq -r '.files[0].url')
FILE_NAME=$(echo "$VERSION_DATA" | jq -r '.files[0].filename')
curl -sSL -o "/downloads/plugins/$FILE_NAME" "$FILE_URL"
echo "✓ $PROJECT"
EOF
RUN chmod +x /usr/local/bin/download_modrinth

# Download all Modrinth plugins in parallel
RUN cat <<'PLUGINS' | parallel -j8 --colsep ' ' download_modrinth {1} ${MC_VERSION} {2}
multiverse-core paper
multiverse-portals paper
multiverse-netherportals paper
multiverse-signportals paper
multiverse-inventories paper
bluemap paper
fastasyncworldedit paper
worldguard paper
simple-voice-chat paper
chunker paper
lagfixer paper
coreprotect paper
viaversion paper
viabackwards paper
voidworld paper
simpledeathchest paper
luckperms paper
essentialsx paper
fancynpcs paper
quickshop-hikari paper
PLUGINS

# Download from other sources
RUN curl -sSL -o /downloads/plugins/Vault.jar \
    "https://api.spiget.org/v2/resources/34315/download" && echo "✓ Vault"

RUN curl -sSL -o /downloads/plugins/SmoothTimber.jar \
    "https://api.spiget.org/v2/resources/39965/download" && echo "✓ SmoothTimber"

# Shopkeepers for NPC-based admin shops (works with FancyNpcs or vanilla villagers)
RUN curl -sSL -o /downloads/plugins/Shopkeepers.jar \
    "https://raw.githubusercontent.com/Shopkeepers/Repository/main/releases/com/nisovin/shopkeepers/Shopkeepers/2.24.0/Shopkeepers-2.24.0.jar" && echo "✓ Shopkeepers"

# PlotSquared is built from source in plotsquared-builder stage
COPY --from=plotsquared-builder /PlotSquared.jar /downloads/plugins/PlotSquared.jar
RUN echo "✓ PlotSquared (built from source)"

# Download Terralith datapack
RUN VERSION_DATA=$(curl -sS "https://api.modrinth.com/v2/project/terralith/version?loaders=%5B%22datapack%22%5D&game_versions=%5B%22${MC_VERSION}%22%5D" | jq -r '.[0]') && \
    FILE_URL=$(echo "$VERSION_DATA" | jq -r '.files[0].url') && \
    FILE_NAME=$(echo "$VERSION_DATA" | jq -r '.files[0].filename') && \
    curl -sSL -o "/downloads/datapacks/$FILE_NAME" "$FILE_URL" && echo "✓ Terralith"

RUN echo "=== Downloaded ===" && ls -la /downloads/plugins/ && ls -la /downloads/datapacks/

# =============================================================================
# Stage 4: Final minimal image
# =============================================================================
FROM eclipse-temurin:${JAVA_VERSION}-jre-alpine

LABEL maintainer="Luca Silverentand"
LABEL description="Lumo Minecraft Server"

# Create minecraft user
RUN addgroup -g 1000 minecraft && \
    adduser -u 1000 -G minecraft -h /data -D minecraft

# Install minimal runtime dependencies
RUN apk add --no-cache bash tini netcat-openbsd iproute2 procps socat python3

WORKDIR /server

# Copy server and plugins
COPY --from=downloader /downloads/paper.jar /server/paper.jar
COPY --from=downloader /downloads/plugins/ /server/plugins/
COPY --from=downloader /downloads/datapacks/ /server/datapacks/

# Copy mcrcon for RCON commands
COPY --from=mcrcon-builder /tmp/mcrcon/mcrcon /usr/local/bin/mcrcon

# Copy plugin configurations
COPY --chown=minecraft:minecraft config/plugins/BlueMap/ /server/plugins/BlueMap/
COPY --chown=minecraft:minecraft config/plugins/Chunker/ /server/plugins/Chunker/
COPY --chown=minecraft:minecraft config/plugins/Essentials/ /server/plugins/Essentials/
COPY --chown=minecraft:minecraft config/plugins/PlotSquared/ /server/plugins/PlotSquared/

# Copy entrypoint and scripts
COPY --chmod=755 docker/server/entrypoint.sh /entrypoint.sh
COPY --chmod=755 docker/server/init-worlds.sh /init-worlds.sh
COPY --chmod=755 docker/server/autopause.sh /autopause.sh
COPY --chmod=755 docker/server/wake-listener.py /wake-listener.py

# Set ownership
RUN chown -R minecraft:minecraft /server

# Environment defaults
ENV MEMORY=4G \
    EULA=false \
    MAX_PLAYERS=20 \
    MOTD="Welcome to the Lumo Universe!" \
    DIFFICULTY=normal \
    GAMEMODE=survival \
    HARDCORE=false \
    PVP=true \
    ONLINE_MODE=true \
    VIEW_DISTANCE=12 \
    SIMULATION_DISTANCE=10 \
    SPAWN_PROTECTION=0 \
    ENABLE_COMMAND_BLOCK=true \
    WHITELIST=false \
    ENFORCE_WHITELIST=false \
    ENABLE_RCON=true \
    RCON_PASSWORD=minecraft \
    RCON_PORT=25575 \
    ENABLE_AUTOPAUSE=true \
    AUTOPAUSE_TIMEOUT=10 \
    AUTOPAUSE_POLL_INTERVAL=30

# Ports
EXPOSE 25565/tcp
EXPOSE 25575/tcp
EXPOSE 8100/tcp
EXPOSE 24454/udp

# Health check - verify server port is accepting connections
HEALTHCHECK --interval=30s --timeout=10s --start-period=300s --retries=3 \
    CMD nc -z localhost 25565 || exit 1

USER minecraft
VOLUME /data
WORKDIR /data

ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]
