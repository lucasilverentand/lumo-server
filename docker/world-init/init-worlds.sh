#!/bin/bash
set -e

RCON_HOST="${RCON_HOST:-minecraft}"
RCON_PORT="${RCON_PORT:-25575}"
RCON_PASSWORD="${RCON_PASSWORD:-minecraft}"

rcon() {
  mcrcon -H "$RCON_HOST" -P "$RCON_PORT" -p "$RCON_PASSWORD" "$@"
}

world_exists() {
  [ -d "/data/$1" ]
}

create_world() {
  local world_name=$1
  shift
  if world_exists "$world_name"; then
    echo "[SKIP] World '$world_name' already exists"
  else
    echo "[CREATE] Creating world '$world_name'..."
    rcon "mv create $world_name $*" || echo "[WARN] Failed to create $world_name"
    sleep 2
  fi
}

echo "========================================"
echo "  Lumo Server World Initialization"
echo "========================================"
echo ""

echo "Waiting for server to be ready..."
until rcon "list" > /dev/null 2>&1; do
  echo "  Server not ready, waiting..."
  sleep 5
done
echo "Server is ready!"
echo ""

echo "--- Phase 1: Creating Worlds ---"
create_world hub NORMAL -g VoidWorld
create_world lumo_wilds NORMAL
create_world lumo_wilds_nether NETHER
create_world lumo_wilds_the_end THE_END
create_world lumo_city NORMAL -g PlotSquared
echo ""

echo "--- Phase 2: Configuring Worlds ---"

if world_exists hub; then
  echo "[CONFIG] Configuring hub..."
  rcon "mv modify hub set gamemode adventure"
  rcon "mv modify hub set difficulty peaceful"
  rcon "mv modify hub set pvp false"
fi

if world_exists lumo_wilds; then
  echo "[CONFIG] Configuring lumo_wilds..."
  rcon "mv modify lumo_wilds set gamemode survival"
  rcon "mv modify lumo_wilds set difficulty hard"
fi

if world_exists lumo_city; then
  echo "[CONFIG] Configuring lumo_city..."
  rcon "mv modify lumo_city set gamemode survival"
  rcon "mv modify lumo_city set difficulty peaceful"
  rcon "mv modify lumo_city set pvp false"
fi

echo ""
echo "--- Summary ---"
for world in hub lumo_wilds lumo_wilds_nether lumo_wilds_the_end lumo_city; do
  if world_exists "$world"; then
    echo "✓ $world"
  else
    echo "✗ $world (not created)"
  fi
done

echo ""
echo "World initialization complete!"
