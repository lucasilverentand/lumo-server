# Lumo Server

Production-ready Minecraft Paper server with 20+ plugins, autopause, and automated backups.

## Quick Start

```bash
docker run -e EULA=true -p 25565:25565 ghcr.io/lucasilverentand/lumo-server:latest
```

Connect to `localhost:25565` in Minecraft 1.21.10.

## Features

- **20+ Pre-configured Plugins** - Multiverse, BlueMap, FAWE, WorldGuard, LuckPerms, Essentials, and more
- **5 Auto-Created Worlds** - Hub, survival wilds (Terralith), nether, end, and creative plots
- **Autopause** - Saves resources when idle, instant wake on connection
- **Automated Backups** - S3/rclone support, retention policies, Discord notifications
- **Single Container** - No docker-compose required for basic usage

## Full Setup

```bash
docker run -d --name minecraft-server \
  -e EULA=true \
  -e MEMORY=4G \
  -e ENABLE_AUTOPAUSE=true \
  -p 25565:25565 \
  -p 8100:8100 \
  -p 25575:25575 \
  -p 24454:24454/udp \
  -v minecraft_data:/data \
  -v minecraft_backups:/backups \
  --restart unless-stopped \
  ghcr.io/lucasilverentand/lumo-server:latest
```

## Documentation

**Full documentation:** https://lucasilverentand.github.io/lumo-server/

- [Quick Start Guide](https://lucasilverentand.github.io/lumo-server/getting-started/quick-start/)
- [Docker Setup](https://lucasilverentand.github.io/lumo-server/getting-started/docker/)
- [Kubernetes Deployment](https://lucasilverentand.github.io/lumo-server/deployment/kubernetes/)
- [Environment Variables](https://lucasilverentand.github.io/lumo-server/configuration/environment/)
- [Automated Backups](https://lucasilverentand.github.io/lumo-server/features/backups/)
- [Troubleshooting](https://lucasilverentand.github.io/lumo-server/reference/troubleshooting/)

## Image Tags

- `latest` - Latest stable release
- `1.21.10` - Specific Minecraft version
- `<commit-sha>` - Specific build

## Ports

| Port | Service | Protocol |
|------|---------|----------|
| 25565 | Minecraft | TCP |
| 8100 | BlueMap Web | TCP |
| 25575 | RCON | TCP |
| 24454 | Voice Chat | UDP |

## License

See [LICENSE](LICENSE) file for details.
