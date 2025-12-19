# Hub World Setup Guide

This guide explains how to set up informational signs and NPCs in the hub world to help new players navigate the server.

## Portal Signs

Place signs near each portal with the following information:

### Lumo Wilds Portal
```
[Portal Sign 1]
&6&l━━━━━━━━━━━━
&e&lLumo Wilds
&7Survival Hard Mode
&7Build, explore, survive!
&6&l━━━━━━━━━━━━

[Portal Sign 2]
&b✦ &7PvP enabled
&b✦ &7Claim protection with PlotSquared
&b✦ &7Terralith terrain
```

Commands to create:
```
/essentials:createholo LumoWildsInfo 0 64 0 &e&lLumo Wilds\n&7Survival Hard Mode
```

### Lumo City Portal
```
[Portal Sign 1]
&6&l━━━━━━━━━━━━
&b&lLumo City
&7Creative plots
&7Peaceful building area
&6&l━━━━━━━━━━━━

[Portal Sign 2]
&e✦ &7Use /plot auto to claim
&e✦ &7Free plots for all players
&e✦ &7No PvP, no mobs
```

### Economy Tutorial Sign
Place near spawn in hub:

```
[Economy Sign 1]
&a&l━━━━━━━━━━━━━━━━━━━━
&2&lEconomy Guide
&a&l━━━━━━━━━━━━━━━━━━━━
&7You start with &a$1000

[Economy Sign 2]
&6How to earn money:
&e✦ &7/sell - Sell items
&e✦ &7Complete quests
&e✦ &7Trade with players

[Economy Sign 3]
&6How to spend money:
&e✦ &7/buy - Buy from shops
&e✦ &7/plot auto - Claim plots
&e✦ &7Trade with players

[Economy Sign 4]
&6Commands:
&e/balance &7- Check money
&e/pay <player> <amount>
&e/worth &7- Check item value
```

## Welcome Area Setup

### Spawn Platform
1. Build a central spawn platform in the hub (coordinates: 0, 64, 0 recommended)
2. Place a welcome hologram or sign above spawn point
3. Add directional signs pointing to each portal

### Information Board
Create a large wall with signs explaining:

```
[Welcome Board - Top]
&6&l━━━━━━━━━━━━━━━━━━━━━━━━━━━━
&e&lWelcome to Lumo Server!
&6&l━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Commands Section]
&a&lUseful Commands:
&e/spawn &7- Return to hub
&e/warp &7- List all warps
&e/sethome <name> &7- Set home
&e/home <name> &7- Teleport home
&e/tpa <player> &7- Request teleport
&e/help &7- Show all commands

[Worlds Section]
&b&lAvailable Worlds:
&e• &bHub &7- You are here
&e• &6Lumo Wilds &7- Survival hard
&e• &aLumo City &7- Creative plots
&e• &cNether &7- Accessed via portals
&e• &5The End &7- Accessed via portals

[Economy Section]
&2&lEconomy:
&7Starting balance: &a$1000
&7Use &e/sell &7to sell items
&7Use &e/balance &7to check money
&7Use &e/pay &7to trade with players

[Plots Section]
&d&lPlot Claims:
&7Go to &bLumo City
&7Use &e/plot auto &7to claim
&7Free plots for everyone!
```

## NPCs (Using FancyNPCs)

If using FancyNPCs, create NPCs with the following configurations:

### Information NPC
```
/npc create "Server Guide" PLAYER
/npc skin "Server Guide" <skin-name>
/npc message add "Server Guide" "&6Welcome to Lumo Server!"
/npc message add "Server Guide" "&7Use portals to explore different worlds"
/npc message add "Server Guide" "&7Type &e/help &7for commands"
```

### Economy NPC
```
/npc create "Economy Helper" VILLAGER
/npc message add "Economy Helper" "&aYou start with $1000!"
/npc message add "Economy Helper" "&7Use &e/sell &7to sell items for money"
/npc message add "Economy Helper" "&7Use &e/worth &7to check item values"
```

### Plot Guide NPC
```
/npc create "Plot Guide" PLAYER
/npc message add "Plot Guide" "&bWant your own building space?"
/npc message add "Plot Guide" "&7Visit &bLumo City &7and use &e/plot auto"
/npc message add "Plot Guide" "&7Plots are free for all players!"
```

## Automated Setup

For automated hub setup, you can create a script to run these commands when the server starts:

1. Add to `docker/server/init-hub.sh` (create new file)
2. Run commands via RCON to place signs/NPCs
3. Call from `entrypoint.sh` after world creation

## Portal Locations

Recommended portal locations in hub (around spawn at 0, 64, 0):

- **Lumo Wilds**: North (+Z direction) - Portal at 0, 64, 20
- **Lumo City**: South (-Z direction) - Portal at 0, 64, -20
- **Nether**: East (+X direction) - Portal at 20, 64, 0 (or use vanilla portals)
- **The End**: West (-X direction) - Portal at -20, 64, 0 (or use vanilla stronghold)

Use Multiverse portals:
```
/mv portal <portal-name> <destination-world>
```

## Testing Checklist

After setting up the hub:
- [ ] Signs are visible and readable
- [ ] Portal destinations are correct
- [ ] NPCs respond with messages
- [ ] Commands in signs work
- [ ] Welcome message shows on first join
- [ ] Starter kit is given to new players
- [ ] Economy tutorial is clear and accurate
