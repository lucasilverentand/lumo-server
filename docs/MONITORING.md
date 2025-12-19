# Server Monitoring

The Lumo Server includes built-in monitoring with health checks and optional Discord webhooks for server alerts.

## Features

- **Health Check Endpoint**: HTTP endpoint returning server status as JSON
- **Player Count Monitoring**: Track online players in real-time
- **TPS Monitoring**: Monitor server performance (Ticks Per Second)
- **Memory Usage**: Track server memory consumption
- **Discord Webhooks**: Optional notifications for server events
- **Auto-Recovery**: Integration with Docker healthchecks

## Quick Start

### Enable Monitoring

Monitoring is enabled by default. The health endpoint is available at:

```
http://localhost:8080/health
```

### Configure Discord Webhooks (Optional)

To receive Discord notifications:

1. Create a Discord webhook in your server:
   - Server Settings → Integrations → Webhooks → New Webhook
   - Copy the webhook URL

2. Set the webhook URL when running the container:
   ```bash
   docker run -e DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/..." lumo-server
   ```

## Health Endpoint

### Endpoint: `GET /health`

Returns current server status in JSON format.

**Example Request:**
```bash
curl http://localhost:8080/health
```

**Example Response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-12-19T12:00:00Z",
  "server": {
    "online": true,
    "players": 5,
    "max_players": 20,
    "tps": 19.85,
    "memory_used": 0,
    "memory_max": 0,
    "uptime": 3600,
    "last_check": "2025-12-19T12:00:00Z",
    "error": null
  }
}
```

**Response Fields:**
- `status`: "healthy" or "unhealthy"
- `timestamp`: Current time in ISO 8601 format
- `server.online`: Whether server is responding to RCON
- `server.players`: Current player count
- `server.max_players`: Maximum players allowed
- `server.tps`: Ticks per second (target: 20.0)
- `server.uptime`: Server uptime in seconds
- `server.error`: Error message if server is down

## Discord Notifications

When Discord webhook is configured, you'll receive notifications for:

### Server Down/Up
```
❌ Server is DOWN or not responding
✅ Server is now ONLINE
```

### Low TPS Warning
```
⚠️ Server TPS is low: 12.5 (threshold: 15.0)
```

TPS warnings are sent once every 5 minutes to avoid spam.

## Configuration

Configure monitoring via environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `ENABLE_MONITOR` | `true` | Enable/disable monitoring |
| `MONITOR_PORT` | `8080` | HTTP port for health endpoint |
| `MONITOR_CHECK_INTERVAL` | `60` | Check interval in seconds |
| `TPS_WARNING_THRESHOLD` | `15.0` | TPS level to trigger warnings |
| `DISCORD_WEBHOOK_URL` | `""` | Discord webhook URL (optional) |
| `RCON_HOST` | `localhost` | RCON hostname |
| `RCON_PORT` | `25575` | RCON port |
| `RCON_PASSWORD` | `minecraft` | RCON password |

### Example with Custom Configuration

```bash
docker run \
  -e ENABLE_MONITOR=true \
  -e MONITOR_PORT=9000 \
  -e MONITOR_CHECK_INTERVAL=30 \
  -e TPS_WARNING_THRESHOLD=18.0 \
  -e DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/..." \
  -p 9000:9000 \
  lumo-server
```

## Docker Integration

### Healthcheck

The Docker container includes a built-in healthcheck that uses the monitoring endpoint:

```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=300s --retries=3 \
    CMD curl -f http://localhost:8080/health || nc -z localhost 25565 || exit 1
```

This means:
- Check every 30 seconds
- Wait 5 minutes after startup before first check
- Mark unhealthy after 3 failed checks
- Fallback to port check if monitor is unavailable

### Check Container Health

```bash
# View health status
docker inspect --format='{{.State.Health.Status}}' <container>

# View health log
docker inspect --format='{{json .State.Health}}' <container> | jq
```

## Monitoring Dashboards

### Using the JSON Endpoint

The health endpoint can be integrated with monitoring tools:

**Prometheus** (with json_exporter):
```yaml
scrape_configs:
  - job_name: 'minecraft'
    static_configs:
      - targets: ['localhost:8080']
    metrics_path: /health
```

**Grafana** (with SimpleJSON datasource):
- Add SimpleJSON datasource pointing to `http://localhost:8080/health`
- Create dashboard with player count, TPS, and uptime metrics

**Uptime Kuma**:
- Monitor Type: HTTP(s)
- URL: `http://localhost:8080/health`
- Expected Status Code: 200

### Using Discord Webhooks

Discord webhooks provide instant notifications without external monitoring:
- No additional infrastructure needed
- Instant alerts to your Discord server
- Color-coded messages (green = up, red = down, yellow = warning)

## Troubleshooting

### Monitor not starting

Check logs for errors:
```bash
docker logs <container> | grep MONITOR
```

Common issues:
- Port 8080 already in use (change `MONITOR_PORT`)
- RCON not enabled or wrong credentials
- Python3 not available in container

### Health endpoint returns unhealthy

The server may be:
- Still starting up (wait for startup period)
- Crashed or frozen
- Not responding to RCON (check RCON settings)

Check server logs:
```bash
docker logs <container> | tail -100
```

### Discord webhooks not working

Verify:
- Webhook URL is correct and not expired
- Webhook URL is properly escaped in environment variable
- Network connectivity to Discord API
- Check monitor logs for webhook errors

### TPS always shows 0

TPS requires a plugin that provides TPS data:
- Some plugins provide `/tps` command
- Paper includes built-in TPS tracking
- May require server restart after plugin installation

## Advanced Usage

### Querying via API

```bash
# Get server status
curl -s http://localhost:8080/health | jq

# Check if online
curl -s http://localhost:8080/health | jq -r '.server.online'

# Get player count
curl -s http://localhost:8080/health | jq -r '.server.players'

# Check TPS
curl -s http://localhost:8080/health | jq -r '.server.tps'
```

### Automated Monitoring Script

```bash
#!/bin/bash
while true; do
  STATUS=$(curl -s http://localhost:8080/health | jq -r '.status')
  if [ "$STATUS" != "healthy" ]; then
    echo "Server is unhealthy! Checking logs..."
    docker logs minecraft-server --tail 50
  fi
  sleep 60
done
```

### Load Balancer Health Checks

If using a load balancer (e.g., HAProxy, nginx):

```nginx
upstream minecraft {
  server minecraft1:25565 max_fails=3 fail_timeout=30s;
  server minecraft2:25565 max_fails=3 fail_timeout=30s;
}

# Health check
location /health {
  proxy_pass http://minecraft1:8080/health;
}
```

## Security Considerations

### Exposing the Monitor Port

The health endpoint provides server information. Consider:

**Internal Networks Only** (recommended):
```bash
# Only expose to localhost
docker run -p 127.0.0.1:8080:8080 lumo-server
```

**Public Exposure** (if needed):
- Use a reverse proxy with authentication
- Rate limit the endpoint
- Consider what information is exposed (player counts, uptime)

### Discord Webhook Protection

- Never commit webhook URLs to version control
- Rotate webhooks if exposed
- Use environment variables or secrets management
- Webhooks can be regenerated if compromised

## Performance Impact

The monitoring system is lightweight:
- CPU: <1% overhead
- Memory: ~20MB for Python process
- Network: Minimal (RCON queries every 60s by default)
- Disk: None

To reduce overhead:
- Increase `MONITOR_CHECK_INTERVAL` (e.g., 300 for 5 minutes)
- Disable Discord webhooks if not needed
- Disable monitoring entirely with `ENABLE_MONITOR=false`

---

Last Updated: 2025-12-19
