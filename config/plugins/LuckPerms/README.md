# LuckPerms Configuration

This directory contains pre-configured permission groups for the server.

## Permission Groups

### Default (Member)
- **Weight**: 0
- **Prefix**: Gray text
- **Permissions**: Basic player permissions including:
  - Teleportation (spawn, warp, home, tpa)
  - Economy commands (pay, balance, sell)
  - PlotSquared plot management
  - Multiverse world access
  - Voice chat

### Builder
- **Weight**: 10
- **Prefix**: `[Builder]` in aqua
- **Inherits**: default
- **Additional Permissions**: Full WorldEdit access including:
  - Clipboard operations (copy, paste, rotate, flip)
  - Region editing (set, replace, walls, faces)
  - Brushes and tools
  - Unrestricted build limits

### Moderator
- **Weight**: 20
- **Prefix**: `[Mod]` in gold
- **Inherits**: builder
- **Additional Permissions**: Moderation tools including:
  - Ban, kick, mute players
  - Teleportation commands
  - Gamemode changes
  - Vanish and god mode
  - Inventory inspection
  - Social spy

### Admin
- **Weight**: 100
- **Prefix**: `[Admin]` in red
- **Inherits**: moderator
- **Permissions**: Full server access (`*`)

## Usage

Groups are automatically loaded when LuckPerms starts. To assign a group to a player:

```
/lp user <player> parent add <group>
```

To promote a player through the ranks:
```
/lp user <player> parent set builder
/lp user <player> parent set moderator
/lp user <player> parent set admin
```

To view a player's permissions:
```
/lp user <player> info
```

## Storage Format

Groups are stored in JSON format in `json-storage/groups/`. These files are automatically created when the server starts if LuckPerms is configured to use JSON storage.
