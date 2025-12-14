#!/bin/bash
# Lumo Server World Initialization Script
# Checks if worlds exist before creating them, making setup truly idempotent
# Run via: docker exec lumo-minecraft /scripts/init-worlds.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if rcon-cli is available
if ! command -v rcon-cli &> /dev/null; then
    log_error "rcon-cli not found. Are you running inside the minecraft container?"
    exit 1
fi

# Function to check if world exists (by checking directory)
world_exists() {
    local world_name=$1
    [ -d "/data/$world_name" ]
}

# Function to create world if it doesn't exist
create_world() {
    local world_name=$1
    shift
    local create_args="$@"

    if world_exists "$world_name"; then
        log_info "World '$world_name' already exists, skipping creation"
        return 0
    fi

    log_info "Creating world '$world_name' with args: $create_args"
    if rcon-cli "mv create $world_name $create_args"; then
        log_info "World '$world_name' created successfully"
    else
        log_warn "Failed to create world '$world_name' (generator may not be loaded yet)"
        return 1
    fi
}

# Function to configure world (always runs - idempotent)
configure_world() {
    local world_name=$1
    shift
    local property=$1
    local value=$2

    if ! world_exists "$world_name"; then
        log_warn "World '$world_name' doesn't exist, skipping configuration"
        return 1
    fi

    rcon-cli "mvm set $property $value $world_name" > /dev/null 2>&1 || true
}

echo "========================================"
echo "  Lumo Server World Initialization"
echo "========================================"
echo ""

# Wait for server to be fully ready
log_info "Checking server readiness..."
if ! rcon-cli "list" > /dev/null 2>&1; then
    log_error "Server not responding to RCON. Is it fully started?"
    exit 1
fi
log_info "Server is ready"
echo ""

# Phase 1: Create all worlds
echo "--- Phase 1: Creating Worlds ---"
create_world "hub" "NORMAL" "-g" "VoidWorld"
create_world "lumo_wilds" "NORMAL"
create_world "lumo_wilds_nether" "NETHER"
create_world "lumo_wilds_the_end" "THE_END"
create_world "lumo_city" "NORMAL" "-g" "PlotSquared"
echo ""

# Phase 2: Configure worlds
echo "--- Phase 2: Configuring Worlds ---"

# Hub configuration
if world_exists "hub"; then
    log_info "Configuring hub (adventure, peaceful, no pvp)"
    configure_world "hub" "gamemode" "adventure"
    configure_world "hub" "difficulty" "peaceful"
    configure_world "hub" "pvp" "false"
fi

# Lumo Wilds configuration
if world_exists "lumo_wilds"; then
    log_info "Configuring lumo_wilds (survival, hard)"
    configure_world "lumo_wilds" "gamemode" "survival"
    configure_world "lumo_wilds" "difficulty" "hard"
fi

# Lumo City configuration
if world_exists "lumo_city"; then
    log_info "Configuring lumo_city (survival, peaceful, no pvp)"
    configure_world "lumo_city" "gamemode" "survival"
    configure_world "lumo_city" "difficulty" "peaceful"
    configure_world "lumo_city" "pvp" "false"
fi

echo ""
echo "--- Summary ---"
for world in hub lumo_wilds lumo_wilds_nether lumo_wilds_the_end lumo_city; do
    if world_exists "$world"; then
        echo -e "${GREEN}✓${NC} $world"
    else
        echo -e "${RED}✗${NC} $world (not created)"
    fi
done

echo ""
log_info "World initialization complete!"
