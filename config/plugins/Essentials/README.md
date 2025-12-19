# Essentials Configuration

This directory contains EssentialsX configuration for the Lumo Server.

## Welcome System

### New Player Experience
When a new player joins for the first time, they receive:

1. **Welcome Message**: Colorful announcement explaining server features
   - Starting balance notification ($1000)
   - Hub world navigation instructions
   - Plot claiming guide
   - Command help reference

2. **Starter Kit**: Automatically given on first join
   - Iron tools (sword, pickaxe, axe, shovel)
   - Food (bread and cooked beef)
   - Building materials (planks, cobblestone, torches)
   - Utilities (crafting table, bed)

3. **Starting Balance**: $1000 to get started with the economy

4. **Spawn Location**: New players spawn in the hub world

### Message of the Day (MOTD)
Shown to all players (including returning players) on login:
- Server name and description
- Quick command references
- Warp and help instructions

### Kits

#### Starter Kit
- **Delay**: 0 (one-time, auto-given to new players)
- **Contents**: Iron tools, food, building materials, utilities
- **Command**: `/kit starter` (if they somehow lose items)

#### Tools Kit
- **Delay**: 86400 seconds (24 hours)
- **Contents**: Iron pickaxe, iron axe, torches
- **Command**: `/kit tools`
- **Usage**: Can be claimed once per day for replacement tools

### Economy Settings

- **Starting Balance**: $1000
- **Currency Symbol**: $
- **Currency Format**: #,##0.00 (shows cents)
- **Max Money**: 10,000,000,000,000
- **Min Money**: -10,000 (allows debt)

Players can:
- `/sell` - Sell items for money
- `/balance` - Check current balance
- `/pay <player> <amount>` - Send money to other players
- `/worth` - Check how much items are worth

### Teleportation

- **Delay**: 3 seconds (prevents instant teleport)
- **Cooldown**: 5 seconds between teleports
- **Cancellation**: Movement cancels teleport
- **Homes**: Players can set up to 3 homes by default

### Spawn Settings

- **Priority**: Essentials spawn (use `/setspawn`)
- **Spawn on Join**: New players only
- **Respawn**: Players respawn at home (if set), otherwise spawn

## Customization

### Changing Welcome Message
Edit the `newbies.announce-format` in `config.yml`:
```yaml
newbies:
  announce-format: 'Your custom message here with {DISPLAYNAME}'
```

Color codes:
- `&a` = Green, `&b` = Cyan, `&c` = Red
- `&e` = Yellow, `&6` = Gold, `&7` = Gray
- `&l` = Bold, `&r` = Reset

### Modifying Starter Kit
Edit the `kits.starter.items` list in `config.yml`:
```yaml
kits:
  starter:
    delay: 0
    items:
      - item_name quantity
```

Item names use Minecraft namespaced IDs (e.g., `iron_sword`, `cooked_beef`).

### Adding New Kits
Add new kit sections under `kits:`:
```yaml
kits:
  your-kit-name:
    delay: 86400  # seconds (0 = one-time)
    items:
      - item_name quantity
```

### Changing Economy Values
Edit economy settings in `config.yml`:
```yaml
starting-balance: 1000
currency-symbol: '$'
max-money: 10000000000000
```

## File Reference

- **config.yml**: Main configuration (economy, teleports, kits, welcome)
- **worth.yml**: Item sell values for `/sell` command
- **README.md**: This documentation file

## Useful Commands

### Admin Commands
```
/setspawn - Set the server spawn point
/setwarp <name> - Create a warp point
/delwarp <name> - Delete a warp point
/essentials reload - Reload configuration
```

### Player Commands
```
/spawn - Teleport to spawn
/warp <name> - Teleport to warp
/sethome <name> - Set home location
/home <name> - Teleport to home
/kit <name> - Claim a kit
/balance - Check money
/sell - Sell items in hand
```

## Notes

- Changes to config.yml require server restart or `/essentials reload`
- Kit items use modern Minecraft item IDs (1.13+ format)
- Welcome message supports multi-line with `\n`
- Color codes work in signs, chat, and announcements
