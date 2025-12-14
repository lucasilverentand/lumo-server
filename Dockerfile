# Lumo Minecraft Server
# Pre-built image with all plugins and datapacks
# Based on itzg/minecraft-server

ARG BASE_IMAGE=itzg/minecraft-server:java21
ARG MC_VERSION=1.21.4

# =============================================================================
# Stage 1: Build PlotSquared from source
# =============================================================================
FROM gradle:8.11-jdk21 AS plotsquared-builder

WORKDIR /build

# Clone PlotSquared repository
RUN git clone --depth 1 https://github.com/IntellectualSites/PlotSquared.git .

# Build PlotSquared (Bukkit module for Paper/Spigot)
RUN ./gradlew :plotsquared-bukkit:shadowJar --no-daemon -x test

# Find and copy the built JAR (shadowJar output is in Bukkit/build/libs/)
RUN mkdir -p /output && \
    cp /build/Bukkit/build/libs/plotsquared-bukkit-*.jar /output/PlotSquared-Bukkit.jar && \
    ls -la /output/

# =============================================================================
# Stage 2: Download plugins from Modrinth
# =============================================================================
FROM alpine:3.20 AS downloader

RUN apk add --no-cache curl jq

WORKDIR /downloads

# Create directories
RUN mkdir -p plugins datapacks

# Download script for Modrinth plugins
# Usage: download_modrinth <project_slug> <mc_version> <loader>
COPY <<'DOWNLOAD_SCRIPT' /usr/local/bin/download_modrinth
#!/bin/sh
set -e
PROJECT=$1
MC_VERSION=$2
LOADER=$3

echo "Downloading $PROJECT for MC $MC_VERSION ($LOADER)..."

# Get the latest compatible version
VERSION_DATA=$(curl -sS "https://api.modrinth.com/v2/project/$PROJECT/version?loaders=%5B%22$LOADER%22%5D&game_versions=%5B%22$MC_VERSION%22%5D" | jq -r '.[0]')

if [ "$VERSION_DATA" = "null" ] || [ -z "$VERSION_DATA" ]; then
    echo "Warning: No compatible version found for $PROJECT, trying without version filter..."
    VERSION_DATA=$(curl -sS "https://api.modrinth.com/v2/project/$PROJECT/version?loaders=%5B%22$LOADER%22%5D" | jq -r '.[0]')
fi

if [ "$VERSION_DATA" = "null" ] || [ -z "$VERSION_DATA" ]; then
    echo "Error: Could not find $PROJECT for $LOADER"
    exit 1
fi

FILE_URL=$(echo "$VERSION_DATA" | jq -r '.files[0].url')
FILE_NAME=$(echo "$VERSION_DATA" | jq -r '.files[0].filename')

curl -sSL -o "/downloads/plugins/$FILE_NAME" "$FILE_URL"
echo "Downloaded: $FILE_NAME"
DOWNLOAD_SCRIPT

# Download script for Modrinth datapacks
COPY <<'DOWNLOAD_DATAPACK' /usr/local/bin/download_datapack
#!/bin/sh
set -e
PROJECT=$1
MC_VERSION=$2

echo "Downloading datapack $PROJECT for MC $MC_VERSION..."

VERSION_DATA=$(curl -sS "https://api.modrinth.com/v2/project/$PROJECT/version?loaders=%5B%22datapack%22%5D&game_versions=%5B%22$MC_VERSION%22%5D" | jq -r '.[0]')

if [ "$VERSION_DATA" = "null" ] || [ -z "$VERSION_DATA" ]; then
    echo "Warning: No compatible version found for $PROJECT, trying without version filter..."
    VERSION_DATA=$(curl -sS "https://api.modrinth.com/v2/project/$PROJECT/version?loaders=%5B%22datapack%22%5D" | jq -r '.[0]')
fi

if [ "$VERSION_DATA" = "null" ] || [ -z "$VERSION_DATA" ]; then
    echo "Error: Could not find datapack $PROJECT"
    exit 1
fi

FILE_URL=$(echo "$VERSION_DATA" | jq -r '.files[0].url')
FILE_NAME=$(echo "$VERSION_DATA" | jq -r '.files[0].filename')

curl -sSL -o "/downloads/datapacks/$FILE_NAME" "$FILE_URL"
echo "Downloaded datapack: $FILE_NAME"
DOWNLOAD_DATAPACK

RUN chmod +x /usr/local/bin/download_modrinth /usr/local/bin/download_datapack

ARG MC_VERSION

# Download all Modrinth plugins (Paper/Bukkit loader)
RUN download_modrinth multiverse-core ${MC_VERSION} paper || download_modrinth multiverse-core ${MC_VERSION} bukkit
RUN download_modrinth multiverse-portals ${MC_VERSION} paper || download_modrinth multiverse-portals ${MC_VERSION} bukkit
RUN download_modrinth multiverse-netherportals ${MC_VERSION} paper || download_modrinth multiverse-netherportals ${MC_VERSION} bukkit
RUN download_modrinth multiverse-signportals ${MC_VERSION} paper || download_modrinth multiverse-signportals ${MC_VERSION} bukkit
RUN download_modrinth multiverse-inventories ${MC_VERSION} paper || download_modrinth multiverse-inventories ${MC_VERSION} bukkit
RUN download_modrinth bluemap ${MC_VERSION} paper || download_modrinth bluemap ${MC_VERSION} bukkit
RUN download_modrinth worldedit ${MC_VERSION} paper || download_modrinth worldedit ${MC_VERSION} bukkit
RUN download_modrinth worldguard ${MC_VERSION} paper || download_modrinth worldguard ${MC_VERSION} bukkit
RUN download_modrinth simple-voice-chat ${MC_VERSION} paper || download_modrinth simple-voice-chat ${MC_VERSION} bukkit
RUN download_modrinth chunker ${MC_VERSION} paper || download_modrinth chunker ${MC_VERSION} bukkit
RUN download_modrinth lagfixer ${MC_VERSION} paper || download_modrinth lagfixer ${MC_VERSION} bukkit
RUN download_modrinth coreprotect ${MC_VERSION} paper || download_modrinth coreprotect ${MC_VERSION} bukkit
RUN download_modrinth viaversion ${MC_VERSION} paper || download_modrinth viaversion ${MC_VERSION} bukkit
RUN download_modrinth viabackwards ${MC_VERSION} paper || download_modrinth viabackwards ${MC_VERSION} bukkit
RUN download_modrinth voidworld ${MC_VERSION} paper || download_modrinth voidworld ${MC_VERSION} bukkit
RUN download_modrinth simpledeathchest ${MC_VERSION} paper || download_modrinth simpledeathchest ${MC_VERSION} bukkit

# Permissions & Economy
RUN download_modrinth luckperms ${MC_VERSION} paper || download_modrinth luckperms ${MC_VERSION} bukkit
RUN download_modrinth essentialsx ${MC_VERSION} paper || download_modrinth essentialsx ${MC_VERSION} bukkit

# Download Vault from Spiget (resource 34315)
RUN echo "Downloading Vault from Spiget..." && \
    curl -sSL -o /downloads/plugins/Vault.jar \
    "https://api.spiget.org/v2/resources/34315/download"

# Download SmoothTimber from Spiget (resource 39965)
RUN echo "Downloading SmoothTimber from Spiget..." && \
    curl -sSL -o /downloads/plugins/SmoothTimber.jar \
    "https://api.spiget.org/v2/resources/39965/download"

# Download Terralith datapack
RUN download_datapack terralith ${MC_VERSION}

# List all downloaded files
RUN echo "=== Downloaded Plugins ===" && ls -la /downloads/plugins/ && \
    echo "=== Downloaded Datapacks ===" && ls -la /downloads/datapacks/

# =============================================================================
# Stage 2: Final image
# =============================================================================
FROM ${BASE_IMAGE}

# Re-declare ARG to use in this stage
ARG MC_VERSION=1.21.4

LABEL maintainer="Luca Silverentand"
LABEL description="Lumo Minecraft Server with pre-installed plugins"

# Copy plugins from downloader stage
COPY --chown=1000:1000 --from=downloader /downloads/plugins/ /plugins/

# Copy PlotSquared from builder stage
COPY --chown=1000:1000 --from=plotsquared-builder /output/PlotSquared-Bukkit.jar /plugins/

# Copy datapacks from downloader stage
COPY --chown=1000:1000 --from=downloader /downloads/datapacks/ /datapacks/

# Copy BlueMap configuration (needs to be in plugins/BlueMap/ for BlueMap to find it)
COPY --chown=1000:1000 config/plugins/BlueMap/ /plugins/BlueMap/

# Copy Chunker configuration (auto pre-generation when no players online)
COPY --chown=1000:1000 config/plugins/Chunker/ /plugins/Chunker/

# Server configuration defaults (can be overridden at runtime)
# Note: VERSION must be hardcoded here as Docker ARGs don't persist in ENV
ENV EULA=TRUE \
    TYPE=PAPER \
    VERSION=1.21.4 \
    MEMORY=4G \
    MAX_PLAYERS=20 \
    MOTD="Welcome to the Lumo Universe!" \
    DIFFICULTY=normal \
    MODE=survival \
    PVP=true \
    ONLINE_MODE=true \
    VIEW_DISTANCE=12 \
    SPAWN_PROTECTION=0 \
    ENABLE_COMMAND_BLOCK=true \
    USE_AIKAR_FLAGS=true \
    MAX_TICK_TIME=-1 \
    WHITELIST_ENABLED=true \
    ENFORCE_WHITELIST=true \
    # Disable automatic plugin downloads since we pre-baked them
    MODRINTH_PROJECTS="" \
    SPIGET_RESOURCES="" \
    # Tell the container to use our pre-downloaded content
    COPY_PLUGINS_SRC=/plugins \
    COPY_DATAPACKS_SRC=/datapacks \
    # Enable autopause for resource efficiency
    ENABLE_AUTOPAUSE=true \
    AUTOPAUSE_TIMEOUT_EST=600 \
    AUTOPAUSE_TIMEOUT_INIT=300 \
    AUTOPAUSE_TIMEOUT_KN=300

# Expose ports
EXPOSE 25565/tcp
EXPOSE 8100/tcp
EXPOSE 24454/udp

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=300s --retries=5 \
    CMD mc-health || exit 1
