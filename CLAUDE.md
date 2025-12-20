# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Lumo Server is a Docker-based Minecraft Paper server with 20+ plugins, autopause functionality, and automated CI/CD. Single container design - no docker-compose required for basic usage.

## Build & Run Commands

```bash
# Build the Docker image
docker build -t lumo-server .

# Run locally (minimum)
docker run -e EULA=true -p 25565:25565 lumo-server

# Run with persistence and all features
docker run -e EULA=true -e MEMORY=4G -e ENABLE_AUTOPAUSE=true \
  -p 25565:25565 -p 8100:8100 -p 25575:25575 -p 24454:24454/udp \
  -v minecraft_data:/data lumo-server

# RCON command (requires mcrcon or docker exec)
docker exec <container> mcrcon -H localhost -P 25575 -p minecraft "list"
```

## Architecture

### Multi-Stage Docker Build (Dockerfile)
1. **mcrcon-builder**: Compiles RCON CLI tool
2. **plotsquared-builder**: Builds PlotSquared from source (Gradle)
3. **downloader**: Parallel downloads of 20+ plugins from Modrinth/Spiget
4. **final**: Alpine JRE 21 runtime with plugins + configs

### Background Services (started by entrypoint.sh)
- **init-worlds.sh**: Creates 5 worlds via Multiverse RCON commands on first run
- **autopause.sh**: Monitors idle state, pauses JVM with SIGSTOP to save resources
- **wake-listener.py**: Shows "server sleeping" message when paused, triggers wake on login

### Autopause Port Proxy
When autopause is enabled:
- Active: External:25565 → socat proxy → localhost:25566 (MC server)
- Paused: External:25565 → wake-listener.py (shows sleep message, triggers wake)

## Key Files

| File | Purpose |
|------|---------|
| `Dockerfile` | Multi-stage build with plugin downloads |
| `docker/server/entrypoint.sh` | EULA check, config generation, JVM startup with Aikar flags |
| `docker/server/autopause.sh` | Player/Chunker monitoring, SIGSTOP/SIGCONT control |
| `docker/server/wake-listener.py` | Python daemon for paused-server client messages |
| `docker/server/init-worlds.sh` | Multiverse world creation via RCON |
| `config/plugins/` | Plugin configs (Essentials, PlotSquared, Chunker, BlueMap) |
| `.github/workflows/build.yml` | CI: build → test 17 plugins → push to ghcr.io |

## CI/CD Pipeline

Triggered on: push to main, PRs, manual dispatch

1. **build**: Docker build with layer caching
2. **test**: Starts server, waits for startup, validates 17+ plugins load via log parsing and RCON
3. **push**: Tags as `latest`, `{MC_VERSION}`, `{sha}` → ghcr.io/lucasilverentand/lumo-server

## Adding/Updating Plugins

Plugins are downloaded during Docker build (Dockerfile lines 62-83). To add a plugin:
1. Find the Modrinth project ID or Spiget resource ID
2. Add download command in the `downloader` stage
3. Rebuild image - plugins sync to `/data` on container start

## Environment Variables

**Required**: `EULA=true`

**Common**:
- `MEMORY=4G` - JVM heap
- `OPS="player1,player2:3"` - Op list (optional level suffix)
- `WHITELIST_USERS="player1,player2"` - Whitelist (requires `WHITELIST=true`)
- `ENABLE_AUTOPAUSE=true` - Enable idle pause
- `RCON_PASSWORD=minecraft` - RCON password (change in production)

**Ports**: 25565 (game), 25575 (RCON), 8100 (BlueMap web), 24454/udp (voice chat)

## Worlds

Auto-created on first startup via init-worlds.sh:
- **hub**: VoidWorld, adventure mode, peaceful - spawn/portal hub
- **lumo_wilds**: Terralith terrain, survival hard, main gameplay
- **lumo_wilds_nether/end**: Linked dimensions
- **lumo_city**: PlotSquared plots, peaceful - building area

## Health Checks

The image includes a `mc-health` script for Kubernetes health checks:

```yaml
# Kubernetes readiness probe
readinessProbe:
  exec:
    command: ["mc-health"]
  initialDelaySeconds: 300
  periodSeconds: 30
  timeoutSeconds: 10

# Kubernetes liveness probe
livenessProbe:
  exec:
    command: ["mc-health"]
  initialDelaySeconds: 300
  periodSeconds: 60
  timeoutSeconds: 10
```

The `mc-health` script uses RCON to verify the server is responsive. It respects the `RCON_HOST`, `RCON_PORT`, and `RCON_PASSWORD` environment variables (defaults: localhost, 25575, minecraft).
