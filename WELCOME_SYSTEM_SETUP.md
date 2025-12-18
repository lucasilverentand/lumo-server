# Welcome System Setup Guide

This document describes the in-game setup required to complete the welcome system for new players.

## Completed (Config-Based)

The following features have been implemented via configuration files and will work automatically:

### ✅ Welcome Message
- **File**: `config/plugins/Essentials/custom.txt`
- **Trigger**: Automatically shown to new players on first join
- **Content**: Comprehensive guide covering:
  - Server features overview
  - World descriptions (hub, lumo_wilds, lumo_city, nether, end)
  - Economy tutorial (starting balance, earning money, buying plots)
  - Useful commands (/spawn, /home, /kit starter, /sell, /plot auto)

### ✅ Starter Kit
- **Command**: `/kit starter` (auto-given on first join)
- **Items**:
  - Stone sword, pickaxe, axe, and shovel (basic tools)
  - 16 apples (food)
  - 32 torches (lighting)
  - 16 cooked beef (better food)
  - 64 oak planks (building)
  - 64 cobblestone (building)

### ✅ Economy System
- **Starting Balance**: $1000
- **Item Values**: Configured in `config/plugins/Essentials/worth.yml`
- **Commands**: `/balance`, `/sell hand`, `/pay <player> <amount>`

## Required In-Game Setup

The following tasks require manual in-game setup by an admin/operator:

### 🔨 Hub Portal Signs

Create informational signs near each portal in the hub world explaining destinations:

#### Lumo Wilds Portal
```
[Line 1] &3&l→ Lumo Wilds
[Line 2] &7Survival Hard
[Line 3] &7Terralith terrain
[Line 4] &eExplore & survive!
```

#### Lumo City Portal
```
[Line 1] &3&l→ Lumo City
[Line 2] &7Creative Plots
[Line 3] &7Use /plot auto
[Line 4] &eCost: $500
```

#### Nether Portal
```
[Line 1] &3&l→ Nether
[Line 2] &7Dangerous!
[Line 3] &7Find rare items
[Line 4] &eBeware of mobs
```

#### End Portal
```
[Line 1] &3&l→ The End
[Line 2] &7Dragon & cities
[Line 3] &7End-game content
[Line 4] &eGear up first!
```

### 🔨 Tutorial NPC (Optional)

Using FancyNPCs plugin, create a tutorial NPC in the hub:

1. **Create NPC**:
   ```
   /npc create Tutorial_Guide
   /npc skin Tutorial_Guide <player_name_or_url>
   ```

2. **Set NPC Messages** (interactive tutorial):
   ```
   /npc message Tutorial_Guide add &6Welcome to Lumo Server!
   /npc message Tutorial_Guide add &7Click me to learn more about:
   /npc message Tutorial_Guide add &e1. Worlds & Portals
   /npc message Tutorial_Guide add &e2. Economy & Money
   /npc message Tutorial_Guide add &e3. Plot Claims
   /npc message Tutorial_Guide add &e4. Commands & Features
   ```

3. **Add Click Actions** (execute commands on click):
   ```
   /npc action Tutorial_Guide add tell &3--- WORLDS ---
   /npc action Tutorial_Guide add tell &7Hub: Spawn & portals
   /npc action Tutorial_Guide add tell &7Wilds: Survival gameplay
   /npc action Tutorial_Guide add tell &7City: Creative plots
   /npc action Tutorial_Guide add tell &7Nether/End: Dimensions
   ```

### 🔨 Economy Tutorial NPC (Optional)

Create a "Banker" NPC to explain economy:

1. **Create NPC**:
   ```
   /npc create Banker
   /npc skin Banker <villager_or_player_skin>
   ```

2. **Set Messages**:
   ```
   /npc message Banker add &6&lEconomy Guide
   /npc message Banker add &7Starting Balance: &a$1000
   /npc message Banker add &7Earn by: &eMining, selling items
   /npc message Banker add &7Commands: &a/balance, /sell hand
   /npc message Banker add &7Buy plots: &a/plot auto &7($500)
   /npc message Banker add &7Best earnings: &eDiamonds, Netherite
   ```

### 🔨 Spawn Point Setup

Ensure new players spawn correctly in the hub:

1. **Go to desired spawn location in hub world**
2. **Set spawn point**:
   ```
   /setspawn
   ```
   Or using Essentials:
   ```
   /essentials setspawn hub
   ```

3. **Verify in config** that `spawn-on-join: newbies` is enabled (already set)

## Testing Checklist

To verify the welcome system works:

- [ ] Join server with a new account/player
- [ ] Verify welcome message displays automatically
- [ ] Verify starter kit is automatically given
- [ ] Check starting balance is $1000 (`/balance`)
- [ ] Test `/kit starter` command shows cooldown (already used)
- [ ] Verify spawn location is in hub world
- [ ] Check portal signs are visible and readable
- [ ] Test NPC interactions (if created)
- [ ] Test economy commands (`/sell hand` with an ore)

## Additional Enhancement Ideas

Future improvements to consider:

1. **Quest System**: Add a quest plugin for guided progression
2. **Tutorial Parkour**: Build a parkour course with rewards
3. **Daily Rewards**: Configure daily login bonuses
4. **Achievements**: Set up advancement tracking
5. **Discord Integration**: Link welcome messages to Discord
6. **Interactive Hub**: Add more interactive elements (buttons, holograms)
7. **Video Tutorial**: Create a showcase video for new players
8. **Rule Board**: Add a physical rules display in hub

## Notes

- The `custom.txt` file uses Minecraft color codes (&1-&f, &l for bold, &m for strikethrough)
- FancyNPCs requires in-game setup as it stores NPC data in its own database
- Signs can use color codes on servers with appropriate permissions
- Consider using WorldGuard to protect hub signs from griefing
- BlueMap web interface helps players explore before joining
