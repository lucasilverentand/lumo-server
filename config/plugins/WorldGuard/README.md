# WorldGuard Configuration

This directory contains pre-configured WorldGuard protections for all server worlds.

## Protection Overview

### Hub World
- **Full protection**: Adventure mode, no building, no PvP, no mobs
- **Purpose**: Central spawn and portal hub for world travel
- **Spawn region**: 100x100 block protected area around spawn

### Lumo Wilds (Survival)
- **Spawn protection only**: 200x200 block safe zone
- **Global flags**: TNT disabled, wither damage disabled, mob griefing disabled
- **PvP**: Enabled outside spawn
- **Building**: Allowed outside spawn
- **Creepers**: Enabled for survival challenge (can be changed to deny)

### Lumo Wilds Nether
- **Spawn protection**: 100x100 block portal zone
- **Global flags**: TNT disabled, wither damage disabled, mob griefing disabled
- **Ghast fireballs**: Enabled for nether challenge
- **PvP**: Enabled outside spawn
- **Fire/lava**: Natural hazards enabled

### Lumo Wilds The End
- **Spawn protection**: 100x100 block main island spawn
- **Global flags**: TNT disabled, wither damage disabled, enderman griefing disabled
- **PvP**: Enabled outside spawn
- **Dragon fight**: Not restricted

### Lumo City (PlotSquared)
- **Plot-based protection**: PlotSquared handles individual plots
- **Global flags**: All explosions disabled, PvP disabled, peaceful mode
- **Roads/unclaimed**: Protected from griefing by global flags
- **Spawn region**: 100x100 block protected area

## Region Structure

Each world has a `regions.yml` file with two key regions:

1. **`__global__`**: Applies to the entire world (priority 0)
   - Anti-grief protections
   - World-specific rules
   - Entry messages

2. **`spawn`**: Protected spawn area (priority 10)
   - Overrides global settings
   - Prevents building near spawn
   - Safe zone for new players

## Managing Regions

### View Regions
```
/rg list
/rg info <region>
/rg info __global__
```

### Modify Flags
```
/rg flag <region> <flag> <value>
/rg flag __global__ block-tnt deny
/rg flag spawn pvp deny
```

### Create New Regions
```
# Select area with wooden axe (WorldEdit wand)
# Left-click one corner, right-click opposite corner
/rg define <region-name>
/rg flag <region-name> <flag> <value>
```

### Add Owners/Members
```
/rg addowner <region> <player>
/rg addmember <region> <player>

# Use groups (requires LuckPerms integration)
/rg addowner <region> g:admin
/rg addmember <region> g:builder
```

### Reload Regions
```
/rg load
```

## Common Flags

| Flag | Values | Purpose |
|------|--------|---------|
| `build` | allow/deny | Building permission |
| `block-tnt` | deny | Prevent TNT explosions |
| `creeper-explosion` | allow/deny | Control creeper explosions |
| `wither-damage` | deny | Prevent wither explosions |
| `mob-griefing` | deny | Prevent mob block damage |
| `enderman-grief` | deny | Prevent enderman block stealing |
| `pvp` | allow/deny | Enable/disable PvP |
| `fire-spread` | allow/deny | Control fire spreading |
| `mob-spawning` | allow/deny | Control mob spawning |
| `greeting` | text | Message on region entry |
| `farewell` | text | Message on region exit |

## Priority System

Regions with higher priority override lower priority regions:
- **Priority 10**: Spawn regions (highest)
- **Priority 0**: Global regions (lowest)

This means spawn protections override global settings.

## Customization

To adjust protections:

1. **Edit region files**: Modify `worlds/<world>/regions.yml`
2. **Reload**: Run `/rg load` in-game
3. **Or use commands**: Use `/rg flag` commands for live changes

## Important Notes

- Region coordinates use **spawn location** as reference point
- All coordinates are inclusive (min and max are both protected)
- Y-axis uses full build height: -64 to 320 (1.18+ world height)
- Groups (e.g., `admin`, `moderator`) require LuckPerms integration
- Changes to YAML files require `/rg load` to take effect
